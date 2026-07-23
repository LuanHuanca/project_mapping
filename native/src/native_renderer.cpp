#include "../native_renderer.h"
#include "internal_state.h"
#include <fstream>
#include <sstream>
#include <iostream>

static std::string load_shader_source(const std::string& filepath) {
    std::ifstream file(filepath);
    if (!file.is_open()) return "";
    std::stringstream buffer;
    buffer << file.rdbuf();
    return buffer.str();
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
    std::string base_v = load_shader_source("native/src/shaders/base_vertex.glsl");
    std::string base_f = load_shader_source("native/src/shaders/base_fragment.glsl");
    compile_shader(base_v, base_f, base_shader);

    // Load Concentric Pulse Shader
    std::string pulse_v = load_shader_source("native/src/shaders/concentric_pulse_vertex.glsl");
    std::string pulse_f = load_shader_source("native/src/shaders/concentric_pulse_fragment.glsl");
    ShaderProgram pulse_shader;
    if (compile_shader(pulse_v, pulse_f, pulse_shader)) {
        effect_shaders[EFFECT_CONCENTRIC_PULSE] = pulse_shader;
    }

    // Load Outline Tracer Shader
    std::string outline_v = load_shader_source("native/src/shaders/outline_tracer_vertex.glsl");
    std::string outline_f = load_shader_source("native/src/shaders/outline_tracer_fragment.glsl");
    ShaderProgram outline_shader;
    if (compile_shader(outline_v, outline_f, outline_shader)) {
        effect_shaders[EFFECT_OUTLINE_TRACER] = outline_shader;
    }

    // Load Grid Wave Shader
    std::string grid_v = load_shader_source("native/src/shaders/grid_wave_vertex.glsl");
    std::string grid_f = load_shader_source("native/src/shaders/grid_wave_fragment.glsl");
    ShaderProgram grid_shader;
    if (compile_shader(grid_v, grid_f, grid_shader)) {
        effect_shaders[EFFECT_GRID_WAVE] = grid_shader;
    }

    // Load Rainbow Wave Shader
    std::string rainbow_v = load_shader_source("native/src/shaders/rainbow_wave_vertex.glsl");
    std::string rainbow_f = load_shader_source("native/src/shaders/rainbow_wave_fragment.glsl");
    ShaderProgram rainbow_shader;
    if (compile_shader(rainbow_v, rainbow_f, rainbow_shader)) {
        effect_shaders[EFFECT_RAINBOW_WAVE] = rainbow_shader;
    }

    // Load Strobe Shader
    std::string strobe_v = load_shader_source("native/src/shaders/strobe_vertex.glsl");
    std::string strobe_f = load_shader_source("native/src/shaders/strobe_fragment.glsl");
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

        // Pass 1: Render Base Texture/Color
        if (engine.base_shader.program_id != 0) {
            engine.apply_blend_mode(BLEND_NORMAL);
            glUseProgram(engine.base_shader.program_id);

            if (engine.base_shader.u_homography_loc >= 0) {
                glUniformMatrix3fv(engine.base_shader.u_homography_loc, 1, GL_FALSE, engine.homography_matrix);
            }
            if (engine.base_shader.u_opacity_loc >= 0) {
                glUniform1f(engine.base_shader.u_opacity_loc, 1.0f);
            }

            // Bind Texture if available (Layer 100)
            auto tex_it = engine.textures.find(100);
            GLint u_has_tex_loc = glGetUniformLocation(engine.base_shader.program_id, "u_has_texture");
            GLint u_color_loc = glGetUniformLocation(engine.base_shader.program_id, "u_color");

            if (tex_it != engine.textures.end() && tex_it->second.texture_id != 0) {
                glActiveTexture(GL_TEXTURE0);
                glBindTexture(GL_TEXTURE_2D, tex_it->second.texture_id);
                if (engine.base_shader.u_texture_loc >= 0) {
                    glUniform1i(engine.base_shader.u_texture_loc, 0);
                }
                if (u_has_tex_loc >= 0) glUniform1i(u_has_tex_loc, 1);
            } else {
                if (u_has_tex_loc >= 0) glUniform1i(u_has_tex_loc, 0);
                if (u_color_loc >= 0) glUniform4f(u_color_loc, 0.96f, 0.62f, 0.04f, 1.0f); // #F59E0B
            }

            glBindVertexArray(shape.vao);
            glDrawArrays(GL_TRIANGLE_FAN, 0, shape.vertex_count);
            glBindVertexArray(0);
        }

        // Pass 2: Render Generative Effect Layer (e.g. EFFECT_CONCENTRIC_PULSE) Additive Blended on top!
        auto pulse_it = engine.effect_shaders.find(EFFECT_CONCENTRIC_PULSE);
        if (pulse_it != engine.effect_shaders.end() && pulse_it->second.program_id != 0) {
            engine.apply_blend_mode(BLEND_ADDITIVE);
            const auto& shader = pulse_it->second;
            glUseProgram(shader.program_id);

            if (shader.u_homography_loc >= 0) {
                glUniformMatrix3fv(shader.u_homography_loc, 1, GL_FALSE, engine.homography_matrix);
            }
            if (shader.u_time_loc >= 0) {
                glUniform1f(shader.u_time_loc, current_time_seconds);
            }
            if (shader.u_speed_loc >= 0) {
                glUniform1f(shader.u_speed_loc, 1.0f);
            }
            if (shader.u_color_loc >= 0) {
                glUniform4f(shader.u_color_loc, 0.2f, 0.8f, 1.0f, 1.0f); // Cyan Pulse
            }
            if (shader.u_opacity_loc >= 0) {
                glUniform1f(shader.u_opacity_loc, 0.8f);
            }

            glBindVertexArray(shape.vao);
            glDrawArrays(GL_TRIANGLE_FAN, 0, shape.vertex_count);
            glBindVertexArray(0);
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
