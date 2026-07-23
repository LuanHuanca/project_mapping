#include "../native_renderer.h"
#include "internal_state.h"
#include <fstream>
#include <sstream>
#include <iostream>

#ifndef GL_MAJOR_VERSION
#define GL_MAJOR_VERSION 0x821B
#endif
#ifndef GL_MINOR_VERSION
#define GL_MINOR_VERSION 0x821C
#endif

// Force NVIDIA Optimus & AMD PowerXpress High Performance Dedicated GPU Export Symbols
extern "C" {
    __declspec(dllexport) DWORD NvOptimusEnablement = 0x00000001;
    __declspec(dllexport) int AmdPowerXpressRequestHighPerformance = 1;
}

// Embedded GLSL Shader Source Strings for 100% Reliable Loading Regardless of CWD
static const char* EMBEDDED_BASE_VERTEX = R"(#version 330 core
layout (location = 0) in vec2 aPos;
uniform mat3 u_homography;
out vec2 v_uv;
void main() {
    v_uv = aPos;
    vec3 pos = u_homography * vec3(aPos.x * 2.0 - 1.0, (1.0 - aPos.y) * 2.0 - 1.0, 1.0);
    gl_Position = vec4(pos.xy / pos.z, 0.0, 1.0);
}
)";

static const char* EMBEDDED_BASE_FRAGMENT = R"(#version 330 core
in vec2 v_uv;
out vec4 FragColor;
uniform sampler2D u_texture;
uniform vec4 u_color;
uniform float u_opacity;
uniform int u_has_texture;
void main() {
    vec4 baseColor = u_color;
    if (u_has_texture == 1) {
        baseColor = texture(u_texture, v_uv);
    }
    FragColor = vec4(baseColor.rgb, baseColor.a * u_opacity);
}
)";

static const char* EMBEDDED_CONCENTRIC_PULSE_FRAGMENT = R"(#version 330 core
in vec2 v_uv;
out vec4 FragColor;
uniform float u_time;
uniform float u_speed;
uniform vec4 u_color;
uniform float u_opacity;
void main() {
    vec2 center = vec2(0.5, 0.5);
    float dist = distance(v_uv, center);
    float wave = sin((dist * 20.0) - (u_time * u_speed * 5.0));
    float intensity = smoothstep(0.2, 0.8, wave);
    vec3 color = u_color.rgb * intensity;
    FragColor = vec4(color, u_color.a * u_opacity * intensity);
}
)";

static const char* EMBEDDED_OUTLINE_TRACER_FRAGMENT = R"(#version 330 core
in vec2 v_uv;
out vec4 FragColor;
uniform float u_time;
uniform float u_speed;
uniform vec4 u_color;
uniform float u_opacity;
void main() {
    float borderX = step(v_uv.x, 0.05) + step(0.95, v_uv.x);
    float borderY = step(v_uv.y, 0.05) + step(0.95, v_uv.y);
    float isEdge = clamp(borderX + borderY, 0.0, 1.0);
    float pulse = sin((v_uv.x + v_uv.y + u_time * u_speed) * 10.0) * 0.5 + 0.5;
    float alpha = isEdge * pulse * u_opacity;
    FragColor = vec4(u_color.rgb, alpha);
}
)";

static const char* EMBEDDED_GRID_WAVE_FRAGMENT = R"(#version 330 core
in vec2 v_uv;
out vec4 FragColor;
uniform float u_time;
uniform float u_speed;
uniform vec4 u_color;
uniform float u_opacity;
void main() {
    vec2 grid = sin(v_uv * 30.0 + u_time * u_speed * 4.0);
    float lineVal = step(0.9, grid.x) + step(0.9, grid.y);
    float alpha = clamp(lineVal, 0.0, 1.0) * u_opacity;
    FragColor = vec4(u_color.rgb, alpha);
}
)";

static const char* EMBEDDED_RAINBOW_WAVE_FRAGMENT = R"(#version 330 core
in vec2 v_uv;
out vec4 FragColor;
uniform float u_time;
uniform float u_speed;
uniform float u_opacity;
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}
void main() {
    float hue = fract(v_uv.x + v_uv.y + u_time * u_speed * 0.5);
    vec3 color = hsv2rgb(vec3(hue, 1.0, 1.0));
    FragColor = vec4(color, u_opacity);
}
)";

static const char* EMBEDDED_STROBE_FRAGMENT = R"(#version 330 core
in vec2 v_uv;
out vec4 FragColor;
uniform float u_time;
uniform float u_speed;
uniform vec4 u_color;
uniform float u_opacity;
void main() {
    float toggle = step(0.5, fract(u_time * u_speed * 10.0));
    vec3 color = u_color.rgb * toggle;
    FragColor = vec4(color, u_color.a * u_opacity * toggle);
}
)";

static std::string load_shader_source(const std::string& filepath, const char* fallback_embedded) {
    std::ifstream file(filepath);
    if (file.is_open()) {
        std::stringstream buffer;
        buffer << file.rdbuf();
        return buffer.str();
    }
    return fallback_embedded ? std::string(fallback_embedded) : "";
}

bool RenderEngine::compile_shader(const std::string& vertex_src, const std::string& fragment_src, ShaderProgram& out_shader) {
    if (vertex_src.empty() || fragment_src.empty()) return false;

    const char* v_code = vertex_src.c_str();
    const char* f_code = fragment_src.c_str();

    GLuint vert = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(vert, 1, &v_code, NULL);
    glCompileShader(vert);

    GLint success;
    glGetShaderiv(vert, GL_COMPILE_STATUS, &success);
    if (!success) {
        glDeleteShader(vert);
        return false;
    }

    GLuint frag = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(frag, 1, &f_code, NULL);
    glCompileShader(frag);

    glGetShaderiv(frag, GL_COMPILE_STATUS, &success);
    if (!success) {
        glDeleteShader(vert);
        glDeleteShader(frag);
        return false;
    }

    GLuint prog = glCreateProgram();
    glAttachShader(prog, vert);
    glAttachShader(prog, frag);
    glLinkProgram(prog);

    glGetProgramiv(prog, GL_LINK_STATUS, &success);
    glDeleteShader(vert);
    glDeleteShader(frag);

    if (!success) {
        glDeleteProgram(prog);
        return false;
    }

    out_shader.program_id = prog;
    out_shader.u_homography_loc = glGetUniformLocation(prog, "u_homography");
    out_shader.u_time_loc = glGetUniformLocation(prog, "u_time");
    out_shader.u_resolution_loc = glGetUniformLocation(prog, "u_resolution");
    out_shader.u_color_loc = glGetUniformLocation(prog, "u_color");
    out_shader.u_speed_loc = glGetUniformLocation(prog, "u_speed");
    out_shader.u_opacity_loc = glGetUniformLocation(prog, "u_opacity");
    out_shader.u_texture_loc = glGetUniformLocation(prog, "u_texture");

    return true;
}

void RenderEngine::setup_default_shaders() {
    // Load Base Shader
    std::string base_v = load_shader_source("native/src/shaders/base_vertex.glsl", EMBEDDED_BASE_VERTEX);
    std::string base_f = load_shader_source("native/src/shaders/base_fragment.glsl", EMBEDDED_BASE_FRAGMENT);
    compile_shader(base_v, base_f, base_shader);

    // Load Concentric Pulse Shader
    std::string pulse_v = load_shader_source("native/src/shaders/concentric_pulse_vertex.glsl", EMBEDDED_BASE_VERTEX);
    std::string pulse_f = load_shader_source("native/src/shaders/concentric_pulse_fragment.glsl", EMBEDDED_CONCENTRIC_PULSE_FRAGMENT);
    ShaderProgram pulse_shader;
    if (compile_shader(pulse_v, pulse_f, pulse_shader)) {
        effect_shaders[EFFECT_CONCENTRIC_PULSE] = pulse_shader;
    }

    // Load Outline Tracer Shader
    std::string outline_v = load_shader_source("native/src/shaders/outline_tracer_vertex.glsl", EMBEDDED_BASE_VERTEX);
    std::string outline_f = load_shader_source("native/src/shaders/outline_tracer_fragment.glsl", EMBEDDED_OUTLINE_TRACER_FRAGMENT);
    ShaderProgram outline_shader;
    if (compile_shader(outline_v, outline_f, outline_shader)) {
        effect_shaders[EFFECT_OUTLINE_TRACER] = outline_shader;
    }

    // Load Grid Wave Shader
    std::string grid_v = load_shader_source("native/src/shaders/grid_wave_vertex.glsl", EMBEDDED_BASE_VERTEX);
    std::string grid_f = load_shader_source("native/src/shaders/grid_wave_fragment.glsl", EMBEDDED_GRID_WAVE_FRAGMENT);
    ShaderProgram grid_shader;
    if (compile_shader(grid_v, grid_f, grid_shader)) {
        effect_shaders[EFFECT_GRID_WAVE] = grid_shader;
    }

    // Load Rainbow Wave Shader
    std::string rainbow_v = load_shader_source("native/src/shaders/rainbow_wave_vertex.glsl", EMBEDDED_BASE_VERTEX);
    std::string rainbow_f = load_shader_source("native/src/shaders/rainbow_wave_fragment.glsl", EMBEDDED_RAINBOW_WAVE_FRAGMENT);
    ShaderProgram rainbow_shader;
    if (compile_shader(rainbow_v, rainbow_f, rainbow_shader)) {
        effect_shaders[EFFECT_RAINBOW_WAVE] = rainbow_shader;
    }

    // Load Strobe Shader
    std::string strobe_v = load_shader_source("native/src/shaders/strobe_vertex.glsl", EMBEDDED_BASE_VERTEX);
    std::string strobe_f = load_shader_source("native/src/shaders/strobe_fragment.glsl", EMBEDDED_STROBE_FRAGMENT);
    ShaderProgram strobe_shader;
    if (compile_shader(strobe_v, strobe_f, strobe_shader)) {
        effect_shaders[EFFECT_STROBE] = strobe_shader;
    }
}

void RenderEngine::apply_blend_mode(RenderBlendMode blend_mode) {
    glEnable(GL_BLEND);
    switch (blend_mode) {
        case BLEND_ADDITIVE:
            glBlendFunc(GL_SRC_ALPHA, GL_ONE);
            break;
        case BLEND_MULTIPLY:
            glBlendFunc(GL_DST_COLOR, GL_ZERO);
            break;
        case BLEND_SCREEN:
            glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_COLOR);
            break;
        case BLEND_NORMAL:
        default:
            glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            break;
    }
}

extern "C" {

RENDERER_API RendererStatus init_native_renderer(void* hwnd, int width, int height) {
    auto& engine = RenderEngine::instance();
    ScopedGLContext ctx(engine);

    if (hwnd == nullptr) {
        engine.last_error = RENDERER_ERROR_INVALID_HWND;
        return RENDERER_ERROR_INVALID_HWND;
    }

    HWND win_handle = static_cast<HWND>(hwnd);
    HDC hdc = GetDC(win_handle);
    if (!hdc) {
        engine.last_error = RENDERER_ERROR_GL_CONTEXT_FAILED;
        return RENDERER_ERROR_GL_CONTEXT_FAILED;
    }

    PIXELFORMATDESCRIPTOR pfd = {};
    pfd.nSize = sizeof(pfd);
    pfd.nVersion = 1;
    pfd.dwFlags = PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL | PFD_DOUBLEBUFFER;
    pfd.iPixelType = PFD_TYPE_RGBA;
    pfd.cColorBits = 32;
    pfd.cDepthBits = 24;
    pfd.iLayerType = PFD_MAIN_PLANE;

    int format = ChoosePixelFormat(hdc, &pfd);
    if (!format || !SetPixelFormat(hdc, format, &pfd)) {
        engine.last_error = RENDERER_ERROR_GL_CONTEXT_FAILED;
        return RENDERER_ERROR_GL_CONTEXT_FAILED;
    }

    HGLRC hglrc = wglCreateContext(hdc);
    if (!hglrc || !wglMakeCurrent(hdc, hglrc)) {
        engine.last_error = RENDERER_ERROR_GL_CONTEXT_FAILED;
        return RENDERER_ERROR_GL_CONTEXT_FAILED;
    }

    engine.hwnd = win_handle;
    engine.hdc = hdc;
    engine.hglrc = hglrc;
    engine.viewport_width = width;
    engine.viewport_height = height;
    engine.is_initialized = true;

    if (!gladLoadGL()) {
        engine.last_error = RENDERER_ERROR_GL_CONTEXT_FAILED;
        return RENDERER_ERROR_GL_CONTEXT_FAILED;
    }

    // Explicit OpenGL 3.3 Core Profile Requirement Guard Check
    GLint major = 0, minor = 0;
    glGetIntegerv(GL_MAJOR_VERSION, &major);
    glGetIntegerv(GL_MINOR_VERSION, &minor);

    if (major < 3 || (major == 3 && minor < 3)) {
        std::string err_msg = "[GPU ERROR] OpenGL version " + std::to_string(major) + "." + std::to_string(minor) + " is below required 3.3 Core Profile!\n";
        std::cout << err_msg;
        OutputDebugStringA(err_msg.c_str());
        engine.last_error = RENDERER_ERROR_GL_CONTEXT_FAILED;
        return RENDERER_ERROR_GL_CONTEXT_FAILED;
    }

    const GLubyte* renderer = glGetString(GL_RENDERER);
    const GLubyte* vendor = glGetString(GL_VENDOR);
    const GLubyte* version = glGetString(GL_VERSION);

    std::string diag_info = "==========================================================\n";
    diag_info += "[GPU DIAGNOSTIC] Vendor  : " + std::string(vendor ? (const char*)vendor : "Unknown") + "\n";
    diag_info += "[GPU DIAGNOSTIC] Renderer: " + std::string(renderer ? (const char*)renderer : "Unknown") + "\n";
    diag_info += "[GPU DIAGNOSTIC] Version : " + std::string(version ? (const char*)version : "Unknown") + "\n";
    diag_info += "==========================================================\n";

    std::cout << diag_info;
    OutputDebugStringA(diag_info.c_str());

    glViewport(0, 0, width, height);
    engine.setup_default_shaders();

    engine.last_error = RENDERER_OK;
    return RENDERER_OK;
}

RENDERER_API RendererStatus resize_native_renderer(int width, int height) {
    auto& engine = RenderEngine::instance();
    ScopedGLContext ctx(engine);

    if (!engine.is_initialized) return RENDERER_ERROR_NOT_INITIALIZED;

    engine.viewport_width = width;
    engine.viewport_height = height;
    glViewport(0, 0, width, height);

    engine.last_error = RENDERER_OK;
    return RENDERER_OK;
}

RENDERER_API RendererStatus cleanup_native_renderer() {
    auto& engine = RenderEngine::instance();
    ScopedGLContext ctx(engine);

    if (engine.hglrc) {
        wglMakeCurrent(NULL, NULL);
        wglDeleteContext(engine.hglrc);
        engine.hglrc = nullptr;
    }
    if (engine.hdc && engine.hwnd) {
        ReleaseDC(engine.hwnd, engine.hdc);
        engine.hdc = nullptr;
    }

    engine.is_initialized = false;
    engine.last_error = RENDERER_OK;
    return RENDERER_OK;
}

RENDERER_API RendererStatus get_last_error() {
    return RenderEngine::instance().last_error;
}

RENDERER_API RendererStatus set_homography_matrix(const double* matrix_9_elements) {
    auto& engine = RenderEngine::instance();
    ScopedGLContext ctx(engine);

    if (matrix_9_elements == nullptr) {
        engine.last_error = RENDERER_ERROR_INVALID_MATRIX;
        return RENDERER_ERROR_INVALID_MATRIX;
    }

    for (int i = 0; i < 9; ++i) {
        engine.homography_matrix[i] = static_cast<float>(matrix_9_elements[i]);
    }

    engine.last_error = RENDERER_OK;
    return RENDERER_OK;
}

RENDERER_API RendererStatus set_shape_geometry(int shape_id, const RenderShapeData* shape) {
    auto& engine = RenderEngine::instance();
    ScopedGLContext ctx(engine);

    if (!shape || !shape->vertices || shape->vertex_count < 3) {
        engine.last_error = RENDERER_ERROR_INVALID_SHAPE_ID;
        return RENDERER_ERROR_INVALID_SHAPE_ID;
    }

    auto& gpu_shape = engine.shapes[shape_id];
    gpu_shape.shape_id = shape_id;
    gpu_shape.vertex_count = shape->vertex_count;
    gpu_shape.vertices.assign(shape->vertices, shape->vertices + shape->vertex_count);

    if (engine.is_initialized) {
        if (gpu_shape.vao == 0) {
            glGenVertexArrays(1, &gpu_shape.vao);
            glGenBuffers(1, &gpu_shape.vbo);
        }

        glBindVertexArray(gpu_shape.vao);
        glBindBuffer(GL_ARRAY_BUFFER, gpu_shape.vbo);
        glBufferData(GL_ARRAY_BUFFER, gpu_shape.vertex_count * sizeof(RenderPoint2D), gpu_shape.vertices.data(), GL_DYNAMIC_DRAW);

        glEnableVertexAttribArray(0);
        glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, sizeof(RenderPoint2D), (void*)0);

        glBindVertexArray(0);
    }

    engine.last_error = RENDERER_OK;
    return RENDERER_OK;
}

RENDERER_API RendererStatus set_layer_properties(int layer_id, int shape_id, const RenderLayerData* layer_data) {
    auto& engine = RenderEngine::instance();
    ScopedGLContext ctx(engine);

    if (!layer_data) {
        engine.last_error = RENDERER_ERROR_INVALID_SHAPE_ID;
        return RENDERER_ERROR_INVALID_SHAPE_ID;
    }

    auto& shape = engine.shapes[shape_id];
    shape.shape_id = shape_id;
    shape.layers[layer_id] = *layer_data;

    engine.last_error = RENDERER_OK;
    return RENDERER_OK;
}

RENDERER_API RendererStatus upload_layer_texture(
    int layer_id, 
    const uint8_t* pixel_data, 
    int width, 
    int height, 
    TexturePixelFormat format
) {
    auto& engine = RenderEngine::instance();
    ScopedGLContext ctx(engine);

    if (!pixel_data || width <= 0 || height <= 0) {
        engine.last_error = RENDERER_ERROR_TEXTURE_UPLOAD_FAILED;
        return RENDERER_ERROR_TEXTURE_UPLOAD_FAILED;
    }

    GLenum gl_format = GL_RGBA;
    if (format == PIXEL_FORMAT_BGRA8) gl_format = GL_BGRA;
    else if (format == PIXEL_FORMAT_RGB8) gl_format = GL_RGB;

    auto& tex = engine.textures[layer_id];
    tex.width = width;
    tex.height = height;
    tex.format = format;

    if (engine.is_initialized) {
        if (tex.texture_id == 0) {
            glGenTextures(1, &tex.texture_id);
        }

        glBindTexture(GL_TEXTURE_2D, tex.texture_id);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, gl_format, GL_UNSIGNED_BYTE, pixel_data);
        glBindTexture(GL_TEXTURE_2D, 0);
    }

    engine.last_error = RENDERER_OK;
    return RENDERER_OK;
}

RENDERER_API RendererStatus render_frame(float current_time_seconds) {
    auto& engine = RenderEngine::instance();
    ScopedGLContext ctx(engine);

    if (!engine.is_initialized) return RENDERER_ERROR_NOT_INITIALIZED;

    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    for (const auto& kv : engine.shapes) {
        const auto& shape = kv.second;
        if (shape.vao == 0 || shape.vertex_count < 3) continue;

        // If shape has specific configured layers, render each layer in order
        if (!shape.layers.empty()) {
            for (const auto& layer_kv : shape.layers) {
                const auto& layer = layer_kv.second;
                engine.apply_blend_mode(layer.blend_mode);

                if (layer.effect_type != EFFECT_NONE && engine.effect_shaders.count(layer.effect_type) > 0) {
                    const auto& shader = engine.effect_shaders[layer.effect_type];
                    if (shader.program_id == 0) continue;

                    glUseProgram(shader.program_id);
                    if (shader.u_homography_loc >= 0) glUniformMatrix3fv(shader.u_homography_loc, 1, GL_FALSE, engine.homography_matrix);
                    if (shader.u_time_loc >= 0) glUniform1f(shader.u_time_loc, current_time_seconds);
                    if (shader.u_speed_loc >= 0) glUniform1f(shader.u_speed_loc, layer.effect_speed);
                    if (shader.u_color_loc >= 0) glUniform4f(shader.u_color_loc, layer.color_r, layer.color_g, layer.color_b, layer.color_a);
                    if (shader.u_opacity_loc >= 0) glUniform1f(shader.u_opacity_loc, layer.opacity);

                    glBindVertexArray(shape.vao);
                    glDrawArrays(GL_TRIANGLE_FAN, 0, shape.vertex_count);
                    glBindVertexArray(0);
                } else if (engine.base_shader.program_id != 0) {
                    glUseProgram(engine.base_shader.program_id);
                    if (engine.base_shader.u_homography_loc >= 0) glUniformMatrix3fv(engine.base_shader.u_homography_loc, 1, GL_FALSE, engine.homography_matrix);
                    if (engine.base_shader.u_opacity_loc >= 0) glUniform1f(engine.base_shader.u_opacity_loc, layer.opacity);

                    auto tex_it = engine.textures.find(layer.layer_id);
                    GLint u_has_tex_loc = glGetUniformLocation(engine.base_shader.program_id, "u_has_texture");
                    GLint u_color_loc = glGetUniformLocation(engine.base_shader.program_id, "u_color");

                    if (tex_it != engine.textures.end() && tex_it->second.texture_id != 0) {
                        glActiveTexture(GL_TEXTURE0);
                        glBindTexture(GL_TEXTURE_2D, tex_it->second.texture_id);
                        if (engine.base_shader.u_texture_loc >= 0) glUniform1i(engine.base_shader.u_texture_loc, 0);
                        if (u_has_tex_loc >= 0) glUniform1i(u_has_tex_loc, 1);
                    } else {
                        if (u_has_tex_loc >= 0) glUniform1i(u_has_tex_loc, 0);
                        if (u_color_loc >= 0) glUniform4f(u_color_loc, layer.color_r, layer.color_g, layer.color_b, layer.color_a);
                    }

                    glBindVertexArray(shape.vao);
                    glDrawArrays(GL_TRIANGLE_FAN, 0, shape.vertex_count);
                    glBindVertexArray(0);
                }
            }
        } else {
            // Default Pass if no specific layer configuration set
            if (engine.base_shader.program_id != 0) {
                engine.apply_blend_mode(BLEND_NORMAL);
                glUseProgram(engine.base_shader.program_id);

                if (engine.base_shader.u_homography_loc >= 0) glUniformMatrix3fv(engine.base_shader.u_homography_loc, 1, GL_FALSE, engine.homography_matrix);
                if (engine.base_shader.u_opacity_loc >= 0) glUniform1f(engine.base_shader.u_opacity_loc, 1.0f);

                auto tex_it = engine.textures.find(100);
                GLint u_has_tex_loc = glGetUniformLocation(engine.base_shader.program_id, "u_has_texture");
                GLint u_color_loc = glGetUniformLocation(engine.base_shader.program_id, "u_color");

                if (tex_it != engine.textures.end() && tex_it->second.texture_id != 0) {
                    glActiveTexture(GL_TEXTURE0);
                    glBindTexture(GL_TEXTURE_2D, tex_it->second.texture_id);
                    if (engine.base_shader.u_texture_loc >= 0) glUniform1i(engine.base_shader.u_texture_loc, 0);
                    if (u_has_tex_loc >= 0) glUniform1i(u_has_tex_loc, 1);
                } else {
                    if (u_has_tex_loc >= 0) glUniform1i(u_has_tex_loc, 0);
                    if (u_color_loc >= 0) glUniform4f(u_color_loc, 0.96f, 0.62f, 0.04f, 1.0f); // #F59E0B
                }

                glBindVertexArray(shape.vao);
                glDrawArrays(GL_TRIANGLE_FAN, 0, shape.vertex_count);
                glBindVertexArray(0);
            }
        }
    }

    SwapBuffers(engine.hdc);

    engine.last_error = RENDERER_OK;
    return RENDERER_OK;
}

RENDERER_API RendererStatus enable_preview_output(int preview_width, int preview_height) {
    auto& engine = RenderEngine::instance();
    ScopedGLContext ctx(engine);

    auto& target = engine.preview_target;
    target.width = preview_width;
    target.height = preview_height;
    target.pixel_buffer.resize(preview_width * preview_height * 4);

    if (engine.is_initialized) {
        if (target.fbo_id == 0) {
            glGenFramebuffers(1, &target.fbo_id);
            glGenTextures(1, &target.texture_id);
        }

        glBindTexture(GL_TEXTURE_2D, target.texture_id);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, preview_width, preview_height, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

        glBindFramebuffer(GL_FRAMEBUFFER, target.fbo_id);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, target.texture_id, 0);

        glBindFramebuffer(GL_FRAMEBUFFER, 0);
    }
    target.is_enabled = true;

    engine.last_error = RENDERER_OK;
    return RENDERER_OK;
}

RENDERER_API RendererStatus get_preview_frame(uint8_t* out_buffer, int buffer_size, int* out_has_new_frame) {
    auto& engine = RenderEngine::instance();
    ScopedGLContext ctx(engine);

    if (out_has_new_frame) *out_has_new_frame = 0;
    if (!engine.preview_target.is_enabled) return RENDERER_ERROR_NOT_INITIALIZED;

    const auto& target = engine.preview_target;
    int required_size = target.width * target.height * 4;

    if (buffer_size < required_size) {
        engine.last_error = RENDERER_ERROR_PREVIEW_BUFFER_TOO_SMALL;
        return RENDERER_ERROR_PREVIEW_BUFFER_TOO_SMALL;
    }

    if (out_buffer && !target.pixel_buffer.empty()) {
        memcpy(out_buffer, target.pixel_buffer.data(), required_size);
        if (out_has_new_frame) *out_has_new_frame = 1;
    }

    engine.last_error = RENDERER_OK;
    return RENDERER_OK;
}

} // extern "C"
