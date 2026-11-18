part of 'scene_graph_canvas.dart';

sealed class _GraphMenu {
  const _GraphMenu(this.screen);

  final Offset screen;
}

final class _StepMenu extends _GraphMenu {
  const _StepMenu(super.screen, this.world, this.from);

  final SceneGraphPoint world;
  final SceneGraphExit? from;
}

final class _CardMenu extends _GraphMenu {
  const _CardMenu(super.screen);
}

final class _PortMenu extends _GraphMenu {
  const _PortMenu(super.screen, this.nodeId, {this.portId});

  final String nodeId;
  final String? portId;
}

typedef _MenuAction = ({String id, String label, VoidCallback? run});

extension _SceneGraphCanvasMenus on SceneGraphCanvasState {
  Iterable<SceneEdge> _portEdges(String nodeId, String? portId) =>
      widget.scene.graph.edges.where(
        (edge) => portId == null
            ? edge.toNodeId == nodeId
            : edge.fromNodeId == nodeId && edge.fromPortId == portId,
      );

  void _openContextMenu(Offset screen, SceneGraphCamera camera) {
    final world = camera.toWorld(screen);
    final radius = SceneGraphCanvasState._portReach / camera.scale;
    final exit = sceneGraphExitAt(_view, world, radius);
    final input = exit == null
        ? _view.cards.reversed
              .where(
                (card) =>
                    card.acceptsInput &&
                    (sceneGraphInputAnchor(card) - world).distance <= radius,
              )
              .firstOrNull
        : null;
    final id = exit?.nodeId ?? input?.id ?? sceneGraphCardAt(_view, world)?.id;
    if (id == null) {
      _openStepMenu(screen);
      return;
    }
    _mutate(() {
      if (!_selected.contains(id)) _selected = {id};
      _menu = exit != null || input != null
          ? _PortMenu(screen, id, portId: exit?.portId)
          : _CardMenu(screen);
    });
  }

  void _openStepMenu(Offset screen, {SceneGraphExit? from}) {
    final world = _camera!.value.toWorld(screen);
    _mutate(() => _menu = _StepMenu(screen, _snapped(world), from));
  }

  void _closeMenu() {
    _mutate(() => _menu = null);
    _focus.requestFocus();
  }

  void _addFromMenu(SceneStepTemplate template) {
    final menu = _menu;
    _closeMenu();
    if (menu is! _StepMenu) return;
    final from = menu.from;
    if (from != null && _portEdges(from.nodeId, from.portId).isNotEmpty) return;
    _insert(template, at: menu.world, from: from);
  }

  List<_MenuAction> _cardActions() {
    final l10n = context.l10n;
    final graph = widget.scene.graph;
    final removable = _selected.any((id) => id != graph.startNodeId);
    final links = {
      for (final edge in graph.edges)
        if (_selected.contains(edge.fromNodeId) ||
            _selected.contains(edge.toNodeId))
          edge.id,
    };
    return [
      (
        id: 'copy',
        label: l10n.sceneGraphMenuAction('copy'),
        run: removable ? _copy : null,
      ),
      (
        id: 'cut',
        label: l10n.sceneGraphMenuAction('cut'),
        run: removable ? _cut : null,
      ),
      (
        id: 'duplicate',
        label: l10n.sceneGraphMenuAction('duplicate'),
        run: removable ? _duplicate : null,
      ),
      (
        id: 'delete',
        label: l10n.sceneGraphMenuAction('delete'),
        run: removable && !_selected.contains(graph.startNodeId)
            ? _removeSelection
            : null,
      ),
      (
        id: 'break-all',
        label: l10n.sceneGraphMenuAction('breakAll'),
        run: links.isEmpty ? null : () => _unlinkEdges(links),
      ),
    ];
  }

  List<_MenuAction> _portActions(_PortMenu menu) {
    final l10n = context.l10n;
    final edges = _portEdges(menu.nodeId, menu.portId).toList();
    final port = menu.portId;
    if (edges.isEmpty) {
      return [
        (
          id: 'no-links',
          label: l10n.sceneGraphMenuAction('noLinks'),
          run: null,
        ),
        if (port != null)
          (
            id: 'add',
            label: l10n.sceneGraphSearch,
            run: () => _openStepMenu(
              menu.screen,
              from: (nodeId: menu.nodeId, portId: port),
            ),
          ),
      ];
    }
    return [
      (
        id: 'break-all',
        label: l10n.sceneGraphMenuAction('breakAll'),
        run: () => _unlinkEdges({for (final edge in edges) edge.id}),
      ),
      for (final edge in edges)
        (
          id: 'break-${edge.id}',
          label: l10n.sceneGraphMenuBreakWith(
            port == null
                ? _incomingLinkLabel(edge)
                : sceneGraphNodeTitle(l10n, _view.card(edge.toNodeId)!.node),
          ),
          run: () => _unlinkEdges({edge.id}),
        ),
    ];
  }

  String _incomingLinkLabel(SceneEdge edge) {
    final l10n = context.l10n;
    final source = _view.card(edge.fromNodeId)!.node;
    final dialogueId = switch (source.payload) {
      SceneYarnDialoguePayload(:final dialogueId) => dialogueId,
      _ => null,
    };
    return l10n.sceneFocusPathStepDetail(
      sceneGraphNodeTitle(l10n, source),
      sceneGraphPortLabel(
        l10n,
        edge.fromPortId,
        widget.dialogues[dialogueId],
        choiceLabels: widget.choiceLabels[dialogueId] ?? const {},
      ),
    );
  }

  Widget _buildMenu(_GraphMenu menu) {
    final actions = switch (menu) {
      _StepMenu() => null,
      _CardMenu() => _cardActions(),
      _PortMenu() => _portActions(menu),
    };
    final height = math.min(
      _viewport.height,
      actions == null ? 380.0 : math.min(380.0, 24.0 + 46.0 * actions.length),
    );
    return Positioned(
      left: menu.screen.dx
          .clamp(0, math.max(0, _viewport.width - SceneGraphStepMenu.width))
          .toDouble(),
      top: menu.screen.dy
          .clamp(0, math.max(0, _viewport.height - height))
          .toDouble(),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: height),
        child: actions == null
            ? SceneGraphStepMenu(
                choices: sceneGraphStepChoices(
                  context,
                  widget.project,
                  widget.map,
                ),
                onChosen: _addFromMenu,
                onDismiss: _closeMenu,
              )
            : _buildContextActions(menu, actions),
      ),
    );
  }

  Widget _buildContextActions(
    _GraphMenu menu,
    List<_MenuAction> actions,
  ) => CallbackShortcuts(
    bindings: {const SingleActivator(LogicalKeyboardKey.escape): _closeMenu},
    child: Focus(
      autofocus: true,
      child: Material(
        key: ValueKey(
          menu is _CardMenu ? 'scene-graph-card-menu' : 'scene-graph-port-menu',
        ),
        elevation: 8,
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(StudioMetrics.panelRadius),
        child: SizedBox(
          width: SceneGraphStepMenu.width,
          child: ListView(
            padding: const EdgeInsets.all(StudioSpacing.m),
            shrinkWrap: true,
            children: [
              for (final action in actions)
                StudioChoice(
                  key: ValueKey('scene-graph-menu-${action.id}'),
                  label: action.label,
                  dense: true,
                  maxLines: 2,
                  onTap: action.run == null
                      ? null
                      : () {
                          _closeMenu();
                          action.run!();
                        },
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
