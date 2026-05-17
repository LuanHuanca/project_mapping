import 'dart:convert';

import '../geometry/homography.dart';
import '../models/bounding_box.dart';
import '../models/calibration.dart';
import '../models/project.dart';
import '../models/scene.dart';
import '../models/scene_object.dart';

/// In-memory store with JSON serialization for offline cache.
class SceneStore {
  Project? _activeProject;
  Scene? _activeScene;

  Project? get activeProject => _activeProject;
  Scene? get activeScene => _activeScene;

  void loadProject(Project project, {Scene? scene}) {
    _activeProject = project;
    _activeScene = scene ?? (project.scenes.isNotEmpty ? project.scenes.first : null);
  }

  void setActiveScene(Scene scene) {
    _activeScene = scene;
    final project = _activeProject;
    if (project == null) return;
    final idx = project.scenes.indexWhere((s) => s.id == scene.id);
    if (idx >= 0) {
      project.scenes[idx] = scene;
    } else {
      project.scenes.add(scene);
    }
  }

  void applyHomographyToObjects() {
    final scene = _activeScene;
    if (scene == null) return;
    final h = scene.calibration.homography;
    if (h == null || h.length != 9) return;
    final homography = Homography(h);
    for (final obj in scene.objects) {
      obj.bboxProjector = homography.transformBBox(obj.bboxCamera);
    }
  }

  void updateCalibration(Calibration calibration) {
    final scene = _activeScene;
    if (scene == null) return;
    scene.calibration = calibration;
    scene.lastCalibratedAt = DateTime.now();
    applyHomographyToObjects();
  }

  void replaceObjects(List<SceneObject> objects) {
    final scene = _activeScene;
    if (scene == null) return;
    scene.objects = objects;
    applyHomographyToObjects();
  }

  void addManualObject({
    required String id,
    required String label,
    required NormalizedBBox bbox,
  }) {
    final scene = _activeScene;
    if (scene == null) return;
    final obj = SceneObject(
      id: id,
      label: label,
      bboxCamera: bbox,
    );
    scene.objects.add(obj);
    applyHomographyToObjects();
  }

  String exportJson() {
    final project = _activeProject;
    if (project == null) return '{}';
    return const JsonEncoder.withIndent('  ').convert(project.toJson());
  }

  void importJson(String json) {
    final map = jsonDecode(json) as Map<String, dynamic>;
    loadProject(Project.fromJson(map));
  }
}
