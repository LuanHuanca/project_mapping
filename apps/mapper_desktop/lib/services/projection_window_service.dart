import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mapper_core/mapper_core.dart';
import 'package:mapper_render/mapper_render.dart';
import 'package:window_manager/window_manager.dart';

import '../widgets/projection_canvas.dart';

/// Floating & Fullscreen projection output service.
class ProjectionWindowService {
  static Future<void> open(BuildContext context, Scene scene) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      builder: (ctx) => _FloatingProjectionDialog(scene: scene),
    );
  }
}

class _FloatingProjectionDialog extends StatefulWidget {
  const _FloatingProjectionDialog({required this.scene});

  final Scene scene;

  @override
  State<_FloatingProjectionDialog> createState() => _FloatingProjectionDialogState();
}

class _FloatingProjectionDialogState extends State<_FloatingProjectionDialog> with WindowListener {
  RenderEngine? _engine;
  Timer? _renderTimer;
  double _timeCounter = 0.0;
  bool _useNativeEngine = false;
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _initNativeEngine();
  }

  void _initNativeEngine() {
    try {
      final engine = RenderEngine();

      // 1. Sync Homography Matrix from mapper_core
      final h = widget.scene.calibration.homography;
      if (h != null && h.length == 9) {
        engine.setHomographyMatrix(h);
      } else {
        engine.setHomographyMatrix([1, 0, 0, 0, 1, 0, 0, 0, 1]);
      }

      // 2. Sync Scene Objects and Layers to Native Engine
      for (final obj in widget.scene.objects) {
        if (!obj.isHidden) {
          obj.syncToNativeEngine(engine);
        }
      }

      _engine = engine;
      _useNativeEngine = true;

      // 3. Start 60 FPS Native Ticker
      _renderTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
        _timeCounter += 0.016;
        try {
          _engine?.renderFrame(_timeCounter);
        } catch (_) {}
      });
    } catch (e) {
      debugPrint('⚠️ WARNING: Native OpenGL Engine Init Failed ($e). Falling back to Flutter CustomPainter...');
      _useNativeEngine = false;
    }
  }

  Future<void> _toggleFullScreen() async {
    await windowManager.ensureInitialized();
    setState(() => _isFullScreen = !_isFullScreen);
    await windowManager.setFullScreen(_isFullScreen);
  }

  @override
  void dispose() {
    _renderTimer?.cancel();
    try {
      _engine?.cleanup();
    } catch (_) {}
    windowManager.removeListener(this);
    if (_isFullScreen) {
      windowManager.setFullScreen(false);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dialogWidth = _isFullScreen ? MediaQuery.of(context).size.width : 680.0;
    final dialogHeight = _isFullScreen ? MediaQuery.of(context).size.height : 420.0;

    return Align(
      alignment: _isFullScreen ? Alignment.center : Alignment.topRight,
      child: Padding(
        padding: EdgeInsets.all(_isFullScreen ? 0 : 20),
        child: Material(
          elevation: 16,
          color: Colors.transparent,
          child: Container(
            width: dialogWidth,
            height: dialogHeight,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(_isFullScreen ? 0 : 12),
              border: Border.all(
                color: _useNativeEngine ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                width: 1.5,
              ),
              boxShadow: const [
                BoxShadow(color: Colors.black87, blurRadius: 20, spreadRadius: 4),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Render Canvas (Flutter CustomPainter fallback or native backend)
                ProjectionCanvas(objects: widget.scene.objects, muted: true),

                // Top Header Controls (Window Title + Engine Status + Fullscreen Toggle)
                Positioned(
                  top: 10,
                  left: 10,
                  right: 10,
                  child: Row(
                    children: [
                      // Engine Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _useNativeEngine
                              ? const Color(0xFF10B981).withValues(alpha: 0.25)
                              : const Color(0xFFF59E0B).withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _useNativeEngine ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _useNativeEngine ? Icons.memory : Icons.warning_amber_rounded,
                              size: 14,
                              color: _useNativeEngine ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _useNativeEngine
                                  ? 'Salida Proyección OpenGL C++ (60 FPS)'
                                  : '⚠️ FALLBACK: Engine CustomPainter',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _useNativeEngine ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // Fullscreen / Restore Toggle Button
                      IconButton(
                        tooltip: _isFullScreen ? 'Restaurar Ventana Flotante' : 'Maximizar a Proyector Secundario',
                        icon: Icon(
                          _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: _toggleFullScreen,
                      ),

                      // Close Dialog Button
                      IconButton(
                        tooltip: 'Cerrar Proyección',
                        icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
