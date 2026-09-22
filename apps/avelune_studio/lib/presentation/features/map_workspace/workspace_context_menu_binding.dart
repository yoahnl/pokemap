part of 'map_workspace_screen.dart';

extension _WorkspaceContextMenuBinding on _MapWorkspaceScreenState {
  MapSelectionFamily _selectionFamily(MapContextFamily family) =>
      switch (family) {
        MapContextFamily.decor => MapSelectionFamily.decor,
        MapContextFamily.character => MapSelectionFamily.character,
        MapContextFamily.marker => MapSelectionFamily.marker,
        MapContextFamily.warp => MapSelectionFamily.warp,
        MapContextFamily.zone => MapSelectionFamily.zone,
        MapContextFamily.trigger => MapSelectionFamily.trigger,
        MapContextFamily.cell => MapSelectionFamily.decor,
      };

  MapContextActionContext? _contextAt(GridPos cell) {
    final document = _controller.active;
    final project = _controller.project;
    if (document == null || project == null) return null;
    return MapContextActionContext(
      document: document,
      project: project,
      position: cell,
      referenceGuard: _draftReferences.guard,
      narrativeGuard: (id) => _narrative?.blocksDeletion(id) == true
          ? 'Une interaction en cours d’écriture utilise ce personnage.'
          : null,
    );
  }

  /// Keyboard entry point: opens the menu on the current selection, anchored
  /// on its cell.
  void _openContextMenuFromKeyboard() {
    final document = _controller.active;
    final target = _view?.target;
    if (document == null) return;
    final cell = document.stackPosition ?? const GridPos(x: 0, y: 0);
    if (target != null && target.mapId != document.current.id) return;
    _openContextMenu(cell, const Offset(120, 120));
  }

  void _openContextMenu(GridPos cell, Offset globalPosition) {
    final context = _contextAt(cell);
    if (context == null) return;
    final targets = mapContextTargetsAt(
      context.document,
      context.project,
      cell,
    );
    final selected = targets.firstOrNull;
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
    _view?.select(document, _selectionFamily(target.family), target.id);
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
          final family = _selectionFamily(target.family);
          _view
            ?..tool = StudioMapTool.select
            ..select(context.document, family, target.id)
            ..pendingMove = MapSelectionTarget(
              mapId: context.document.current.id,
              family: family,
              id: target.id,
            );
          context.document.stackPosition = context.position;
          _movingHint =
              'Faites glisser ${target.label} vers sa nouvelle case, ou '
              'appuyez sur Échap pour annuler.';
          _toolChanged();
        },
      );

  /// Every interaction attached to this exact source: unsaved sessions,
  /// event drafts and saved records alike.
  List<String> _interactionsOnSource(String mapId, String triggerId) {
    final narrative = _narrative;
    if (narrative == null) return const [];
    bool matches(NarrativeEventSourceRef? source) {
      final json = source?.toJson();
      return json != null &&
          json['mapId'] == mapId &&
          json['triggerId'] == triggerId;
    }

    final found = <String>{
      for (final entry in narrative.sessions.entries)
        if (matches(entry.value.current.interaction.source)) entry.key,
      for (final record
          in _events?.records ??
              narrative.project.eventRegistry?.records ??
              const <NarrativeEventRecord>[])
        if (matches(recordSource(record))) record.id,
    };
    return found.toList();
  }

  /// Opens the interaction already attached to a story zone. It never creates
  /// a narrative identity: opening is not authoring.
  Future<void> _openExistingStoryZone(
    EditableMapDocument document,
    MapTrigger trigger,
  ) async {
    final mapId = document.current.id;
    final found = _interactionsOnSource(mapId, trigger.id);
    if (found.isEmpty) {
      document.error =
          'Aucune interaction n’est liée à cette zone. Tracez-la depuis '
          'Histoire pour en écrire une.';
      _changed();
      return;
    }
    if (found.length > 1) {
      document.error =
          '${found.length} interactions utilisent cette zone. Choisissez '
          'celle à ouvrir dans Événements.';
      _openEvents();
      return;
    }
    final request = ++_navigationRequest;
    final problem = await _openStoryInteraction(found.single);
    if (!mounted || request != _navigationRequest) return;
    if (_controller.active?.current.id != mapId) return;
    if (problem != null) {
      document.error = problem;
      _changed();
    }
  }
}
