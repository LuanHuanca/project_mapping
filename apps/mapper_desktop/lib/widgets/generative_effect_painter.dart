import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:mapper_core/mapper_core.dart';

class GenerativeEffectWidget extends StatefulWidget {
  const GenerativeEffectWidget({
    super.key,
    required this.effectType,
    required this.speed,
    required this.color,
  });

  final GenerativeEffectType effectType;
  final double speed;
  final Color color;

  @override
  State<GenerativeEffectWidget> createState() => _GenerativeEffectWidgetState();
}

class _GenerativeEffectWidgetState extends State<GenerativeEffectWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.effectType == GenerativeEffectType.none) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = (_controller.value * widget.speed) % 1.0;
        return CustomPaint(
          size: Size.infinite,
          painter: _GenerativeEffectPainter(
            effectType: widget.effectType,
            progress: progress,
            color: widget.color,
          ),
        );
      },
    );
  }
}

class _GenerativeEffectPainter extends CustomPainter {
  _GenerativeEffectPainter({
    required this.effectType,
    required this.progress,
    required this.color,
  });

  final GenerativeEffectType effectType;
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    switch (effectType) {
      case GenerativeEffectType.none:
        break;

      case GenerativeEffectType.outlineTracer:
        final rect = Rect.fromLTWH(0, 0, w, h);
        final path = Path()..addRect(rect);

        final strokePaint = Paint()
          ..color = color.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawPath(path, strokePaint);

        // Neon tracer pulse along perimeter
        final perimeter = 2 * (w + h);
        final currentDist = progress * perimeter;

        Offset pos;
        if (currentDist < w) {
          pos = Offset(currentDist, 0);
        } else if (currentDist < w + h) {
          pos = Offset(w, currentDist - w);
        } else if (currentDist < 2 * w + h) {
          pos = Offset(w - (currentDist - (w + h)), h);
        } else {
          pos = Offset(0, h - (currentDist - (2 * w + h)));
        }

        final tracerPaint = Paint()
          ..color = color
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 8);
        canvas.drawCircle(pos, 8, tracerPaint);
        break;

      case GenerativeEffectType.concentricPulse:
        final center = Offset(w / 2, h / 2);
        final maxRadius = math.sqrt(w * w + h * h) / 2;

        for (var i = 0; i < 3; i++) {
          final p = (progress + i / 3.0) % 1.0;
          final radius = p * maxRadius;
          final opacity = (1.0 - p).clamp(0.0, 1.0);

          final pulsePaint = Paint()
            ..color = color.withValues(alpha: opacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3;
          canvas.drawCircle(center, radius, pulsePaint);
        }
        break;

      case GenerativeEffectType.gridWave:
        final linePaint = Paint()
          ..color = color.withValues(alpha: 0.4)
          ..strokeWidth = 1.5;

        final cols = 6;
        final rows = 6;

        for (var i = 1; i < cols; i++) {
          final x = w * i / cols;
          final waveY = math.sin(progress * 2 * math.pi + i) * 10;
          canvas.drawLine(Offset(x, 0 + waveY), Offset(x, h + waveY), linePaint);
        }
        for (var j = 1; j < rows; j++) {
          final y = h * j / rows;
          final waveX = math.cos(progress * 2 * math.pi + j) * 10;
          canvas.drawLine(Offset(0 + waveX, y), Offset(w + waveX, y), linePaint);
        }
        break;

      case GenerativeEffectType.rainbowWave:
        final rect = Rect.fromLTWH(0, 0, w, h);
        final shader = LinearGradient(
          colors: const [
            Colors.red,
            Colors.orange,
            Colors.yellow,
            Colors.green,
            Colors.blue,
            Colors.purple,
            Colors.red,
          ],
          transform: GradientRotation(progress * 2 * math.pi),
        ).createShader(rect);

        final gradPaint = Paint()
          ..shader = shader
          ..style = PaintingStyle.fill;
        canvas.drawRect(rect, gradPaint);
        break;

      case GenerativeEffectType.strobe:
        final isBright = (progress * 10).floor() % 2 == 0;
        final opacity = isBright ? 0.85 : 0.05;
        final strobePaint = Paint()..color = color.withValues(alpha: opacity);
        canvas.drawRect(Rect.fromLTWH(0, 0, w, h), strobePaint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _GenerativeEffectPainter oldDelegate) => true;
}
