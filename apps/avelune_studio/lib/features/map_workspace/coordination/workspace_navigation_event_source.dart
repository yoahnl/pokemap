part of 'workspace_navigation_session.dart';

extension WorkspaceEventSourceNavigation on WorkspaceNavigationSession {
  Future<void> openEventSource(
    NarrativeEventSourceRef source, {
    required Future<String?> Function(List<NarrativeEventRecord>) choose,
    required Future<String?> Function() askName,
  }) async {
    final ticket = await _prepare(MapWorkspaceWorkshop.events);
    if (!isActive() || ticket == null) return;
    final owner = events?.call();
    if (owner == null) return;
    final matches = owner.records
        .where((r) => eventSource(r) == source)
        .toList();
    final result = await choose(matches);
    if (!isActive() || ticket != request || result == null) return;
    if (result == 'create') {
      final name = await askName();
      if (!isActive() || ticket != request || name == null) return;
      if (!await owner.prepare() || !isActive() || ticket != request) return;
      final created = owner.create(name, source: source);
      if (created == null) return;
      unawaited(openEvents(created.id));
    } else {
      unawaited(openEvents(result));
    }
  }

  Future<String?> locateEventSource(NarrativeEventSourceRef source) async {
    final event = events?.call()?.active;
    final mapId = eventMapId(source);
    if (mapId == null) {
      return 'Ce résultat est global et ne possède pas de carte.';
    }
    final entries = controller.project!.maps.where((e) => e.id == mapId);
    if (entries.length != 1) return 'Cette carte est absente ou ambiguë.';
    final ticket = nextNavigationRequest?.call() ?? ++_request;
    bool current() =>
        isActive() &&
        ticket == request &&
        events?.call()?.active == event &&
        space == WorkspaceSpace.events;
    await controller.activate(entries.single, isCurrent: current);
    if (!current()) return null;
    final document = controller.active;
    if (document == null || document.base.mapId != mapId) {
      return controller.error ?? 'Carte indisponible.';
    }
    final map = document.current;
    final id = eventTargetId(source);
    final entities =
        (source.kind == NarrativeEventSourceKind.entityInteract ||
            source.kind == NarrativeEventSourceKind.entityBump ||
            source.kind == NarrativeEventSourceKind.entityAutorun)
        ? map.entities.where((e) => e.id == id).toList()
        : const <MapEntity>[];
    final entity = entities.length == 1 ? entities.single : null;
    final trigger =
        (source.kind == NarrativeEventSourceKind.triggerEnter ||
            source.kind == NarrativeEventSourceKind.triggerBump)
        ? map.triggers.where((t) => t.id == id).firstOrNull
        : null;
    final instance = source.kind == NarrativeEventSourceKind.modelInteract
        ? map.spatialScene?.instances.where((item) => item.id == id).firstOrNull
        : null;
    if (id != null && entity == null && trigger == null && instance == null) {
      return 'La cible est absente. Aucune cible de remplacement n’a été choisie.';
    }
    final view = mapView?.call();
    if (view == null) return 'La vue de cette carte est indisponible.';
    view.tool = StudioMapTool.select;
    if (entity != null) {
      view.select(document, MapSelectionFamily.character, entity.id);
    } else if (trigger != null) {
      view.select(document, MapSelectionFamily.trigger, trigger.id);
    } else if (instance != null) {
      view.select(document, MapSelectionFamily.decor, instance.id);
    } else {
      view.clearSelection(document);
    }
    final position =
        entity?.pos ??
        trigger?.area.pos ??
        (instance == null
            ? null
            : GridPos(
                x: instance.position.x.floor(),
                y: instance.position.z.floor(),
              ));
    eventMapReturn = true;
    show(WorkspaceSpace.map);
    toolChanged?.call();
    void center() {
      if (isActive() &&
          space == WorkspaceSpace.map &&
          controller.active == document &&
          position != null) {
        view.centerOn?.call(position);
      }
    }

    final schedule = afterViewportLayout;
    schedule == null ? center() : schedule(center);
    return null;
  }
}
