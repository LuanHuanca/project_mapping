import 'package:flutter/material.dart';

class HeavyMRightFxBar extends StatelessWidget {
  const HeavyMRightFxBar({
    super.key,
    required this.selectedFxMode,
    required this.onSelectFxMode,
    this.suggestedShaderNames = const ['Grid Wave', 'Outline Tracer'],
  });

  final String selectedFxMode;
  final ValueChanged<String> onSelectFxMode;
  final List<String> suggestedShaderNames;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      color: const Color(0xFF141414),
      child: Column(
        children: [
          const SizedBox(height: 8),

          // Outline Mode
          _fxIconButton(
            modeKey: 'outline',
            tooltip: 'Modo Contorno (Outline Shader)',
            icon: Icons.check_box_outline_blank_rounded,
            activeColor: const Color(0xFFEF4444),
          ),

          // Solid Fill Mode
          _fxIconButton(
            modeKey: 'solid',
            tooltip: 'Modo Relleno Sólido',
            icon: Icons.square_rounded,
            activeColor: const Color(0xFFEF4444),
          ),

          // Generative Shaders with AI Suggestion Badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              _fxIconButton(
                modeKey: 'shaders',
                tooltip: 'Efectos Generativos (Sugeridos para esta superficie: ${suggestedShaderNames.join(", ")})',
                icon: Icons.auto_awesome,
                activeColor: const Color(0xFFF59E0B),
              ),
              if (suggestedShaderNames.isNotEmpty)
                Positioned(
                  top: 2,
                  right: 4,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),

          // Media Library
          _fxIconButton(
            modeKey: 'media',
            tooltip: 'Galería de Medios (Fotos y Videos)',
            icon: Icons.perm_media_outlined,
            activeColor: const Color(0xFF38BDF8),
          ),

          // Sparkles / Special FX
          _fxIconButton(
            modeKey: 'sparkles',
            tooltip: 'Efectos Especiales Generativos',
            icon: Icons.blur_on_rounded,
            activeColor: const Color(0xFFEC4899),
          ),
        ],
      ),
    );
  }

  Widget _fxIconButton({
    required String modeKey,
    required String tooltip,
    required IconData icon,
    required Color activeColor,
  }) {
    final isSelected = selectedFxMode == modeKey;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: IconButton(
        tooltip: tooltip,
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? activeColor : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isSelected ? activeColor : Colors.white54,
          ),
        ),
        onPressed: () => onSelectFxMode(modeKey),
      ),
    );
  }
}
