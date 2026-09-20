import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_canvas_types.dart';

Path sceneWirePath(Offset start, Offset end) {
  final bend = math.max(48.0, (end.dx - start.dx).abs() * .5);
  return Path()
    ..moveTo(start.dx, start.dy)
    ..cubicTo(start.dx + bend, start.dy, end.dx - bend, end.dy, end.dx, end.dy);
}

String? sceneEdgeAt(
  SceneCanvasGeometry geometry,
  SceneGraphViewport view,
  Map<String, Offset> positions,
  Offset pointer,
) {
  for (final edge in geometry.scene.graph.edges.reversed) {
    if (!geometry.nodes.containsKey(edge.fromNodeId) ||
        !geometry.nodes.containsKey(edge.toNodeId)) {
      continue;
    }
    final path = sceneWirePath(
      view.worldToLocal(
        geometry.output(edge.fromNodeId, edge.fromPortId, positions),
      ),
      view.worldToLocal(geometry.input(edge.toNodeId, positions)),
    );
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d <= metric.length; d += 6) {
        final tangent = metric.getTangentForOffset(d);
        if (tangent != null && (tangent.position - pointer).distance <= 10) {
          return edge.id;
        }
      }
    }
  }
  return null;
}

class SceneCanvasPainter extends CustomPainter {
  SceneCanvasPainter({
    required this.geometry,
    required this.viewport,
    required this.positions,
    required this.gridColor,
    required this.wireColor,
    required this.selectionColor,
    required this.successColor,
    required this.falseColor,
    this.selectedEdgeId,
    this.highlighted = const {},
    this.previewStart,
    this.previewEnd,
  });
  final SceneCanvasGeometry geometry;
  final SceneGraphViewport viewport;
  final Map<String, Offset> positions;
  final Color gridColor, wireColor, selectionColor, successColor, falseColor;
  final String? selectedEdgeId;
  final Set<String> highlighted;
  final Offset? previewStart, previewEnd;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = .6;
    final spacing = 24 * viewport.zoom;
    for (var x = viewport.pan.dx % spacing; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = viewport.pan.dy % spacing; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    for (final edge in geometry.scene.graph.edges) {
      if (!geometry.nodes.containsKey(edge.fromNodeId) ||
          !geometry.nodes.containsKey(edge.toNodeId)) {
        continue;
      }
      final color = edge.id == selectedEdgeId
          ? selectionColor
          : highlighted.contains(edge.id)
          ? successColor
          : edge.fromPortId == 'true'
          ? successColor
          : edge.fromPortId == 'false'
          ? falseColor
          : wireColor;
      _wire(
        canvas,
        viewport.worldToLocal(
          geometry.output(edge.fromNodeId, edge.fromPortId, positions),
        ),
        viewport.worldToLocal(geometry.input(edge.toNodeId, positions)),
        color,
        edge.id == selectedEdgeId ? 3 : 1.8,
      );
    }
    if (previewStart != null && previewEnd != null) {
      _wire(canvas, previewStart!, previewEnd!, selectionColor, 2.5);
    }
  }

  void _wire(
    Canvas canvas,
    Offset start,
    Offset end,
    Color color,
    double width,
  ) {
    canvas.drawPath(
      sceneWirePath(start, end),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width,
    );
    final arrow = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(end.dx - 8, end.dy - 5)
      ..lineTo(end.dx - 8, end.dy + 5)
      ..close();
    canvas.drawPath(arrow, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant SceneCanvasPainter oldDelegate) => true;
}
