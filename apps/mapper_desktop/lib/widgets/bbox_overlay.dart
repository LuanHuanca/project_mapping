import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mapper_core/mapper_core.dart';

class BboxOverlay extends StatelessWidget {
  const BboxOverlay({
    super.key,
    required this.objects,
    required this.selectedId,
    required this.onSelect,
    this.showLabels = true,
    this.useProjectorSpace = false,
  });

  final List<SceneObject> objects;
  final String? selectedId;
  final ValueChanged<String> onSelect;
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
                bbox: useProjectorSpace ? obj.bboxProjector : obj.bboxCamera,
                width: w,
                height: h,
                label: obj.label,
                confidence: obj.confidence,
                selected: obj.id == selectedId,
                showLabel: showLabels,
                color: _parseColor(obj.content.colorHex),
                onTap: () => onSelect(obj.id),
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
    required this.bbox,
    required this.width,
    required this.height,
    required this.label,
    required this.confidence,
    required this.selected,
    required this.showLabel,
    required this.color,
    required this.onTap,
  });

  final NormalizedBBox bbox;
  final double width;
  final double height;
  final String label;
  final double confidence;
  final bool selected;
  final bool showLabel;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final left = bbox.left * width;
    final top = bbox.top * height;
    final rectW = bbox.width * width;
    final rectH = bbox.height * height;
    final activeColor = selected ? const Color(0xFF818CF8) : color;

    return Positioned(
      left: left,
      top: top,
      width: rectW,
      height: rectH,
      child: GestureDetector(
        onTap: onTap,
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
    );
  }
}
