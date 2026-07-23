import 'dart:ffi' as ffi;

final class NativeRenderPoint2D extends ffi.Struct {
  @ffi.Float()
  external double x;

  @ffi.Float()
  external double y;
}

final class NativeRenderShapeData extends ffi.Struct {
  external ffi.Pointer<NativeRenderPoint2D> vertices;

  @ffi.Int32()
  external int vertexCount;
}

final class NativeRenderLayerData extends ffi.Struct {
  @ffi.Int32()
  external int layerId;

  @ffi.Int32()
  external int layerType;

  @ffi.Float()
  external double opacity;

  @ffi.Int32()
  external int blendMode;

  @ffi.Int32()
  external int effectType;

  @ffi.Float()
  external double effectSpeed;

  @ffi.Float()
  external double colorR;

  @ffi.Float()
  external double colorG;

  @ffi.Float()
  external double colorB;

  @ffi.Float()
  external double colorA;
}
