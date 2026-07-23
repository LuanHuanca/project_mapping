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
  bool _showDebugGrid = true;

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

  void _simulateGesture(HandGesture g) {
    setState(() {
      _activeGesture = g;
      if (g == HandGesture.point) {
        _activeLandmarks = List.generate(21, (i) {
          if (i == 8) return const HandLandmark(id: 8, x: 0.5, y: 0.2); // fingertip up
          if (i == 6) return const HandLandmark(id: 6, x: 0.5, y: 0.4);
          return const HandLandmark(id: 0, x: 0.5, y: 0.7);
        });
      } else {
        _activeLandmarks = [];
      }
    });

    if (g == HandGesture.openPalm) {
      ref.read(appStateProvider.notifier).resyncTracking();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(appStateProvider);
    final scene = ref.read(sceneStoreProvider).activeScene;
    final isRehearsal = mode == AppMode.rehearsal;

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
            child: Row(
              children: [
                // Live Projection Canvas
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ProjectionCanvas(
                        objects: scene.objects,
                        showDebugGrid: isRehearsal && _showDebugGrid,
                        muted: mode == AppMode.show,
                      ),
                      if (isRehearsal)
                        HandOverlay(
                          landmarks: _activeLandmarks,
                          gesture: _activeGesture,
                        ),
                    ],
                  ),
                ),

                // Rehearsal Live Control Panel (Only visible in Ensayo mode)
                if (isRehearsal)
                  SizedBox(
                    width: 300,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111827).withValues(alpha: 0.95),
                        border: Border(
                          left: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.tune_outlined, color: Color(0xFF10B981), size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Consola de Ensayo',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Grid Toggle
                            SwitchListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Rejilla Debug', style: TextStyle(fontSize: 12)),
                              value: _showDebugGrid,
                              onChanged: (val) => setState(() => _showDebugGrid = val),
                            ),

                            const Divider(height: 24),
                            const Text(
                              'Simulador de Gestos en Vivo',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                ChoiceChip(
                                  label: const Text('Señalar (Point)', style: TextStyle(fontSize: 11)),
                                  selected: _activeGesture == HandGesture.point,
                                  onSelected: (_) => _simulateGesture(HandGesture.point),
                                ),
                                ChoiceChip(
                                  label: const Text('Puño (Fist)', style: TextStyle(fontSize: 11)),
                                  selected: _activeGesture == HandGesture.fist,
                                  onSelected: (_) => _simulateGesture(HandGesture.fist),
                                ),
                                ChoiceChip(
                                  label: const Text('Palma (OpenPalm)', style: TextStyle(fontSize: 11)),
                                  selected: _activeGesture == HandGesture.openPalm,
                                  onSelected: (_) => _simulateGesture(HandGesture.openPalm),
                                ),
                                ChoiceChip(
                                  label: const Text('Reset Gestos', style: TextStyle(fontSize: 11)),
                                  selected: _activeGesture == HandGesture.none,
                                  onSelected: (_) => _simulateGesture(HandGesture.none),
                                ),
                              ],
                            ),

                            const Divider(height: 24),
                            Text(
                              'Regiones Activas (${scene.objects.length})',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),

                            for (final obj in scene.objects)
                              Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.03),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _parseColor(obj.content.colorHex),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        obj.label,
                                        style: const TextStyle(fontSize: 12, color: Colors.white),
                                      ),
                                    ),
                                    Text(
                                      '${obj.layers.length} capas',
                                      style: const TextStyle(fontSize: 10, color: Colors.white54),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hex) {
    final value = hex.replaceFirst('#', '');
    if (value.length == 6) {
      return Color(int.parse('FF$value', radix: 16));
    }
    return const Color(0xFF6366F1);
  }
}
