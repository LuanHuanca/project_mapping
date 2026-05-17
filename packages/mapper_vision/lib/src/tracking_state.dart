import 'package:mapper_core/mapper_core.dart';

class TrackedObject {
  TrackedObject({
    required this.objectId,
    required this.bboxCamera,
    this.velocityX = 0,
    this.velocityY = 0,
    this.lostFrames = 0,
  });

  final String objectId;
  NormalizedBBox bboxCamera;
  double velocityX;
  double velocityY;
  int lostFrames;
}

class TrackingState {
  TrackingState({this.isActive = false, this.lastSyncAt});

  bool isActive;
  DateTime? lastSyncAt;
  final Map<String, TrackedObject> tracks = {};
}
