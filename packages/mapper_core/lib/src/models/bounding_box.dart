/// Normalized bounding box (0..1) as returned by Amazon Rekognition.
class NormalizedBBox {
  const NormalizedBBox({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final double left;
  final double top;
  final double width;
  final double height;

  double get right => left + width;
  double get bottom => top + height;

  double get centerX => left + width / 2;
  double get centerY => top + height / 2;

  NormalizedBBox translate(double dx, double dy) {
    return NormalizedBBox(
      left: left + dx,
      top: top + dy,
      width: width,
      height: height,
    );
  }

  Map<String, dynamic> toJson() => {
        'left': left,
        'top': top,
        'width': width,
        'height': height,
      };

  factory NormalizedBBox.fromJson(Map<String, dynamic> json) {
    return NormalizedBBox(
      left: (json['left'] as num).toDouble(),
      top: (json['top'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
    );
  }

  @override
  String toString() =>
      'BBox(l:$left, t:$top, w:$width, h:$height)';
}
