part of 'event_workspace_controller.dart';

extension EventWorkspaceCommands on EventWorkspaceController {
  bool _edit(
    String id,
    NarrativeEventAuthoringResult Function(NarrativeEventAuthoringContext)
    operation, {
    bool disable = true,
  }) {
    if (_closed) return false;
    if (!prepared) {
      return _fail('Chargez le catalogue avant de modifier cet événement.');
    }
    final problem = narrative.interactionAccessProblem(id);
    if (problem != null) return _fail(problem);
    try {
      final original = record(id);
      var snapshot = context;
      if (disable && original?.enabledOrNull == true) {
        final disabled = deactivateNarrativeEvent(
          context: snapshot,
          expectedRevision: snapshot.revision,
          eventId: id,
        );
        if (disabled.status != NarrativeEventAuthoringStatus.applied) {
          return _fail(disabled.humanReason ?? 'Désactivation impossible.');
        }
        snapshot = _context(
          project.copyWith(eventRegistry: disabled.nextRegistry),
        );
      }
      return _apply(operation(snapshot), original: original);
    } catch (failure) {
      return _fail(failure.toString());
    }
  }

  NarrativeEventRecord? create(String name, {NarrativeEventSourceRef? source}) {
    if (_closed || !prepared) {
      _fail('Chargez le catalogue avant de créer un événement.');
      return null;
    }
    final c = context;
    final result = createNarrativeEventDraft(
      context: c,
      expectedRevision: c.revision,
      name: name,
      initialSource: source,
      idGenerator: NarrativeEventIdGenerator(),
    );
    if (!_apply(result)) return null;
    activeId = result.eventId;
    changed();
    return result.nextRecord;
  }

  NarrativeEventRecord? duplicate(String id) {
    NarrativeEventRecord? created;
    final ok = _edit(id, (c) {
      final result = duplicateNarrativeEvent(
        context: c,
        expectedRevision: c.revision,
        eventId: id,
        idGenerator: NarrativeEventIdGenerator(),
      );
      created = result.nextRecord;
      return result;
    }, disable: false);
    if (!ok) return null;
    activeId = created?.id;
    changed();
    return created;
  }

  bool delete(String id) => _edit(
    id,
    (c) => deleteNarrativeEvent(
      context: c,
      expectedRevision: c.revision,
      eventId: id,
      dependencyIndex: buildNarrativeDependencyIndex(
        project: project,
        maps: maps,
      ),
    ),
    disable: false,
  );
  bool rename(String id, String name) => _edit(
    id,
    (c) => renameNarrativeEvent(
      context: c,
      expectedRevision: c.revision,
      eventId: id,
      name: name,
    ),
    disable: false,
  );
  bool setSource(String id, NarrativeEventSourceRef? source) => _edit(id, (c) {
    if (source == null) {
      return removeNarrativeEventSource(
        context: c,
        expectedRevision: c.revision,
        eventId: id,
      );
    }
    return record(id)?.source == null
        ? selectNarrativeEventSource(
            context: c,
            expectedRevision: c.revision,
            eventId: id,
            source: source,
          )
        : replaceNarrativeEventSource(
            context: c,
            expectedRevision: c.revision,
            eventId: id,
            source: source,
          );
  });
  bool setScene(String id, String? sceneId) => _edit(
    id,
    (c) => sceneId == null
        ? removeNarrativeEventScene(
            context: c,
            expectedRevision: c.revision,
            eventId: id,
          )
        : setNarrativeEventScene(
            context: c,
            expectedRevision: c.revision,
            eventId: id,
            sceneId: sceneId,
          ),
  );
  bool setExpression(String id, NarrativeEventConditionExpression expression) =>
      _edit(
        id,
        (c) => setNarrativeEventConditionExpression(
          context: c,
          expectedRevision: c.revision,
          eventId: id,
          expression: expression,
        ),
      );
  bool setReuse(String id, NarrativeEventReusePolicy policy) => _edit(
    id,
    (c) => setNarrativeEventReusePolicy(
      context: c,
      expectedRevision: c.revision,
      eventId: id,
      reusePolicy: policy,
    ),
  );
  bool setReset(String id, NarrativeEventResetPolicy policy) => _edit(
    id,
    (c) => setNarrativeEventResetPolicy(
      context: c,
      expectedRevision: c.revision,
      eventId: id,
      resetPolicy: policy,
    ),
  );
  bool setPriority(String id, int priority) => _edit(
    id,
    (c) => setNarrativeEventPriority(
      context: c,
      expectedRevision: c.revision,
      eventId: id,
      priority: priority,
    ),
  );
  bool setOrder(String id, int order) => _edit(
    id,
    (c) => setNarrativeEventOrder(
      context: c,
      expectedRevision: c.revision,
      eventId: id,
      order: order,
    ),
  );
  bool configure(String id) => _edit(
    id,
    (c) => publishNarrativeEvent(
      context: c,
      expectedRevision: c.revision,
      eventId: id,
    ),
    disable: false,
  );
  bool unconfigure(String id) => _edit(
    id,
    (c) => unpublishNarrativeEvent(
      context: c,
      expectedRevision: c.revision,
      eventId: id,
    ),
  );
  bool setEnabled(String id, bool enabled) => _edit(
    id,
    (c) => enabled
        ? activateNarrativeEvent(
            context: c,
            expectedRevision: c.revision,
            eventId: id,
          )
        : deactivateNarrativeEvent(
            context: c,
            expectedRevision: c.revision,
            eventId: id,
          ),
    disable: false,
  );
}
