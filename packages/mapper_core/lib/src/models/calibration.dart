import '../geometry/point2d.dart';

/// Four-point correspondence: projector corners mapped to camera view.
class Calibration {
  const Calibration({
    this.homography,
    this.cameraPoints = const [],
    this.projectorPoints = const [],
    this.isComplete = false,
  });

  /// Flat 3x3 row-major homography (camera normalized -> projector normalized).
  final List<double>? homography;
  final List<Point2D> cameraPoints;
  final List<Point2D> projectorPoints;
  final bool isComplete;

  Map<String, dynamic> toJson() => {
        'homography': homography,
        'cameraPoints': cameraPoints.map((p) => p.toJson()).toList(),
        'projectorPoints': projectorPoints.map((p) => p.toJson()).toList(),
        'isComplete': isComplete,
      };

  factory Calibration.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const Calibration();
    return Calibration(
      homography: (json['homography'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
      cameraPoints: (json['cameraPoints'] as List<dynamic>?)
              ?.map((e) => Point2D.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      projectorPoints: (json['projectorPoints'] as List<dynamic>?)
              ?.map((e) => Point2D.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      isComplete: json['isComplete'] as bool? ?? false,
    );
  }

  Calibration copyWith({
    List<double>? homography,
    List<Point2D>? cameraPoints,
    List<Point2D>? projectorPoints,
    bool? isComplete,
  }) {
    return Calibration(
      homography: homography ?? this.homography,
      cameraPoints: cameraPoints ?? this.cameraPoints,
      projectorPoints: projectorPoints ?? this.projectorPoints,
      isComplete: isComplete ?? this.isComplete,
    );
  }
}
