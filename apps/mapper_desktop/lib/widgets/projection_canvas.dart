import 'package:flutter/material.dart';
import 'package:mapper_core/mapper_core.dart';

import 'region_content_tile.dart';

/// Composes per-region content in projector normalized space.
class ProjectionCanvas extends StatelessWidget {
  const ProjectionCanvas({
    super.key,
    required this.objects,
    this.showDebugGrid = false,
    this.muted = true,
  });

  final List<SceneObject> objects;
  final bool showDebugGrid;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final sorted = [...objects]
          ..sort((a, b) => a.content.zIndex.compareTo(b.content.zIndex));

        return ColoredBox(
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (showDebugGrid) const _DebugGrid(),
              for (final obj in sorted)
                Positioned(
                  left: obj.bboxProjector.left * w,
                  top: obj.bboxProjector.top * h,
                  width: obj.bboxProjector.width * w,
                  height: obj.bboxProjector.height * h,
                  child: ClipRect(
                    child: RegionContentTile(
                      object: obj,
                      size: Size(
                        obj.bboxProjector.width * w,
                        obj.bboxProjector.height * h,
                      ),
                      muted: muted,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _DebugGrid extends StatelessWidget {
  const _DebugGrid();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GridPainter());
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white12
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      final x = size.width * i / 4;
      final y = size.height * i / 4;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
