import 'bounding_box.dart';
import 'content_binding.dart';

class SceneObject {
  SceneObject({
    required this.id,
    required this.label,
    required this.bboxCamera,
    this.rekognitionLabel,
    this.confidence = 1.0,
    ContentBinding? content,
    NormalizedBBox? bboxProjector,
  })  : content = content ?? const ContentBinding(),
        bboxProjector = bboxProjector ?? bboxCamera;

  final String id;
  String label;
  final String? rekognitionLabel;
  double confidence;
  NormalizedBBox bboxCamera;
  NormalizedBBox bboxProjector;
  ContentBinding content;

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'rekognitionLabel': rekognitionLabel,
        'confidence': confidence,
        'bboxCamera': bboxCamera.toJson(),
        'bboxProjector': bboxProjector.toJson(),
        'content': content.toJson(),
      };

  factory SceneObject.fromJson(Map<String, dynamic> json) {
    return SceneObject(
      id: json['id'] as String,
      label: json['label'] as String,
      rekognitionLabel: json['rekognitionLabel'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      bboxCamera:
          NormalizedBBox.fromJson(json['bboxCamera'] as Map<String, dynamic>),
      bboxProjector: NormalizedBBox.fromJson(
        json['bboxProjector'] as Map<String, dynamic>,
      ),
      content: ContentBinding.fromJson(
        json['content'] as Map<String, dynamic>?,
      ),
    );
  }
}
