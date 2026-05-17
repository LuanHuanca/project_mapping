import 'package:mapper_core/mapper_core.dart';

import 'tracking_state.dart';

/// Lightweight tracker between Rekognition re-detections.
/// Uses velocity smoothing when objects shift slightly on the table.
class BboxTracker {
  BboxTracker({
    this.damping = 0.35,
    this.maxStep = 0.08,
    this.lostFrameThreshold = 30,
  });

  final double damping;
  final double maxStep;
  final int lostFrameThreshold;

  final TrackingState state = TrackingState();

  void resetFromScene(List<SceneObject> objects) {
    state.tracks.clear();
    for (final obj in objects) {
      state.tracks[obj.id] = TrackedObject(
        objectId: obj.id,
        bboxCamera: obj.bboxCamera,
      );
    }
    state.isActive = true;
    state.lastSyncAt = DateTime.now();
  }

  void syncFromDetections(List<SceneObject> detected) {
    final used = <String>{};
    for (final det in detected) {
      final existing = state.tracks[det.id];
      if (existing != null) {
        final dx = det.bboxCamera.centerX - existing.bboxCamera.centerX;
        final dy = det.bboxCamera.centerY - existing.bboxCamera.centerY;
        existing.velocityX = existing.velocityX * (1 - damping) + dx * damping;
        existing.velocityY = existing.velocityY * (1 - damping) + dy * damping;
        existing.bboxCamera = det.bboxCamera;
        existing.lostFrames = 0;
      } else {
        state.tracks[det.id] = TrackedObject(
          objectId: det.id,
          bboxCamera: det.bboxCamera,
        );
      }
      used.add(det.id);
    }

    for (final entry in state.tracks.entries.toList()) {
      if (!used.contains(entry.key)) {
        entry.value.lostFrames++;
        if (entry.value.lostFrames > lostFrameThreshold) {
          state.tracks.remove(entry.key);
        }
      }
    }
    state.lastSyncAt = DateTime.now();
  }

  void tick() {
    if (!state.isActive) return;
    for (final track in state.tracks.values) {
      var dx = track.velocityX.clamp(-maxStep, maxStep);
      var dy = track.velocityY.clamp(-maxStep, maxStep);
      track.bboxCamera = track.bboxCamera.translate(dx, dy);
      track.velocityX *= 0.92;
      track.velocityY *= 0.92;
    }
  }

  List<SceneObject> applyToObjects(List<SceneObject> objects) {
    return objects.map((obj) {
      final track = state.tracks[obj.id];
      if (track == null) return obj;
      obj.bboxCamera = track.bboxCamera;
      return obj;
    }).toList();
  }
}
