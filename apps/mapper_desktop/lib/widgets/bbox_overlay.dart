import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mapper_core/mapper_core.dart';

class BboxOverlay extends StatelessWidget {
  const BboxOverlay({
    super.key,
    required this.objects,
    required this.selectedId,
    required this.onSelect,
    this.onBboxChanged,
    this.showLabels = true,
    this.useProjectorSpace = false,
  });

  final List<SceneObject> objects;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  final void Function(String id, NormalizedBBox newBbox)? onBboxChanged;
  final bool showLabels;
  final bool useProjectorSpace;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        return Stack(
          children: [
            for (final obj in objects)
              _BBoxRect(
                objectId: obj.id,
                bbox: useProjectorSpace ? obj.bboxProjector : obj.bboxCamera,
                width: w,
                height: h,
                label: obj.label,
                confidence: obj.confidence,
                selected: obj.id == selectedId,
                showLabel: showLabels,
                color: _parseColor(obj.content.colorHex),
                onTap: () => onSelect(obj.id),
                onBboxChanged: onBboxChanged != null
                    ? (newBbox) => onBboxChanged!(obj.id, newBbox)
                    : null,
              ),
          ],
        );
      },
    );
  }

  Color _parseColor(String hex) {
    final value = hex.replaceFirst('#', '');
    if (value.length == 6) {
      return Color(int.parse('FF$value', radix: 16));
    }
    return const Color(0xFF6366F1);
  }
}

class _BBoxRect extends StatelessWidget {
  const _BBoxRect({
    required this.objectId,
    required this.bbox,
    required this.width,
    required this.height,
    required this.label,
    required this.confidence,
    required this.selected,
    required this.showLabel,
    required this.color,
    required this.onTap,
    this.onBboxChanged,
  });

  final String objectId;
  final NormalizedBBox bbox;
  final double width;
  final double height;
  final String label;
  final double confidence;
  final bool selected;
  final bool showLabel;
  final Color color;
  final VoidCallback onTap;
  final ValueChanged<NormalizedBBox>? onBboxChanged;

  @override
  Widget build(BuildContext context) {
    final left = (bbox.left * width).clamp(0.0, width);
    final top = (bbox.top * height).clamp(0.0, height);
    final rectW = (bbox.width * width).clamp(20.0, width);
    final rectH = (bbox.height * height).clamp(20.0, height);
    final activeColor = selected ? const Color(0xFF818CF8) : color;

    return Stack(
      children: [
        Positioned(
          left: left,
          top: top,
          width: rectW,
          height: rectH,
          child: GestureDetector(
            onTap: onTap,
            onPanUpdate: selected && onBboxChanged != null
                ? (details) {
                    final dx = details.delta.dx / width;
                    final dy = details.delta.dy / height;
                    final newBbox = NormalizedBBox(
                      left: (bbox.left + dx).clamp(0.0, 1.0 - bbox.width),
                      top: (bbox.top + dy).clamp(0.0, 1.0 - bbox.height),
                      width: bbox.width,
                      height: bbox.height,
                    );
                    onBboxChanged!(newBbox);
                  }
                : null,
            child: AnimatedContainer(
              duration: 150.ms,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: activeColor,
                  width: selected ? 3 : 2,
                ),
                color: activeColor.withValues(alpha: selected ? 0.25 : 0.12),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: activeColor.withValues(alpha: 0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
              child: showLabel
                  ? Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: activeColor.withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: activeColor,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${(confidence * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : null,
            ),
          ),
        ),

        // Interactive Corner Resizing Handles when selected
        if (selected && onBboxChanged != null) ...[
          // Bottom-Right Corner Resize Handle
          Positioned(
            left: left + rectW - 12,
            top: top + rectH - 12,
            child: GestureDetector(
              onPanUpdate: (details) {
                final newW = ((rectW + details.delta.dx) / width).clamp(0.05, 1.0 - bbox.left);
                final newH = ((rectH + details.delta.dy) / height).clamp(0.05, 1.0 - bbox.top);
                onBboxChanged!(
                  NormalizedBBox(
                    left: bbox.left,
                    top: bbox.top,
                    width: newW,
                    height: newH,
                  ),
                );
              },
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFEC4899),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Colors.black45, blurRadius: 6),
                  ],
                ),
                child: const Icon(Icons.open_in_full_rounded, size: 12, color: Colors.white),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
