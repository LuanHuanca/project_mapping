#include <windows.h>
#include "../native_renderer.h"
#include <iostream>
#include <fstream>
#include <cmath>

LRESULT CALLBACK WindowProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam) {
    if (uMsg == WM_DESTROY) {
        PostQuitMessage(0);
        return 0;
    }
    return DefWindowProc(hwnd, uMsg, wParam, lParam);
}

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow) {
    // Attach to parent console window for immediate stdout printing
    if (AttachConsole(ATTACH_PARENT_PROCESS)) {
        freopen("CONOUT$", "w", stdout);
        freopen("CONOUT$", "w", stderr);
    }

    WNDCLASS wc = {};
    wc.lpfnWndProc = WindowProc;
    wc.hInstance = hInstance;
    wc.lpszClassName = "HeavyMTestWindowClass";
    RegisterClass(&wc);

    HWND hwnd = CreateWindowEx(
        0,
        "HeavyMTestWindowClass",
        "Project Mapping Native Renderer Test (Win32 Standalone)",
        WS_OVERLAPPEDWINDOW | WS_VISIBLE,
        CW_USEDEFAULT, CW_USEDEFAULT, 800, 600,
        NULL, NULL, hInstance, NULL
    );

    if (!hwnd) {
        return -1;
    }

    // 1. Inicializar Motor Nativo C++
    RendererStatus status = init_native_renderer(hwnd, 800, 600);
    if (status != RENDERER_OK) {
        return -1;
    }

    // 2. Subir una textura 2x2 de color sólido de prueba (Amber #F59E0B)
    uint8_t amber_pixels[16] = {
        245, 158, 11, 255,  245, 158, 11, 255,
        245, 158, 11, 255,  245, 158, 11, 255
    };
    upload_layer_texture(100, amber_pixels, 2, 2, PIXEL_FORMAT_RGBA8);

    // 3. Configurar propiedades de capa dinámica vía set_layer_properties
    RenderLayerData layer_data = {};
    layer_data.layer_id = 100;
    layer_data.layer_type = 3; // Shader Layer
    layer_data.opacity = 0.85f;
    layer_data.blend_mode = BLEND_ADDITIVE;
    layer_data.effect_type = EFFECT_CONCENTRIC_PULSE;
    layer_data.effect_speed = 1.2f;
    layer_data.color_r = 0.2f;
    layer_data.color_g = 0.8f;
    layer_data.color_b = 1.0f;
    layer_data.color_a = 1.0f;
    set_layer_properties(100, 1, &layer_data);

    // 4. Prueba de propagación de errores a propósito (Pass NULL pointer to set_homography_matrix)
    RendererStatus err_status = set_homography_matrix(NULL);
    RendererStatus last_err = get_last_error();
    if (err_status == RENDERER_ERROR_INVALID_MATRIX && last_err == RENDERER_ERROR_INVALID_MATRIX) {
        // Error capturado y manejado limpiamente sin crash!
    }

    // Restaurar matriz identidad válida
    double identity[9] = { 1, 0, 0, 0, 1, 0, 0, 0, 1 };
    set_homography_matrix(identity);

    // 5. Bucle corto de 10 frames para capturar diagnósticos
    for (int frame = 0; frame < 10; ++frame) {
        MSG msg = {};
        while (PeekMessage(&msg, NULL, 0, 0, PM_REMOVE)) {
            TranslateMessage(&msg);
            DispatchMessage(&msg);
        }

        RenderPoint2D quad_vertices[4] = {
            {0.2f, 0.2f},
            {0.8f, 0.2f},
            {0.8f, 0.8f},
            {0.2f, 0.8f}
        };
        RenderShapeData shape_data = { quad_vertices, 4 };
        set_shape_geometry(1, &shape_data);

        render_frame(0.016f * frame);
        Sleep(16);
    }

    // 6. Cleanup final
    cleanup_native_renderer();
    return 0;
}
