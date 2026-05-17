import 'package:flutter/material.dart';
import 'package:mapper_core/mapper_core.dart';
import 'package:window_manager/window_manager.dart';

import '../widgets/projection_canvas.dart';

/// Fullscreen projection output (drag window to the projector display).
class ProjectionWindowService {
  static Future<void> open(BuildContext context, Scene scene) async {
    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        fullscreenDialog: true,
        pageBuilder: (ctx, _, __) => _ProjectionPage(scene: scene),
      ),
    );
  }
}

class _ProjectionPage extends StatefulWidget {
  const _ProjectionPage({required this.scene});

  final Scene scene;

  @override
  State<_ProjectionPage> createState() => _ProjectionPageState();
}

class _ProjectionPageState extends State<_ProjectionPage> with WindowListener {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _enterFullscreen();
  }

  Future<void> _enterFullscreen() async {
    await windowManager.ensureInitialized();
    await windowManager.setFullScreen(true);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    windowManager.setFullScreen(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          ProjectionCanvas(objects: widget.scene.objects, muted: true),
          Positioned(
            top: 16,
            right: 16,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: Colors.white54),
            ),
          ),
        ],
      ),
    );
  }
}
