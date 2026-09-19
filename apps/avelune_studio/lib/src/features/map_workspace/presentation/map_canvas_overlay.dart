import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

class MapCanvasOverlay extends CustomPainter {
  MapCanvasOverlay({
    required this.map,
    required this.project,
    required this.selected,
    required this.cellWidth,
    required this.cellHeight,
    required this.grid,
    required this.color,
    this.preview,
    this.strokeCells = const [],
  });
  final MapData map;
  final ProjectManifest project;
  final MapPlacedElement? selected;
  final double cellWidth;
  final double cellHeight;
  final bool grid;
  final Color color;
  final GridPos? preview;
  final List<GridPos> strokeCells;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: .18)
      ..strokeWidth = 1;
    if (grid) {
      for (var x = 0; x <= map.size.width; x++) {
        canvas.drawLine(
          Offset(x * cellWidth, 0),
          Offset(x * cellWidth, size.height),
          paint,
        );
      }
      for (var y = 0; y <= map.size.height; y++) {
        canvas.drawLine(
          Offset(0, y * cellHeight),
          Offset(size.width, y * cellHeight),
          paint,
        );
      }
    }
    paint.color = color.withValues(alpha: .4);
    for (final cell in strokeCells) {
      canvas.drawRect(
        Rect.fromLTWH(
          cell.x * cellWidth,
          cell.y * cellHeight,
          cellWidth,
          cellHeight,
        ),
        paint,
      );
    }
    final instance = selected;
    if (instance == null) return;
    final entry = project.elements
        .where((e) => e.id == instance.elementId)
        .firstOrNull;
    final footprint = entry == null
        ? const GridSize(width: 1, height: 1)
        : resolveMapPlacedElementFootprint(
            instance: instance,
            element: entry,
          ).destinationSize;
    final position = preview ?? instance.pos;
    paint
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(
      Rect.fromLTWH(
        position.x * cellWidth,
        position.y * cellHeight,
        footprint.width * cellWidth,
        footprint.height * cellHeight,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant MapCanvasOverlay oldDelegate) => true;
}
