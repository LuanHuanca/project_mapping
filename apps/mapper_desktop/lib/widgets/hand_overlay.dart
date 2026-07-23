import 'package:flutter/material.dart';
import 'package:mapper_vision/mapper_vision.dart';

/// Overlay widget rendering 21-point hand skeleton mesh, landmarks, and active gesture badge.
class HandOverlay extends StatelessWidget {
  const HandOverlay({
    super.key,
    required this.landmarks,
    required this.gesture,
  });

  final List<HandLandmark> landmarks;
  final HandGesture gesture;

  static const _connections = [
    // Thumb
    [0, 1], [1, 2], [2, 3], [3, 4],
    // Index
    [0, 5], [5, 6], [6, 7], [7, 8],
    // Middle
    [5, 9], [9, 10], [10, 11], [11, 12],
    // Ring
    [9, 13], [13, 14], [14, 15], [15, 16],
    // Pinky
    [13, 17], [0, 17], [17, 18], [18, 19], [19, 20],
  ];

  @override
  Widget build(BuildContext context) {
    if (landmarks.isEmpty && gesture == HandGesture.none) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        return Stack(
          children: [
            // Hand Skeleton Connections Line Painter
            if (landmarks.length >= 21)
              CustomPaint(
                size: Size(w, h),
                painter: _SkeletonPainter(landmarks, _connections),
              ),

            // Render landmark dots
            for (final lm in landmarks)
              Positioned(
                left: lm.x * w - 6,
                top: lm.y * h - 6,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: lm.id == 8 ? const Color(0xFFEC4899) : const Color(0xFF10B981),
                    boxShadow: [
                      BoxShadow(
                        color: (lm.id == 8 ? const Color(0xFFEC4899) : const Color(0xFF10B981))
                            .withValues(alpha: 0.6),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),

            // Gesture Badge
            if (gesture != HandGesture.none)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.2),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.back_hand, color: Color(0xFF10B981), size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Gesto: ${_gestureLabel(gesture)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  String _gestureLabel(HandGesture g) => switch (g) {
        HandGesture.point => 'Señalar (Seleccionar)',
        HandGesture.fist => 'Puño (Play / Pause)',
        HandGesture.openPalm => 'Palma (Re-sync)',
        HandGesture.ok => 'OK (Playlist)',
        HandGesture.peace => 'V (Grid Debug)',
        HandGesture.none => '',
      };
}

class _SkeletonPainter extends CustomPainter {
  _SkeletonPainter(this.landmarks, this.connections);

  final List<HandLandmark> landmarks;
  final List<List<int>> connections;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (final pair in connections) {
      final p1 = landmarks[pair[0]];
      final p2 = landmarks[pair[1]];
      canvas.drawLine(
        Offset(p1.x * size.width, p1.y * size.height),
        Offset(p2.x * size.width, p2.y * size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SkeletonPainter oldDelegate) => true;
}
