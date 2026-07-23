import 'package:flutter/material.dart';
import 'package:mapper_core/mapper_core.dart';

class HeavyMTopBar extends StatelessWidget {
  const HeavyMTopBar({
    super.key,
    required this.onAddShape,
    required this.onOpenProjector,
    required this.showGrid,
    required this.onToggleGrid,
    required this.snapToGrid,
    required this.onToggleSnap,
    required this.zoomLevel,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  final ValueChanged<ShapeType> onAddShape;
  final VoidCallback onOpenProjector;
  final bool showGrid;
  final VoidCallback onToggleGrid;
  final bool snapToGrid;
  final VoidCallback onToggleSnap;
  final double zoomLevel;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        border: Border(bottom: BorderSide(color: Color(0xFF262626))),
      ),
      child: Row(
        children: [
          // Studio Title Logo
          const Row(
            children: [
              Icon(Icons.layers_rounded, color: Color(0xFFF59E0B), size: 20),
              SizedBox(width: 8),
              Text(
                'Project Mapping Studio',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          const _VerticalDivider(),
          const SizedBox(width: 16),

          // Projector Output Shortcut
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.videocam_outlined, size: 18),
            label: const Text(
              'Abrir Ventana de Proyección',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            onPressed: onOpenProjector,
          ),
          const SizedBox(width: 16),
          const _VerticalDivider(),
          const SizedBox(width: 16),

          // Shape Creation Tools
          _shapeButton(
            icon: Icons.change_history_rounded,
            label: 'Triángulo',
            onTap: () => onAddShape(ShapeType.triangle),
          ),
          _shapeButton(
            icon: Icons.crop_square_rounded,
            label: 'Cuadro (Quad)',
            onTap: () => onAddShape(ShapeType.rectangle),
          ),
          _shapeButton(
            icon: Icons.circle_outlined,
            label: 'Círculo',
            onTap: () => onAddShape(ShapeType.circle),
          ),
          _shapeButton(
            icon: Icons.hexagon_outlined,
            label: 'Hexágono',
            onTap: () => onAddShape(ShapeType.hexagon),
          ),

          const SizedBox(width: 16),
          const _VerticalDivider(),
          const SizedBox(width: 16),

          // Canvas Controls (Snap, Grid)
          IconButton(
            tooltip: snapToGrid ? 'Imantación (Snap) Activa' : 'Imantación (Snap)',
            icon: Icon(
              Icons.center_focus_strong,
              color: snapToGrid ? const Color(0xFF38BDF8) : Colors.white54,
              size: 20,
            ),
            onPressed: onToggleSnap,
          ),
          IconButton(
            tooltip: showGrid ? 'Ocultar Rejilla' : 'Mostrar Rejilla',
            icon: Icon(
              Icons.grid_4x4_rounded,
              color: showGrid ? const Color(0xFF10B981) : Colors.white54,
              size: 20,
            ),
            onPressed: onToggleGrid,
          ),

          const Spacer(),

          // Zoom Level Controls
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: onZoomOut,
                  child: const Icon(Icons.remove, size: 14, color: Colors.white70),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(zoomLevel * 100).toInt()}%',
                  style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: onZoomIn,
                  child: const Icon(Icons.add, size: 14, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _shapeButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFFF59E0B), size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 20,
      color: Colors.white12,
    );
  }
}
