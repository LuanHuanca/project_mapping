import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';
import 'package:mapper_core/mapper_core.dart';

import 'ffi/native_renderer_bindings.dart';
import 'ffi/native_structs.dart';

class NativeRendererException implements Exception {
  NativeRendererException(this.statusCode, this.lastErrorCode);

  final int statusCode;
  final int lastErrorCode;

  @override
  String toString() =>
      'NativeRendererException(statusCode: $statusCode, lastError: $lastErrorCode)';
}

class RenderEngine {
  RenderEngine({NativeRendererBindings? bindings})
      : _bindings = bindings ?? NativeRendererBindings.load();

  final NativeRendererBindings _bindings;

  void _checkStatus(int status) {
    if (status != RendererStatus.ok) {
      final lastErr = _bindings.getLastError();
      throw NativeRendererException(status, lastErr);
    }
  }

  void init(ffi.Pointer<ffi.Void> hwnd, int width, int height) {
    _checkStatus(_bindings.initRenderer(hwnd, width, height));
  }

  void resize(int width, int height) {
    _checkStatus(_bindings.resizeRenderer(width, height));
  }

  void cleanup() {
    _checkStatus(_bindings.cleanupRenderer());
  }

  void setHomographyMatrix(List<double> matrix9Elements) {
    if (matrix9Elements.length != 9) {
      throw ArgumentError('Homography matrix must have exactly 9 elements.');
    }

    final ptr = calloc<ffi.Double>(9);
    try {
      for (var i = 0; i < 9; i++) {
        ptr[i] = matrix9Elements[i];
      }
      _checkStatus(_bindings.setHomographyMatrix(ptr));
    } finally {
      calloc.free(ptr);
    }
  }

  void setShapeGeometry(int shapeId, List<Point2D> points) {
    if (points.length < 3) {
      throw ArgumentError('Shape geometry must have at least 3 vertices.');
    }

    final count = points.length;
    final vertPtr = calloc<NativeRenderPoint2D>(count);
    final shapePtr = calloc<NativeRenderShapeData>();

    try {
      for (var i = 0; i < count; i++) {
        vertPtr[i].x = points[i].x;
        vertPtr[i].y = points[i].y;
      }

      shapePtr.ref.vertices = vertPtr;
      shapePtr.ref.vertexCount = count;

      _checkStatus(_bindings.setShapeGeometry(shapeId, shapePtr));
    } finally {
      calloc.free(vertPtr);
      calloc.free(shapePtr);
    }
  }

  void setLayerProperties({
    required int layerId,
    required int shapeId,
    required LayerItem layer,
  }) {
    final layerPtr = calloc<NativeRenderLayerData>();
    try {
      final color = _parseColorHex(layer.colorHex);

      layerPtr.ref.layerId = layerId;
      layerPtr.ref.layerType = layer.type.index;
      layerPtr.ref.opacity = layer.opacity;
      layerPtr.ref.blendMode = layer.blendMode.index;
      layerPtr.ref.effectType = layer.effectType.index;
      layerPtr.ref.effectSpeed = layer.effectSpeed;
      layerPtr.ref.colorR = color.r;
      layerPtr.ref.colorG = color.g;
      layerPtr.ref.colorB = color.b;
      layerPtr.ref.colorA = color.a;

      _checkStatus(_bindings.setLayerProperties(layerId, shapeId, layerPtr));
    } finally {
      calloc.free(layerPtr);
    }
  }

  void renderFrame(double currentTimeSeconds) {
    _checkStatus(_bindings.renderFrame(currentTimeSeconds));
  }

  ({double r, double g, double b, double a}) _parseColorHex(String hex) {
    final clean = hex.replaceFirst('#', '');
    if (clean.length == 6) {
      final r = int.parse(clean.substring(0, 2), radix: 16) / 255.0;
      final g = int.parse(clean.substring(2, 4), radix: 16) / 255.0;
      final b = int.parse(clean.substring(4, 6), radix: 16) / 255.0;
      return (r: r, g: g, b: b, a: 1.0);
    }
    return (r: 0.96, g: 0.62, b: 0.04, a: 1.0);
  }
}
