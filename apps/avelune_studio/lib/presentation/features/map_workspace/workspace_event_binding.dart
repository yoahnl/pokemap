part of 'map_workspace_screen.dart';

extension _WorkspaceEventBinding on _MapWorkspaceScreenState {
  void _initializeEvents() {
    if (_narrative case final narrative?) {
      if (widget.eventPort case final port?) {
        _events = EventWorkspaceController(
          narrative,
          port,
          changed: _changed,
          sceneDrafts: () => _scenes?.scenes ?? narrative.project.scenes,
        );
      }
    }
  }

  void _openEvents([String? id]) {
    final events = _events;
    if (events == null) return;
    _eventOrigin = _space == WorkspaceSpace.map
        ? WorkspaceSpace.map
        : WorkspaceSpace.story;
    _eventView.filterMapId ??= _controller.active?.base.mapId;
    if (id != null) events.open(id);
    _show(WorkspaceSpace.events);
  }

  Future<void> _openEventSource(NarrativeEventSourceRef source) async {
    final events = _events;
    if (events == null) return;
    final request = ++_navigationRequest;
    final matches = events.records
        .where((r) => eventSource(r) == source)
        .toList();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Événements de cette source'),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final r in matches)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: StudioButton(
                      label: eventName(r),
                      secondary: true,
                      onPressed: () => Navigator.pop(context, r.id),
                    ),
                  ),
                if (matches.isEmpty)
                  const Text(
                    'Aucun événement. Créez explicitement un brouillon pour cette source.',
                  ),
              ],
            ),
          ),
        ),
        actions: [
          StudioButton(
            label: 'Annuler',
            secondary: true,
            onPressed: () => Navigator.pop(context),
          ),
          StudioButton(
            label: 'Créer un événement',
            onPressed: () => Navigator.pop(context, 'create'),
          ),
        ],
      ),
    );
    if (!mounted || request != _navigationRequest || result == null) return;
    if (result == 'create') {
      final name = await askNarrativeName(context, 'Nom du nouvel événement');
      if (!mounted || request != _navigationRequest || name == null) return;
      if (!await events.prepare() ||
          !mounted ||
          request != _navigationRequest) {
        return;
      }
      final created = events.create(name, source: source);
      if (created == null) return;
      _openEvents(created.id);
    } else {
      _openEvents(result);
    }
  }

  Future<String?> _locateEvent(NarrativeEventSourceRef source) async {
    final event = _events?.active;
    final mapId = eventMapId(source);
    if (mapId == null) {
      return 'Ce résultat est global et ne possède pas de carte.';
    }
    final entries = _controller.project!.maps.where((e) => e.id == mapId);
    if (entries.length != 1) return 'Cette carte est absente ou ambiguë.';
    final request = ++_navigationRequest;
    bool current() =>
        mounted &&
        request == _navigationRequest &&
        _events?.active == event &&
        _space == WorkspaceSpace.events;
    await _controller.activate(entries.single, isCurrent: current);
    if (!current()) return null;
    final document = _controller.active;
    if (document == null || document.base.mapId != mapId) {
      return _controller.error ?? 'Carte indisponible.';
    }
    final map = document.current;
    final id = eventTargetId(source);
    final entity = source.kind == NarrativeEventSourceKind.entityInteract
        ? map.entities.where((e) => e.id == id).firstOrNull
        : null;
    final trigger = source.kind == NarrativeEventSourceKind.triggerEnter
        ? map.triggers.where((t) => t.id == id).firstOrNull
        : null;
    if (id != null && entity == null && trigger == null) {
      return 'La cible est absente. Aucune cible de remplacement n’a été choisie.';
    }
    final view = _view!;
    view.tool = StudioMapTool.select;
    view.selectedEntityId = entity?.id;
    view.selectedTriggerId = trigger?.id;
    document.selectedId = null;
    final position = entity?.pos ?? trigger?.area.pos;
    _eventMapReturn = true;
    _openMap();
    _toolChanged();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          _space == WorkspaceSpace.map &&
          _controller.active == document &&
          position != null) {
        view.centerOn?.call(position);
      }
    });
    return null;
  }

  Future<void> _testEvent() async {
    final events = _events;
    final record = events?.active;
    if (events == null || record == null) return;
    final mapId = eventMapId(eventSource(record));
    if (mapId == null) return;
    final problem = await launchPublishedEvent(
      context: context,
      events: events,
      scenes: _scenes,
      mapId: mapId,
      eventId: record.id,
      runtimeBuilder: widget.runtimeBuilder,
    );
    if (mounted && problem != null) {
      events.error = problem;
      _changed();
    }
  }
}
