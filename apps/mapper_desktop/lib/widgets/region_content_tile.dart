import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mapper_core/mapper_core.dart';
import 'package:video_player/video_player.dart';

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
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  @override
  void didUpdateWidget(covariant RegionContentTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.object.content.localPath != widget.object.content.localPath) {
      _disposeVideo();
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    final path = widget.object.content.localPath;
    if (path == null || path.isEmpty || !File(path).existsSync()) return;
    final controller = VideoPlayerController.file(File(path));
    _controller = controller;
    await controller.initialize();
    controller.setLooping(widget.object.content.loop);
    controller.setVolume(widget.muted ? 0 : widget.object.content.volume);
    await controller.play();
    if (mounted) setState(() {});
  }

  void _disposeVideo() {
    _controller?.dispose();
    _controller = null;
  }

  @override
  void dispose() {
    _disposeVideo();
    super.dispose();
  }

  Color get _fallbackColor {
    if (widget.object.content.isSpotlight) {
      return Colors.white;
    }
    final hex = widget.object.content.colorHex.replaceFirst('#', '');
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    }
    return const Color(0xFF6366F1);
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.object.content;
    final controller = _controller;

    Widget childWidget;

    if (content.isSpotlight) {
      childWidget = Container(
        width: widget.size.width,
        height: widget.size.height,
        color: Colors.white,
      );
    } else if (controller != null && controller.value.isInitialized) {
      childWidget = SizedBox(
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
      childWidget = Container(
        width: widget.size.width,
        height: widget.size.height,
        color: _fallbackColor,
      );
    }

    // Apply Light Intensity ColorFilter
    final intensity = content.lightIntensity.clamp(0.0, 2.0);
    if ((intensity - 1.0).abs() > 0.01) {
      final matrix = <double>[
        intensity, 0, 0, 0, 0,
        0, intensity, 0, 0, 0,
        0, 0, intensity, 0, 0,
        0, 0, 0, 1, 0,
      ];
      childWidget = ColorFiltered(
        colorFilter: ColorFilter.matrix(matrix),
        child: childWidget,
      );
    }

    // Apply Opacity
    if (content.opacity < 1.0) {
      childWidget = Opacity(
        opacity: content.opacity.clamp(0.0, 1.0),
        child: childWidget,
      );
    }

    // Apply Feathering (edge blur mask)
    if (content.feathering > 0.0) {
      final blurRadius = content.feathering * 16.0;
      childWidget = Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.8),
              blurRadius: blurRadius,
              spreadRadius: blurRadius / 2,
            ),
          ],
        ),
        child: childWidget,
      );
    }

    return childWidget;
  }
}
