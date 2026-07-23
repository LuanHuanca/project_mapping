#ifndef NATIVE_RENDERER_H
#define NATIVE_RENDERER_H

#include <stdint.h>

#ifdef _WIN32
  #define RENDERER_API __declspec(dllexport)
#else
  #define RENDERER_API
#endif

extern "C" {

    // =========================================================================
    // ENUMS Y ESTADO DE ERRORES
    // =========================================================================

    typedef enum {
        RENDERER_OK = 0,
        RENDERER_ERROR_INVALID_HWND = 1,
        RENDERER_ERROR_GL_CONTEXT_FAILED = 2,
        RENDERER_ERROR_INVALID_MATRIX = 3,
        RENDERER_ERROR_INVALID_SHAPE_ID = 4,
        RENDERER_ERROR_TEXTURE_UPLOAD_FAILED = 5,
        RENDERER_ERROR_PREVIEW_BUFFER_TOO_SMALL = 6,
        RENDERER_ERROR_NOT_INITIALIZED = 7
    } RendererStatus;

    typedef enum {
        PIXEL_FORMAT_RGBA8 = 0,
        PIXEL_FORMAT_BGRA8 = 1,
        PIXEL_FORMAT_RGB8 = 2
    } TexturePixelFormat;

    typedef enum {
        BLEND_NORMAL = 0,
        BLEND_ADDITIVE = 1,
        BLEND_MULTIPLY = 2,
        BLEND_SCREEN = 3
    } RenderBlendMode;

    typedef enum {
        EFFECT_NONE = 0,
        EFFECT_OUTLINE_TRACER = 1,
        EFFECT_CONCENTRIC_PULSE = 2,
        EFFECT_GRID_WAVE = 3,
        EFFECT_RAINBOW_WAVE = 4,
        EFFECT_STROBE = 5
    } RenderEffectType;

    // =========================================================================
    // ESTRUCTURAS DE DATOS
    // =========================================================================

    typedef struct {
        float x;
        float y;
    } RenderPoint2D;

    typedef struct {
        const RenderPoint2D* vertices;
        int vertex_count;
    } RenderShapeData;

    typedef struct {
        int layer_id;
        int layer_type; // 0: Color, 1: Image, 2: Video, 3: Shader, 4: Spotlight
        float opacity;
        RenderBlendMode blend_mode;
        RenderEffectType effect_type;
        float effect_speed;
        float color_r;
        float color_g;
        float color_b;
        float color_a;
    } RenderLayerData;

    // =========================================================================
    // FUNCIONES DEL ABI NATIVO (EXPORTADAS)
    // =========================================================================

    RENDERER_API RendererStatus init_native_renderer(void* hwnd, int width, int height);
    RENDERER_API RendererStatus resize_native_renderer(int width, int height);
    RENDERER_API RendererStatus cleanup_native_renderer(void);
    RENDERER_API RendererStatus get_last_error(void);

    RENDERER_API RendererStatus set_homography_matrix(const double* matrix_9_elements);
    RENDERER_API RendererStatus set_shape_geometry(int shape_id, const RenderShapeData* shape);

    RENDERER_API RendererStatus upload_layer_texture(
        int layer_id, 
        const uint8_t* pixel_data, 
        int width, 
        int height, 
        TexturePixelFormat format
    );

    RENDERER_API RendererStatus render_frame(float current_time_seconds);
    RENDERER_API RendererStatus enable_preview_output(int preview_width, int preview_height);
    
    RENDERER_API RendererStatus get_preview_frame(
        uint8_t* out_buffer, 
        int buffer_size, 
        int* out_has_new_frame
    );
}

#endif // NATIVE_RENDERER_H
