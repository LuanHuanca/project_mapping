import 'dart:typed_data';
import 'package:mapper_core/mapper_core.dart';
import 'package:mapper_vision/mapper_vision.dart';
import 'package:test/test.dart';

void main() {
  group('SurfaceDetectionService Real Sobel Algorithm Unit Tests', () {
    late SurfaceDetectionService service;

    setUp(() {
      service = SurfaceDetectionService();
    });

    test('Returns null for empty or uniform featureless image buffer (Low Confidence Fallback)', () async {
      // Create uniform 640x480 gray image (no edges)
      final uniformPixels = Uint8List(640 * 480 * 4)..fillRange(0, 640 * 480 * 4, 128);
      final result = await service.detectSurface(uniformPixels, imageWidth: 640, imageHeight: 480);
      
      // Should cleanly return null to trigger manual calibration mode
      expect(result, isNull);
    });

    test('Detects 4 quad corners and computes real confidence from high-contrast quad image buffer', () async {
      const w = 640;
      const h = 480;
      final highContrastFrame = Uint8List(w * h * 4);

      // Draw a high-contrast white quad in the middle of a black frame
      for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
          final idx = (y * w + x) * 4;
          if (x >= 100 && x <= 500 && y >= 80 && y <= 400) {
            highContrastFrame[idx] = 255;   // R
            highContrastFrame[idx + 1] = 255; // G
            highContrastFrame[idx + 2] = 255; // B
            highContrastFrame[idx + 3] = 255; // A
          } else {
            highContrastFrame[idx] = 0;
            highContrastFrame[idx + 1] = 0;
            highContrastFrame[idx + 2] = 0;
            highContrastFrame[idx + 3] = 255;
          }
        }
      }

      final result = await service.detectSurface(highContrastFrame, imageWidth: w, imageHeight: h);

      expect(result, isNotNull);
      expect(result!.vertices.length, equals(4));
      expect(result.confidence, greaterThanOrEqualTo(0.35));

      // Verify corner points match high contrast edges (normalized ~[0.15..0.85])
      expect(result.vertices[0].x, closeTo(0.15, 0.05)); // Top-Left X
      expect(result.vertices[0].y, closeTo(0.16, 0.05)); // Top-Left Y
      expect(result.vertices[2].x, closeTo(0.78, 0.05)); // Bottom-Right X
      expect(result.vertices[2].y, closeTo(0.83, 0.05)); // Bottom-Right Y

      // Verify classification
      expect(result.surfaceType, equals(SurfaceType.flatLarge));
      expect(result.suggestedShaders, contains(GenerativeEffectType.gridWave));
    });
  });
}
