import 'dart:convert';
import 'dart:io';

import 'package:mapper_core/mapper_core.dart';
import 'package:path_provider/path_provider.dart';

/// Offline cache for scenes and media metadata.
class CacheService {
  Future<File> _cacheFile(String name) async {
    final dir = await getApplicationSupportDirectory();
    final cacheDir = Directory('${dir.path}/cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return File('${cacheDir.path}/$name');
  }

  Future<void> saveScene(Project project) async {
    final file = await _cacheFile('active_project.json');
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(project.toJson()),
    );
  }

  Future<Project?> loadScene() async {
    try {
      final file = await _cacheFile('active_project.json');
      if (!await file.exists()) return null;
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return Project.fromJson(json);
    } catch (_) {
      return null;
    }
  }
}
