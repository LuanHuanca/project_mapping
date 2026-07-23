class ContentBinding {
  const ContentBinding({
    this.localPath,
    this.s3Key,
    this.colorHex = '#6366F1',
    this.loop = true,
    this.volume = 1.0,
    this.zIndex = 0,
    this.lightIntensity = 1.0,
    this.feathering = 0.0,
    this.opacity = 1.0,
    this.isSpotlight = false,
  });

  final String? localPath;
  final String? s3Key;
  final String colorHex;
  final bool loop;
  final double volume;
  final int zIndex;

  /// Light intensity multiplier (0.0 to 2.0)
  final double lightIntensity;

  /// Edge feathering / blur mask (0.0 to 1.0)
  final double feathering;

  /// Region opacity (0.0 to 1.0)
  final double opacity;

  /// Whether this region acts as a pure projector light spotlight cutout
  final bool isSpotlight;

  bool get hasVideo => localPath != null && localPath!.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'localPath': localPath,
        's3Key': s3Key,
        'colorHex': colorHex,
        'loop': loop,
        'volume': volume,
        'zIndex': zIndex,
        'lightIntensity': lightIntensity,
        'feathering': feathering,
        'opacity': opacity,
        'isSpotlight': isSpotlight,
      };

  factory ContentBinding.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ContentBinding();
    return ContentBinding(
      localPath: json['localPath'] as String?,
      s3Key: json['s3Key'] as String?,
      colorHex: json['colorHex'] as String? ?? '#6366F1',
      loop: json['loop'] as bool? ?? true,
      volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
      zIndex: json['zIndex'] as int? ?? 0,
      lightIntensity: (json['lightIntensity'] as num?)?.toDouble() ?? 1.0,
      feathering: (json['feathering'] as num?)?.toDouble() ?? 0.0,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      isSpotlight: json['isSpotlight'] as bool? ?? false,
    );
  }

  ContentBinding copyWith({
    String? localPath,
    String? s3Key,
    String? colorHex,
    bool? loop,
    double? volume,
    int? zIndex,
    double? lightIntensity,
    double? feathering,
    double? opacity,
    bool? isSpotlight,
  }) {
    return ContentBinding(
      localPath: localPath ?? this.localPath,
      s3Key: s3Key ?? this.s3Key,
      colorHex: colorHex ?? this.colorHex,
      loop: loop ?? this.loop,
      volume: volume ?? this.volume,
      zIndex: zIndex ?? this.zIndex,
      lightIntensity: lightIntensity ?? this.lightIntensity,
      feathering: feathering ?? this.feathering,
      opacity: opacity ?? this.opacity,
      isSpotlight: isSpotlight ?? this.isSpotlight,
    );
  }
}
