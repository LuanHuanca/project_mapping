import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:mapper_core/mapper_core.dart';

import 'api_config.dart';
import 'models/analyze_response.dart';

class ProjectionMapperApi {
  ProjectionMapperApi(this.config, {Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: config.baseUrl,
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 60),
                headers: {
                  if (config.apiKey != null && config.apiKey!.isNotEmpty)
                    'x-api-key': config.apiKey,
                },
              ),
            );

  final ApiConfig config;
  final Dio _dio;

  Future<Scene> getScene(String sceneId) async {
    final res = await _dio.get<Map<String, dynamic>>('/scenes/$sceneId');
    return Scene.fromJson(res.data!);
  }

  Future<AnalyzeResponse> analyzeScene({
    required String sceneId,
    required Uint8List jpegBytes,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/scenes/$sceneId/capture/analyze',
      data: jpegBytes,
      options: Options(
        contentType: 'image/jpeg',
        responseType: ResponseType.json,
      ),
    );
    return AnalyzeResponse.fromJson(res.data!);
  }

  Future<String> presignUpload({
    required String filename,
    required String contentType,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/media/presign',
      data: {
        'filename': filename,
        'contentType': contentType,
      },
    );
    return res.data!['uploadUrl'] as String;
  }

  Future<void> bindContent({
    required String sceneId,
    required String objectId,
    required String s3Key,
    bool loop = true,
  }) async {
    await _dio.put(
      '/scenes/$sceneId/objects/$objectId/content',
      data: {
        's3Key': s3Key,
        'loop': loop,
      },
    );
  }

  Future<void> saveScene(Scene scene) async {
    await _dio.put(
      '/scenes/${scene.id}',
      data: scene.toJson(),
    );
  }
}
