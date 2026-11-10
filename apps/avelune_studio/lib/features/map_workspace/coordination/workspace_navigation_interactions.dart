part of 'workspace_navigation_session.dart';

extension WorkspaceInteractionNavigation on WorkspaceNavigationSession {
  Future<String?> openNarrativeMap(
    String mapId, {
    void Function()? cancelGestures,
  }) async {
    final project = controller.project;
    final entry = project?.maps.where((item) => item.id == mapId).firstOrNull;
    if (entry == null) return null;
    final ticket = nextNavigationRequest?.call() ?? ++_request;
    bool current() =>
        isActive() &&
        ticket == request &&
        identical(controller.project, project) &&
        space == WorkspaceSpace.story;
    await controller.activate(entry, isCurrent: current);
    if (!current()) return null;
    if (controller.active?.base.mapId != mapId) {
      return controller.error ?? 'Carte indisponible.';
    }
    cancelGestures?.call();
    final view = mapView?.call();
    view?.pendingMove = null;
    view?.tool = StudioMapTool.select;
    show(WorkspaceSpace.map);
    toolChanged?.call();
    return null;
  }

  Future<String?> openInteractionScene(
    MapEntity entity, {
    required Future<SceneAsset?> Function(
      List<(NarrativeEventRecord, SceneAsset)>,
    )
    choose,
  }) async {
    final document = controller.active;
    if (document == null) return null;
    final mapId = document.current.id;
    final ticket = await _prepare(MapWorkspaceWorkshop.events);
    if (!isActive() || ticket == null) return null;
    final owner = events?.call();
    if (owner == null) return null;
    final source = NarrativeEventSourceRef.entityInteract(mapId, entity.id);
    final available =
        scenes?.call()?.scenes ??
        narrative?.call()?.project.scenes ??
        const <SceneAsset>[];
    final played = <(NarrativeEventRecord, SceneAsset)>[
      for (final record in owner.records)
        if (eventSource(record) == source)
          if (eventSceneId(record) case final sceneId?)
            if (available.where((scene) => scene.id == sceneId).firstOrNull
                case final scene?)
              (record, scene),
    ];
    if (played.isEmpty)
      return 'Aucune interaction de ce personnage ne joue encore de scène. « Écrire son interaction » en crée une.';
    final chosen = played.length == 1 ? played.single.$2 : await choose(played);
    if (!isActive() || ticket != request || chosen == null) return null;
    return openScene(
      chosen.id,
      nodeId: chosen.graph.startNodeId,
      origin: WorkspaceReturn(
        WorkspaceSpace.map,
        documentId: mapId,
        elementId: entity.id,
      ),
    );
  }

  bool openProgression({String? preferredStoryId}) {
    final owner = stories?.call();
    if (!isActive() || owner == null) return false;
    progressionOrigin = WorkspaceReturn.story;
    final id =
        preferredStoryId != null &&
            owner.stories.any((story) => story.id == preferredStoryId)
        ? preferredStoryId
        : owner.activeId ?? owner.stories.firstOrNull?.id;
    if (id != null) owner.open(id);
    show(WorkspaceSpace.progression);
    return true;
  }

  bool openProgressionStep(String storyId, String stepId) {
    final owner = stories?.call();
    if (!isActive() || owner == null || !owner.open(storyId)) return false;
    final projection = buildStorylineProgressionProjection(
      project: owner.project,
      storylineId: storyId,
    );
    final node = projection.nodes
        .where((node) => node.stepId == stepId)
        .firstOrNull;
    if (node != null) {
      progressionNodes[storyId] = node;
      selectProgressionNode?.call(storyId, node);
    }
    progressionOrigin = WorkspaceReturn.story;
    show(WorkspaceSpace.progression);
    return true;
  }

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
