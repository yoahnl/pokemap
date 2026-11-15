part of 'scene_graph_canvas.dart';

final class _StepMenu {
  const _StepMenu({required this.screen, required this.world, this.from});

  final Offset screen;
  final SceneGraphPoint world;
  final SceneGraphExit? from;
}

extension _SceneGraphCanvasEdits on SceneGraphCanvasState {
  SceneStepIds get _ids {
    final graph = widget.scene.graph;
    final taken = {
      for (final node in graph.nodes) node.id,
      for (final edge in graph.edges) edge.id,
    };
    String next(String prefix) {
      var index = taken.length;
      while (!taken.add('${prefix}_$index')) {
        index++;
      }
      return '${prefix}_$index';
    }

    return SceneStepIds(node: () => next('step'), edge: () => next('link'));
  }

  void _apply(SceneGraphEditResult result, {Set<String>? select}) {
    switch (result) {
      case SceneGraphEdited(:final scene, :final createdNodeId):
        final accepted = widget.onChanged?.call(scene) ?? false;
        _mutate(() {
          if (!accepted) _moved = const {};
          if (accepted && createdNodeId != null) _selected = {createdNodeId};
          if (accepted && select != null) _selected = select;
        });
      case SceneGraphEditRefused(:final reason):
        _mutate(() => _moved = const {});
        ScaffoldMessenger.maybeOf(context)
          ?..removeCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              key: const ValueKey('scene-graph-refused'),
              content: Text(context.l10n.sceneGraphRefused(reason.name)),
            ),
          );
    }
  }

  void _unlink(SceneGraphExit exit) => _apply(
    removeSceneGraphItems(
      widget.scene,
      edgeIds: {
        for (final edge in widget.scene.graph.edges)
          if (edge.fromNodeId == exit.nodeId && edge.fromPortId == exit.portId)
            edge.id,
      },
    ),
  );

  void _dropWire(SceneGraphExit from, Offset screen) {
    final camera = _camera!.value;
    final target = sceneGraphCardAt(_view, camera.toWorld(screen));
    if (target == null) {
      _openMenu(screen, from);
      return;
    }
    if (target.id == from.nodeId) return;
    _apply(
      connectSceneGraphExit(
        widget.scene,
        from: from,
        toNodeId: target.id,
        ids: _ids,
      ),
    );
  }

  void _commitMove() =>
      _apply(moveSceneGraphSteps(widget.scene, Map.of(_moved)));

  void _removeSelection() => _apply(
    removeSceneGraphItems(widget.scene, nodeIds: _selected),
    select: {},
  );

  void _openMenu(Offset screen, SceneGraphExit? from) {
    final world = _camera!.value.toWorld(screen);
    _mutate(
      () =>
          _menu = _StepMenu(screen: screen, world: _snapped(world), from: from),
    );
  }

  void _closeMenu() {
    _mutate(() => _menu = null);
    _focus.requestFocus();
  }

  void _addFromMenu(SceneStepTemplate template) {
    final menu = _menu;
    _closeMenu();
    if (menu == null) return;
    _apply(
      addSceneGraphStep(
        widget.scene,
        kind: template.kind,
        payload: template.payload,
        at: menu.world,
        from: menu.from,
        ids: _ids,
      ),
    );
  }
}
