import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../scenes/scene_canvas_painter.dart' show sceneWirePath;
import 'story_graph_geometry.dart';
import 'story_view_state.dart';

Path storyGraphEdgePath(
  StoryGraphGeometry graph,
  StoryViewState state,
  Map<String, Offset> positions,
  StorylineProgressionEdge edge,
) => sceneWirePath(
  state.viewport.worldToLocal(graph.output(edge.fromNodeId, positions)),
  state.viewport.worldToLocal(graph.input(edge.toNodeId, positions)),
);

StorylineProgressionEdge? storyGraphEdgeAt(
  StoryGraphGeometry graph,
  StoryViewState state,
  Map<String, Offset> positions,
  Offset point,
) {
  for (final edge in graph.edges.reversed) {
    if (!graph.nodes.containsKey(edge.fromNodeId) ||
        !graph.nodes.containsKey(edge.toNodeId)) {
      continue;
    }
    final path = storyGraphEdgePath(graph, state, positions, edge);
    if (!path.getBounds().inflate(12).contains(point)) continue;
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d <= metric.length; d += 6) {
        if ((metric.getTangentForOffset(d)!.position - point).distance <= 10) {
          return edge;
        }
      }
    }
  }
  return null;
}

class StoryGraphPainter extends CustomPainter {
  StoryGraphPainter({
    required this.graph,
    required this.state,
    required this.positions,
    required this.colors,
    required this.labelStyle,
    required this.textScaler,
    this.selectedId,
    this.previewStart,
    this.previewEnd,
  });
  final StoryGraphGeometry graph;
  final StoryViewState state;
  final Map<String, Offset> positions;
  final ColorScheme colors;
  final TextStyle labelStyle;
  final TextScaler textScaler;
  final String? selectedId;
  final Offset? previewStart, previewEnd;
  @override
  void paint(Canvas canvas, Size size) {
    final view = state.viewport;
    final grid = Paint()
      ..color = colors.outlineVariant.withValues(alpha: .25)
      ..strokeWidth = .6;
    final spacing = 24 * view.zoom;
    for (var x = view.pan.dx % spacing; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = view.pan.dy % spacing; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    for (final edge in graph.edges) {
      if (!graph.nodes.containsKey(edge.fromNodeId) ||
          !graph.nodes.containsKey(edge.toNodeId)) {
        continue;
      }
      final path = storyGraphEdgePath(graph, state, positions, edge);
      if (!path.getBounds().inflate(40).overlaps(Offset.zero & size)) continue;
      final order = edge.kind == StorylineProgressionEdgeKind.authorOrder;
      final color = edge.id == selectedId
          ? colors.primary
          : order
          ? colors.outline
          : switch (edge.kind) {
              StorylineProgressionEdgeKind.blocks => colors.error,
              StorylineProgressionEdgeKind.entryCondition ||
              StorylineProgressionEdgeKind.completionCondition =>
                colors.tertiary,
              _ => colors.secondary,
            };
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = edge.id == selectedId ? 3 : 1.5;
      if (order) {
        for (final metric in path.computeMetrics()) {
          for (var d = 0.0; d < metric.length; d += 12) {
            canvas.drawPath(metric.extractPath(d, d + 6), paint);
          }
        }
      } else {
        canvas.drawPath(path, paint);
      }
      final end = view.worldToLocal(graph.input(edge.toNodeId, positions));
      canvas.drawPath(
        Path()
          ..moveTo(end.dx, end.dy)
          ..lineTo(end.dx - 8, end.dy - 4)
          ..lineTo(end.dx - 8, end.dy + 4)
          ..close(),
        Paint()..color = color,
      );
      final metrics = path.computeMetrics().toList();
      if (metrics.isEmpty) continue;
      final center = metrics.first
          .getTangentForOffset(metrics.first.length * .5)!
          .position;
      final text = TextPainter(
        text: TextSpan(
          text: graph.edgeLabel(edge),
          style: labelStyle.copyWith(color: color),
        ),
        textDirection: TextDirection.ltr,
        textScaler: textScaler,
      )..layout(maxWidth: 150);
      final origin = center - Offset(text.width * .5, text.height + 5);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          (origin & text.size).inflate(4),
          const Radius.circular(4),
        ),
        Paint()..color = colors.surface,
      );
      text.paint(canvas, origin);
    }
    if (previewStart != null && previewEnd != null) {
      canvas.drawPath(
        sceneWirePath(previewStart!, previewEnd!),
        Paint()
          ..color = colors.primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant StoryGraphPainter oldDelegate) => true;
}
