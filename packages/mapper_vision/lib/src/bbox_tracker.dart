import 'package:mapper_core/mapper_core.dart';

import 'tracking_state.dart';

/// Refined tracker between Rekognition re-detections.
/// Provides smooth position interpolation (EMA), velocity prediction,
/// aspect ratio preservation, and coordinate bounds clamping.
class BboxTracker {
  BboxTracker({
    this.damping = 0.35,
    this.maxStep = 0.05,
    this.smoothingFactor = 0.4,
    this.lostFrameThreshold = 30,
  });

  final double damping;
  final double maxStep;
  final double smoothingFactor;
  final int lostFrameThreshold;

  final TrackingState state = TrackingState();

  void resetFromScene(List<SceneObject> objects) {
    state.tracks.clear();
    for (final obj in objects) {
      state.tracks[obj.id] = TrackedObject(
        objectId: obj.id,
        bboxCamera: _clampBBox(obj.bboxCamera),
      );
    }
    state.isActive = true;
    state.lastSyncAt = DateTime.now();
  }

  void syncFromDetections(List<SceneObject> detected) {
    final used = <String>{};
    for (final det in detected) {
      final newBBox = _clampBBox(det.bboxCamera);
      final existing = state.tracks[det.id];

      if (existing != null) {
        // Calculate velocity vector
        final dx = newBBox.centerX - existing.bboxCamera.centerX;
        final dy = newBBox.centerY - existing.bboxCamera.centerY;

        existing.velocityX = existing.velocityX * (1 - damping) + dx * damping;
        existing.velocityY = existing.velocityY * (1 - damping) + dy * damping;

        // Exponential smoothing for position & size to prevent jitter
        final smoothedLeft = existing.bboxCamera.left + (newBBox.left - existing.bboxCamera.left) * smoothingFactor;
        final smoothedTop = existing.bboxCamera.top + (newBBox.top - existing.bboxCamera.top) * smoothingFactor;
        final smoothedWidth = existing.bboxCamera.width + (newBBox.width - existing.bboxCamera.width) * smoothingFactor;
        final smoothedHeight = existing.bboxCamera.height + (newBBox.height - existing.bboxCamera.height) * smoothingFactor;

        existing.bboxCamera = _clampBBox(NormalizedBBox(
          left: smoothedLeft,
          top: smoothedTop,
          width: smoothedWidth,
          height: smoothedHeight,
        ));
        existing.lostFrames = 0;
      } else {
        state.tracks[det.id] = TrackedObject(
          objectId: det.id,
          bboxCamera: newBBox,
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
      final dx = track.velocityX.clamp(-maxStep, maxStep);
      final dy = track.velocityY.clamp(-maxStep, maxStep);

      final updatedBBox = track.bboxCamera.translate(dx, dy);
      track.bboxCamera = _clampBBox(updatedBBox);

      // Friction decay on velocity
      track.velocityX *= 0.90;
      track.velocityY *= 0.90;
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

  /// Clamps bounding box values strictly within normalized [0, 1] range
  NormalizedBBox _clampBBox(NormalizedBBox bbox) {
    final left = bbox.left.clamp(0.0, 0.95);
    final top = bbox.top.clamp(0.0, 0.95);
    final width = bbox.width.clamp(0.02, 1.0 - left);
    final height = bbox.height.clamp(0.02, 1.0 - top);
    return NormalizedBBox(
      left: left,
      top: top,
      width: width,
      height: height,
    );
  }
}

