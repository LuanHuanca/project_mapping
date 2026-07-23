/// Hand gesture categories recognized by the local vision module.
enum HandGesture {
  none,
  point,     // Index finger extended -> Select / highlight object
  fist,      // Fist closed -> Play / pause content
  openPalm,  // Open palm -> Stop or reset tracking
  ok,        // OK sign -> Toggle next playlist video
  peace,     // V sign -> Toggle debug grid
}

class HandLandmark {
  const HandLandmark({
    required this.id,
    required this.x,
    required this.y,
    this.z = 0.0,
  });

  final int id;
  final double x; // Normalized 0..1
  final double y; // Normalized 0..1
  final double z;

  Map<String, dynamic> toJson() => {'id': id, 'x': x, 'y': y, 'z': z};

  factory HandLandmark.fromJson(Map<String, dynamic> json) => HandLandmark(
        id: json['id'] as int,
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        z: (json['z'] as num?)?.toDouble() ?? 0.0,
      );
}
