class ContentBinding {
  const ContentBinding({
    this.localPath,
    this.s3Key,
    this.colorHex = '#6366F1',
    this.loop = true,
    this.volume = 1.0,
    this.zIndex = 0,
  });

  final String? localPath;
  final String? s3Key;
  final String colorHex;
  final bool loop;
  final double volume;
  final int zIndex;

  bool get hasVideo => localPath != null && localPath!.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'localPath': localPath,
        's3Key': s3Key,
        'colorHex': colorHex,
        'loop': loop,
        'volume': volume,
        'zIndex': zIndex,
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
    );
  }

  ContentBinding copyWith({
    String? localPath,
    String? s3Key,
    String? colorHex,
    bool? loop,
    double? volume,
    int? zIndex,
  }) {
    return ContentBinding(
      localPath: localPath ?? this.localPath,
      s3Key: s3Key ?? this.s3Key,
      colorHex: colorHex ?? this.colorHex,
      loop: loop ?? this.loop,
      volume: volume ?? this.volume,
      zIndex: zIndex ?? this.zIndex,
    );
  }
}
