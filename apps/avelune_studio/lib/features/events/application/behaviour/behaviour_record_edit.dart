import 'package:map_core/map_core_domain.dart';

typedef BehaviourPolicy = ({
  NarrativeEventReusePolicy? reuse,
  NarrativeEventResetPolicy reset,
});

NarrativeEventRecord editBehaviourRecord(
  NarrativeEventRecord record, {
  NarrativeEventConditionExpression? conditionExpression,
  int? priority,
  int? order,
  BehaviourPolicy? policy,
}) => record.when(
  draft: (draft) => NarrativeEventRecord.draft(
    NarrativeEventDraft(
      id: draft.id,
      name: draft.name,
      source: draft.source,
      conditions: conditionExpression?.leaves ?? draft.conditions,
      conditionExpression: conditionExpression ?? draft.conditionExpression,
      sceneId: draft.sceneId,
      reusePolicy: policy == null ? draft.reusePolicy : policy.reuse,
      priority: priority ?? draft.priority,
      order: order ?? draft.order,
      resetPolicy: policy?.reset ?? draft.resetPolicy,
      parallelPolicy: draft.parallelPolicy,
    ),
  ),
  configured: (definition, enabled) =>
      NarrativeEventRecord.configuredStructurallyUnchecked(
        NarrativeEventDefinition(
          id: definition.id,
          name: definition.name,
          source: definition.source,
          conditions: conditionExpression?.leaves ?? definition.conditions,
          conditionExpression:
              conditionExpression ?? definition.conditionExpression,
          sceneId: definition.sceneId,
          reusePolicy: policy?.reuse ?? definition.reusePolicy,
          priority: priority ?? definition.priority,
          order: order ?? definition.order,
          resetPolicy: policy?.reset ?? definition.resetPolicy,
          parallelPolicy: definition.parallelPolicy,
        ),
        enabled: enabled,
        activeInLegacyMode: record.activeInLegacyMode,
      ),
);
