#include <windows.h>
#include "../native_renderer.h"
#include <iostream>
#include <cmath>

LRESULT CALLBACK WindowProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam) {
    if (uMsg == WM_DESTROY) {
        PostQuitMessage(0);
        return 0;
    }
    return DefWindowProc(hwnd, uMsg, wParam, lParam);
}

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow) {
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

    // 3. Prueba de propagación de errores a propósito (Pass NULL pointer to set_homography_matrix)
    RendererStatus err_status = set_homography_matrix(NULL);
    RendererStatus last_err = get_last_error();
    if (err_status == RENDERER_ERROR_INVALID_MATRIX && last_err == RENDERER_ERROR_INVALID_MATRIX) {
        // Error capturado y manejado limpiamente sin crash!
    }

    // Restaurar matriz identidad válida
    double identity[9] = { 1, 0, 0, 0, 1, 0, 0, 0, 1 };
    set_homography_matrix(identity);

    // 4. Bucle de mensajes 60 FPS Win32 con deformación dinámica de vértices (Hot Reload Warp)
    MSG msg = {};
    float time_counter = 0.0f;
    bool running = true;

    while (running) {
        while (PeekMessage(&msg, NULL, 0, 0, PM_REMOVE)) {
            if (msg.message == WM_QUIT) {
                running = false;
            }
            TranslateMessage(&msg);
            DispatchMessage(&msg);
        }

        time_counter += 0.016f;

        // Animar en caliente la posición del vértice 2 (esquina inferior derecha) mediante set_shape_geometry
        float offsetX = sinf(time_counter * 3.0f) * 0.1f;
        float offsetY = cosf(time_counter * 3.0f) * 0.1f;

        RenderPoint2D quad_vertices[4] = {
            {0.2f, 0.2f},
            {0.8f, 0.2f},
            {0.8f + offsetX, 0.8f + offsetY}, // Vértice 2 animado en caliente
            {0.2f, 0.8f}
        };
        RenderShapeData shape_data = { quad_vertices, 4 };
        set_shape_geometry(1, &shape_data);

        // Renderizar frame con pulso concéntrico animado
        render_frame(time_counter);
        Sleep(16); // ~60 FPS
    }

    // 5. Cleanup final
    cleanup_native_renderer();
    return 0;
}
