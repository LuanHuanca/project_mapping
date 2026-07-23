import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:mapper_core/mapper_core.dart';

class ShapeClipper extends CustomClipper<Path> {
  const ShapeClipper(this.shapeType);

  final ShapeType shapeType;

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();

    switch (shapeType) {
      case ShapeType.rectangle:
        path.addRect(Rect.fromLTWH(0, 0, w, h));
        break;

      case ShapeType.circle:
        path.addOval(Rect.fromLTWH(0, 0, w, h));
        break;

      case ShapeType.triangle:
        path.moveTo(w / 2, 0);
        path.lineTo(w, h);
        path.lineTo(0, h);
        path.close();
        break;

      case ShapeType.hexagon:
        final cx = w / 2;
        final cy = h / 2;
        final rx = w / 2;
        final ry = h / 2;
        for (var i = 0; i < 6; i++) {
          final angle = (i * 60 - 30) * math.pi / 180;
          final x = cx + rx * math.cos(angle);
          final y = cy + ry * math.sin(angle);
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        path.close();
        break;

      case ShapeType.polygon:
        path.moveTo(w / 2, 0);
        path.lineTo(w, h * 0.35);
        path.lineTo(w * 0.8, h);
        path.lineTo(w * 0.2, h);
        path.lineTo(0, h * 0.35);
        path.close();
        break;
    }

    return path;
  }

  @override
  bool shouldReclip(covariant ShapeClipper oldClipper) =>
      oldClipper.shapeType != shapeType;
}
