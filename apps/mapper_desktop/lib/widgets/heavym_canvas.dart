import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:mapper_core/mapper_core.dart';

import 'region_content_tile.dart';

class HeavyMCanvas extends StatefulWidget {
  const HeavyMCanvas({
    super.key,
    required this.objects,
    required this.selectedId,
    required this.onSelectObject,
    required this.onVertexUpdated,
    required this.showGrid,
    required this.snapToGrid,
    required this.cameraController,
    required this.isCameraInitialized,
  });

  final List<SceneObject> objects;
  final String? selectedId;
  final ValueChanged<String> onSelectObject;
  final void Function(String objectId, int vertexIndex, Point2D newPos) onVertexUpdated;
  final bool showGrid;
  final bool snapToGrid;
  final CameraController? cameraController;
  final bool isCameraInitialized;

  @override
  State<HeavyMCanvas> createState() => _HeavyMCanvasState();
}

class _HeavyMCanvasState extends State<HeavyMCanvas> {
  int? _hoveredVertexIndex;
  String? _hoveredObjectId;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        return Container(
          color: const Color(0xFF181818),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Grid overlay
              if (widget.showGrid) const _GridPainterWidget(),

              // Render Faces and Multi-Vertex Polygons
              for (final obj in widget.objects)
                if (!obj.isHidden) ...[
                  // Polygon Face Render
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () => widget.onSelectObject(obj.id),
                      child: CustomPaint(
                        painter: _PolygonFacePainter(
                          object: obj,
                          isSelected: obj.id == widget.selectedId,
                        ),
                        child: _buildTileForObject(obj, Size(w, h)),
                      ),
                    ),
                  ),

                  // Interactive Vertex Node Handles (⚪ / 🟠)
                  if (!obj.isLocked)
                    for (var i = 0; i < obj.vertices.length; i++)
                      _buildVertexHandle(
                        object: obj,
                        vertexIndex: i,
                        canvasWidth: w,
                        canvasHeight: h,
                      ),
                ],

              // Picture-in-Picture (PiP) Mini Camera Viewport in Bottom-Right Corner
              Positioned(
                bottom: 16,
                right: 16,
                child: Container(
                  width: 220,
                  height: 140,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
                    boxShadow: const [
                      BoxShadow(color: Colors.black54, blurRadius: 12),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      if (widget.isCameraInitialized && widget.cameraController != null)
                        CameraPreview(widget.cameraController!)
                      else
                        const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.videocam_off_outlined, color: Colors.white38, size: 24),
                              SizedBox(height: 4),
                              Text(
                                'Cámara Proyección PiP',
                                style: TextStyle(color: Colors.white54, fontSize: 10),
                              ),
                            ],
                          ),
                        ),

                      // PiP Badge Header
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFF59E0B), width: 0.8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.circle, color: Colors.redAccent, size: 8),
                              SizedBox(width: 4),
                              Text(
                                'PROYECCIÓN REAL (PiP)',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTileForObject(SceneObject obj, Size size) {
    if (obj.vertices.length < 3) return const SizedBox.shrink();

    return ClipPath(
      clipper: _PolygonClipper(obj.vertices),
      child: RegionContentTile(
        object: obj,
        size: size,
        muted: false,
      ),
    );
  }

  Widget _buildVertexHandle({
    required SceneObject object,
    required int vertexIndex,
    required double canvasWidth,
    required double canvasHeight,
  }) {
    final v = object.vertices[vertexIndex];
    final isSelectedObj = object.id == widget.selectedId;
    final isHovered = _hoveredObjectId == object.id && _hoveredVertexIndex == vertexIndex;

    final px = (v.x * canvasWidth).clamp(0.0, canvasWidth);
    final py = (v.y * canvasHeight).clamp(0.0, canvasHeight);

    final nodeColor = (isHovered || isSelectedObj)
        ? const Color(0xFFF59E0B) // Amber HeavyM Orange
        : Colors.white;

    return Positioned(
      left: px - 10,
      top: py - 10,
      child: GestureDetector(
        onPanUpdate: (details) {
          widget.onSelectObject(object.id);
          var newX = (v.x + details.delta.dx / canvasWidth).clamp(0.0, 1.0);
          var newY = (v.y + details.delta.dy / canvasHeight).clamp(0.0, 1.0);

          if (widget.snapToGrid) {
            newX = (newX * 20).round() / 20;
            newY = (newY * 20).round() / 20;
          }

          widget.onVertexUpdated(object.id, vertexIndex, Point2D(newX, newY));
        },
        child: MouseRegion(
          onEnter: (_) => setState(() {
            _hoveredObjectId = object.id;
            _hoveredVertexIndex = vertexIndex;
          }),
          onExit: (_) => setState(() {
            _hoveredObjectId = null;
            _hoveredVertexIndex = null;
          }),
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: nodeColor,
              border: Border.all(color: Colors.black, width: 2),
              boxShadow: [
                BoxShadow(
                  color: nodeColor.withValues(alpha: 0.6),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PolygonClipper extends CustomClipper<Path> {
  _PolygonClipper(this.vertices);

  final List<Point2D> vertices;

  @override
  Path getClip(Size size) {
    final path = Path();
    if (vertices.isEmpty) return path;

    path.moveTo(vertices[0].x * size.width, vertices[0].y * size.height);
    for (var i = 1; i < vertices.length; i++) {
      path.lineTo(vertices[i].x * size.width, vertices[i].y * size.height);
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _PolygonClipper oldClipper) => true;
}

class _PolygonFacePainter extends CustomPainter {
  _PolygonFacePainter({
    required this.object,
    required this.isSelected,
  });

  final SceneObject object;
  final bool isSelected;

  @override
  void paint(Canvas canvas, Size size) {
    if (object.vertices.length < 3) return;

    final path = Path()
      ..moveTo(
        object.vertices[0].x * size.width,
        object.vertices[0].y * size.height,
      );

    for (var i = 1; i < object.vertices.length; i++) {
      path.lineTo(
        object.vertices[i].x * size.width,
        object.vertices[i].y * size.height,
      );
    }
    path.close();

    // Polygon wireframe border line
    final borderPaint = Paint()
      ..color = isSelected ? const Color(0xFFF59E0B) : Colors.white54
      ..strokeWidth = isSelected ? 2.5 : 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _PolygonFacePainter oldDelegate) => true;
}

class _GridPainterWidget extends StatelessWidget {
  const _GridPainterWidget();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GridCustomPainter(),
    );
  }
}

class _GridCustomPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1;

    final step = 40.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
