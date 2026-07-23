import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapper_core/mapper_core.dart';
import 'package:mapper_vision/mapper_vision.dart';

import '../../providers/app_state.dart';
import '../../services/projection_window_service.dart';
import '../../widgets/hand_overlay.dart';
import '../../widgets/projection_canvas.dart';

class PresentationScreen extends ConsumerStatefulWidget {
  const PresentationScreen({super.key});

  @override
  ConsumerState<PresentationScreen> createState() => _PresentationScreenState();
}

class _PresentationScreenState extends ConsumerState<PresentationScreen> {
  Timer? _trackTimer;
  final HandLandmarkService _handService = HandLandmarkService();
  List<HandLandmark> _activeLandmarks = const [];
  HandGesture _activeGesture = HandGesture.none;

  @override
  void initState() {
    super.initState();
    _trackTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      ref.read(appStateProvider.notifier).tickTracking();
      if (mounted) setState(() {});
    });
  }

  void updateHandFrame(List<HandLandmark> landmarks) {
    final gesture = _handService.classify(landmarks);
    setState(() {
      _activeLandmarks = landmarks;
      _activeGesture = gesture;
    });

    if (gesture == HandGesture.openPalm) {
      ref.read(appStateProvider.notifier).resyncTracking();
    }
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
      _analyzeLocal();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _analyzeLocal() async {
    final scene = ref.read(sceneStoreProvider).activeScene;
    if (scene == null) return;
    try {
      final objects = await LocalDetector().detectObjects(Uint8List(0));
      await ref.read(appStateProvider.notifier).applyRekognitionResults(objects);
      if (mounted) setState(() {});
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(appStateProvider);
    final scene = ref.read(sceneStoreProvider).activeScene;
    final showDebug = mode == AppMode.rehearsal;

    if (scene == null) {
      return const Center(child: Text('Sin escena activa'));
    }

    return Focus(
      autofocus: true,
      onKeyEvent: _onKey,
      child: Column(
        children: [
          if (mode != AppMode.show)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                border: Border(
                  bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                ),
              ),
              child: Row(
                children: [
                  FilledButton.icon(
                    onPressed: _openProjection,
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('Abrir Pantalla Proyector (Fullscreen)'),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: () => ref.read(appStateProvider.notifier).resyncTracking(),
                    icon: const Icon(Icons.sync, size: 16),
                    label: const Text('Re-sync Posiciones'),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.keyboard_outlined, size: 14, color: Colors.white54),
                        const SizedBox(width: 6),
                        Text(
                          'Espacio = Re-sync · R = Re-analizar local',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ProjectionCanvas(
                  objects: scene.objects,
                  showDebugGrid: showDebug,
                  muted: mode == AppMode.show,
                ),
                if (showDebug)
                  HandOverlay(
                    landmarks: _activeLandmarks,
                    gesture: _activeGesture,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
