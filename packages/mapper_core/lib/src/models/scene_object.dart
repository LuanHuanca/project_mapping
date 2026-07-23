import '../geometry/point2d.dart';
import 'bounding_box.dart';
import 'content_binding.dart';
import 'layer_item.dart';
import 'shape_type.dart';

class SceneObject {
  SceneObject({
    required this.id,
    required this.label,
    required this.bboxCamera,
    this.rekognitionLabel,
    this.confidence = 1.0,
    ContentBinding? content,
    NormalizedBBox? bboxProjector,
    this.shapeType = ShapeType.rectangle,
    List<LayerItem>? layers,
    this.groupName = 'Group 1',
    this.isLocked = false,
    this.isHidden = false,
    List<Point2D>? vertices,
  })  : content = content ?? const ContentBinding(),
        bboxProjector = bboxProjector ?? bboxCamera,
        layers = layers ?? _createDefaultLayers(content, id),
        vertices = vertices ?? _createDefaultVertices(shapeType, bboxCamera);

  final String id;
  String label;
  final String? rekognitionLabel;
  double confidence;
  NormalizedBBox bboxCamera;
  NormalizedBBox bboxProjector;
  ContentBinding content;
  ShapeType shapeType;
  List<LayerItem> layers;
  String groupName;
  bool isLocked;
  bool isHidden;
  List<Point2D> vertices;

  static List<LayerItem> _createDefaultLayers(ContentBinding? binding, String id) {
    if (binding == null) {
      return [
        LayerItem(
          id: '${id}_layer_1',
          name: 'Capa Base',
          type: LayerType.color,
          colorHex: '#6366F1',
        ),
      ];
    }
    return [
      LayerItem(
        id: '${id}_layer_1',
        name: binding.hasVideo ? 'Video Principal' : 'Capa Base',
        type: binding.hasVideo ? LayerType.video : LayerType.color,
        localPath: binding.localPath,
        colorHex: binding.colorHex,
      ),
    ];
  }

  static List<Point2D> _createDefaultVertices(ShapeType shapeType, NormalizedBBox bbox) {
    final l = bbox.left;
    final t = bbox.top;
    final w = bbox.width;
    final h = bbox.height;

    return switch (shapeType) {
      ShapeType.triangle => [
          Point2D(l + w / 2, t),
          Point2D(l + w, t + h),
          Point2D(l, t + h),
        ],
      ShapeType.rectangle => [
          Point2D(l, t),
          Point2D(l + w, t),
          Point2D(l + w, t + h),
          Point2D(l, t + h),
        ],
      ShapeType.circle => [
          Point2D(l, t),
          Point2D(l + w, t),
          Point2D(l + w, t + h),
          Point2D(l, t + h),
        ],
      ShapeType.hexagon => [
          Point2D(l + w * 0.25, t),
          Point2D(l + w * 0.75, t),
          Point2D(l + w, t + h * 0.5),
          Point2D(l + w * 0.75, t + h),
          Point2D(l + w * 0.25, t + h),
          Point2D(l, t + h * 0.5),
        ],
      ShapeType.polygon => [
          Point2D(l + w / 2, t),
          Point2D(l + w, t + h * 0.35),
          Point2D(l + w * 0.8, t + h),
          Point2D(l + w * 0.2, t + h),
          Point2D(l, t + h * 0.35),
        ],
    };
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'rekognitionLabel': rekognitionLabel,
        'confidence': confidence,
        'bboxCamera': bboxCamera.toJson(),
        'bboxProjector': bboxProjector.toJson(),
        'content': content.toJson(),
        'shapeType': shapeType.name,
        'layers': layers.map((l) => l.toJson()).toList(),
        'groupName': groupName,
        'isLocked': isLocked,
        'isHidden': isHidden,
        'vertices': vertices.map((v) => v.toJson()).toList(),
      };

  factory SceneObject.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final content = ContentBinding.fromJson(
      json['content'] as Map<String, dynamic>?,
    );
    final rawLayers = (json['layers'] as List<dynamic>?)
        ?.map((e) => LayerItem.fromJson(e as Map<String, dynamic>))
        .toList();
    final bboxCam = NormalizedBBox.fromJson(json['bboxCamera'] as Map<String, dynamic>);
    final shapeType = ShapeType.values.firstWhere(
      (e) => e.name == json['shapeType'],
      orElse: () => ShapeType.rectangle,
    );
    final rawVertices = (json['vertices'] as List<dynamic>?)
        ?.map((e) => Point2D.fromJson(e as Map<String, dynamic>))
        .toList();

    return SceneObject(
      id: id,
      label: json['label'] as String,
      rekognitionLabel: json['rekognitionLabel'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      bboxCamera: bboxCam,
      bboxProjector: NormalizedBBox.fromJson(
        json['bboxProjector'] as Map<String, dynamic>,
      ),
      content: content,
      shapeType: shapeType,
      layers: rawLayers ?? _createDefaultLayers(content, id),
      groupName: json['groupName'] as String? ?? 'Group 1',
      isLocked: json['isLocked'] as bool? ?? false,
      isHidden: json['isHidden'] as bool? ?? false,
      vertices: rawVertices ?? _createDefaultVertices(shapeType, bboxCam),
    );
  }
}
