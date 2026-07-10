import '../models/narrative_event_definition.dart';

NarrativeEventRecord publishNarrativeEventRecord(NarrativeEventRecord record) {
  final draft = record.draftOrNull;
  if (draft == null) {
    throw ArgumentError.value(record, 'record', 'must be a draft record');
  }
  if (!draft.isComplete) {
    throw StateError(
        'A Narrative Event draft must be complete before publication.');
  }

  return NarrativeEventRecord.configured(
    NarrativeEventDefinition(
      id: draft.id,
      name: draft.name,
      source: draft.source!,
      conditions: draft.conditions,
      sceneId: draft.sceneId!,
      reusePolicy: draft.reusePolicy!,
      priority: draft.priority,
      order: draft.order,
    ),
    enabled: false,
  );
}

NarrativeEventRecord activateNarrativeEventRecord(NarrativeEventRecord record) {
  final definition = record.definitionOrNull;
  if (definition == null) {
    throw ArgumentError.value(record, 'record', 'must be configured');
  }
  return NarrativeEventRecord.configured(definition, enabled: true);
}

NarrativeEventRecord deactivateNarrativeEventRecord(
    NarrativeEventRecord record) {
  final definition = record.definitionOrNull;
  if (definition == null) {
    throw ArgumentError.value(record, 'record', 'must be configured');
  }
  return NarrativeEventRecord.configured(definition, enabled: false);
}
