import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapper_core/mapper_core.dart';

import '../../providers/app_state.dart';

class CalibrationWizard extends ConsumerStatefulWidget {
  const CalibrationWizard({super.key});

  @override
  ConsumerState<CalibrationWizard> createState() => _CalibrationWizardState();
}

class _CalibrationWizardState extends ConsumerState<CalibrationWizard> {
  int _step = 0;
  final List<Offset?> _cameraCorners = List.filled(4, null);

  static const _cornerLabels = [
    'Superior izquierda',
    'Superior derecha',
    'Inferior derecha',
    'Inferior izquierda',
  ];

  static const _projectorCorners = [
    Point2D(0, 0),
    Point2D(1, 0),
    Point2D(1, 1),
    Point2D(0, 1),
  ];

  void _onTapCanvas(Offset local, Size size) {
    if (_step != 1) return;
    final idx = _cameraCorners.indexWhere((c) => c == null);
    if (idx < 0) return;
    setState(() {
      _cameraCorners[idx] = local;
    });
  }

  void _applyCalibration() {
    final cameraPoints = <Point2D>[];
    for (final corner in _cameraCorners) {
      if (corner == null) return;
    }
    final box = context.findRenderObject() as RenderBox?;
    final w = box?.size.width ?? 1.0;
    final h = box?.size.height ?? 1.0;

    for (final corner in _cameraCorners) {
      cameraPoints.add(Point2D(corner!.dx / w, corner.dy / h));
    }

    final homography = Homography.fromCorrespondences(
      source: cameraPoints,
      destination: _projectorCorners,
    );

    if (homography == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo calcular la homografía. Repite los 4 puntos.')),
      );
      return;
    }

    ref.read(appStateProvider.notifier).completeCalibration(
          Calibration(
            homography: homography.matrix,
            cameraPoints: cameraPoints,
            projectorPoints: _projectorCorners,
            isComplete: true,
          ),
        );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Calibración guardada. Las regiones se proyectan al espacio del proyector.')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calibración cámara → proyector')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Paso ${_step + 1} de 2', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            if (_step == 0) ...[
              const Text(
                'Proyecta un rectángulo blanco en toda el área útil del proyector. '
                'En el siguiente paso marcarás las 4 esquinas de ese rectángulo en la vista de cámara.',
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => setState(() => _step = 1),
                child: const Text('Continuar'),
              ),
            ] else ...[
              Text(
                'Toca las esquinas en orden: ${_cornerLabels[_cameraCorners.indexWhere((c) => c == null).clamp(0, 3)]}',
              ),
              const SizedBox(height: 12),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return GestureDetector(
                      onTapDown: (d) => _onTapCanvas(
                        d.localPosition,
                        Size(constraints.maxWidth, constraints.maxHeight),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white24),
                          color: const Color(0xFF1E1E2E),
                        ),
                        child: CustomPaint(
                          size: Size(constraints.maxWidth, constraints.maxHeight),
                          painter: _CornerPainter(_cameraCorners),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () => setState(() {
                      for (var i = 0; i < _cameraCorners.length; i++) {
                        _cameraCorners[i] = null;
                      }
                    }),
                    child: const Text('Reiniciar puntos'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _cameraCorners.every((c) => c != null) ? _applyCalibration : null,
                    child: const Text('Aplicar calibración'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  _CornerPainter(this.corners);

  final List<Offset?> corners;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.amber
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawRect(Rect.fromLTWH(24, 24, size.width - 48, size.height - 48), paint);

    for (var i = 0; i < corners.length; i++) {
      final c = corners[i];
      if (c == null) continue;
      canvas.drawCircle(c, 8, Paint()..color = Colors.amber);
      final tp = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, c + const Offset(10, -6));
    }
  }

  @override
  bool shouldRepaint(covariant _CornerPainter oldDelegate) => true;
}
