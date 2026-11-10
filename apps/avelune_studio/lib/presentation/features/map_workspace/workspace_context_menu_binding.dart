part of 'map_workspace_screen.dart';

extension _WorkspaceContextMenuBinding on _MapWorkspaceScreenState {
  void _releaseStaleMapState() {
    final document = _controller.active;
    releaseStaleMapMoves(_views, document);
    if (_contextMapId != null &&
        (_contextMapId != document?.current.id ||
            document?.exteriorDecoration?.editingExterior == true)) {
      _contextRequest = null;
      _contextCell = null;
      _contextTarget = null;
      _contextMapId = null;
    }
  }

  MapContextActionContext? _contextAt(GridPos cell) {
    final document = _controller.active;
    final project = _controller.project;
    if (document == null ||
        project == null ||
        document.exteriorDecoration?.editingExterior == true) {
      return null;
    }
    return MapContextActionContext(
      document: document,
      project: project,
      position: cell,
      referenceGuard: _draftReferences.guard,
    );
  }

  /// Keyboard entry point: opens the menu on the current selection, anchored
  /// on its cell.
  void _openContextMenuFromKeyboard() {
    final document = _controller.active;
    final project = _controller.project;
    if (document == null ||
        project == null ||
        document.exteriorDecoration?.editingExterior == true) {
      return;
    }
    final selected = selectedContextTarget(document, project, _view);
    if (selected == null) {
      document.error =
          'Aucun élément visible n’est sélectionné sur cette carte : '
          'sélectionnez-en un pour ouvrir son menu.';
      _changed();
      return;
    }
    _openContextMenu(
      selected.at,
      _view?.globalOfCell?.call(selected.at) ?? const Offset(120, 120),
      target: selected.target,
    );
  }

  void _openContextMenu(
    GridPos cell,
    Offset globalPosition, {
    MapContextTarget? target,
  }) {
    final context = _contextAt(cell);
    if (context == null) return;
    final targets = mapContextTargetsAt(
      context.document,
      context.project,
      cell,
    );
    final selected = target == null
        ? targets.firstOrNull
        : targets.where(target.sameAs).firstOrNull;
    _contextCell = cell;
    _contextMapId = context.document.current.id;
    _contextTarget = selected;
    // Frozen at opening: what the author reads is what the command re-checks.
    _contextRequest = MapContextMenuRequest(
      position: globalPosition,
      targets: targets,
      selected: selected,
      actions: mapContextActionsFor(selected, context),
    );
    _applyContextSelection();
    _changed();
  }

  void _applyContextSelection() {
    final target = _contextTarget;
    final document = _controller.active;
    if (document == null) return;
    if (target == null) {
      _view?.clearSelection(document);
      return;
    }
    _view?.select(document, selectionFamilyOf(target.family), target.id);
  }

  void _closeContextMenu() {
    if (_contextRequest == null) return;
    _contextRequest = null;
    _contextCell = null;
    _contextTarget = null;
    _contextMapId = null;
    _changed();
  }

  Widget? _contextMenuOverlay() {
    final request = _contextRequest;
    final document = _controller.active;
    if (request == null || document == null) return null;
    if (_contextMapId != document.current.id) return null;
    return MapContextMenu(
      request: request,
      onTarget: (target) {
        final context = _contextAt(_contextCell!);
        if (context == null) return;
        _contextTarget = target;
        _contextRequest = MapContextMenuRequest(
          position: request.position,
          targets: request.targets,
          selected: target,
          actions: mapContextActionsFor(target, context),
        );
        _applyContextSelection();
        _changed();
      },
      onCommand: _runContextCommand,
      onDismiss: _closeContextMenu,
    );
  }

  void _runContextCommand(MapContextCommand command) {
    final cell = _contextCell;
    final target = _contextTarget;
    final context = cell == null ? null : _contextAt(cell);
    if (context == null || _contextMapId != context.document.current.id) {
      _closeContextMenu();
      return;
    }
    final document = context.document;
    _closeContextMenu();
    final refusal = MapContextCommandRunner(
      context,
      navigation: _contextNavigation(context),
    ).run(command, target);
    if (refusal != null) document.error = refusal;
    _changed();
  }

  MapContextNavigation _contextNavigation(MapContextActionContext context) =>
      MapContextNavigation(
        showProperties: () {
          _inspector = true;
          _view?.revealInspector = true;
        },
        copyCoordinates: (text) =>
            unawaited(Clipboard.setData(ClipboardData(text: text))),
        openResource: (entry) => _openResources(entry),
        editResource: (entry) => _openResources(entry, true),
        openInteraction: _editInteraction,
        openDestination: (entry) {
          _gestureGeneration++;
          unawaited(_controller.activate(entry));
        },
        openStoryZone: (trigger) =>
            unawaited(_openExistingStoryZone(context.document, trigger)),
        startMove: (target) {
          final view = _view;
          if (view != null) {
            armMapContextMove(
              document: context.document,
              view: view,
              target: target,
              anchor: context.position,
              hint:
                  'Faites glisser ${target.label} vers sa nouvelle case, ou '
                  'appuyez sur Échap pour annuler.',
            );
          }
          _toolChanged();
        },
      );

  Future<void> _openExistingStoryZone(
    EditableMapDocument document,
    MapTrigger trigger,
  ) => _navigation.openExistingStoryZone(document, trigger, choose: _chooseInteraction);

  Future<String?> _chooseInteraction(Map<String, String> found) =>
      showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Quelle interaction ouvrir ?'),
          content: SizedBox(
            width: 360,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final entry in found.entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: StudioButton(
                        label: entry.value.trim().isEmpty
                            ? 'Interaction sans nom'
                            : entry.value,
                        secondary: true,
                        onPressed: () =>
                            Navigator.pop(dialogContext, entry.key),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            StudioButton(
              label: 'Annuler',
              secondary: true,
              onPressed: () => Navigator.pop(dialogContext),
            ),
          ],
        ),
      );
}
