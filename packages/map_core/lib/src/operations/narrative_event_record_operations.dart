import '../models/narrative_event_definition.dart';

/// Compiles a complete draft into a disabled configured record.
///
/// This operation checks only record structure. Phase E owns contextual
/// publication against source, Scene, Fact, Event, and conflict catalogs.
NarrativeEventRecord compileNarrativeEventDraftStructurally(
  NarrativeEventRecord record,
) {
  final draft = record.draftOrNull;
  if (draft == null) {
    throw ArgumentError.value(record, 'record', 'must be a draft record');
  }
  if (!draft.isComplete) {
    throw StateError(
        'A Narrative Event draft must be complete before publication.');
  }

  return NarrativeEventRecord.configuredStructurallyUnchecked(
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

/// Changes the structural enabled flag without contextual validation.
///
/// This deliberately explicit helper is not the Phase E activation gate.
NarrativeEventRecord setNarrativeEventRecordEnabledStructurallyUnchecked(
  NarrativeEventRecord record, {
  required bool enabled,
}) {
  final definition = record.definitionOrNull;
  if (definition == null) {
    throw ArgumentError.value(record, 'record', 'must be configured');
  }
  return NarrativeEventRecord.configuredStructurallyUnchecked(
    definition,
    enabled: enabled,
  );
}
