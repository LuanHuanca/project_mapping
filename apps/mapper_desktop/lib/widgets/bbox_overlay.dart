import 'package:flutter/material.dart';
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
    return Colors.indigo;
  }
}

class _BBoxRect extends StatelessWidget {
  const _BBoxRect({
    required this.bbox,
    required this.width,
    required this.height,
    required this.label,
    required this.selected,
    required this.showLabel,
    required this.color,
    required this.onTap,
  });

  final NormalizedBBox bbox;
  final double width;
  final double height;
  final String label;
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

    return Positioned(
      left: left,
      top: top,
      width: rectW,
      height: rectH,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? Colors.white : color,
              width: selected ? 3 : 2,
            ),
            color: color.withValues(alpha: 0.15),
          ),
          child: showLabel
              ? Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    color: Colors.black54,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Text(
                      label,
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
