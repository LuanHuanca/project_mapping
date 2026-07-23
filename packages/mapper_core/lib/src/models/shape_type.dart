enum ShapeType {
  rectangle,
  circle,
  triangle,
  hexagon,
  polygon,
}

extension ShapeTypeExtension on ShapeType {
  String get displayName => switch (this) {
        ShapeType.rectangle => 'Rectángulo',
        ShapeType.circle => 'Círculo',
        ShapeType.triangle => 'Triángulo',
        ShapeType.hexagon => 'Hexágono',
        ShapeType.polygon => 'Polígono',
      };
}
