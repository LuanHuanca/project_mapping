import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapper_core/mapper_core.dart';

import '../../providers/app_state.dart';
import '../../services/projection_window_service.dart';
import '../../widgets/projection_canvas.dart';

class PresentationScreen extends ConsumerStatefulWidget {
  const PresentationScreen({super.key});

  @override
  ConsumerState<PresentationScreen> createState() => _PresentationScreenState();
}

class _PresentationScreenState extends ConsumerState<PresentationScreen> {
  Timer? _trackTimer;

  @override
  void initState() {
    super.initState();
    _trackTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      ref.read(appStateProvider.notifier).tickTracking();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _trackTimer?.cancel();
    super.dispose();
  }

  Future<void> _openProjection() async {
    final scene = ref.read(sceneStoreProvider).activeScene;
    if (scene == null) return;
    await ProjectionWindowService.open(context, scene);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.space) {
      ref.read(appStateProvider.notifier).resyncTracking();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyR) {
      _analyzeRemote();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _analyzeRemote() async {
    final api = ref.read(appStateProvider.notifier).api;
    final scene = ref.read(sceneStoreProvider).activeScene;
    if (api == null || scene == null) return;
    try {
      final response = await api.analyzeScene(
        sceneId: scene.id,
        jpegBytes: Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xD9]),
      );
      await ref.read(appStateProvider.notifier).applyRekognitionResults(response.objects);
      if (mounted) setState(() {});
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(appStateProvider);
    final scene = ref.read(sceneStoreProvider).activeScene;
    final showDebug = mode == AppMode.rehearsal;

    if (scene == null) {
      return const Center(child: Text('Sin escena'));
    }

    return Focus(
      autofocus: true,
      onKeyEvent: _onKey,
      child: Column(
        children: [
          if (mode != AppMode.show)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  FilledButton.icon(
                    onPressed: _openProjection,
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Pantalla proyector (fullscreen)'),
                  ),
                  const Spacer(),
                  Text(
                    'Espacio = re-sync · R = re-analizar AWS',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          Expanded(
            child: ProjectionCanvas(
              objects: scene.objects,
              showDebugGrid: showDebug,
              muted: mode == AppMode.show,
            ),
          ),
        ],
      ),
    );
  }
}
