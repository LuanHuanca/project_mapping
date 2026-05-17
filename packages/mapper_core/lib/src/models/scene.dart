import 'calibration.dart';
import 'scene_object.dart';

class Scene {
  Scene({
    required this.id,
    required this.name,
    required this.projectId,
    List<SceneObject>? objects,
    Calibration? calibration,
    this.lastCalibratedAt,
    this.lastSyncedAt,
  })  : objects = objects ?? [],
        calibration = calibration ?? const Calibration();

  final String id;
  String name;
  final String projectId;
  List<SceneObject> objects;
  Calibration calibration;
  DateTime? lastCalibratedAt;
  DateTime? lastSyncedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'projectId': projectId,
        'objects': objects.map((o) => o.toJson()).toList(),
        'calibration': calibration.toJson(),
        'lastCalibratedAt': lastCalibratedAt?.toIso8601String(),
        'lastSyncedAt': lastSyncedAt?.toIso8601String(),
      };

  factory Scene.fromJson(Map<String, dynamic> json) {
    return Scene(
      id: json['id'] as String,
      name: json['name'] as String,
      projectId: json['projectId'] as String,
      objects: (json['objects'] as List<dynamic>?)
              ?.map((e) => SceneObject.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      calibration: Calibration.fromJson(
        json['calibration'] as Map<String, dynamic>?,
      ),
      lastCalibratedAt: json['lastCalibratedAt'] != null
          ? DateTime.parse(json['lastCalibratedAt'] as String)
          : null,
      lastSyncedAt: json['lastSyncedAt'] != null
          ? DateTime.parse(json['lastSyncedAt'] as String)
          : null,
    );
  }
}
