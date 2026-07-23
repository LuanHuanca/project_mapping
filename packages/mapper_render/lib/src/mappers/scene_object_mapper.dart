import 'package:mapper_core/mapper_core.dart';
import '../render_engine.dart';

extension SceneObjectMapper on SceneObject {
  void syncToNativeEngine(RenderEngine engine) {
    // 1. Sync geometry vertices
    engine.setShapeGeometry(id.hashCode, vertices);

    // 2. Sync layers
    for (var i = 0; i < layers.length; i++) {
      final layer = layers[i];
      if (layer.isVisible) {
        engine.setLayerProperties(
          layerId: layer.id.hashCode,
          shapeId: id.hashCode,
          layer: layer,
        );
      }
    }
  }
}

extension HomographyMapper on Homography {
  List<double> toFlatMatrix9() => List<double>.from(matrix);
}
