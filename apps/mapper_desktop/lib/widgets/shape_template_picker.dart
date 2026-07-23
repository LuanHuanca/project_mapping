import 'package:flutter/material.dart';
import 'package:mapper_core/mapper_core.dart';

class ShapeTemplatePicker extends StatelessWidget {
  const ShapeTemplatePicker({
    super.key,
    required this.selectedShape,
    required this.onShapeSelected,
  });

  final ShapeType selectedShape;
  final ValueChanged<ShapeType> onShapeSelected;

  @override
  Widget build(BuildContext context) {
    final shapes = ShapeType.values;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.category_outlined, color: Color(0xFF818CF8), size: 18),
              const SizedBox(width: 8),
              Text(
                'Plantillas de Formas Geométricas',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final shape in shapes)
                ChoiceChip(
                  avatar: Icon(_getShapeIcon(shape), size: 16),
                  label: Text(shape.displayName),
                  selected: selectedShape == shape,
                  selectedColor: const Color(0xFF6366F1).withValues(alpha: 0.25),
                  side: BorderSide(
                    color: selectedShape == shape
                        ? const Color(0xFF6366F1)
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                  onSelected: (selected) {
                    if (selected) onShapeSelected(shape);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getShapeIcon(ShapeType shape) => switch (shape) {
        ShapeType.rectangle => Icons.crop_square_rounded,
        ShapeType.circle => Icons.circle_outlined,
        ShapeType.triangle => Icons.change_history_rounded,
        ShapeType.hexagon => Icons.hexagon_outlined,
        ShapeType.polygon => Icons.polyline_rounded,
      };
}
