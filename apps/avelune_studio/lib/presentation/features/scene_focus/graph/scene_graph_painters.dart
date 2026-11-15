import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:avelune_studio/features/scenes/application/graph/scene_graph_view.dart';
import 'package:avelune_studio/presentation/features/scene_focus/graph/scene_graph_camera.dart';

final class SceneGraphWireColors {
  const SceneGraphWireColors({
    required this.idle,
    required this.path,
    required this.loop,
    required this.undeclared,
  });

  final Color idle, path, loop, undeclared;
}

class SceneGraphGridPainter extends CustomPainter {
  SceneGraphGridPainter({
    required this.camera,
    required this.minor,
    required this.major,
  });

  static const double spacing = 16;
  static const int majorEvery = 8;

  final SceneGraphCamera camera;
  final Color minor, major;

  @override
  void paint(Canvas canvas, Size size) {
    final step = spacing * camera.scale;
    final paint = Paint()..strokeWidth = 1;
    if (step >= 6) _lines(canvas, size, step, paint..color = minor);
    _lines(canvas, size, step * majorEvery, paint..color = major);
  }

  void _lines(Canvas canvas, Size size, double step, Paint paint) {
    final startX = camera.pan.dx % step;
    final startY = camera.pan.dy % step;
    for (var x = startX; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = startY; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(SceneGraphGridPainter old) =>
      old.camera != camera || old.minor != minor || old.major != major;
}

class SceneGraphWirePainter extends CustomPainter {
  SceneGraphWirePainter({
    required this.view,
    required this.origin,
    required this.pathEdgeIds,
    required this.colors,
  });

  final SceneGraphView view;
  final Offset origin;
  final Set<String> pathEdgeIds;
  final SceneGraphWireColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(-origin.dx, -origin.dy);
    final cards = {for (final card in view.cards) card.id: card};
    final ordered = [
      ...view.wires.where((wire) => !pathEdgeIds.contains(wire.id)),
      ...view.wires.where((wire) => pathEdgeIds.contains(wire.id)),
    ];
    for (final wire in ordered) {
      final from = cards[wire.edge.fromNodeId];
      final to = cards[wire.edge.toNodeId];
      if (from == null || to == null) continue;
      final onPath = pathEdgeIds.contains(wire.id);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = onPath ? 3 : 2
        ..color = switch (wire) {
          _ when onPath => colors.path,
          SceneGraphWire(loop: true) => colors.loop,
          SceneGraphWire(declared: false) => colors.undeclared,
          _ => colors.idle,
        };
      canvas.drawPath(
        sceneGraphWirePath(
          sceneGraphOutputAnchor(from, wire.edge.fromPortId),
          sceneGraphInputAnchor(to),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(SceneGraphWirePainter old) =>
      old.view != view ||
      old.origin != origin ||
      old.colors != colors ||
      !_sameIds(old.pathEdgeIds, pathEdgeIds);
}

Path sceneGraphWirePath(Offset from, Offset to) {
  final reach = math.max(48.0, (to.dx - from.dx).abs() / 2);
  return Path()
    ..moveTo(from.dx, from.dy)
    ..cubicTo(from.dx + reach, from.dy, to.dx - reach, to.dy, to.dx, to.dy);
}

class SceneGraphDraftWirePainter extends CustomPainter {
  SceneGraphDraftWirePainter({
    required this.from,
    required this.to,
    required this.color,
  });

  final Offset from, to;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) => canvas.drawPath(
    sceneGraphWirePath(from, to),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = color,
  );

  @override
  bool shouldRepaint(SceneGraphDraftWirePainter old) =>
      old.from != from || old.to != to || old.color != color;
}

class SceneGraphMarqueePainter extends CustomPainter {
  SceneGraphMarqueePainter({required this.rect, required this.color});

  final Rect rect;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..drawRect(rect, Paint()..color = color.withValues(alpha: .12))
      ..drawRect(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = color,
      );
  }

  @override
  bool shouldRepaint(SceneGraphMarqueePainter old) =>
      old.rect != rect || old.color != color;
}

bool _sameIds(Set<String> a, Set<String> b) =>
    a.length == b.length && a.containsAll(b);
