import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapper_core/mapper_core.dart';
import '../../providers/app_state.dart';
import '../../widgets/bbox_overlay.dart';
import '../calibration/calibration_wizard.dart';

class SceneEditorScreen extends ConsumerStatefulWidget {
  const SceneEditorScreen({super.key});

  @override
  ConsumerState<SceneEditorScreen> createState() => _SceneEditorScreenState();
}

class _SceneEditorScreenState extends ConsumerState<SceneEditorScreen> {
  String? _selectedId;
  bool _analyzing = false;

  Scene? get _scene => ref.read(sceneStoreProvider).activeScene;

  Future<void> _pickVideo(String objectId) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );
    if (result == null || result.files.single.path == null) return;
    ref.read(appStateProvider.notifier).assignLocalVideo(
          objectId,
          result.files.single.path!,
        );
    setState(() {});
  }

  Future<void> _analyzeWithAws() async {
    final api = ref.read(appStateProvider.notifier).api;
    final scene = _scene;
    if (api == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'API no configurada. Copia api_config.example.json y despliega infra/.',
          ),
        ),
      );
      return;
    }
    if (scene == null) return;

    setState(() => _analyzing = true);
    try {
      // Placeholder JPEG 1x1 for demo when no camera frame is available.
      final bytes = Uint8List.fromList([
        0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
        0x01, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00, 0xFF, 0xDB, 0x00, 0x43,
        0x00, 0xFF, 0xD9,
      ]);
      final response = await api.analyzeScene(sceneId: scene.id, jpegBytes: bytes);
      await ref.read(appStateProvider.notifier).applyRekognitionResults(response.objects);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${response.objects.length} objetos detectados')),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al analizar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  void _nudgeSelected(double dx, double dy) {
    final scene = _scene;
    final id = _selectedId;
    if (scene == null || id == null) return;
    final obj = scene.objects.firstWhere((o) => o.id == id);
    final b = obj.bboxCamera;
    ref.read(appStateProvider.notifier).updateObjectBbox(
          id,
          b.translate(dx, dy),
        );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final scene = _scene;
    if (scene == null) {
      return const Center(child: Text('Sin escena activa'));
    }

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(color: const Color(0xFF0F172A)),
                    const Center(
                      child: Text(
                        'Vista cámara (coloca webcam aquí en producción)',
                        style: TextStyle(color: Colors.white38),
                      ),
                    ),
                    BboxOverlay(
                      objects: scene.objects,
                      selectedId: _selectedId,
                      onSelect: (id) => setState(() => _selectedId = id),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Wrap(
                  spacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: () => ref.read(appStateProvider.notifier).addManualRegion(),
                      icon: const Icon(Icons.add_box_outlined),
                      label: const Text('Añadir región'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: _analyzing ? null : _analyzeWithAws,
                      icon: _analyzing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.cloud_outlined),
                      label: const Text('Analizar (Rekognition)'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const CalibrationWizard(),
                        ),
                      ),
                      icon: const Icon(Icons.grid_on),
                      label: const Text('Calibrar'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 300,
          child: Card(
            margin: const EdgeInsets.all(12),
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Text('Objetos', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final obj in scene.objects)
                  ListTile(
                    selected: obj.id == _selectedId,
                    title: Text(obj.label),
                    subtitle: Text(
                      '${(obj.confidence * 100).toStringAsFixed(0)}% · '
                      '${obj.content.hasVideo ? "video" : "color"}',
                    ),
                    onTap: () => setState(() => _selectedId = obj.id),
                    trailing: IconButton(
                      icon: const Icon(Icons.movie_outlined),
                      onPressed: () => _pickVideo(obj.id),
                    ),
                  ),
                if (_selectedId != null) ...[
                  const Divider(),
                  const Text('Ajuste fino (cámara)'),
                  Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        onPressed: () => _nudgeSelected(0, -0.01),
                        icon: const Icon(Icons.keyboard_arrow_up),
                      ),
                      IconButton(
                        onPressed: () => _nudgeSelected(-0.01, 0),
                        icon: const Icon(Icons.keyboard_arrow_left),
                      ),
                      IconButton(
                        onPressed: () => _nudgeSelected(0.01, 0),
                        icon: const Icon(Icons.keyboard_arrow_right),
                      ),
                      IconButton(
                        onPressed: () => _nudgeSelected(0, 0.01),
                        icon: const Icon(Icons.keyboard_arrow_down),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  scene.calibration.isComplete
                      ? 'Calibración: OK'
                      : 'Calibración: pendiente',
                  style: TextStyle(
                    color: scene.calibration.isComplete
                        ? Colors.greenAccent
                        : Colors.orangeAccent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
