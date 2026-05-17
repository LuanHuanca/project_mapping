import 'bounding_box.dart';

/// Result from Rekognition analyze endpoint.
class DetectedObject {
  const DetectedObject({
    required this.label,
    required this.bbox,
    required this.confidence,
    this.rekognitionLabel,
  });

  final String label;
  final String? rekognitionLabel;
  final NormalizedBBox bbox;
  final double confidence;

  factory DetectedObject.fromJson(Map<String, dynamic> json) {
    return DetectedObject(
      label: json['label'] as String,
      rekognitionLabel: json['rekognitionLabel'] as String?,
      bbox: NormalizedBBox.fromJson(json['bbox'] as Map<String, dynamic>),
      confidence: (json['confidence'] as num).toDouble(),
    );
  }
}
