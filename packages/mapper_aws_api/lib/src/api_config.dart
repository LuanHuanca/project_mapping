class ApiConfig {
  const ApiConfig({
    required this.baseUrl,
    this.apiKey,
    this.enabled = true,
  });

  final String baseUrl;
  final String? apiKey;
  final bool enabled;

  bool get isConfigured => enabled && baseUrl.isNotEmpty;

  factory ApiConfig.fromJson(Map<String, dynamic> json) {
    return ApiConfig(
      baseUrl: json['baseUrl'] as String? ?? '',
      apiKey: json['apiKey'] as String?,
      enabled: json['enabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'baseUrl': baseUrl,
        'apiKey': apiKey,
        'enabled': enabled,
      };

  static const offline = ApiConfig(baseUrl: '', enabled: false);
}
