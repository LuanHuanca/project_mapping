import 'dart:math' as math;
import 'package:mapper_core/mapper_core.dart';
import 'hand_gesture.dart';

/// Evaluates 21 3D hand landmarks for live gesture classification
/// and maps pointing actions to physical scene objects.
class HandLandmarkService {
  /// Classifies hand landmarks into a recognized gesture.
  HandGesture classify(List<HandLandmark> landmarks) {
    if (landmarks.length < 21) return HandGesture.none;

    final wrist = landmarks[0];
    final thumbTip = landmarks[4];
    final indexTip = landmarks[8];
    final middleTip = landmarks[12];
    final ringTip = landmarks[16];
    final pinkyTip = landmarks[20];

    final indexPip = landmarks[6];
    final middlePip = landmarks[10];
    final ringPip = landmarks[14];
    final pinkyPip = landmarks[18];

    // Distance from wrist to tips vs PIP joints
    final indexExtended = indexTip.y < indexPip.y;
    final middleExtended = middleTip.y < middlePip.y;
    final ringExtended = ringTip.y < ringPip.y;
    final pinkyExtended = pinkyTip.y < pinkyPip.y;

    // OK gesture check: thumb tip close to index tip
    final thumbIndexDist = math.sqrt(
      math.pow(thumbTip.x - indexTip.x, 2) + math.pow(thumbTip.y - indexTip.y, 2),
    );
    if (thumbIndexDist < 0.08 && middleExtended && ringExtended) {
      return HandGesture.ok;
    }

    // Point gesture: Only index finger extended
    if (indexExtended && !middleExtended && !ringExtended && !pinkyExtended) {
      return HandGesture.point;
    }

    // Peace gesture: Index & Middle extended
    if (indexExtended && middleExtended && !ringExtended && !pinkyExtended) {
      return HandGesture.peace;
    }

    // Open Palm: All 4 fingers extended
    if (indexExtended && middleExtended && ringExtended && pinkyExtended) {
      return HandGesture.openPalm;
    }

    // Fist: All fingers folded down
    if (!indexExtended && !middleExtended && !ringExtended && !pinkyExtended) {
      return HandGesture.fist;
    }

    return HandGesture.none;
  }

  /// Returns the ID of the scene object nearest to the pointing index fingertip, if within threshold.
  String? findTargetObjectId(
    HandLandmark indexFingertip,
    List<SceneObject> objects, {
    double threshold = 0.2,
  }) {
    String? closestId;
    double minDistance = double.infinity;

    for (final obj in objects) {
      final center = Point2D(obj.bboxCamera.centerX, obj.bboxCamera.centerY);
      final dist = math.sqrt(
        math.pow(center.x - indexFingertip.x, 2) +
            math.pow(center.y - indexFingertip.y, 2),
      );

      if (dist < minDistance && dist <= threshold) {
        minDistance = dist;
        closestId = obj.id;
      }
    }

    return closestId;
  }
}
