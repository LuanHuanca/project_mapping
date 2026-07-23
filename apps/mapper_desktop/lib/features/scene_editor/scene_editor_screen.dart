import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapper_core/mapper_core.dart';
import 'package:mapper_vision/mapper_vision.dart';

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

  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  String? _cameraStatusMessage;

  final LocalDetector _localDetector = LocalDetector();

  Scene? get _scene => ref.read(sceneStoreProvider).activeScene;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _cameraStatusMessage = 'No se detectó ninguna webcam conectada';
          });
        }
        return;
      }

      final firstCam = cameras.first;
      final controller = CameraController(
        firstCam,
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
        _cameraStatusMessage = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _cameraStatusMessage = 'Modo simulación (sin cámara): $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

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

  Future<Uint8List> _captureFrameBytes() async {
    if (_isCameraInitialized && _cameraController != null && _cameraController!.value.isInitialized) {
      final xFile = await _cameraController!.takePicture();
      return await xFile.readAsBytes();
    }

    return Uint8List.fromList([
      0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
      0x01, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00, 0xFF, 0xDB, 0x00, 0x43,
      0x00, 0xFF, 0xD9,
    ]);
  }

  Future<void> _detectObjects() async {
    final scene = _scene;
    if (scene == null) return;

    setState(() => _analyzing = true);
    try {
      final bytes = await _captureFrameBytes();
      final api = ref.read(appStateProvider.notifier).api;

      List<DetectedObject> objects;
      String sourceName;

      if (api != null) {
        final response = await api.analyzeScene(sceneId: scene.id, jpegBytes: bytes);
        objects = response.objects;
        sourceName = 'AWS Rekognition';
      } else {
        objects = await _localDetector.detectObjects(bytes);
        sourceName = 'Detección Local';
      }

      await ref.read(appStateProvider.notifier).applyRekognitionResults(objects);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF6366F1),
            content: Text('${objects.length} objetos detectados ($sourceName)'),
          ),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error en detección: $e')),
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
        // Camera Viewport
        Expanded(
          flex: 3,
          child: Column(
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_isCameraInitialized && _cameraController != null)
                        CameraPreview(_cameraController!)
                      else
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.videocam_off_outlined, color: Colors.white38, size: 48),
                              const SizedBox(height: 12),
                              Text(
                                _cameraStatusMessage ?? 'Conectando webcam...',
                                style: const TextStyle(color: Colors.white54),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: _initCamera,
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text('Reintentar webcam'),
                              ),
                            ],
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
              ),

              // Action Toolbar
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton.icon(
                      onPressed: () => ref.read(appStateProvider.notifier).addManualRegion(),
                      icon: const Icon(Icons.add_box_outlined),
                      label: const Text('Añadir Región'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.tonalIcon(
                      onPressed: _analyzing ? null : _detectObjects,
                      icon: _analyzing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: const Text('Detectar Objetos'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const CalibrationWizard(),
                        ),
                      ),
                      icon: const Icon(Icons.grid_on),
                      label: const Text('Calibrar 4 Puntos'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Objects Sidebar Panel
        SizedBox(
          width: 320,
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF111827).withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Objetos en Escena', style: Theme.of(context).textTheme.titleMedium),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${scene.objects.length}',
                        style: const TextStyle(
                          color: Color(0xFF818CF8),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: scene.objects.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final obj = scene.objects[index];
                      final isSelected = obj.id == _selectedId;
                      return InkWell(
                        onTap: () => setState(() => _selectedId = obj.id),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF6366F1).withValues(alpha: 0.15)
                                : Colors.white.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF6366F1)
                                  : Colors.white.withValues(alpha: 0.05),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _parseColor(obj.content.colorHex),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      obj.label,
                                      style: TextStyle(
                                        fontWeight:
                                            isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      obj.content.hasVideo ? 'Video asignado' : 'Color sólido',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.white.withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  obj.content.hasVideo
                                      ? Icons.movie_rounded
                                      : Icons.video_call_outlined,
                                  color: obj.content.hasVideo
                                      ? const Color(0xFF10B981)
                                      : Colors.white54,
                                ),
                                onPressed: () => _pickVideo(obj.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                if (_selectedId != null) ...[
                  const Divider(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.wb_sunny_outlined, size: 16, color: Colors.amberAccent),
                      const SizedBox(width: 6),
                      const Text(
                        'Ajuste de Luz del Proyector',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Light Intensity Slider
                  Builder(
                    builder: (context) {
                      final selectedObj = scene.objects.firstWhere((o) => o.id == _selectedId);
                      final content = selectedObj.content;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Intensidad: ${(content.lightIntensity * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(fontSize: 11, color: Colors.white70),
                              ),
                            ],
                          ),
                          Slider(
                            value: content.lightIntensity,
                            min: 0.0,
                            max: 2.0,
                            divisions: 20,
                            activeColor: Colors.amberAccent,
                            onChanged: (val) {
                              selectedObj.content = content.copyWith(lightIntensity: val);
                              ref.read(appStateProvider.notifier).persist();
                              setState(() {});
                            },
                          ),

                          Row(
                            children: [
                              Text(
                                'Difuminado Bordes: ${(content.feathering * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(fontSize: 11, color: Colors.white70),
                              ),
                            ],
                          ),
                          Slider(
                            value: content.feathering,
                            min: 0.0,
                            max: 1.0,
                            divisions: 20,
                            activeColor: const Color(0xFF818CF8),
                            onChanged: (val) {
                              selectedObj.content = content.copyWith(feathering: val);
                              ref.read(appStateProvider.notifier).persist();
                              setState(() {});
                            },
                          ),

                          SwitchListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Foco de Luz (Spotlight)', style: TextStyle(fontSize: 11)),
                            subtitle: const Text('Luz blanca pura sin video', style: TextStyle(fontSize: 10, color: Colors.white38)),
                            value: content.isSpotlight,
                            onChanged: (val) {
                              selectedObj.content = content.copyWith(isSpotlight: val);
                              ref.read(appStateProvider.notifier).persist();
                              setState(() {});
                            },
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.touch_app_outlined, size: 16, color: Colors.white70),
                      const SizedBox(width: 6),
                      const Text(
                        'Ajuste fino de posición',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.filledTonal(
                        onPressed: () => _nudgeSelected(-0.01, 0),
                        icon: const Icon(Icons.arrow_left),
                      ),
                      Column(
                        children: [
                          IconButton.filledTonal(
                            onPressed: () => _nudgeSelected(0, -0.01),
                            icon: const Icon(Icons.arrow_drop_up),
                          ),
                          IconButton.filledTonal(
                            onPressed: () => _nudgeSelected(0, 0.01),
                            icon: const Icon(Icons.arrow_drop_down),
                          ),
                        ],
                      ),
                      IconButton.filledTonal(
                        onPressed: () => _nudgeSelected(0.01, 0),
                        icon: const Icon(Icons.arrow_right),
                      ),
                    ],
                  ),
                ],

                const Divider(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: scene.calibration.isComplete
                        ? const Color(0xFF10B981).withValues(alpha: 0.1)
                        : const Color(0xFFF59E0B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: scene.calibration.isComplete
                          ? const Color(0xFF10B981).withValues(alpha: 0.3)
                          : const Color(0xFFF59E0B).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        scene.calibration.isComplete
                            ? Icons.check_circle_outline
                            : Icons.warning_amber_rounded,
                        size: 16,
                        color: scene.calibration.isComplete
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        scene.calibration.isComplete
                            ? 'Calibración: OK'
                            : 'Calibración: Pendiente',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: scene.calibration.isComplete
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
