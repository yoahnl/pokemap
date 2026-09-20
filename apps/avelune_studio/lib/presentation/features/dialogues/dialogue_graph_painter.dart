import 'package:flutter/material.dart';
import '../scenes/scene_canvas_painter.dart' show sceneWirePath;
import 'dialogue_graph_geometry.dart';

class DialogueGraphPainter extends CustomPainter {
  DialogueGraphPainter({
    required this.geometry,
    required this.grid,
    required this.wire,
    required this.accent,
    this.pendingStart,
    this.pendingEnd,
  });
  final DialogueGraphGeometry geometry;
  final Color grid, wire, accent;
  final Offset? pendingStart, pendingEnd;
  @override
  void paint(Canvas canvas, Size size) {
    final view = geometry.view.viewport;
    final paint = Paint()
      ..color = grid
      ..strokeWidth = .5;
    final spacing = 24 * view.zoom;
    for (var x = view.pan.dx % spacing; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = view.pan.dy % spacing; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (final edge in geometry.wires) {
      _draw(
        canvas,
        view.worldToLocal(geometry.output(edge.source, edge.row)),
        view.worldToLocal(geometry.input(edge.target)),
        geometry.view.wireId == edge.id ? accent : wire,
      );
    }
    if (pendingStart != null && pendingEnd != null) {
      _draw(canvas, pendingStart!, pendingEnd!, accent);
    }
  }

  void _draw(Canvas canvas, Offset a, Offset b, Color color) {
    canvas.drawPath(
      sceneWirePath(a, b),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawPath(
      Path()
        ..moveTo(b.dx, b.dy)
        ..lineTo(b.dx - 8, b.dy - 5)
        ..lineTo(b.dx - 8, b.dy + 5)
        ..close(),
      Paint()..color = color,
    );
  }

  String? hit(Offset point) {
    final viewport = geometry.view.viewport;
    for (final edge in geometry.wires.reversed) {
      final path = sceneWirePath(
        viewport.worldToLocal(geometry.output(edge.source, edge.row)),
        viewport.worldToLocal(geometry.input(edge.target)),
      );
      for (final metric in path.computeMetrics()) {
        for (var d = 0.0; d <= metric.length; d += 5) {
          if ((metric.getTangentForOffset(d)!.position - point).distance < 10) {
            return edge.id;
          }
        }
      }
    }
    return null;
  }

  @override
  bool shouldRepaint(covariant DialogueGraphPainter oldDelegate) => true;
}
