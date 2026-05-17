import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:mapper_aws_api/mapper_aws_api.dart';
import 'package:path_provider/path_provider.dart';

class ConfigService {
  ApiConfig _config = ApiConfig.offline;

  ApiConfig get config => _config;

  Future<void> load() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final file = File('${dir.path}/api_config.json');
      if (await file.exists()) {
        final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        _config = ApiConfig.fromJson(json);
        return;
      }
    } catch (_) {}

    try {
      final raw = await rootBundle.loadString('assets/config/api_config.example.json');
      _config = ApiConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      _config = ApiConfig.offline;
    }
  }

  Future<void> save(ApiConfig config) async {
    _config = config;
    final dir = await getApplicationSupportDirectory();
    final file = File('${dir.path}/api_config.json');
    await file.writeAsString(jsonEncode(config.toJson()));
  }
}
