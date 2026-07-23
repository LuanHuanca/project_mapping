import 'package:camera/camera.dart';
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
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  int _selectedCornerIndex = 0;

  // Normalized 0..1 corner positions [TopLeft, TopRight, BottomRight, BottomLeft]
  final List<Offset> _corners = [
    const Offset(0.1, 0.1),
    const Offset(0.9, 0.1),
    const Offset(0.9, 0.9),
    const Offset(0.1, 0.9),
  ];

  static const _cornerNames = [
    'Superior Izquierda (TL)',
    'Superior Derecha (TR)',
    'Inferior Derecha (BR)',
    'Inferior Izquierda (BL)',
  ];

  static const _projectorCorners = [
    Point2D(0, 0),
    Point2D(1, 0),
    Point2D(1, 1),
    Point2D(0, 1),
  ];

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      final controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _isCameraInitialized = true;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  void _nudgeSelectedCorner(double dx, double dy) {
    setState(() {
      final current = _corners[_selectedCornerIndex];
      _corners[_selectedCornerIndex] = Offset(
        (current.dx + dx).clamp(0.0, 1.0),
        (current.dy + dy).clamp(0.0, 1.0),
      );
    });
  }

  void _applyCalibration() {
    final cameraPoints = _corners
        .map((c) => Point2D(c.dx.clamp(0.0, 1.0), c.dy.clamp(0.0, 1.0)))
        .toList();

    final homography = Homography.fromCorrespondences(
      source: cameraPoints,
      destination: _projectorCorners,
    );

    if (homography == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al calcular homografía. Ajusta la posición de las 4 esquinas.'),
        ),
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
      const SnackBar(
        backgroundColor: Color(0xFF10B981),
        content: Text('¡Calibración guardada exitosamente! Regiones alineadas con el proyector.'),
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Calibración Interactiva Quad Pinning (Cámara → Proyector)'),
      ),
      body: Row(
        children: [
          // Live Viewport with Drag Handles
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              clipBehavior: Clip.antiAlias,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final h = constraints.maxHeight;

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background Camera Stream
                      if (_isCameraInitialized && _cameraController != null)
                        CameraPreview(_cameraController!)
                      else
                        Container(
                          color: const Color(0xFF1E1E2E),
                          child: const Center(
                            child: Text(
                              'Cámara en vivo (arrastra las 4 esquinas sobre la imagen)',
                              style: TextStyle(color: Colors.white38),
                            ),
                          ),
                        ),

                      // Quad Polygon Paint
                      CustomPaint(
                        size: Size(w, h),
                        painter: _QuadPainter(_corners, _selectedCornerIndex),
                      ),

                      // Draggable Corner Handles
                      for (var i = 0; i < 4; i++)
                        Positioned(
                          left: _corners[i].dx * w - 18,
                          top: _corners[i].dy * h - 18,
                          child: GestureDetector(
                            onPanUpdate: (details) {
                              setState(() {
                                _selectedCornerIndex = i;
                                final newX = (_corners[i].dx + details.delta.dx / w).clamp(0.0, 1.0);
                                final newY = (_corners[i].dy + details.delta.dy / h).clamp(0.0, 1.0);
                                _corners[i] = Offset(newX, newY);
                              });
                            },
                            onTap: () => setState(() => _selectedCornerIndex = i),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _selectedCornerIndex == i
                                    ? const Color(0xFFEC4899)
                                    : const Color(0xFF6366F1),
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: (_selectedCornerIndex == i
                                            ? const Color(0xFFEC4899)
                                            : const Color(0xFF6366F1))
                                        .withValues(alpha: 0.6),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  '${i + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),

          // Side Controls Panel
          SizedBox(
            width: 320,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Control de Esquinas', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),

                  // Select Corner Segmented Buttons
                  for (var i = 0; i < 4; i++)
                    ListTile(
                      dense: true,
                      selected: i == _selectedCornerIndex,
                      selectedTileColor: const Color(0xFF6366F1).withValues(alpha: 0.15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      title: Text(_cornerNames[i]),
                      subtitle: Text(
                        'X: ${(_corners[i].dx * 100).toStringAsFixed(1)}% · Y: ${(_corners[i].dy * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(fontSize: 11),
                      ),
                      leading: CircleAvatar(
                        radius: 12,
                        backgroundColor: i == _selectedCornerIndex
                            ? const Color(0xFFEC4899)
                            : const Color(0xFF6366F1),
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ),
                      onTap: () => setState(() => _selectedCornerIndex = i),
                    ),

                  const Divider(height: 24),
                  const Text(
                    'Ajuste fino (Píxel a Píxel)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.filledTonal(
                        onPressed: () => _nudgeSelectedCorner(-0.002, 0),
                        icon: const Icon(Icons.arrow_left),
                      ),
                      Column(
                        children: [
                          IconButton.filledTonal(
                            onPressed: () => _nudgeSelectedCorner(0, -0.002),
                            icon: const Icon(Icons.arrow_drop_up),
                          ),
                          IconButton.filledTonal(
                            onPressed: () => _nudgeSelectedCorner(0, 0.002),
                            icon: const Icon(Icons.arrow_drop_down),
                          ),
                        ],
                      ),
                      IconButton.filledTonal(
                        onPressed: () => _nudgeSelectedCorner(0.002, 0),
                        icon: const Icon(Icons.arrow_right),
                      ),
                    ],
                  ),

                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() {
                            _corners[0] = const Offset(0.1, 0.1);
                            _corners[1] = const Offset(0.9, 0.1);
                            _corners[2] = const Offset(0.9, 0.9);
                            _corners[3] = const Offset(0.1, 0.9);
                          }),
                          child: const Text('Reiniciar'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: _applyCalibration,
                          child: const Text('Guardar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuadPainter extends CustomPainter {
  _QuadPainter(this.corners, this.selectedIndex);

  final List<Offset> corners;
  final int selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final points = corners.map((c) => Offset(c.dx * w, c.dy * h)).toList();

    final path = Path()
      ..moveTo(points[0].dx, points[0].dy)
      ..lineTo(points[1].dx, points[1].dy)
      ..lineTo(points[2].dx, points[2].dy)
      ..lineTo(points[3].dx, points[3].dy)
      ..close();

    // Fill semi-transparent cyan
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF6366F1).withValues(alpha: 0.15)
        ..style = PaintingStyle.fill,
    );

    // Border line
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF6366F1)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _QuadPainter oldDelegate) => true;
}
