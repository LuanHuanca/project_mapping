enum LayerType {
  color,
  image,
  video,
  generativeEffect,
  spotlightMask,
}

enum GenerativeEffectType {
  none,
  outlineTracer,
  concentricPulse,
  gridWave,
  rainbowWave,
  strobe,
}

enum LayerBlendMode {
  normal,
  additive,
  multiply,
  screen,
}

class LayerItem {
  const LayerItem({
    required this.id,
    required this.name,
    this.type = LayerType.color,
    this.localPath,
    this.colorHex = '#6366F1',
    this.effectType = GenerativeEffectType.none,
    this.effectSpeed = 1.0,
    this.opacity = 1.0,
    this.blendMode = LayerBlendMode.normal,
    this.isVisible = true,
  });

  final String id;
  final String name;
  final LayerType type;
  final String? localPath;
  final String colorHex;
  final GenerativeEffectType effectType;
  final double effectSpeed;
  final double opacity;
  final LayerBlendMode blendMode;
  final bool isVisible;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'localPath': localPath,
        'colorHex': colorHex,
        'effectType': effectType.name,
        'effectSpeed': effectSpeed,
        'opacity': opacity,
        'blendMode': blendMode.name,
        'isVisible': isVisible,
      };

  factory LayerItem.fromJson(Map<String, dynamic> json) {
    return LayerItem(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Capa',
      type: LayerType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => LayerType.color,
      ),
      localPath: json['localPath'] as String?,
      colorHex: json['colorHex'] as String? ?? '#6366F1',
      effectType: GenerativeEffectType.values.firstWhere(
        (e) => e.name == json['effectType'],
        orElse: () => GenerativeEffectType.none,
      ),
      effectSpeed: (json['effectSpeed'] as num?)?.toDouble() ?? 1.0,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      blendMode: LayerBlendMode.values.firstWhere(
        (e) => e.name == json['blendMode'],
        orElse: () => LayerBlendMode.normal,
      ),
      isVisible: json['isVisible'] as bool? ?? true,
    );
  }

  LayerItem copyWith({
    String? name,
    LayerType? type,
    String? localPath,
    String? colorHex,
    GenerativeEffectType? effectType,
    double? effectSpeed,
    double? opacity,
    LayerBlendMode? blendMode,
    bool? isVisible,
  }) {
    return LayerItem(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      localPath: localPath ?? this.localPath,
      colorHex: colorHex ?? this.colorHex,
      effectType: effectType ?? this.effectType,
      effectSpeed: effectSpeed ?? this.effectSpeed,
      opacity: opacity ?? this.opacity,
      blendMode: blendMode ?? this.blendMode,
      isVisible: isVisible ?? this.isVisible,
    );
  }
}
