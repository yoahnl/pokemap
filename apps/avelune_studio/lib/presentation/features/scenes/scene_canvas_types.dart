import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

class SceneBlockDragData {
  const SceneBlockDragData({
    required this.kind,
    required this.label,
    this.payload,
  });
  final SceneNodeKind kind;
  final String label;
  final SceneNodePayload? payload;
}

typedef SceneCanvasAdd =
    void Function(
      SceneBlockDragData block,
      Offset position, {
      String? fromNodeId,
      String? fromPortId,
    });

class SceneGraphViewport extends ChangeNotifier {
  SceneGraphViewport({this.pan = Offset.zero, this.zoom = 1});
  Offset pan;
  double zoom;
  Size size = Size.zero;
  bool initialized = false;
  double gestureStartZoom = 1;
  bool trackpadActive = false;
  Offset _gestureWorld = Offset.zero;
  void startTrackpad(Offset focal) {
    gestureStartZoom = zoom;
    _gestureWorld = localToWorld(focal);
    trackpadActive = true;
  }

  void updateTrackpad(double scale, Offset translation, Offset focal) {
    zoom = (gestureStartZoom * scale).clamp(.3, 2.5);
    pan = focal + translation - _gestureWorld * zoom;
    initialized = true;
    notifyListeners();
  }

  Offset localToWorld(Offset point) => (point - pan) / zoom;
  Offset worldToLocal(Offset point) => point * zoom + pan;
  Offset get center => localToWorld(size.center(Offset.zero));
  void translate(Offset delta) {
    pan += delta;
    initialized = true;
    notifyListeners();
  }

  void zoomAt(double value, Offset focal) {
    final world = localToWorld(focal);
    zoom = value.clamp(.3, 2.5);
    pan = focal - world * zoom;
    initialized = true;
    notifyListeners();
  }

  void centerOn(Offset world) {
    pan = size.center(Offset.zero) - world * zoom;
    initialized = true;
    notifyListeners();
  }

  void fit(Rect bounds) {
    if (size.isEmpty) return;
    zoom = math
        .min(
          (size.width - 80) / bounds.width,
          (size.height - 80) / bounds.height,
        )
        .clamp(.3, 1.1);
    centerOn(bounds.center);
  }
}

class SceneCanvasGeometry {
  SceneCanvasGeometry(this.scene) {
    nodes = {for (final node in scene.graph.nodes) node.id: node};
    ports = {
      for (final node in scene.graph.nodes)
        node.id: authorableSceneOutputPortsForNodeInGraph(node, scene.graph),
    };
    final layouts = {
      for (final layout in scene.layout.nodeLayouts)
        layout.nodeId: Offset(layout.x, layout.y),
    };
    positions = {
      for (var i = 0; i < scene.graph.nodes.length; i++)
        scene.graph.nodes[i].id:
            layouts[scene.graph.nodes[i].id] ??
            Offset(40 + (i % 4) * 280, 40 + (i ~/ 4) * 230),
    };
    occupied = {
      for (final edge in scene.graph.edges)
        '${edge.fromNodeId}:${edge.fromPortId}',
    };
  }
  final SceneAsset scene;
  late final Map<String, SceneNode> nodes;
  late final Map<String, List<SceneAuthorableOutputPort>> ports;
  late final Map<String, Offset> positions;
  late final Set<String> occupied;
  Size nodeSize(String id) => switch (nodes[id]?.kind) {
    SceneNodeKind.start || SceneNodeKind.end => const Size(128, 128),
    _ => Size(208, math.max(176, 120 + (ports[id]?.length ?? 0) * 26)),
  };
  Rect nodeRect(String id, Map<String, Offset> overrides) =>
      (overrides[id] ?? positions[id]!) & nodeSize(id);
  Offset input(String id, Map<String, Offset> overrides) =>
      nodeRect(id, overrides).centerLeft;
  Offset output(String id, String port, Map<String, Offset> overrides) {
    final rect = nodeRect(id, overrides);
    final list = ports[id] ?? [];
    final index = list.indexWhere((p) => p.id == port);
    return Offset(
      rect.right,
      rect.bottom - 18 - (list.length - 1 - index) * 26,
    );
  }

  Rect bounds(Map<String, Offset> overrides) {
    if (nodes.isEmpty) return const Rect.fromLTWH(0, 0, 400, 300);
    return nodes.keys
        .map((id) => nodeRect(id, overrides))
        .reduce((a, b) => a.expandToInclude(b));
  }

  String? targetAt(
    Offset local,
    SceneGraphViewport view,
    Map<String, Offset> overrides,
    String source,
  ) {
    for (final node in nodes.values) {
      if (node.id == source || node.kind == SceneNodeKind.start) continue;
      if ((view.worldToLocal(input(node.id, overrides)) - local).distance <=
          24) {
        return node.id;
      }
    }
    return null;
  }
}

String scenePortLabel(String id) => switch (id) {
  'true' => 'Oui',
  'false' => 'Non',
  'completed' => 'Continuer',
  'victory' => 'Victoire',
  'defeat' => 'Défaite',
  'default' => 'Sinon',
  'error' => 'Erreur',
  _ => id,
};

String sceneKindLabel(SceneNodeKind kind) => switch (kind) {
  SceneNodeKind.start => 'Début',
  SceneNodeKind.end => 'Fin',
  SceneNodeKind.yarnDialogue => 'Dialogue',
  SceneNodeKind.condition => 'Condition',
  SceneNodeKind.action => 'Action',
  SceneNodeKind.battle => 'Combat',
  SceneNodeKind.cinematic => 'Cinématique',
  SceneNodeKind.presentationCinematic => 'Présentation',
  SceneNodeKind.branchByOutcome => 'Branchement',
  SceneNodeKind.merge => 'Convergence',
};

String sceneBlockLabel(SceneNodeKind kind) => sceneKindLabel(kind);
