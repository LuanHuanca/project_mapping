import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mapper_core/mapper_core.dart';
import 'package:uuid/uuid.dart';

import 'shape_template_picker.dart';

class LayerManagerPanel extends StatelessWidget {
  const LayerManagerPanel({
    super.key,
    required this.object,
    required this.onObjectUpdated,
  });

  final SceneObject object;
  final VoidCallback onObjectUpdated;

  static const _uuid = Uuid();

  void _addLayer(LayerType type) {
    final layerId = _uuid.v4();
    final newLayer = LayerItem(
      id: layerId,
      name: switch (type) {
        LayerType.color => 'Capa Color',
        LayerType.image => 'Capa Imagen',
        LayerType.video => 'Capa Video',
        LayerType.generativeEffect => 'Efecto Generativo',
        LayerType.spotlightMask => 'Foco de Luz',
      },
      type: type,
      effectType: type == LayerType.generativeEffect
          ? GenerativeEffectType.outlineTracer
          : GenerativeEffectType.none,
      colorHex: type == LayerType.generativeEffect ? '#EC4899' : '#6366F1',
    );

    object.layers.add(newLayer);
    onObjectUpdated();
  }

  void _removeLayer(String layerId) {
    if (object.layers.length <= 1) return; // Keep at least 1 layer
    object.layers.removeWhere((l) => l.id == layerId);
    onObjectUpdated();
  }

  void _reorderLayers(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = object.layers.removeAt(oldIndex);
    object.layers.insert(newIndex, item);
    onObjectUpdated();
  }

  Future<void> _pickMediaForLayer(LayerItem layer, FileType fileType) async {
    final result = await FilePicker.platform.pickFiles(
      type: fileType,
      allowMultiple: false,
    );
    if (result == null || result.files.single.path == null) return;

    final updated = layer.copyWith(localPath: result.files.single.path!);
    final idx = object.layers.indexWhere((l) => l.id == layer.id);
    if (idx >= 0) {
      object.layers[idx] = updated;
      onObjectUpdated();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Shape Template Picker Header
        ShapeTemplatePicker(
          selectedShape: object.shapeType,
          onShapeSelected: (shape) {
            object.shapeType = shape;
            onObjectUpdated();
          },
        ),

        const SizedBox(height: 16),

        // Layers Header
        Row(
          children: [
            const Icon(Icons.layers_outlined, color: Color(0xFF10B981), size: 18),
            const SizedBox(width: 8),
            Text(
              'Gestor de Capas (HeavyM Stack)',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
            ),
            const Spacer(),
            PopupMenuButton<LayerType>(
              tooltip: 'Añadir Capa',
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add, color: Color(0xFF10B981), size: 18),
              ),
              onSelected: _addLayer,
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: LayerType.image,
                  child: Row(
                    children: [
                      Icon(Icons.image_outlined, size: 16, color: Color(0xFF38BDF8)),
                      SizedBox(width: 8),
                      Text('Capa de Imagen (PNG/JPG)'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: LayerType.video,
                  child: Row(
                    children: [
                      Icon(Icons.movie_outlined, size: 16, color: Color(0xFF10B981)),
                      SizedBox(width: 8),
                      Text('Capa de Video MP4'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: LayerType.generativeEffect,
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome, size: 16, color: Color(0xFFEC4899)),
                      SizedBox(width: 8),
                      Text('Efecto Generativo (Shader)'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: LayerType.color,
                  child: Row(
                    children: [
                      Icon(Icons.palette_outlined, size: 16, color: Color(0xFF818CF8)),
                      SizedBox(width: 8),
                      Text('Capa Color Sólido'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Reorderable Layers Stack List
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: object.layers.length,
          onReorder: _reorderLayers,
          itemBuilder: (context, index) {
            final layer = object.layers[index];

            return Card(
              key: ValueKey(layer.id),
              margin: const EdgeInsets.only(bottom: 8),
              color: const Color(0xFF1E293B).withValues(alpha: 0.7),
              child: ExpansionTile(
                leading: IconButton(
                  icon: Icon(
                    layer.isVisible ? Icons.visibility : Icons.visibility_off,
                    color: layer.isVisible ? const Color(0xFF10B981) : Colors.white38,
                    size: 18,
                  ),
                  onPressed: () {
                    final idx = object.layers.indexOf(layer);
                    object.layers[idx] = layer.copyWith(isVisible: !layer.isVisible);
                    onObjectUpdated();
                  },
                ),
                title: Text(
                  layer.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: layer.isVisible ? Colors.white : Colors.white38,
                  ),
                ),
                subtitle: Text(
                  '${_layerTypeLabel(layer.type)} · Opacidad ${(layer.opacity * 100).toInt()}%',
                  style: const TextStyle(fontSize: 11, color: Colors.white54),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (layer.type == LayerType.image)
                      IconButton(
                        icon: Icon(
                          layer.localPath != null ? Icons.image : Icons.add_photo_alternate_outlined,
                          color: layer.localPath != null
                              ? const Color(0xFF38BDF8)
                              : Colors.white54,
                          size: 18,
                        ),
                        onPressed: () => _pickMediaForLayer(layer, FileType.image),
                      ),
                    if (layer.type == LayerType.video)
                      IconButton(
                        icon: Icon(
                          layer.localPath != null ? Icons.movie : Icons.video_call_outlined,
                          color: layer.localPath != null
                              ? const Color(0xFF10B981)
                              : Colors.white54,
                          size: 18,
                        ),
                        onPressed: () => _pickMediaForLayer(layer, FileType.video),
                      ),
                    if (object.layers.length > 1)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                        onPressed: () => _removeLayer(layer.id),
                      ),
                  ],
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Opacity Slider
                        Row(
                          children: [
                            const Text('Opacidad:', style: TextStyle(fontSize: 11, color: Colors.white70)),
                            Expanded(
                              child: Slider(
                                value: layer.opacity,
                                min: 0.0,
                                max: 1.0,
                                activeColor: const Color(0xFF10B981),
                                onChanged: (val) {
                                  final idx = object.layers.indexOf(layer);
                                  object.layers[idx] = layer.copyWith(opacity: val);
                                  onObjectUpdated();
                                },
                              ),
                            ),
                          ],
                        ),

                        // Blend Mode Picker
                        Row(
                          children: [
                            const Text('Modo Fusión:', style: TextStyle(fontSize: 11, color: Colors.white70)),
                            const SizedBox(width: 8),
                            DropdownButton<LayerBlendMode>(
                              value: layer.blendMode,
                              isDense: true,
                              dropdownColor: const Color(0xFF0F172A),
                              items: LayerBlendMode.values
                                  .map(
                                    (bm) => DropdownMenuItem(
                                      value: bm,
                                      child: Text(
                                        bm.name,
                                        style: const TextStyle(fontSize: 12, color: Colors.white),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (bm) {
                                if (bm == null) return;
                                final idx = object.layers.indexOf(layer);
                                object.layers[idx] = layer.copyWith(blendMode: bm);
                                onObjectUpdated();
                              },
                            ),
                          ],
                        ),

                        // Generative Effect Controls
                        if (layer.type == LayerType.generativeEffect) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text('Efecto Shader:', style: TextStyle(fontSize: 11, color: Colors.white70)),
                              const SizedBox(width: 8),
                              DropdownButton<GenerativeEffectType>(
                                value: layer.effectType,
                                isDense: true,
                                dropdownColor: const Color(0xFF0F172A),
                                items: GenerativeEffectType.values
                                    .where((e) => e != GenerativeEffectType.none)
                                    .map(
                                      (et) => DropdownMenuItem(
                                        value: et,
                                        child: Text(
                                          _effectLabel(et),
                                          style: const TextStyle(fontSize: 12, color: Colors.white),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (et) {
                                  if (et == null) return;
                                  final idx = object.layers.indexOf(layer);
                                  object.layers[idx] = layer.copyWith(effectType: et);
                                  onObjectUpdated();
                                },
                              ),
                            ],
                          ),

                          Row(
                            children: [
                              const Text('Velocidad:', style: TextStyle(fontSize: 11, color: Colors.white70)),
                              Expanded(
                                child: Slider(
                                  value: layer.effectSpeed,
                                  min: 0.2,
                                  max: 3.0,
                                  activeColor: const Color(0xFFEC4899),
                                  onChanged: (val) {
                                    final idx = object.layers.indexOf(layer);
                                    object.layers[idx] = layer.copyWith(effectSpeed: val);
                                    onObjectUpdated();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  String _layerTypeLabel(LayerType t) => switch (t) {
        LayerType.color => 'Color',
        LayerType.image => 'Imagen',
        LayerType.video => 'Video MP4',
        LayerType.generativeEffect => 'Efecto Generativo',
        LayerType.spotlightMask => 'Foco de Luz',
      };

  String _effectLabel(GenerativeEffectType et) => switch (et) {
        GenerativeEffectType.none => 'Ninguno',
        GenerativeEffectType.outlineTracer => 'Trazador de Bordes',
        GenerativeEffectType.concentricPulse => 'Pulso Concéntrico',
        GenerativeEffectType.gridWave => 'Matriz Digital (Grid)',
        GenerativeEffectType.rainbowWave => 'Olas Arcoíris',
        GenerativeEffectType.strobe => 'Strobe Flash',
      };
}
