import 'scene.dart';

class Project {
  Project({
    required this.id,
    required this.name,
    List<Scene>? scenes,
    this.createdAt,
  }) : scenes = scenes ?? [];

  final String id;
  String name;
  List<Scene> scenes;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'scenes': scenes.map((s) => s.toJson()).toList(),
        'createdAt': createdAt?.toIso8601String(),
      };

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      name: json['name'] as String,
      scenes: (json['scenes'] as List<dynamic>?)
              ?.map((e) => Scene.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }
}
