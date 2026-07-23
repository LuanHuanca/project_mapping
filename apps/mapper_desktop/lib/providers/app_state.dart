import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapper_aws_api/mapper_aws_api.dart';
import 'package:mapper_core/mapper_core.dart';
import 'package:mapper_vision/mapper_vision.dart';
import 'package:uuid/uuid.dart';

import '../services/cache_service.dart';
import '../services/config_service.dart';

final configServiceProvider = Provider<ConfigService>((ref) => ConfigService());

final cacheServiceProvider = Provider<CacheService>((ref) => CacheService());

final sceneStoreProvider = Provider<SceneStore>((ref) => SceneStore());

final bboxTrackerProvider = Provider<BboxTracker>((ref) => BboxTracker());

class AppStateNotifier extends StateNotifier<AppMode> {
  AppStateNotifier(this.ref) : super(AppMode.setup);

  final Ref ref;
  final _uuid = const Uuid();

  SceneStore get store => ref.read(sceneStoreProvider);
  BboxTracker get tracker => ref.read(bboxTrackerProvider);

  Future<void> bootstrap() async {
    final configService = ref.read(configServiceProvider);
    await configService.load();

    final cache = ref.read(cacheServiceProvider);
    final cached = await cache.loadScene();
    if (cached != null) {
      store.loadProject(cached);
      return;
    }

    final projectId = _uuid.v4();
    final sceneId = _uuid.v4();
    final project = Project(
      id: projectId,
      name: 'Mi presentación',
      createdAt: DateTime.now(),
      scenes: [
        Scene(
          id: sceneId,
          name: 'Escena principal',
          projectId: projectId,
          objects: [
            SceneObject(
              id: _uuid.v4(),
              label: 'Objeto 1',
              bboxCamera: const NormalizedBBox(
                left: 0.15,
                top: 0.2,
                width: 0.25,
                height: 0.35,
              ),
              content: const ContentBinding(colorHex: '#6366F1'),
            ),
            SceneObject(
              id: _uuid.v4(),
              label: 'Objeto 2',
              bboxCamera: const NormalizedBBox(
                left: 0.55,
                top: 0.25,
                width: 0.3,
                height: 0.4,
              ),
              content: const ContentBinding(colorHex: '#EC4899'),
            ),
          ],
        ),
      ],
    );
    store.loadProject(project);
    tracker.resetFromScene(store.activeScene!.objects);
    await _persist();
  }

  void setMode(AppMode mode) => state = mode;

  Future<void> _persist() async {
    final project = store.activeProject;
    if (project == null) return;
    await ref.read(cacheServiceProvider).saveScene(project);
  }

  Future<void> persist() => _persist();

  ProjectionMapperApi? get api {
    final config = ref.read(configServiceProvider).config;
    if (!config.isConfigured) return null;
    return ProjectionMapperApi(config);
  }

  void addManualRegion() {
    final scene = store.activeScene;
    if (scene == null) return;
    store.addManualObject(
      id: _uuid.v4(),
      label: 'Región ${scene.objects.length + 1}',
      bbox: const NormalizedBBox(
        left: 0.4,
        top: 0.4,
        width: 0.2,
        height: 0.2,
      ),
    );
    tracker.resetFromScene(scene.objects);
    _persist();
  }

  void deleteRegion(String objectId) {
    final scene = store.activeScene;
    if (scene == null) return;
    scene.objects.removeWhere((o) => o.id == objectId);
    tracker.resetFromScene(scene.objects);
    _persist();
  }

  void clearAllRegions() {
    final scene = store.activeScene;
    if (scene == null) return;
    scene.objects.clear();
    tracker.resetFromScene(scene.objects);
    _persist();
  }

  void updateObjectBbox(String objectId, NormalizedBBox bbox) {
    final scene = store.activeScene;
    if (scene == null) return;
    final idx = scene.objects.indexWhere((o) => o.id == objectId);
    if (idx < 0) return;
    scene.objects[idx].bboxCamera = bbox;
    store.applyHomographyToObjects();
    tracker.resetFromScene(scene.objects);
    _persist();
  }

  void assignLocalVideo(String objectId, String path) {
    final scene = store.activeScene;
    if (scene == null) return;
    final obj = scene.objects.firstWhere((o) => o.id == objectId);
    obj.content = obj.content.copyWith(localPath: path);
    _persist();
  }

  void completeCalibration(Calibration calibration) {
    store.updateCalibration(calibration);
    _persist();
  }

  Future<void> applyRekognitionResults(List<DetectedObject> detected) async {
    final scene = store.activeScene;
    if (scene == null) return;
    final objects = detected
        .map(
          (d) => SceneObject(
            id: _uuid.v4(),
            label: d.label,
            rekognitionLabel: d.rekognitionLabel ?? d.label,
            confidence: d.confidence,
            bboxCamera: d.bbox,
          ),
        )
        .toList();
    store.replaceObjects(objects);
    tracker.syncFromDetections(objects);
    scene.lastSyncedAt = DateTime.now();
    await _persist();
  }

  void tickTracking() {
    final scene = store.activeScene;
    if (scene == null) return;
    ref.read(bboxTrackerProvider).tick();
    final updated = ref.read(bboxTrackerProvider).applyToObjects(scene.objects);
    scene.objects = updated;
    store.applyHomographyToObjects();
  }

  void resyncTracking() {
    final scene = store.activeScene;
    if (scene == null) return;
    tracker.resetFromScene(scene.objects);
    scene.lastSyncedAt = DateTime.now();
    _persist();
  }
}

final appStateProvider =
    StateNotifierProvider<AppStateNotifier, AppMode>((ref) {
  return AppStateNotifier(ref);
});
