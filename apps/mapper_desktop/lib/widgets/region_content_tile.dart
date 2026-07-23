import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mapper_core/mapper_core.dart';
import 'package:video_player/video_player.dart';

import 'generative_effect_painter.dart';
import 'shape_clipper.dart';

class RegionContentTile extends StatefulWidget {
  const RegionContentTile({
    super.key,
    required this.object,
    required this.size,
    this.muted = false,
  });

  final SceneObject object;
  final Size size;
  final bool muted;

  @override
  State<RegionContentTile> createState() => _RegionContentTileState();
}

class _RegionContentTileState extends State<RegionContentTile> {
  final Map<String, VideoPlayerController> _videoControllers = {};

  @override
  void initState() {
    super.initState();
    _initVideoLayers();
  }

  @override
  void didUpdateWidget(covariant RegionContentTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    _initVideoLayers();
  }

  Future<void> _initVideoLayers() async {
    final activeVideoPaths = <String, String>{};

    for (final layer in widget.object.layers) {
      if (layer.type == LayerType.video &&
          layer.localPath != null &&
          layer.localPath!.isNotEmpty) {
        activeVideoPaths[layer.id] = layer.localPath!;
      }
    }

    // Also check root contentBinding for fallback
    if (widget.object.content.hasVideo) {
      activeVideoPaths['root_video'] = widget.object.content.localPath!;
    }

    // Clean up unused controllers
    _videoControllers.removeWhere((id, controller) {
      if (!activeVideoPaths.containsKey(id)) {
        controller.dispose();
        return true;
      }
      return false;
    });

    // Initialize new video layers
    for (final entry in activeVideoPaths.entries) {
      final layerId = entry.key;
      final videoPath = entry.value;

      if (!_videoControllers.containsKey(layerId) && File(videoPath).existsSync()) {
        final controller = VideoPlayerController.file(File(videoPath));
        _videoControllers[layerId] = controller;
        await controller.initialize();
        controller.setLooping(true);
        controller.setVolume(widget.muted ? 0 : widget.object.content.volume);
        await controller.play();
        if (mounted) setState(() {});
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    _videoControllers.clear();
    super.dispose();
  }

  BlendMode _toFlutterBlendMode(LayerBlendMode mode) {
    return switch (mode) {
      LayerBlendMode.normal => BlendMode.srcOver,
      LayerBlendMode.additive => BlendMode.plus,
      LayerBlendMode.multiply => BlendMode.multiply,
      LayerBlendMode.screen => BlendMode.screen,
    };
  }

  Color _parseColor(String hex) {
    final clean = hex.replaceFirst('#', '');
    if (clean.length == 6) {
      return Color(int.parse('FF$clean', radix: 16));
    }
    return const Color(0xFF6366F1);
  }

  Widget _buildLayerWidget(LayerItem layer) {
    if (!layer.isVisible) return const SizedBox.shrink();

    Widget layerWidget;

    switch (layer.type) {
      case LayerType.color:
        layerWidget = Container(
          width: widget.size.width,
          height: widget.size.height,
          color: _parseColor(layer.colorHex),
        );
        break;

      case LayerType.image:
        if (layer.localPath != null &&
            layer.localPath!.isNotEmpty &&
            File(layer.localPath!).existsSync()) {
          layerWidget = SizedBox(
            width: widget.size.width,
            height: widget.size.height,
            child: Image.file(
              File(layer.localPath!),
              fit: BoxFit.cover,
            ),
          );
        } else {
          layerWidget = Container(
            width: widget.size.width,
            height: widget.size.height,
            color: _parseColor(layer.colorHex),
          );
        }
        break;

      case LayerType.video:
        final controller = _videoControllers[layer.id] ?? _videoControllers['root_video'];
        if (controller != null && controller.value.isInitialized) {
          layerWidget = SizedBox(
            width: widget.size.width,
            height: widget.size.height,
            child: FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: controller.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            ),
          );
        } else {
          layerWidget = Container(
            width: widget.size.width,
            height: widget.size.height,
            color: _parseColor(layer.colorHex),
          );
        }
        break;

      case LayerType.generativeEffect:
        layerWidget = GenerativeEffectWidget(
          effectType: layer.effectType,
          speed: layer.effectSpeed,
          color: _parseColor(layer.colorHex),
        );
        break;

      case LayerType.spotlightMask:
        layerWidget = Container(
          width: widget.size.width,
          height: widget.size.height,
          color: Colors.white,
        );
        break;
    }

    if (layer.opacity < 1.0) {
      layerWidget = Opacity(
        opacity: layer.opacity.clamp(0.0, 1.0),
        child: layerWidget,
      );
    }

    if (layer.blendMode != LayerBlendMode.normal) {
      layerWidget = ColorFiltered(
        colorFilter: ColorFilter.mode(
          Colors.transparent,
          _toFlutterBlendMode(layer.blendMode),
        ),
        child: layerWidget,
      );
    }

    return layerWidget;
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.object.content;
    final layers = widget.object.layers;

    Widget composedContent;

    if (layers.isNotEmpty) {
      composedContent = Stack(
        fit: StackFit.expand,
        children: [
          for (final layer in layers) _buildLayerWidget(layer),
        ],
      );
    } else {
      composedContent = Container(
        width: widget.size.width,
        height: widget.size.height,
        color: _parseColor(content.colorHex),
      );
    }

    // Apply Light Intensity Matrix
    final intensity = content.lightIntensity.clamp(0.0, 2.0);
    if ((intensity - 1.0).abs() > 0.01) {
      final matrix = <double>[
        intensity, 0, 0, 0, 0,
        0, intensity, 0, 0, 0,
        0, 0, intensity, 0, 0,
        0, 0, 0, 1, 0,
      ];
      composedContent = ColorFiltered(
        colorFilter: ColorFilter.matrix(matrix),
        child: composedContent,
      );
    }

    // Clip to Shape Geometry Template
    Widget styledTile = ClipPath(
      clipper: ShapeClipper(widget.object.shapeType),
      child: composedContent,
    );

    // Apply Feathering (edge blur mask)
    if (content.feathering > 0.0) {
      final blurRadius = content.feathering * 16.0;
      styledTile = Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.8),
              blurRadius: blurRadius,
              spreadRadius: blurRadius / 2,
            ),
          ],
        ),
        child: styledTile,
      );
    }

    return styledTile;
  }
}
