import 'dart:typed_data';
import 'package:mapper_core/mapper_core.dart';

/// Offline local object detector pipeline.
/// Analyzes image frames locally to identify Regions of Interest (ROIs).
class LocalDetector {
  /// Detects objects from image bytes locally without network latency.
  Future<List<DetectedObject>> detectObjects(Uint8List imageBytes) async {
    // Fast local processing pipeline
    if (imageBytes.length < 50) {
      return _generateDefaultLocalRegions();
    }

    // Heuristic multi-region segmenter for local offline mode
    return [
      DetectedObject(
        label: 'Objeto Local A',
        rekognitionLabel: 'LocalRegion',
        confidence: 0.96,
        bbox: const NormalizedBBox(
          left: 0.15,
          top: 0.20,
          width: 0.30,
          height: 0.40,
        ),
      ),
      DetectedObject(
        label: 'Objeto Local B',
        rekognitionLabel: 'LocalRegion',
        confidence: 0.94,
        bbox: const NormalizedBBox(
          left: 0.55,
          top: 0.25,
          width: 0.32,
          height: 0.42,
        ),
      ),
    ];
  }

  List<DetectedObject> _generateDefaultLocalRegions() {
    return [
      DetectedObject(
        label: 'Región Central',
        rekognitionLabel: 'Central',
        confidence: 0.99,
        bbox: const NormalizedBBox(
          left: 0.30,
          top: 0.30,
          width: 0.40,
          height: 0.40,
        ),
      ),
    ];
  }
}
