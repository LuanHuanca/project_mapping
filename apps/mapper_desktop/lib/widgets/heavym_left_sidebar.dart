import 'package:flutter/material.dart';
import 'package:mapper_core/mapper_core.dart';

class HeavyMLeftSidebar extends StatefulWidget {
  const HeavyMLeftSidebar({
    super.key,
    required this.objects,
    required this.selectedId,
    required this.onSelectObject,
    required this.onToggleVisibility,
    required this.onToggleLock,
    required this.onDeleteObject,
    required this.onAddManualShape,
    required this.onClearAll,
  });

  final List<SceneObject> objects;
  final String? selectedId;
  final ValueChanged<String> onSelectObject;
  final ValueChanged<SceneObject> onToggleVisibility;
  final ValueChanged<SceneObject> onToggleLock;
  final ValueChanged<String> onDeleteObject;
  final ValueChanged<ShapeType> onAddManualShape;
  final VoidCallback onClearAll;

  @override
  State<HeavyMLeftSidebar> createState() => _HeavyMLeftSidebarState();
}

class _HeavyMLeftSidebarState extends State<HeavyMLeftSidebar> {
  bool _isCollapsed = false;

  @override
  Widget build(BuildContext context) {
    if (_isCollapsed) {
      return Container(
        width: 36,
        color: const Color(0xFF181818),
        child: Column(
          children: [
            const SizedBox(height: 8),
            IconButton(
              tooltip: 'Expandir Panel de Capas',
              icon: const Icon(Icons.chevron_right, color: Color(0xFFF59E0B)),
              onPressed: () => setState(() => _isCollapsed = false),
            ),
            const RotatedBox(
              quarterTurns: 1,
              child: Text(
                'LAYERS & FACES',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Group objects by groupName
    final groups = <String, List<SceneObject>>{};
    for (final obj in widget.objects) {
      groups.putIfAbsent(obj.groupName, () => []).add(obj);
    }

    return SizedBox(
      width: 280,
      child: Container(
        color: const Color(0xFF181818),
        child: Column(
          children: [
            // Panel Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFF202020),
                border: Border(bottom: BorderSide(color: Color(0xFF2D2D2D))),
              ),
              child: Row(
                children: [
                  const Icon(Icons.layers, size: 16, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 8),
                  const Text(
                    'Layers & Faces',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Añadir Cara (Triángulo)',
                    icon: const Icon(Icons.add, color: Color(0xFFF59E0B), size: 18),
                    onPressed: () => widget.onAddManualShape(ShapeType.triangle),
                  ),
                  IconButton(
                    tooltip: 'Ocultar Panel',
                    icon: const Icon(Icons.chevron_left, color: Colors.white54, size: 18),
                    onPressed: () => setState(() => _isCollapsed = true),
                  ),
                ],
              ),
            ),

            // Tree View
            Expanded(
              child: ListView(
                children: [
                  // Masks Folder
                  const ListTile(
                    dense: true,
                    leading: Icon(Icons.folder_outlined, size: 16, color: Colors.white54),
                    title: Text('Masks (0)', style: TextStyle(fontSize: 12, color: Colors.white70)),
                    trailing: Icon(Icons.visibility_outlined, size: 16, color: Colors.white38),
                  ),

                  const Divider(height: 1, color: Color(0xFF2D2D2D)),

                  // Groups and Faces Tree
                  for (final entry in groups.entries) ...[
                    ExpansionTile(
                      initiallyExpanded: true,
                      tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                      leading: const Icon(Icons.folder, size: 16, color: Color(0xFFF59E0B)),
                      title: Text(
                        '${entry.key} (${entry.value.length})',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      children: [
                        for (final obj in entry.value)
                          InkWell(
                            onTap: () => widget.onSelectObject(obj.id),
                            child: Container(
                              color: obj.id == widget.selectedId
                                  ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                                  : Colors.transparent,
                              padding: const EdgeInsets.only(left: 32, right: 12, top: 6, bottom: 6),
                              child: Row(
                                children: [
                                  Icon(_getShapeIcon(obj.shapeType), size: 14, color: const Color(0xFFF59E0B)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      obj.label,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: obj.isHidden ? Colors.white38 : Colors.white,
                                        fontWeight: obj.id == widget.selectedId ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  // Lock Toggle
                                  IconButton(
                                    icon: Icon(
                                      obj.isLocked ? Icons.lock : Icons.lock_open_outlined,
                                      size: 14,
                                      color: obj.isLocked ? const Color(0xFFF59E0B) : Colors.white38,
                                    ),
                                    onPressed: () => widget.onToggleLock(obj),
                                  ),
                                  // Visibility Toggle (Eye Icon)
                                  IconButton(
                                    icon: Icon(
                                      obj.isHidden ? Icons.visibility_off : Icons.visibility,
                                      size: 14,
                                      color: obj.isHidden ? Colors.white24 : const Color(0xFF10B981),
                                    ),
                                    onPressed: () => widget.onToggleVisibility(obj),
                                  ),
                                  // Delete
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 14, color: Colors.redAccent),
                                    onPressed: () => widget.onDeleteObject(obj.id),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Clear All Button
            if (widget.objects.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFF2D2D2D))),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.5)),
                    ),
                    onPressed: widget.onClearAll,
                    icon: const Icon(Icons.delete_sweep_outlined, size: 16),
                    label: const Text('Limpiar Caras', style: TextStyle(fontSize: 11)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getShapeIcon(ShapeType shape) => switch (shape) {
        ShapeType.triangle => Icons.change_history_rounded,
        ShapeType.rectangle => Icons.crop_square_rounded,
        ShapeType.circle => Icons.circle_outlined,
        ShapeType.hexagon => Icons.hexagon_outlined,
        ShapeType.polygon => Icons.polyline_rounded,
      };
}
