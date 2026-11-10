part of 'map_workspace_screen.dart';

extension _WorkspaceContextMenuBinding on _MapWorkspaceScreenState {
  void _releaseStaleMapState() {
    final document = _controller.active;
    releaseStaleMapMoves(_views, document);
    _contextInteraction.releaseIfStale(
      document?.current.id,
      exterior: document?.exteriorDecoration?.editingExterior == true,
    );
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
    _contextInteraction.open(cell, globalPosition, target: target);
  }

  void _closeContextMenu() => _contextInteraction.close();

  Widget? _contextMenuOverlay() {
    final request = _contextInteraction.request;
    if (request == null || _controller.active == null) return null;
    return MapContextMenu(
      request: request,
      onTarget: _contextInteraction.select,
      onCommand: _runContextCommand,
      onDismiss: _closeContextMenu,
    );
  }

  void _runContextCommand(MapContextCommand command) =>
      _contextInteraction.run(command);

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
  ) => _navigation.openExistingStoryZone(
    document,
    trigger,
    choose: _chooseInteraction,
  );

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
