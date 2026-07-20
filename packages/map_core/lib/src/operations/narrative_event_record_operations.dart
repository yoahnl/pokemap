import '../authoring/narrative_event_authoring_contract.dart';
import '../authoring/narrative_event_authoring_support.dart';
import '../authoring/narrative_event_draft_operations.dart';
import '../models/narrative_event_definition.dart';
import '../models/narrative_event_registry.dart';
import '../read_models/narrative_dependency_index.dart';
import 'narrative_event_id_generator.dart';

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

/// Creates an independent draft from an existing V2 Event.
///
/// The clone owns a fresh Event identity and order. All explicitly selected
/// external references remain unchanged; publication and runtime activation
/// are deliberately reset by returning a draft record.
NarrativeEventAuthoringResult duplicateNarrativeEvent({
  required NarrativeEventAuthoringContext context,
  required String expectedRevision,
  required String eventId,
  required NarrativeEventIdGenerator idGenerator,
}) {
  final registry = context.registryOrNull;
  final record = findNarrativeEventRecord(registry, eventId);
  final contextRejection = rejectNarrativeEventAuthoringContextIssue(
    context: context,
    expectedRevision: expectedRevision,
    mutation: NarrativeEventAuthoringMutation.duplicate,
    record: record,
  );
  if (contextRejection != null) return contextRejection;
  if (registry == null || record == null) {
    return _rejectRecordLifecycle(
      context: context,
      expectedRevision: expectedRevision,
      mutation: NarrativeEventAuthoringMutation.duplicate,
      record: record,
      code: 'eventMissing',
      message: 'L’événement à dupliquer n’existe pas.',
    );
  }
  final nextOrder = _nextLifecycleOrder(registry.records);
  if (nextOrder == null) {
    return _rejectRecordLifecycle(
      context: context,
      expectedRevision: expectedRevision,
      mutation: NarrativeEventAuthoringMutation.duplicate,
      record: record,
      code: 'orderOverflow',
      message: 'Impossible de dupliquer cet événement: la limite est atteinte.',
    );
  }
  late final String cloneId;
  try {
    cloneId = idGenerator.generate(existingRecords: registry.records);
  } on Object {
    return _rejectRecordLifecycle(
      context: context,
      expectedRevision: expectedRevision,
      mutation: NarrativeEventAuthoringMutation.duplicate,
      record: record,
      code: 'idGenerationFailed',
      message: 'Impossible de créer un identifiant unique pour la copie.',
    );
  }
  final clone = record.when(
    draft: (draft) => NarrativeEventDraft(
      id: cloneId,
      name: '${draft.name} — copie',
      source: draft.source,
      conditions: draft.conditions,
      sceneId: draft.sceneId,
      reusePolicy: draft.reusePolicy,
      priority: draft.priority,
      order: nextOrder,
    ),
    configured: (definition, _) => NarrativeEventDraft(
      id: cloneId,
      name: '${definition.name} — copie',
      source: definition.source,
      conditions: definition.conditions,
      sceneId: definition.sceneId,
      reusePolicy: definition.reusePolicy,
      priority: definition.priority,
      order: nextOrder,
    ),
  );
  final nextRecord = NarrativeEventRecord.draft(clone);
  final nextRegistry = NarrativeEventRegistry(
    schemaVersion: registry.schemaVersion,
    mode: registry.mode,
    records: [...registry.records, nextRecord],
    legacyClaims: registry.legacyClaims,
  );
  return NarrativeEventAuthoringResult.applied(
    mutation: NarrativeEventAuthoringMutation.duplicate,
    previousRegistry: registry,
    nextRegistry: nextRegistry,
    previousRecord: record,
    nextRecord: nextRecord,
    expectedRevision: expectedRevision,
    diagnostics: [
      NarrativeEventAuthoringDiagnostic(
        code: 'duplicateCreatedAsDraft',
        message: 'La copie est un brouillon non actif.',
      ),
    ],
  );
}

/// Converts a configured Event back to a complete draft without data loss.
NarrativeEventAuthoringResult unpublishNarrativeEvent({
  required NarrativeEventAuthoringContext context,
  required String expectedRevision,
  required String eventId,
}) {
  final registry = context.registryOrNull;
  final record = findNarrativeEventRecord(registry, eventId);
  final contextRejection = rejectNarrativeEventAuthoringContextIssue(
    context: context,
    expectedRevision: expectedRevision,
    mutation: NarrativeEventAuthoringMutation.unpublish,
    record: record,
  );
  if (contextRejection != null) return contextRejection;
  if (registry == null || record == null) {
    return _rejectRecordLifecycle(
      context: context,
      expectedRevision: expectedRevision,
      mutation: NarrativeEventAuthoringMutation.unpublish,
      record: record,
      code: 'eventMissing',
      message: 'L’événement à dépublier n’existe pas.',
    );
  }
  final definition = record.definitionOrNull;
  if (definition == null) {
    return NarrativeEventAuthoringResult.noOp(
      mutation: NarrativeEventAuthoringMutation.unpublish,
      registry: registry,
      record: record,
      expectedRevision: expectedRevision,
      diagnostics: [
        NarrativeEventAuthoringDiagnostic(
          code: 'alreadyDraft',
          message: 'Cet événement est déjà un brouillon.',
        ),
      ],
    );
  }
  final nextRecord = NarrativeEventRecord.draft(
    NarrativeEventDraft(
      id: definition.id,
      name: definition.name,
      source: definition.source,
      conditions: definition.conditions,
      sceneId: definition.sceneId,
      reusePolicy: definition.reusePolicy,
      priority: definition.priority,
      order: definition.order,
    ),
  );
  return NarrativeEventAuthoringResult.applied(
    mutation: NarrativeEventAuthoringMutation.unpublish,
    previousRegistry: registry,
    nextRegistry: replaceNarrativeEventRecord(registry, nextRecord),
    previousRecord: record,
    nextRecord: nextRecord,
    expectedRevision: expectedRevision,
    impactPreview: NarrativeEventSourceImpactPreview(
      physicalSourceDeleted: false,
      structuralUnpublish: true,
    ),
    diagnostics: [
      NarrativeEventAuthoringDiagnostic(
        code: 'runtimeDisabledByUnpublish',
        message: 'L’événement redevient un brouillon et n’est plus joué.',
      ),
    ],
  );
}

/// Deletes an Event only when the canonical dependency index has no external
/// consumer and no legacy claim still targets it.
NarrativeEventAuthoringResult deleteNarrativeEvent({
  required NarrativeEventAuthoringContext context,
  required String expectedRevision,
  required String eventId,
  required NarrativeDependencyIndex dependencyIndex,
}) {
  final registry = context.registryOrNull;
  final record = findNarrativeEventRecord(registry, eventId);
  final contextRejection = rejectNarrativeEventAuthoringContextIssue(
    context: context,
    expectedRevision: expectedRevision,
    mutation: NarrativeEventAuthoringMutation.delete,
    record: record,
  );
  if (contextRejection != null) return contextRejection;
  if (registry == null || record == null) {
    return _rejectRecordLifecycle(
      context: context,
      expectedRevision: expectedRevision,
      mutation: NarrativeEventAuthoringMutation.delete,
      record: record,
      code: 'eventMissing',
      message: 'L’événement à supprimer n’existe pas.',
    );
  }
  final target = NarrativeDependencyKey.eventV2(eventId);
  final consumers = <NarrativeDependencyUsage>[
    for (final usage in dependencyIndex.usagesFor(target))
      if (usage.owner != target) usage,
    for (final claim in registry.legacyClaims)
      if (claim.targetEventIds.contains(eventId))
        NarrativeDependencyUsage(
          target: target,
          owner: NarrativeDependencyKey.legacySourceClaim(claim.cohortId),
          path: 'eventRegistry.legacyClaims.${claim.cohortId}.targetEventIds',
          criticality: NarrativeDependencyCriticality.runtimeBlocking,
          resolution: NarrativeDependencyResolution.legacyExternal,
        ),
  ];
  final preview = NarrativeEventDeletionPreview(
    eventId: eventId,
    consumers: consumers,
  );
  if (!preview.canDelete) {
    return NarrativeEventAuthoringResult.rejected(
      status: NarrativeEventAuthoringStatus.rejected,
      mutation: NarrativeEventAuthoringMutation.delete,
      registry: registry,
      record: record,
      expectedRevision: expectedRevision,
      code: 'eventReferenced',
      message: 'Cet événement est encore utilisé par le projet.',
      deletionPreview: preview,
    );
  }
  final nextRegistry = NarrativeEventRegistry(
    schemaVersion: registry.schemaVersion,
    mode: registry.mode,
    records: [
      for (final candidate in registry.records)
        if (candidate.id != eventId) candidate,
    ],
    legacyClaims: registry.legacyClaims,
  );
  return NarrativeEventAuthoringResult.applied(
    mutation: NarrativeEventAuthoringMutation.delete,
    previousRegistry: registry,
    nextRegistry: nextRegistry,
    previousRecord: record,
    nextRecord: null,
    expectedRevision: expectedRevision,
    deletionPreview: preview,
  );
}

NarrativeEventAuthoringResult _rejectRecordLifecycle({
  required NarrativeEventAuthoringContext context,
  required String expectedRevision,
  required NarrativeEventAuthoringMutation mutation,
  required NarrativeEventRecord? record,
  required String code,
  required String message,
}) {
  return NarrativeEventAuthoringResult.rejected(
    status: NarrativeEventAuthoringStatus.rejected,
    mutation: mutation,
    registry: context.registryOrNull,
    record: record,
    expectedRevision: expectedRevision,
    code: code,
    message: message,
  );
}

int? _nextLifecycleOrder(List<NarrativeEventRecord> records) {
  if (records.isEmpty) return 0;
  var maximum = 0;
  for (final record in records) {
    final order = record.when(
      draft: (draft) => draft.order,
      configured: (definition, _) => definition.order,
    );
    if (order > maximum) maximum = order;
  }
  if (maximum >= narrativeEventMaximumAuthoringOrder) return null;
  return maximum + 1;
}
