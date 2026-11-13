part of 'map_builder_story_binding.dart';

final class _StoryTriggers {
  (ProjectManifest, MapData, String, List<NarrativeEventSourceKind>)? _cached;

  List<NarrativeEventSourceKind> kinds(
    ProjectManifest project,
    MapData map,
    MapStoryElement element,
  ) {
    final cached = _cached;
    if (cached != null &&
        identical(cached.$1, project) &&
        identical(cached.$2, map) &&
        cached.$3 == element.key) {
      return cached.$4;
    }
    final kinds = List<NarrativeEventSourceKind>.unmodifiable(
      behaviourTriggerKinds(
        project: project,
        map: map,
        owner: switch (element.target) {
          MapStoryElementTarget.entity => BehaviourOwner.entity,
          MapStoryElementTarget.model => BehaviourOwner.model,
          MapStoryElementTarget.trigger => BehaviourOwner.trigger,
          MapStoryElementTarget.map => BehaviourOwner.map,
        },
        ownerId: element.target == MapStoryElementTarget.map
            ? null
            : element.id,
      ),
    );
    _cached = (project, map, element.key, kinds);
    return kinds;
  }
}

typedef MapStoryCases = ({
  List<BehaviourCaseGroup> groups,
  List<NarrativeEventRecord> unsorted,
  Map<String, String> shadowedBy,
});

extension MapStoryCaseEditing on MapBuilderStoryBinding {
  bool setAfter(
    NarrativeEventRecord record,
    BehaviourAfter after, {
    bool dropOutcomeRearm = false,
  }) {
    pendingAfter = null;
    switch (changeBehaviourAfter(
      record,
      after,
      dropOutcomeRearm: dropOutcomeRearm,
    )) {
      case BehaviourAfterUnchanged():
        return true;
      case BehaviourAfterRefused(:final reason):
        attempts++;
        error = '${MapBuilderStoryBinding.afterRefused}${reason.name}';
        if (reason == BehaviourAfterRefusal.wouldDropOutcomeRearm) {
          pendingAfter = after;
        }
        changed();
        return false;
      case BehaviourAfterApplied(:final steps):
        return _operate(
          [record],
          [
            for (final step in steps)
              (c) => switch (step.reusePolicy) {
                final reuse? => setNarrativeEventReusePolicy(
                  context: c,
                  expectedRevision: c.revision,
                  eventId: record.id,
                  reusePolicy: reuse,
                ),
                null => setNarrativeEventResetPolicy(
                  context: c,
                  expectedRevision: c.revision,
                  eventId: record.id,
                  resetPolicy: step.resetPolicy!,
                ),
              },
          ],
        );
    }
  }

  MapStoryCases casesOf(MapStoryElement element) {
    final project = maps.project;
    final registry = project == null ? null : behaviours.registry(project);
    final groups = behaviourCaseGroups(
      element.behaviours,
      registry?.mode ?? EventSystemMode.v2Only,
    );
    final uncertain = {
      for (final rule
          in project == null
              ? const <WorldRuleDefinition>[]
              : behaviours.project(project).worldRules)
        ?rule.target.eventId,
    };
    return (
      groups: groups,
      unsorted: [
        for (final record in element.behaviours)
          if (record.source == null) record,
      ],
      shadowedBy: {
        for (final group in groups)
          for (final shadow in shadowedBehaviourCases(
            group,
            uncertainIds: uncertain,
          ))
            shadow.caseId: shadow.shadowedBy,
      },
    );
  }

  bool moveCase(BehaviourCaseGroup group, int from, int to) {
    final List<NarrativeEventRecord> moved;
    try {
      moved = moveBehaviourCase(group.records, from, to);
    } on Object catch (failure) {
      attempts++;
      error = '$failure';
      changed();
      return false;
    }
    if (moved.isEmpty) return true;
    final before = {for (final record in group.records) record.id: record};
    return _operate(
      [for (final record in moved) before[record.id]!],
      [
        for (final record in moved) ...[
          if (record.priority != before[record.id]!.priority)
            (NarrativeEventAuthoringContext c) => setNarrativeEventPriority(
              context: c,
              expectedRevision: c.revision,
              eventId: record.id,
              priority: record.priority,
            ),
          if (record.order != before[record.id]!.order)
            (NarrativeEventAuthoringContext c) => setNarrativeEventOrder(
              context: c,
              expectedRevision: c.revision,
              eventId: record.id,
              order: record.order,
            ),
        ],
      ],
    );
  }
}
