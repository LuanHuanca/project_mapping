import 'package:mapper_core/mapper_core.dart';

class AnalyzeResponse {
  const AnalyzeResponse({
    required this.sceneId,
    required this.objects,
    this.imageS3Key,
  });

  final String sceneId;
  final List<DetectedObject> objects;
  final String? imageS3Key;

  factory AnalyzeResponse.fromJson(Map<String, dynamic> json) {
    return AnalyzeResponse(
      sceneId: json['sceneId'] as String,
      imageS3Key: json['imageS3Key'] as String?,
      objects: (json['objects'] as List<dynamic>)
          .map((e) => DetectedObject.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
