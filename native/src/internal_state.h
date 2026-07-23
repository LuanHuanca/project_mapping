#ifndef INTERNAL_STATE_H
#define INTERNAL_STATE_H

#include <windows.h>
#include <glad/glad.h>

#include <map>
#include <vector>
#include <string>
#include <mutex>
#include "../native_renderer.h"

struct GpuTexture {
    GLuint texture_id = 0;
    int width = 0;
    int height = 0;
    TexturePixelFormat format = PIXEL_FORMAT_RGBA8;
};

struct GpuShape {
    int shape_id = 0;
    GLuint vao = 0;
    GLuint vbo = 0;
    int vertex_count = 0;
    std::vector<RenderPoint2D> vertices;
};

struct PreviewFBO {
    GLuint fbo_id = 0;
    GLuint texture_id = 0;
    GLuint depth_rbo_id = 0;
    int width = 0;
    int height = 0;
    std::vector<uint8_t> pixel_buffer;
    bool has_new_frame = false;
    bool is_enabled = false;
};

struct ShaderProgram {
    GLuint program_id = 0;
    GLint u_homography_loc = -1;
    GLint u_time_loc = -1;
    GLint u_resolution_loc = -1;
    GLint u_color_loc = -1;
    GLint u_speed_loc = -1;
    GLint u_opacity_loc = -1;
    GLint u_texture_loc = -1;
};

class RenderEngine {
public:
    static RenderEngine& instance() {
        static RenderEngine instance;
        return instance;
    }

    std::mutex engine_mutex;

    HWND hwnd = nullptr;
    HDC hdc = nullptr;
    HGLRC hglrc = nullptr;
    int viewport_width = 0;
    int viewport_height = 0;
    bool is_initialized = false;

    float homography_matrix[9] = {
        1.0f, 0.0f, 0.0f,
        0.0f, 1.0f, 0.0f,
        0.0f, 0.0f, 1.0f
    };

    std::map<int, GpuShape> shapes;
    std::map<int, GpuTexture> textures;
    
    ShaderProgram base_shader;
    std::map<RenderEffectType, ShaderProgram> effect_shaders;

    PreviewFBO preview_target;

    RendererStatus last_error = RENDERER_OK;

    bool compile_shader(const std::string& vertex_src, const std::string& fragment_src, ShaderProgram& out_shader);
    void setup_default_shaders();
    void apply_blend_mode(RenderBlendMode blend_mode);
};

class ScopedGLContext {
public:
    ScopedGLContext(RenderEngine& engine) 
        : engine_(engine), lock_(engine.engine_mutex) 
    {
        if (engine_.is_initialized && engine_.hdc && engine_.hglrc) {
            wglMakeCurrent(engine_.hdc, engine_.hglrc);
        }
    }

private:
    RenderEngine& engine_;
    std::lock_guard<std::mutex> lock_;
};

#endif // INTERNAL_STATE_H
