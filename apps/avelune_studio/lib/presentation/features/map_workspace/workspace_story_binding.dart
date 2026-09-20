part of 'map_workspace_screen.dart';

extension _WorkspaceStoryBinding on _MapWorkspaceScreenState {
  void _initializeScenes() {
    if (widget.scenePort case final port?) {
      _scenes = SceneWorkspaceController(
        _controller,
        port,
        narrative: _narrative,
        changed: _changed,
      );
    }
  }

  void _saveWorkspaceDocument() {
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
    final document = _controller.active;
    if (document != null) {
      unawaited(
        _narrative?.save(document: document) ?? _controller.save(document),
      );
    }
  }

  void _openScenes() {
    _sceneOrigin = WorkspaceSpace.story;
    if (_scenes?.active == null) _sceneViews.sceneLibrary = true;
    _show(WorkspaceSpace.scene);
  }

  Future<String?> _openScene(String sceneId) async {
    final scenes = _scenes;
    if (scenes == null) return 'L’éditeur de scène est indisponible.';
    if (!scenes.open(sceneId)) return scenes.error;
    _sceneOrigin = switch (_space) {
      WorkspaceSpace.progression => WorkspaceSpace.progression,
      WorkspaceSpace.events => WorkspaceSpace.events,
      _ => WorkspaceSpace.story,
    };
    _show(WorkspaceSpace.scene);
    return null;
  }

  Future<void> _editInteraction(MapEntity entity) async {
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
      _interactionNotice = ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
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

  Future<String?> _openStoryInteraction(String id) async {
    if (_events?.record(id) != null) {
      _openEvents(id);
      return null;
    }
    final narrative = _narrative;
    if (narrative == null) return 'Le projet narratif est indisponible.';
    final request = ++_navigationRequest;
    final local = narrative.sessions[id];
    final record = narrative.project.eventRegistry?.records
        .where((record) => record.id == id)
        .firstOrNull;
    if (local == null && record == null) {
      return 'Cette interaction n’existe plus.';
    }
    final opened = local != null
        ? await narrative.openSession(local)
        : await narrative.openRecord(record!);
    if (!mounted ||
        request != _navigationRequest ||
        _space != WorkspaceSpace.story ||
        widget.home?.visible == true) {
      return null;
    }
    if (!opened) {
      return narrative.error ?? 'Cette interaction est indisponible.';
    }
    _interactionOrigin = WorkspaceSpace.story;
    _show(WorkspaceSpace.interaction);
    return null;
  }

  Future<String?> _locateStoryInteraction(String id) async {
    final narrative = _narrative;
    if (narrative == null) return 'Le projet narratif est indisponible.';
    final request = ++_navigationRequest;
    final location = await narrative.locateInteraction(id);
    if (!mounted ||
        request != _navigationRequest ||
        _space != WorkspaceSpace.story ||
        widget.home?.visible == true) {
      return null;
    }
    if (location == null) {
      return narrative.error ?? 'La source est indisponible.';
    }
    final view = _view!;
    view.tool = StudioMapTool.select;
    view.selectedEntityId = location.entityId;
    view.selectedTriggerId = location.triggerId;
    view.positioned = true;
    location.document.selectedId = null;
    location.document.stackPosition = location.position;
    _openMap();
    _toolChanged();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          _space == WorkspaceSpace.map &&
          _controller.active == location.document) {
        view.centerOn?.call(location.position);
      }
    });
    return null;
  }

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
}
