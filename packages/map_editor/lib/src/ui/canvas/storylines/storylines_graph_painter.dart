import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'storylines_graph_model.dart';

final class StorylineGraphPaintEdge {
  const StorylineGraphPaintEdge({
    required this.from,
    required this.to,
    required this.kind,
  });

  final Offset from;
  final Offset to;
  final StorylineGraphEdgeKind kind;
}

class StorylinesGraphPainter extends CustomPainter {
  const StorylinesGraphPainter({
    required this.edges,
    required this.gridColor,
    required this.authorOrderColor,
    required this.containsColor,
  });

  final List<StorylineGraphPaintEdge> edges;
  final Color gridColor;
  final Color authorOrderColor;
  final Color containsColor;

  @override
  void paint(Canvas canvas, Size size) {
    _paintGrid(canvas, size);
    for (final edge in edges) {
      _paintEdge(canvas, edge);
    }
  }

  void _paintGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    const spacing = 28.0;
    for (var x = 0.0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _paintEdge(Canvas canvas, StorylineGraphPaintEdge edge) {
    final color = edge.kind == StorylineGraphEdgeKind.authorOrder
        ? authorOrderColor
        : containsColor;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth =
          edge.kind == StorylineGraphEdgeKind.authorOrder ? 2.4 : 1.4;
    final controlOffset =
        math.max((edge.to.dx - edge.from.dx).abs() * 0.42, 48);
    final path = Path()
      ..moveTo(edge.from.dx, edge.from.dy)
      ..cubicTo(
        edge.from.dx + controlOffset,
        edge.from.dy,
        edge.to.dx - controlOffset,
        edge.to.dy,
        edge.to.dx,
        edge.to.dy,
      );
    canvas.drawPath(path, paint);
    if (edge.kind == StorylineGraphEdgeKind.authorOrder) {
      _paintArrowHead(canvas, edge, color);
    }
  }

  void _paintArrowHead(
    Canvas canvas,
    StorylineGraphPaintEdge edge,
    Color color,
  ) {
    final angle =
        math.atan2(edge.to.dy - edge.from.dy, edge.to.dx - edge.from.dx);
    const size = 8.0;
    final left = Offset(
      edge.to.dx - math.cos(angle - math.pi / 7) * size,
      edge.to.dy - math.sin(angle - math.pi / 7) * size,
    );
    final right = Offset(
      edge.to.dx - math.cos(angle + math.pi / 7) * size,
      edge.to.dy - math.sin(angle + math.pi / 7) * size,
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(
      Path()
        ..moveTo(edge.to.dx, edge.to.dy)
        ..lineTo(left.dx, left.dy)
        ..lineTo(right.dx, right.dy)
        ..close(),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant StorylinesGraphPainter oldDelegate) {
    return edges != oldDelegate.edges ||
        gridColor != oldDelegate.gridColor ||
        authorOrderColor != oldDelegate.authorOrderColor ||
        containsColor != oldDelegate.containsColor;
  }
}
