part of 'map_workspace_screen.dart';

extension _WorkspaceStoryBinding on _MapWorkspaceScreenState {
  void _saveWorkspaceDocument() {
    if (_space == WorkspaceSpace.presentation) {
      unawaited(_presentations?.save());
      return;
    }
    if (_space == WorkspaceSpace.cinematic) {
      FocusManager.instance.primaryFocus?.unfocus();
      FocusManager.instance.applyFocusChangesIfNeeded();
      unawaited(_cinematics?.save());
      return;
    }
    if (_space == WorkspaceSpace.dialogue) {
      FocusManager.instance.primaryFocus?.unfocus();
      FocusManager.instance.applyFocusChangesIfNeeded();
      unawaited(_dialogues?.save());
      return;
    }
    if (_space == WorkspaceSpace.events) {
      FocusManager.instance.primaryFocus?.unfocus();
      FocusManager.instance.applyFocusChangesIfNeeded();
      unawaited(_events?.saveAll());
      return;
    }
    if (_space == WorkspaceSpace.progression) {
      FocusManager.instance.primaryFocus?.unfocus();
      FocusManager.instance.applyFocusChangesIfNeeded();
      unawaited(_stories?.saveAll());
      return;
    }
    if (_space == WorkspaceSpace.scene) {
      unawaited(_scenes?.save());
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    FocusManager.instance.applyFocusChangesIfNeeded();
    final document = _controller.active;
    if (document != null) {
      if (document.weatherVisuals?.dirty == true) {
        unawaited(_controller.save(document));
        return;
      }
      unawaited(
        _narrative?.save(document: document) ?? _controller.save(document),
      );
    }
  }

  void _openScenes() {
    _sceneOrigin = WorkspaceReturn.story;
    if (_scenes?.active == null) _sceneViews.sceneLibrary = true;
    _show(WorkspaceSpace.scene);
  }

  void _openNarrativeMap(String mapId) {
    unawaited(_openNarrativeMapAsync(mapId));
  }

  Future<void> _openNarrativeMapAsync(String mapId) async {
    final project = _controller.project;
    final entry = project?.maps.where((item) => item.id == mapId).firstOrNull;
    if (entry == null) return;
    final request = ++_navigationRequest;
    bool current() =>
        mounted &&
        request == _navigationRequest &&
        identical(_controller.project, project) &&
        _space == WorkspaceSpace.story;
    await _controller.activate(entry, isCurrent: current);
    if (!current()) return;
    if (_controller.active?.base.mapId != mapId) {
      _storyViewState.notice = _controller.error ?? 'Carte indisponible.';
      _changed();
      return;
    }
    _gestureGeneration++;
    _view?.pendingMove = null;
    _view?.tool = StudioMapTool.select;
    _show(WorkspaceSpace.map);
    _toolChanged();
  }

  Future<void> _editInteraction(MapEntity entity) async {
    if (_controller.active?.current.spatialScene != null) {
      final dialogue = entity.npc?.dialogue;
      if (dialogue == null) {
        _dialogueOrigin = WorkspaceSpace.map;
        _show(WorkspaceSpace.dialogue);
      } else {
        _openMapDialogue(dialogue.dialogueId);
      }
      return;
    }
    if (_events != null && _controller.active != null) {
      await _openEventSource(
        NarrativeEventSourceRef.entityInteract(
          _controller.active!.current.id,
          entity.id,
        ),
      );
      return;
    }
    final document = _controller.active;
    final narrative = _narrative;
    if (narrative == null || document == null) return;
    final request = ++_navigationRequest;
    await narrative.openNpc(document, entity);
    if (!mounted ||
        request != _navigationRequest ||
        _controller.active != document ||
        _space != WorkspaceSpace.map) {
      return;
    }
    if (narrative.active != null) {
      _interactionOrigin = WorkspaceSpace.map;
      _show(WorkspaceSpace.interaction);
    } else if (narrative.error case final error?) {
      _interactionNotice = ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _zone(MapRect area) async {
    final narrative = _narrative;
    if (narrative == null) return;
    final request = ++_navigationRequest;
    await openNarrativeZone(narrative, area);
    if (!mounted || request != _navigationRequest || narrative.active == null) {
      return;
    }
    _interactionOrigin = WorkspaceSpace.map;
    _show(WorkspaceSpace.interaction);
  }

  Future<String?> _openStoryInteraction(
    String id, {
    WorkspaceSpace from = WorkspaceSpace.story,
  }) => _navigation.openStoryInteraction(id, from: from);

  Future<String?> _locateStoryInteraction(String id) =>
      _navigation.locateStoryInteraction(id);

  Future<void> _createStoryInteraction() async {
    final project = _controller.project;
    if (project == null || project.maps.isEmpty) {
      _interactionNotice = ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucune carte disponible pour placer une interaction.'),
        ),
      );
      return;
    }
    final request = ++_navigationRequest;
    bool current() =>
        mounted &&
        request == _navigationRequest &&
        _space == WorkspaceSpace.story &&
        widget.home?.visible != true;
    if (_controller.active == null) {
      await _controller.activate(project.maps.first, isCurrent: current);
    }
    if (!mounted || !current() || _controller.active == null) return;
    _view?.tool = StudioMapTool.select;
    _openMap();
    _toolChanged();
    _interactionNotice = ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Choisissez un personnage sur la carte ou tracez une zone avec l’outil Zone.',
        ),
      ),
    );
  }

  void _selectMapEntity(EditableMapDocument document, String entityId) {
    final entity = document.current.entities
        .where((value) => value.id == entityId)
        .firstOrNull;
    final view = _view;
    if (entity == null || view == null) return;
    view.tool = StudioMapTool.select;
    view.select(
      document,
      entity.kind == MapEntityKind.npc
          ? MapSelectionFamily.character
          : MapSelectionFamily.marker,
      entity.id,
    );
    _toolChanged();
  }
}
