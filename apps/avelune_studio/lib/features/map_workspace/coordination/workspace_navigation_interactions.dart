part of 'workspace_navigation_session.dart';

extension WorkspaceInteractionNavigation on WorkspaceNavigationSession {
  Future<void> openEvents(String? id, {bool filterSource = false}) async {
    final ticket = await _prepare(MapWorkspaceWorkshop.events);
    if (ticket == null) return;
    final owner = events?.call();
    if (owner == null) return;
    eventOrigin = space == WorkspaceSpace.map
        ? WorkspaceSpace.map
        : WorkspaceSpace.story;
    eventFilterMapId =
        (readEventFilter == null
            ? eventFilterMapId
            : readEventFilter!.call()) ??
        controller.active?.base.mapId;
    eventFilterChanged?.call(eventFilterMapId);
    if (id != null) {
      if (!owner.open(id)) return;
      if (filterSource) {
        eventFilterMapId = eventMapId(eventSource(owner.record(id)!));
      }
    }
    eventFilterChanged?.call(eventFilterMapId);
    show(WorkspaceSpace.events);
  }

  Future<String?> openStoryInteraction(
    String id, {
    WorkspaceSpace from = WorkspaceSpace.story,
  }) async {
    final owner = narrative?.call();
    final local = owner?.sessions[id];
    if (local?.dirty != true && events?.call()?.record(id) != null) {
      unawaited(openEvents(id));
      return null;
    }
    if (owner == null) return 'Le projet narratif est indisponible.';
    final ticket = nextNavigationRequest?.call() ?? ++_request;
    final record = owner.project.eventRegistry?.records
        .where((record) => record.id == id)
        .firstOrNull;
    if (local == null && record == null) {
      return 'Cette interaction n’existe plus.';
    }
    final opened = local != null
        ? await owner.openSession(local)
        : await owner.openRecord(record!);
    if (!isActive() ||
        ticket != request ||
        space != from ||
        homeVisible?.call() == true) {
      return null;
    }
    if (!opened) return owner.error ?? 'Cette interaction est indisponible.';
    interactionOrigin = from;
    show(WorkspaceSpace.interaction);
    return null;
  }

  Map<String, String> interactionsOnSource(String mapId, String triggerId) {
    final owner = narrative?.call();
    if (owner == null) return const {};
    bool matches(NarrativeEventSourceRef? source) {
      final json = source?.toJson();
      return json != null &&
          json['mapId'] == mapId &&
          json['triggerId'] == triggerId;
    }

    final found = <String, String>{};
    for (final entry in owner.sessions.entries) {
      final interaction = entry.value.current.interaction;
      if (matches(interaction.source)) found[entry.key] = interaction.name;
    }
    for (final record
        in events?.call()?.records ??
            owner.project.eventRegistry?.records ??
            const <NarrativeEventRecord>[]) {
      if (matches(eventSource(record))) {
        found.putIfAbsent(record.id, () => eventName(record));
      }
    }
    return found;
  }

  Future<void> openExistingStoryZone(
    EditableMapDocument document,
    MapTrigger trigger, {
    required Future<String?> Function(Map<String, String>) choose,
  }) async {
    final mapId = document.current.id;
    final found = interactionsOnSource(mapId, trigger.id);
    if (found.isEmpty) {
      document.error =
          'Aucune interaction n’est liée à cette zone. Tracez-la depuis '
          'Histoire pour en écrire une.';
      changed();
      return;
    }
    final id = found.length == 1 ? found.keys.single : await choose(found);
    bool stillHere() =>
        isActive() &&
        space == WorkspaceSpace.map &&
        controller.active?.current.id == mapId;
    if (id == null || !stillHere()) return;
    final problem = await openStoryInteraction(id, from: WorkspaceSpace.map);
    if (problem == null || !stillHere()) return;
    document.error = problem;
    changed();
  }

  Future<String?> locateStoryInteraction(String id) async {
    final owner = narrative?.call();
    if (owner == null) return 'Le projet narratif est indisponible.';
    final ticket = nextNavigationRequest?.call() ?? ++_request;
    final location = await owner.locateInteraction(id);
    if (!isActive() ||
        ticket != request ||
        space != WorkspaceSpace.story ||
        homeVisible?.call() == true) {
      return null;
    }
    if (location == null) return owner.error ?? 'La source est indisponible.';
    final view = mapView?.call();
    if (view == null) return 'La vue de cette carte est indisponible.';
    view.tool = StudioMapTool.select;
    view.positioned = true;
    if (location.entityId case final entityId?) {
      view.select(location.document, MapSelectionFamily.character, entityId);
    } else if (location.triggerId case final triggerId?) {
      view.select(location.document, MapSelectionFamily.trigger, triggerId);
    } else if (location.instanceId case final instanceId?) {
      view.select(location.document, MapSelectionFamily.decor, instanceId);
    } else {
      view.clearSelection(location.document);
    }
    location.document.stackPosition = location.position;
    show(WorkspaceSpace.map);
    toolChanged?.call();
    void center() {
      if (isActive() &&
          space == WorkspaceSpace.map &&
          controller.active == location.document) {
        view.centerOn?.call(location.position);
      }
    }

    final schedule = afterViewportLayout;
    schedule == null ? center() : schedule(center);
    return null;
  }
}
