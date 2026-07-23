import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:path/path.dart' as path;

import 'native_structs.dart';

abstract class RendererStatus {
  static const int ok = 0;
  static const int errorInvalidHwnd = 1;
  static const int errorGlContextFailed = 2;
  static const int errorInvalidMatrix = 3;
  static const int errorInvalidShapeId = 4;
  static const int errorTextureUploadFailed = 5;
  static const int errorPreviewBufferTooSmall = 6;
  static const int errorNotInitialized = 7;
}

typedef NativeInitRenderer = ffi.Int32 Function(ffi.Pointer<ffi.Void> hwnd, ffi.Int32 width, ffi.Int32 height);
typedef DartInitRenderer = int Function(ffi.Pointer<ffi.Void> hwnd, int width, int height);

typedef NativeResizeRenderer = ffi.Int32 Function(ffi.Int32 width, ffi.Int32 height);
typedef DartResizeRenderer = int Function(int width, int height);

typedef NativeCleanupRenderer = ffi.Int32 Function();
typedef DartCleanupRenderer = int Function();

typedef NativeGetLastError = ffi.Int32 Function();
typedef DartGetLastError = int Function();

typedef NativeSetHomographyMatrix = ffi.Int32 Function(ffi.Pointer<ffi.Double> matrix);
typedef DartSetHomographyMatrix = int Function(ffi.Pointer<ffi.Double> matrix);

typedef NativeSetShapeGeometry = ffi.Int32 Function(ffi.Int32 shapeId, ffi.Pointer<NativeRenderShapeData> shape);
typedef DartSetShapeGeometry = int Function(int shapeId, ffi.Pointer<NativeRenderShapeData> shape);

typedef NativeSetLayerProperties = ffi.Int32 Function(
  ffi.Int32 layerId,
  ffi.Int32 shapeId,
  ffi.Pointer<NativeRenderLayerData> layerData,
);
typedef DartSetLayerProperties = int Function(
  int layerId,
  int shapeId,
  ffi.Pointer<NativeRenderLayerData> layerData,
);

typedef NativeUploadLayerTexture = ffi.Int32 Function(
  ffi.Int32 layerId,
  ffi.Pointer<ffi.Uint8> pixelData,
  ffi.Int32 width,
  ffi.Int32 height,
  ffi.Int32 format,
);
typedef DartUploadLayerTexture = int Function(
  int layerId,
  ffi.Pointer<ffi.Uint8> pixelData,
  int width,
  int height,
  int format,
);

typedef NativeRenderFrame = ffi.Int32 Function(ffi.Float currentTimeSeconds);
typedef DartRenderFrame = int Function(double currentTimeSeconds);

typedef NativeEnablePreviewOutput = ffi.Int32 Function(ffi.Int32 width, ffi.Int32 height);
typedef DartEnablePreviewOutput = int Function(int width, int height);

typedef NativeGetPreviewFrame = ffi.Int32 Function(
  ffi.Pointer<ffi.Uint8> outBuffer,
  ffi.Int32 bufferSize,
  ffi.Pointer<ffi.Int32> outHasNewFrame,
);
typedef DartGetPreviewFrame = int Function(
  ffi.Pointer<ffi.Uint8> outBuffer,
  int bufferSize,
  ffi.Pointer<ffi.Int32> outHasNewFrame,
);

class NativeRendererBindings {
  NativeRendererBindings._(ffi.DynamicLibrary lib)
      : initRenderer = lib.lookupFunction<NativeInitRenderer, DartInitRenderer>('init_native_renderer'),
        resizeRenderer = lib.lookupFunction<NativeResizeRenderer, DartResizeRenderer>('resize_native_renderer'),
        cleanupRenderer = lib.lookupFunction<NativeCleanupRenderer, DartCleanupRenderer>('cleanup_native_renderer'),
        getLastError = lib.lookupFunction<NativeGetLastError, DartGetLastError>('get_last_error'),
        setHomographyMatrix = lib.lookupFunction<NativeSetHomographyMatrix, DartSetHomographyMatrix>('set_homography_matrix'),
        setShapeGeometry = lib.lookupFunction<NativeSetShapeGeometry, DartSetShapeGeometry>('set_shape_geometry'),
        setLayerProperties = lib.lookupFunction<NativeSetLayerProperties, DartSetLayerProperties>('set_layer_properties'),
        uploadLayerTexture = lib.lookupFunction<NativeUploadLayerTexture, DartUploadLayerTexture>('upload_layer_texture'),
        renderFrame = lib.lookupFunction<NativeRenderFrame, DartRenderFrame>('render_frame'),
        enablePreviewOutput = lib.lookupFunction<NativeEnablePreviewOutput, DartEnablePreviewOutput>('enable_preview_output'),
        getPreviewFrame = lib.lookupFunction<NativeGetPreviewFrame, DartGetPreviewFrame>('get_preview_frame');

  factory NativeRendererBindings.load([String? customPath]) {
    final libPath = customPath ?? _resolveLibraryPath();
    final lib = ffi.DynamicLibrary.open(libPath);
    return NativeRendererBindings._(lib);
  }

  static String _resolveLibraryPath() {
    if (Platform.isWindows) {
      var dir = Directory.current;
      for (var i = 0; i < 4; i++) {
        final relPath = path.join(dir.path, 'native', 'build', 'Release', 'native_renderer.dll');
        if (File(relPath).existsSync()) return relPath;
        if (dir.parent.path == dir.path) break;
        dir = dir.parent;
      }
      return 'native_renderer.dll';
    }
    throw UnsupportedError('Project Mapping native renderer is only supported on Windows.');
  }

  final DartInitRenderer initRenderer;
  final DartResizeRenderer resizeRenderer;
  final DartCleanupRenderer cleanupRenderer;
  final DartGetLastError getLastError;
  final DartSetHomographyMatrix setHomographyMatrix;
  final DartSetShapeGeometry setShapeGeometry;
  final DartSetLayerProperties setLayerProperties;
  final DartUploadLayerTexture uploadLayerTexture;
  final DartRenderFrame renderFrame;
  final DartEnablePreviewOutput enablePreviewOutput;
  final DartGetPreviewFrame getPreviewFrame;
}
