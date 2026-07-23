import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapper_core/mapper_core.dart';
import 'package:uuid/uuid.dart';

import '../../providers/app_state.dart';
import '../../services/projection_window_service.dart';
import '../../widgets/heavym_canvas.dart';
import '../../widgets/heavym_left_sidebar.dart';
import '../../widgets/heavym_right_fx_bar.dart';
import '../../widgets/heavym_top_bar.dart';

class SceneEditorScreen extends ConsumerStatefulWidget {
  const SceneEditorScreen({super.key});

  @override
  ConsumerState<SceneEditorScreen> createState() => _SceneEditorScreenState();
}

class _SceneEditorScreenState extends ConsumerState<SceneEditorScreen> {
  String? _selectedId;
  CameraController? _cameraController;
  bool _isCameraInitialized = false;

  bool _showGrid = false;
  bool _snapToGrid = false;
  double _zoomLevel = 1.0;
  String _selectedFxMode = 'shaders';

  static const _uuid = Uuid();

  Scene? get _scene => ref.read(sceneStoreProvider).activeScene;

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

  void _addShape(ShapeType shapeType) {
    final scene = _scene;
    if (scene == null) return;

    final id = _uuid.v4();
    final count = scene.objects.length + 1;
    final label = switch (shapeType) {
      ShapeType.triangle => 'Face $count (Triángulo)',
      ShapeType.rectangle => 'Face $count (Cuadro)',
      ShapeType.circle => 'Face $count (Círculo)',
      ShapeType.hexagon => 'Face $count (Hexágono)',
      ShapeType.polygon => 'Face $count (Polígono)',
    };

    final obj = SceneObject(
      id: id,
      label: label,
      bboxCamera: NormalizedBBox(
        left: 0.35 + (count % 4) * 0.05,
        top: 0.30 + (count % 4) * 0.05,
        width: 0.25,
        height: 0.25,
      ),
      shapeType: shapeType,
    );

    scene.objects.add(obj);
    ref.read(appStateProvider.notifier).persist();
    setState(() => _selectedId = id);
  }

  void _openProjector() {
    final scene = _scene;
    if (scene == null) return;
    ProjectionWindowService.open(context, scene);
  }

  void _onVertexUpdated(String objectId, int vertexIndex, Point2D newPos) {
    final scene = _scene;
    if (scene == null) return;

    final idx = scene.objects.indexWhere((o) => o.id == objectId);
    if (idx < 0) return;

    final obj = scene.objects[idx];
    if (vertexIndex < obj.vertices.length) {
      obj.vertices[vertexIndex] = newPos;
      ref.read(appStateProvider.notifier).persist();
      setState(() {});
    }
  }

  void _toggleVisibility(SceneObject obj) {
    obj.isHidden = !obj.isHidden;
    ref.read(appStateProvider.notifier).persist();
    setState(() {});
  }

  void _toggleLock(SceneObject obj) {
    obj.isLocked = !obj.isLocked;
    ref.read(appStateProvider.notifier).persist();
    setState(() {});
  }

  void _deleteObject(String id) {
    ref.read(appStateProvider.notifier).deleteRegion(id);
    if (_selectedId == id) {
      setState(() => _selectedId = null);
    } else {
      setState(() {});
    }
  }

  void _clearAll() {
    ref.read(appStateProvider.notifier).clearAllRegions();
    setState(() => _selectedId = null);
  }

  @override
  Widget build(BuildContext context) {
    final scene = _scene;
    if (scene == null) {
      return const Center(child: Text('Sin escena activa'));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      body: Column(
        children: [
          // HeavyM Studio Top Toolbar
          HeavyMTopBar(
            onAddShape: _addShape,
            onOpenProjector: _openProjector,
            showGrid: _showGrid,
            onToggleGrid: () => setState(() => _showGrid = !_showGrid),
            snapToGrid: _snapToGrid,
            onToggleSnap: () => setState(() => _snapToGrid = !_snapToGrid),
            zoomLevel: _zoomLevel,
            onZoomIn: () => setState(() => _zoomLevel = (_zoomLevel + 0.1).clamp(0.5, 3.0)),
            onZoomOut: () => setState(() => _zoomLevel = (_zoomLevel - 0.1).clamp(0.5, 3.0)),
          ),

          // Main HeavyM Studio Area (Left Tree + Center Canvas + Right FX Toolbar)
          Expanded(
            child: Row(
              children: [
                // Collapsible Layers & Faces Tree Sidebar (Left)
                HeavyMLeftSidebar(
                  objects: scene.objects,
                  selectedId: _selectedId,
                  onSelectObject: (id) => setState(() => _selectedId = id),
                  onToggleVisibility: _toggleVisibility,
                  onToggleLock: _toggleLock,
                  onDeleteObject: _deleteObject,
                  onAddManualShape: _addShape,
                  onClearAll: _clearAll,
                ),

                // Center Multi-Vertex Mesh Canvas + PiP Camera Stream
                Expanded(
                  child: HeavyMCanvas(
                    objects: scene.objects,
                    selectedId: _selectedId,
                    onSelectObject: (id) => setState(() => _selectedId = id),
                    onVertexUpdated: _onVertexUpdated,
                    showGrid: _showGrid,
                    snapToGrid: _snapToGrid,
                    cameraController: _cameraController,
                    isCameraInitialized: _isCameraInitialized,
                  ),
                ),

                // Right FX Toolbar
                HeavyMRightFxBar(
                  selectedFxMode: _selectedFxMode,
                  onSelectFxMode: (mode) => setState(() => _selectedFxMode = mode),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
