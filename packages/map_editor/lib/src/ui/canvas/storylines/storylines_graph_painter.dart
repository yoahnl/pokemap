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
    required this.sideQuestAvailabilityColor,
  });

  final List<StorylineGraphPaintEdge> edges;
  final Color gridColor;
  final Color authorOrderColor;
  final Color containsColor;
  final Color sideQuestAvailabilityColor;

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
    final color = switch (edge.kind) {
      StorylineGraphEdgeKind.authorOrder => authorOrderColor,
      StorylineGraphEdgeKind.sideQuestAttachment => sideQuestAvailabilityColor,
      StorylineGraphEdgeKind.contains => containsColor,
    };
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = switch (edge.kind) {
        StorylineGraphEdgeKind.authorOrder => 2.4,
        StorylineGraphEdgeKind.sideQuestAttachment => 1.8,
        StorylineGraphEdgeKind.contains => 1.4,
      };
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
    switch (edge.kind) {
      case StorylineGraphEdgeKind.sideQuestAttachment:
        _paintDashedPath(canvas, path, paint);
        _paintArrowHead(canvas, edge, color, size: 6);
      case StorylineGraphEdgeKind.authorOrder:
        canvas.drawPath(path, paint);
        _paintArrowHead(canvas, edge, color);
      case StorylineGraphEdgeKind.contains:
        canvas.drawPath(path, paint);
    }
  }

  void _paintDashedPath(Canvas canvas, Path path, Paint paint) {
    const dash = 8.0;
    const gap = 7.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + dash, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + gap;
      }
    }
  }

  void _paintArrowHead(
    Canvas canvas,
    StorylineGraphPaintEdge edge,
    Color color, {
    double size = 8,
  }) {
    final angle =
        math.atan2(edge.to.dy - edge.from.dy, edge.to.dx - edge.from.dx);
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
        containsColor != oldDelegate.containsColor ||
        sideQuestAvailabilityColor != oldDelegate.sideQuestAvailabilityColor;
  }
}
