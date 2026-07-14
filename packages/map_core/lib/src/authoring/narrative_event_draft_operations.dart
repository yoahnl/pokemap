import '../catalogs/narrative_event_project_catalog.dart';
import '../catalogs/narrative_outcome_event_source_catalog.dart';
import '../catalogs/narrative_spatial_event_source_catalog.dart';
import '../models/narrative_event_definition.dart';
import '../models/narrative_event_registry.dart';
import '../models/narrative_event_source_ref.dart';
import '../operations/narrative_event_id_generator.dart';
import '../operations/narrative_event_canonical_json.dart';
import 'narrative_event_authoring_contract.dart';

const int narrativeEventMaximumAuthoringOrder = 0x1fffffffffffff;

NarrativeEventAuthoringResult createNarrativeEventDraft({
  required NarrativeEventAuthoringContext context,
  required String expectedRevision,
  required String name,
  NarrativeEventSourceRef? initialSource,
  required NarrativeEventIdGenerator idGenerator,
}) {
  final contextRejection = rejectNarrativeEventAuthoringContextIssue(
    context: context,
    expectedRevision: expectedRevision,
    mutation: NarrativeEventAuthoringMutation.createDraft,
  );
  if (contextRejection != null) return contextRejection;

  final normalizedName = name.trim();
  if (normalizedName.isEmpty) {
    return NarrativeEventAuthoringResult.rejected(
      status: NarrativeEventAuthoringStatus.rejected,
      mutation: NarrativeEventAuthoringMutation.createDraft,
      registry: context.registryOrNull,
      record: null,
      expectedRevision: expectedRevision,
      code: 'emptyName',
      message: 'Le nom de l’Event doit être renseigné.',
    );
  }

  try {
    narrativeEventCanonicalSha256({'name': normalizedName});
  } on FormatException {
    return NarrativeEventAuthoringResult.rejected(
      status: NarrativeEventAuthoringStatus.rejected,
      mutation: NarrativeEventAuthoringMutation.createDraft,
      registry: context.registryOrNull,
      record: null,
      expectedRevision: expectedRevision,
      code: 'invalidNameEncoding',
      message:
          'Le nom contient des caractères qui ne peuvent pas être enregistrés.',
    );
  }

  if (context.catalog.hasBlockingDiagnostics) {
    return NarrativeEventAuthoringResult.rejected(
      status: NarrativeEventAuthoringStatus.rejected,
      mutation: NarrativeEventAuthoringMutation.createDraft,
      registry: context.registryOrNull,
      record: null,
      expectedRevision: expectedRevision,
      code: 'catalogBlocked',
      message:
          'Le projet contient des références à corriger avant cette création.',
    );
  }

  NarrativeEventAuthoringDiagnostic? sourceDiagnostic;
  if (initialSource != null) {
    final resolution = context.catalog.resolveSource(initialSource);
    if (resolution.status != NarrativeEventProjectResolutionStatus.found) {
      return NarrativeEventAuthoringResult.rejected(
        status: NarrativeEventAuthoringStatus.rejected,
        mutation: NarrativeEventAuthoringMutation.createDraft,
        registry: context.registryOrNull,
        record: null,
        expectedRevision: expectedRevision,
        code: switch (resolution.status) {
          NarrativeEventProjectResolutionStatus.missing => 'sourceMissing',
          NarrativeEventProjectResolutionStatus.unavailable =>
            'sourceUnavailable',
          NarrativeEventProjectResolutionStatus.ambiguous => 'sourceAmbiguous',
          NarrativeEventProjectResolutionStatus.found =>
            throw StateError('A found source cannot be rejected.'),
        },
        message: switch (resolution.status) {
          NarrativeEventProjectResolutionStatus.missing =>
            'La source choisie n’existe plus.',
          NarrativeEventProjectResolutionStatus.unavailable =>
            _unavailableSourceReason(resolution.valueOrNull),
          NarrativeEventProjectResolutionStatus.ambiguous =>
            'La source choisie n’est pas unique.',
          NarrativeEventProjectResolutionStatus.found =>
            throw StateError('A found source cannot be rejected.'),
        },
      );
    }
    sourceDiagnostic = NarrativeEventAuthoringDiagnostic(
      code: 'initialSourceSelected',
      message: _selectedSourceDescription(resolution.valueOrNull),
    );
  }

  final previousRegistry = context.registryOrNull;
  final existingRecords = previousRegistry?.records ?? const [];
  final nextOrderResult = _nextOrder(existingRecords);
  if (nextOrderResult == null) {
    return NarrativeEventAuthoringResult.rejected(
      status: NarrativeEventAuthoringStatus.rejected,
      mutation: NarrativeEventAuthoringMutation.createDraft,
      registry: previousRegistry,
      record: null,
      expectedRevision: expectedRevision,
      code: 'orderOverflow',
      message:
          'Impossible d’ajouter un nouvel événement car la limite du projet est atteinte.',
    );
  }

  late final String eventId;
  try {
    eventId = idGenerator.generate(existingRecords: existingRecords);
  } on Object {
    return NarrativeEventAuthoringResult.rejected(
      status: NarrativeEventAuthoringStatus.rejected,
      mutation: NarrativeEventAuthoringMutation.createDraft,
      registry: previousRegistry,
      record: null,
      expectedRevision: expectedRevision,
      code: 'idGenerationFailed',
      message: 'Impossible de créer un identifiant unique pour cet événement.',
    );
  }

  final draft = NarrativeEventDraft(
    id: eventId,
    name: normalizedName,
    source: initialSource,
    conditions: const [],
    sceneId: null,
    reusePolicy: null,
    priority: 0,
    order: nextOrderResult,
  );
  final record = NarrativeEventRecord.draft(draft);
  final nextRegistry = NarrativeEventRegistry(
    schemaVersion: previousRegistry?.schemaVersion ?? 1,
    mode: previousRegistry?.mode ?? EventSystemMode.legacyOnly,
    records: [...existingRecords, record],
    legacyClaims: previousRegistry?.legacyClaims ?? const [],
  );

  return NarrativeEventAuthoringResult.applied(
    mutation: NarrativeEventAuthoringMutation.createDraft,
    previousRegistry: previousRegistry,
    nextRegistry: nextRegistry,
    previousRecord: null,
    nextRecord: record,
    expectedRevision: expectedRevision,
    diagnostics: [if (sourceDiagnostic != null) sourceDiagnostic],
  );
}

String _selectedSourceDescription(Object? option) {
  return switch (option) {
    NarrativeSpatialEventSourceOption value => value.humanDescription,
    NarrativeOutcomeEventSourceOption value => value.humanSourceSentence,
    _ => 'La source choisie est disponible.',
  };
}

String _unavailableSourceReason(Object? option) {
  return switch (option) {
    NarrativeSpatialEventSourceOption value =>
      value.unavailableReason ?? 'La source choisie n’est pas disponible.',
    NarrativeOutcomeEventSourceOption value =>
      value.unavailableReason ?? 'La source choisie n’est pas disponible.',
    _ => 'La source choisie n’est pas disponible.',
  };
}

int? _nextOrder(List<NarrativeEventRecord> records) {
  if (records.isEmpty) return 0;
  var maximum = records.first.when(
    draft: (draft) => draft.order,
    configured: (definition, _) => definition.order,
  );
  for (var index = 1; index < records.length; index++) {
    final order = records[index].when(
      draft: (draft) => draft.order,
      configured: (definition, _) => definition.order,
    );
    if (order > maximum) maximum = order;
  }
  if (maximum >= narrativeEventMaximumAuthoringOrder) return null;
  final next = maximum + 1;
  final collision = records.any(
    (record) => record.when(
      draft: (draft) => draft.order == next,
      configured: (definition, _) => definition.order == next,
    ),
  );
  return collision ? null : next;
}
