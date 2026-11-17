part of 'scene_graph_canvas.dart';

final class _StepMenu {
  const _StepMenu({required this.screen, required this.world, this.from});

  final Offset screen;
  final SceneGraphPoint world;
  final SceneGraphExit? from;
}

extension _SceneGraphCanvasEdits on SceneGraphCanvasState {
  Set<String> get _pathEdgeIds {
    final steps = {
      for (var i = 1; i < widget.pathNodeIds.length; i++)
        (widget.pathNodeIds[i - 1], widget.pathNodeIds[i]),
    };
    return {
      for (final wire in _view.wires)
        if (steps.contains((wire.edge.fromNodeId, wire.edge.toNodeId)) &&
            (widget.pathChoices[wire.edge.fromNodeId] ??
                    wire.edge.fromPortId) ==
                wire.edge.fromPortId)
          wire.id,
    };
  }

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

  bool _apply(SceneGraphEditResult result, {Set<String>? select}) {
    switch (result) {
      case SceneGraphEdited(:final scene, :final createdNodeIds):
        final accepted = widget.onChanged?.call(scene) ?? false;
        _mutate(() {
          if (!accepted) _moved = const {};
          if (accepted && createdNodeIds.isNotEmpty) _selected = createdNodeIds;
          if (accepted && select != null) _selected = select;
        });
        return accepted;
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
        return false;
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

  void _copy() {
    final fragment = copySceneGraphSteps(widget.scene, _selected);
    if (fragment != null) SceneGraphCanvasState._clipboard = fragment;
  }

  void _cut() {
    _copy();
    _apply(
      removeSceneGraphItems(
        widget.scene,
        nodeIds: {..._selected}..remove(widget.scene.graph.startNodeId),
      ),
      select: {},
    );
  }

  void _paste() {
    final fragment = SceneGraphCanvasState._clipboard;
    final camera = _camera?.value;
    if (fragment == null || camera == null) return;
    final pointer = camera.toWorld(_pointer ?? _viewport.center(Offset.zero));
    final floor = camera
        .toWorld(
          Offset(0, _viewport.height - SceneGraphCanvasState._toolbarReserve),
        )
        .dy;
    _apply(
      pasteSceneGraphSteps(
        widget.scene,
        fragment,
        at: _snapped(
          Offset(pointer.dx, math.min(pointer.dy, floor - fragment.height)),
        ),
        ids: _ids,
      ),
    );
  }

  void _duplicate() {
    final fragment = copySceneGraphSteps(widget.scene, _selected);
    if (fragment == null) return;
    final origins = [
      for (final card in _view.cards)
        if (fragment.offsets.containsKey(card.id)) card.position,
    ];
    const shift = SceneGraphCanvasState._duplicateShift;
    _apply(
      pasteSceneGraphSteps(
        widget.scene,
        fragment,
        at: SceneGraphPoint(
          origins.map((p) => p.x).reduce(math.min) + shift,
          origins.map((p) => p.y).reduce(math.min) + shift,
        ),
        ids: _ids,
      ),
    );
  }

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
    _insert(template, at: menu.world, from: menu.from);
  }

  void _addFromPalette(SceneStepTemplate template) {
    if (!_editable || _camera == null) return;
    if (_menu != null) _closeMenu();
    final bounds = sceneGraphBounds(_view);
    final at = _snapped(
      Offset(bounds.right + SceneGraphMetrics.columnGap, bounds.top),
    );
    final accepted = _insert(template, at: at);
    if ((accepted ? _selected.singleOrNull : null) case final id?) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _selected.contains(id)) show(id);
      });
    }
    requestFocus();
  }

  bool _insert(
    SceneStepTemplate template, {
    required SceneGraphPoint at,
    SceneGraphExit? from,
  }) {
    return _apply(
      addSceneGraphStep(
        widget.scene,
        kind: template.kind,
        payload: template.payload,
        at: at,
        from: from,
        ids: _ids,
      ),
    );
  }
}
