import 'dart:math' as math;
import 'dart:ui';

import 'package:avelune_studio/features/scenes/application/graph/scene_graph_metrics.dart';
import 'package:avelune_studio/features/scenes/application/graph/scene_graph_view.dart';

final class SceneGraphCamera {
  const SceneGraphCamera({this.pan = Offset.zero, this.scale = 1});

  static const double minScale = 0.2;
  static const double maxScale = 2;
  static const double fitMargin = 48;
  static const double readableScale = 0.75;

  final Offset pan;
  final double scale;

  Offset toWorld(Offset screen) => (screen - pan) / scale;

  Offset toScreen(Offset world) => world * scale + pan;

  SceneGraphCamera panBy(Offset delta) =>
      SceneGraphCamera(pan: pan + delta, scale: scale);

  SceneGraphCamera zoomAt(
    Offset focus,
    double factor, {
    double minimum = minScale,
  }) {
    final next = (scale * factor).clamp(minimum, maxScale).toDouble();
    final world = toWorld(focus);
    return SceneGraphCamera(pan: focus - world * next, scale: next);
  }

  static SceneGraphCamera fit(
    Rect bounds,
    Size viewport, {
    double margin = fitMargin,
  }) {
    if (bounds.isEmpty || viewport.isEmpty) return const SceneGraphCamera();
    final available = Size(
      math.max(1, viewport.width - margin * 2),
      math.max(1, viewport.height - margin * 2),
    );
    final scale = math.min(
      1.0,
      math.min(
        available.width / bounds.width,
        available.height / bounds.height,
      ),
    );
    final center = viewport.center(Offset.zero);
    return SceneGraphCamera(pan: center - bounds.center * scale, scale: scale);
  }

  static SceneGraphCamera opening(Rect bounds, Size viewport, Offset start) {
    final fitted = fit(bounds, viewport);
    if (fitted.scale >= readableScale || viewport.isEmpty) return fitted;
    return SceneGraphCamera(
      pan: Offset(
        fitMargin - bounds.left * readableScale,
        viewport.height / 2 - start.dy * readableScale,
      ),
      scale: readableScale,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SceneGraphCamera && other.pan == pan && other.scale == scale;

  @override
  int get hashCode => Object.hash(pan, scale);
}

Rect sceneGraphCardRect(SceneGraphCard card) => Rect.fromLTWH(
  card.position.x,
  card.position.y,
  SceneGraphMetrics.cardWidth,
  card.height,
);

Rect sceneGraphBounds(SceneGraphView view) =>
    view.cards
        .map(sceneGraphCardRect)
        .fold<Rect?>(
          null,
          (bounds, rect) => bounds?.expandToInclude(rect) ?? rect,
        ) ??
    Rect.zero;

SceneGraphCard? sceneGraphCardAt(SceneGraphView view, Offset world) {
  for (final card in view.cards.reversed) {
    if (sceneGraphCardRect(card).contains(world)) return card;
  }
  return null;
}

Set<String> sceneGraphCardsIn(SceneGraphView view, Rect world) => {
  for (final card in view.cards)
    if (sceneGraphCardRect(card).overlaps(world)) card.id,
};

({String nodeId, String portId})? sceneGraphExitAt(
  SceneGraphView view,
  Offset world,
  double radius,
) {
  ({String nodeId, String portId})? nearest;
  var best = radius;
  for (final card in view.cards) {
    for (final port in card.outputs) {
      final distance = (sceneGraphOutputAnchor(card, port.id) - world).distance;
      if (distance <= best) {
        best = distance;
        nearest = (nodeId: card.id, portId: port.id);
      }
    }
  }
  return nearest;
}

Offset sceneGraphOutputAnchor(SceneGraphCard card, String portId) {
  final index = card.outputs.indexWhere((port) => port.id == portId);
  return Offset(
    card.position.x + SceneGraphMetrics.cardWidth,
    card.position.y + SceneGraphMetrics.outputPortY(math.max(0, index)),
  );
}

Offset sceneGraphInputAnchor(SceneGraphCard card) =>
    Offset(card.position.x, card.position.y + SceneGraphMetrics.inputPortY);
