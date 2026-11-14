part of 'map_builder_story_binding.dart';

extension MapStoryBehaviourEditing on MapBuilderStoryBinding {
  NarrativeEventSourceRef? defaultSource(MapStoryElement element) {
    final map = this.map;
    if (map == null) return null;
    return switch (element.target) {
      MapStoryElementTarget.entity => NarrativeEventSourceRef.entityInteract(
        map.id,
        element.id,
      ),
      MapStoryElementTarget.model => NarrativeEventSourceRef.modelInteract(
        map.id,
        element.id,
      ),
      MapStoryElementTarget.trigger => NarrativeEventSourceRef.triggerEnter(
        map.id,
        element.id,
      ),
      MapStoryElementTarget.map => NarrativeEventSourceRef.mapEnter(map.id),
    };
  }

  List<NarrativeEventSourceKind> triggerKinds(MapStoryElement element) {
    final project = maps.project;
    final map = this.map;
    return project == null || map == null
        ? const []
        : _triggers.kinds(behaviours.project(project), map, element);
  }

  bool addBehaviour(MapStoryElement element) {
    final source = defaultSource(element);
    final order = element.behaviours.fold<int>(
      -1,
      (highest, record) => record.order > highest ? record.order : highest,
    );
    String? created;
    final applied = _operate(const [], [
      (c) {
        final result = createNarrativeEventDraft(
          context: c,
          expectedRevision: c.revision,
          name: _behaviourName(element.behaviours.length + 1),
          initialSource: source,
          idGenerator: NarrativeEventIdGenerator(),
        );
        created = result.eventId;
        return result;
      },
      (c) => setNarrativeEventReusePolicy(
        context: c,
        expectedRevision: c.revision,
        eventId: created!,
        reusePolicy: NarrativeEventReusePolicy.oneShot,
      ),
      (c) => setNarrativeEventOrder(
        context: c,
        expectedRevision: c.revision,
        eventId: created!,
        order: order + 1,
      ),
    ]);
    if (applied) {
      behaviour = element.behaviours.length;
      tab = MapStoryTab.behaviour;
      changed();
    }
    return applied;
  }

  bool renameBehaviour(NarrativeEventRecord record, String name) =>
      _operate(const [], [
        (c) => renameNarrativeEvent(
          context: c,
          expectedRevision: c.revision,
          eventId: record.id,
          name: name,
        ),
      ]);

  bool setTrigger(
    MapStoryElement element,
    NarrativeEventRecord record,
    NarrativeEventSourceKind kind,
  ) {
    final map = this.map;
    if (map == null) return false;
    final source = switch (kind) {
      NarrativeEventSourceKind.entityInteract =>
        NarrativeEventSourceRef.entityInteract(map.id, element.id),
      NarrativeEventSourceKind.entityBump => NarrativeEventSourceRef.entityBump(
        map.id,
        element.id,
      ),
      NarrativeEventSourceKind.entityAutorun =>
        NarrativeEventSourceRef.entityAutorun(map.id, element.id),
      NarrativeEventSourceKind.modelInteract =>
        NarrativeEventSourceRef.modelInteract(map.id, element.id),
      NarrativeEventSourceKind.triggerEnter =>
        NarrativeEventSourceRef.triggerEnter(map.id, element.id),
      NarrativeEventSourceKind.triggerBump =>
        NarrativeEventSourceRef.triggerBump(map.id, element.id),
      NarrativeEventSourceKind.mapEnter => NarrativeEventSourceRef.mapEnter(
        map.id,
      ),
      NarrativeEventSourceKind.outcomeReceived => null,
    };
    if (source == null) return false;
    return _operate(
      [record],
      [
        (c) => record.source == null
            ? selectNarrativeEventSource(
                context: c,
                expectedRevision: c.revision,
                eventId: record.id,
                source: source,
              )
            : replaceNarrativeEventSource(
                context: c,
                expectedRevision: c.revision,
                eventId: record.id,
                source: source,
              ),
      ],
    );
  }

  bool setScene(NarrativeEventRecord record, String? sceneId) => _operate(
    [record],
    [
      (c) => sceneId == null
          ? removeNarrativeEventScene(
              context: c,
              expectedRevision: c.revision,
              eventId: record.id,
            )
          : setNarrativeEventScene(
              context: c,
              expectedRevision: c.revision,
              eventId: record.id,
              sceneId: sceneId,
            ),
    ],
  );

  bool setActive(NarrativeEventRecord record, bool active) =>
      _operate(const [], [
        if (active && record.draftOrNull != null)
          (c) => publishNarrativeEvent(
            context: c,
            expectedRevision: c.revision,
            eventId: record.id,
          ),
        (c) => active
            ? activateNarrativeEvent(
                context: c,
                expectedRevision: c.revision,
                eventId: record.id,
              )
            : deactivateNarrativeEvent(
                context: c,
                expectedRevision: c.revision,
                eventId: record.id,
              ),
      ]);

  bool reassign(NarrativeEventRecord record, MapStoryElement element) {
    final kinds = triggerKinds(element);
    final current = record.source?.kind;
    if (kinds.isEmpty) return false;
    return _repair(
      () => setTrigger(
        element,
        record,
        kinds.contains(current) ? current! : kinds.first,
      ),
    );
  }

  bool deleteOrphan(NarrativeEventRecord record) =>
      _repair(() => deleteBehaviour(record));

  bool _repair(bool Function() repair) {
    final before = attempts;
    final repaired = repair();
    if (attempts == before) return repaired;
    repairError = error;
    error = null;
    changed();
    return repaired;
  }

  bool deleteBehaviour(NarrativeEventRecord record) {
    final project = maps.project;
    final map = this.map;
    if (project == null || map == null) return false;
    final applied = _operate(const [], [
      (c) => deleteNarrativeEvent(
        context: c,
        expectedRevision: c.revision,
        eventId: record.id,
        dependencyIndex: buildNarrativeDependencyIndex(
          project: behaviours.project(project),
          maps: [map],
        ),
      ),
    ]);
    if (applied) behaviour = 0;
    return applied;
  }

  bool _operate(
    List<NarrativeEventRecord> active,
    List<MapStoryBehaviourOperation> operations, {
    void Function(StoryDraft draft)? stage,
  }) {
    final project = maps.project;
    final map = this.map;
    if (project == null || map == null || publishing || !ready) return false;
    attempts++;
    repairError = null;
    final enabled = [
      for (final record in active)
        if (record.enabledOrNull == true) record.id,
    ];
    final wrapped = [
      for (final id in enabled)
        (NarrativeEventAuthoringContext c) => deactivateNarrativeEvent(
          context: c,
          expectedRevision: c.revision,
          eventId: id,
        ),
      ...operations,
    ];
    final draft = behaviours.draft;
    final recorded = draft.recorded;
    String? problem;
    String? notice;
    try {
      draft.group(() {
        stage?.call(draft);
        var result = behaviours.apply(project, map, [
          ...wrapped,
          for (final id in enabled)
            (NarrativeEventAuthoringContext c) => activateNarrativeEvent(
              context: c,
              expectedRevision: c.revision,
              eventId: id,
            ),
        ]);
        if (result.problem != null && enabled.isNotEmpty) {
          notice = result.problem;
          result = behaviours.apply(project, map, wrapped);
        }
        if (result.problem case final refused?) throw _StoryRefused(refused);
      });
    } on _StoryRefused catch (refused) {
      problem = refused.problem;
    } on Object catch (failure) {
      problem = failure is StateError ? failure.message : '$failure';
    }
    final records = {
      for (final record
          in behaviours.registry(project)?.records ??
              const <NarrativeEventRecord>[])
        record.id: record,
    };
    final dropped = enabled.any(
      (id) => records[id] != null && records[id]!.enabledOrNull != true,
    );
    error =
        problem ??
        (dropped
            ? '${MapBuilderStoryBinding.deactivated}${notice?.trim().isNotEmpty == true ? ' $notice' : ''}'
            : null);
    if (draft.recorded != recorded) _record(_StorySide.behaviours, null);
    changed();
    return problem == null;
  }
}
