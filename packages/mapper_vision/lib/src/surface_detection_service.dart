import 'dart:math';
import 'dart:typed_data';
import 'package:mapper_core/mapper_core.dart';

enum SurfaceType {
  flatLarge,
  irregularObject,
  multiFace,
}

class SurfaceDetectionResult {
  const SurfaceDetectionResult({
    required this.vertices,
    required this.surfaceType,
    required this.confidence,
    this.suggestedShaders = const [],
  });

  /// 4 suggested corner points normalized [0.0..1.0]
  final List<Point2D> vertices;

  /// Surface classification
  final SurfaceType surfaceType;

  /// Detection confidence score [0.0..1.0] calculated from edge gradient density
  final double confidence;

  /// Suggested generative shaders based on surface geometry
  final List<GenerativeEffectType> suggestedShaders;
}

/// Real On-Device Surface & Edge Detection Pipeline (Luminance Sobel Gradient Sampling).
/// 
/// **DESIGN ASSUMPTION**:
/// Assumes the target projection surface/object is prominently framed in the camera view
/// by the operator. To prevent false positives or tiny noise quadrilaterals in cluttered scenes,
/// candidate quads with a normalized area smaller than 15% of the total frame (minQuadAreaThreshold)
/// are automatically rejected, causing [detectSurface] to return null (falling back cleanly to manual calibration).
/// 
/// Runs 100% locally on-device without any network calls or remote model downloads.
class SurfaceDetectionService {
  /// Minimum gradient confidence threshold required to confirm a surface detection.
  static const double minConfidenceThreshold = 0.25;

  /// Minimum normalized area threshold (15% of total frame area) for a valid surface quad.
  static const double minQuadAreaThreshold = 0.15;

  /// Analyzes a camera frame image byte buffer and detects quad corners & surface type.
  Future<SurfaceDetectionResult?> detectSurface(
    Uint8List frameBytes, {
    int imageWidth = 640,
    int imageHeight = 480,
  }) async {
    if (frameBytes.length < imageWidth * imageHeight) {
      return null;
    }

    // 1. Compute Luminance Edge Gradient Map (Sobel Filter)
    final edgeMap = _computeSobelGradientMap(frameBytes, imageWidth, imageHeight);
    final significantEdges = edgeMap.significantEdges;
    final confidenceScore = edgeMap.confidenceScore;

    // Reject low-contrast or featureless scenes below threshold
    if (confidenceScore < minConfidenceThreshold || significantEdges.length < 15) {
      return null;
    }

    // 2. Extract Convex Quad Corners (Extremal Projected Points)
    final corners = _extractExtremalCorners(significantEdges, imageWidth, imageHeight);
    if (corners.length != 4) {
      return null;
    }

    // 3. Area Validation: Reject degenerate or tiny noisy quads (< 15% of frame area)
    final quadArea = _computeQuadArea(corners);
    if (quadArea < minQuadAreaThreshold) {
      return null;
    }

    // 4. Classify Surface Geometry & Recommend Shaders
    final surfaceType = _classifySurfaceType(quadArea);
    final suggestedShaders = _recommendShaders(surfaceType);

    return SurfaceDetectionResult(
      vertices: corners,
      surfaceType: surfaceType,
      confidence: confidenceScore,
      suggestedShaders: suggestedShaders,
    );
  }

  /// Computes Sobel luminance gradient magnitude for raw RGBA/BGRA bytes
  _SobelAnalysisResult _computeSobelGradientMap(Uint8List bytes, int width, int height) {
    final bytesPerPixel = bytes.length ~/ (width * height);
    final stride = max(1, bytesPerPixel);

    // Compute luminance map L = 0.299R + 0.587G + 0.114B
    final luminance = Float32List(width * height);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final idx = (y * width + x) * stride;
        if (idx + 2 < bytes.length) {
          final r = bytes[idx];
          final g = bytes[idx + 1];
          final b = bytes[idx + 2];
          luminance[y * width + x] = (0.299 * r + 0.587 * g + 0.114 * b);
        }
      }
    }

    // Sobel 3x3 horizontal and vertical gradient masks
    final List<Point2D> significantEdges = [];
    double totalGradientMagnitude = 0.0;
    int sampledPointsCount = 0;

    // Step sampling for fast performance (~60 FPS)
    const step = 2;
    for (int y = step; y < height - step; y += step) {
      for (int x = step; x < width - step; x += step) {
        final gx = (luminance[(y - 1) * width + (x + 1)] + 2 * luminance[y * width + (x + 1)] + luminance[(y + 1) * width + (x + 1)]) -
                   (luminance[(y - 1) * width + (x - 1)] + 2 * luminance[y * width + (x - 1)] + luminance[(y + 1) * width + (x - 1)]);

        final gy = (luminance[(y + 1) * width + (x - 1)] + 2 * luminance[(y + 1) * width + x] + luminance[(y + 1) * width + (x + 1)]) -
                   (luminance[(y - 1) * width + (x - 1)] + 2 * luminance[(y - 1) * width + x] + luminance[(y - 1) * width + (x + 1)]);

        final magnitude = sqrt(gx * gx + gy * gy);
        totalGradientMagnitude += magnitude;
        sampledPointsCount++;

        // Edge detection threshold (gradient > 25.0)
        if (magnitude > 25.0) {
          significantEdges.add(Point2D(x / width, y / height));
        }
      }
    }

    // Confidence metric: scaled based on count of valid edge contours found
    final confidenceScore = (significantEdges.length / 200.0).clamp(0.0, 0.95);

    return _SobelAnalysisResult(significantEdges, confidenceScore);
  }

  /// Extracts the 4 extremal convex corners (Top-Left, Top-Right, Bottom-Right, Bottom-Left)
  List<Point2D> _extractExtremalCorners(List<Point2D> edges, int width, int height) {
    if (edges.isEmpty) return const [];

    Point2D topLeft = edges.first;
    Point2D topRight = edges.first;
    Point2D bottomRight = edges.first;
    Point2D bottomLeft = edges.first;

    double minSum = double.infinity;   // x + y (Top-Left)
    double diffMax = -double.infinity; // x - y (Top-Right)
    double maxSum = -double.infinity;  // x + y (Bottom-Right)
    double diffMin = double.infinity;  // x - y (Bottom-Left)

    for (final p in edges) {
      final sum = p.x + p.y;
      final diff = p.x - p.y;

      if (sum < minSum) {
        minSum = sum;
        topLeft = p;
      }
      if (diff > diffMax) {
        diffMax = diff;
        topRight = p;
      }
      if (sum > maxSum) {
        maxSum = sum;
        bottomRight = p;
      }
      if (diff < diffMin) {
        diffMin = diff;
        bottomLeft = p;
      }
    }

    return [topLeft, topRight, bottomRight, bottomLeft];
  }

  SurfaceType _classifySurfaceType(double quadArea) {
    if (quadArea > 0.35) {
      return SurfaceType.flatLarge;
    } else if (quadArea > 0.20) {
      return SurfaceType.irregularObject;
    }
    return SurfaceType.multiFace;
  }

  double _computeQuadArea(List<Point2D> corners) {
    if (corners.length < 4) return 0.0;
    double area = 0.0;
    for (int i = 0; i < 4; i++) {
      int j = (i + 1) % 4;
      area += corners[i].x * corners[j].y;
      area -= corners[j].x * corners[i].y;
    }
    return (area / 2.0).abs();
  }

  List<GenerativeEffectType> _recommendShaders(SurfaceType type) {
    switch (type) {
      case SurfaceType.flatLarge:
        return const [
          GenerativeEffectType.gridWave,
          GenerativeEffectType.outlineTracer,
          GenerativeEffectType.concentricPulse,
        ];
      case SurfaceType.irregularObject:
        return const [
          GenerativeEffectType.outlineTracer,
          GenerativeEffectType.strobe,
        ];
      case SurfaceType.multiFace:
        return const [
          GenerativeEffectType.rainbowWave,
          GenerativeEffectType.concentricPulse,
        ];
    }
  }
}

class _SobelAnalysisResult {
  _SobelAnalysisResult(this.significantEdges, this.confidenceScore);
  final List<Point2D> significantEdges;
  final double confidenceScore;
}
