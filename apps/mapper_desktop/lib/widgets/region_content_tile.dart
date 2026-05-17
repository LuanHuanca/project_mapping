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
    final hex = widget.object.content.colorHex.replaceFirst('#', '');
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    }
    return const Color(0xFF6366F1);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller != null && controller.value.isInitialized) {
      return SizedBox(
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
    }

    return Container(
      width: widget.size.width,
      height: widget.size.height,
      color: _fallbackColor,
    );
  }
}
