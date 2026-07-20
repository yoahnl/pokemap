import '../catalogs/narrative_event_project_catalog.dart';
import '../models/game_state.dart';
import '../models/narrative_event_definition.dart';
import '../models/narrative_event_occurrence.dart';
import '../models/narrative_event_progress.dart';
import '../models/narrative_event_registry.dart';
import '../models/narrative_event_source_ref.dart';
import '../models/narrative_fact.dart';
import '../models/narrative_fact_runtime_state.dart';
import '../operations/narrative_event_dispatch_authority.dart';
import '../operations/narrative_event_registry_codec.dart';
import '../operations/narrative_fact_runtime.dart';
import '../read_models/narrative_event_validation_read_model.dart';
import 'narrative_event_authoring_contract.dart';
import 'narrative_event_authoring_support.dart';
import 'narrative_event_configuration_validation.dart';

/// Runs a controlled Event preview through the production dispatch authority.
///
/// The editor owns only the input state. Eligibility, candidate ordering and
/// the final decision remain owned by [NarrativeEventDispatchAuthority].
NarrativeEventSimulationReport simulateNarrativeEventDispatch({
  required EventRegistryDecodeResult registryResult,
  required NarrativeEventProjectCatalog projectCatalog,
  required Iterable<NarrativeFactDefinition> facts,
  required NarrativeEventSimulationInput input,
  ValidatedLegacyClaimIndex? legacyClaimIndex,
}) {
  final registry = registryResult.registryOrNull;
  NarrativeEventRecord? target;
  for (final record in registry?.records ?? const <NarrativeEventRecord>[]) {
    if (record.id == input.targetEventId) {
      target = record;
      break;
    }
  }
  final targetSource = target?.when(
    draft: (draft) => draft.source,
    configured: (definition, _) => definition.source,
  );
  final source = input.source ?? targetSource;
  if (source == null) {
    return NarrativeEventSimulationReport(
      status: NarrativeEventSimulationStatus.sourceMissing,
      targetEventId: input.targetEventId,
      source: null,
      mode: registry?.mode,
      handledEventId: null,
      sceneId: null,
      legacyFallbackAllowed: false,
      reasons: [
        if (target == null) NarrativeEventSimulationReason.eventMissing,
        NarrativeEventSimulationReason.sourceMissing,
      ],
      candidates: [
        if (target != null) _sourceMissingCandidate(target),
      ],
      diagnostics: const [
        'Choisissez une source réelle avant de simuler le dispatch.',
      ],
    );
  }

  final resolver = NarrativeFactRuntimeResolver.fromFacts(facts);
  final preparation = NarrativeEventDispatchAuthority.prepare(
    registryResult: registryResult,
    occurrence: NarrativeEventOccurrence(source: source),
    factResolver: resolver,
    legacyClaimIndex: legacyClaimIndex,
    projectCatalog: projectCatalog,
  );
  if (preparation is NarrativeEventDispatchAuthorityBlocked) {
    return NarrativeEventSimulationReport(
      status: NarrativeEventSimulationStatus.authorityBlocked,
      targetEventId: input.targetEventId,
      source: source,
      mode: registry?.mode,
      handledEventId: null,
      sceneId: null,
      legacyFallbackAllowed: false,
      reasons: const [NarrativeEventSimulationReason.authorityBlocked],
      candidates: const [],
      diagnostics: preparation.diagnostics,
    );
  }

  final gameState = GameState(
    saveId: 'event-builder-simulation',
    narrativeFactRuntimeState: NarrativeFactRuntimeState(
      overridesByFactId: input.factValues,
    ),
    narrativeEventProgress: NarrativeEventProgress(
      consumedNarrativeEventIds: input.consumedNarrativeEventIds,
    ),
  );
  return (preparation as NarrativeEventDispatchAuthorityReady).simulate(
    gameState: gameState,
    targetEventId: input.targetEventId,
    inFlightNarrativeEventIds: input.inFlightNarrativeEventIds,
  );
}

NarrativeEventSimulationCandidateTrace _sourceMissingCandidate(
  NarrativeEventRecord record,
) {
  return record.when(
    draft: (draft) => NarrativeEventSimulationCandidateTrace(
      eventId: draft.id,
      name: draft.name,
      configured: false,
      enabled: false,
      sourceMatches: false,
      reusePolicy: draft.reusePolicy,
      priority: draft.priority,
      order: draft.order,
      selected: false,
      reasons: const [
        NarrativeEventSimulationReason.draft,
        NarrativeEventSimulationReason.sourceMissing,
      ],
      conditions: const [],
    ),
    configured: (definition, enabled) => NarrativeEventSimulationCandidateTrace(
      eventId: definition.id,
      name: definition.name,
      configured: true,
      enabled: enabled,
      sourceMatches: false,
      reusePolicy: definition.reusePolicy,
      priority: definition.priority,
      order: definition.order,
      selected: false,
      reasons: const [NarrativeEventSimulationReason.sourceMissing],
      conditions: const [],
    ),
  );
}

NarrativeEventAuthoringResult renameNarrativeEvent({
  required NarrativeEventAuthoringContext context,
  required String expectedRevision,
  required String eventId,
  required String name,
}) {
  final target = _configurationTarget(
    context: context,
    expectedRevision: expectedRevision,
    eventId: eventId,
    mutation: NarrativeEventAuthoringMutation.rename,
  );
  if (target.rejection != null) return target.rejection!;
  final catalogRejection = _configurationCatalogRejection(target);
  if (catalogRejection != null) return catalogRejection;
  final normalized = name.trim();
  final issue = validateNarrativeEventAuthoringName(name);
  if (issue != null) {
    return _rejectConfiguration(target, issue);
  }
  final current = _EditableNarrativeEvent.fromRecord(target.record!);
  if (current.name == normalized) {
    return _noOpConfiguration(target);
  }
  return _applyConfiguration(
    target,
    current.copyWith(name: normalized).toOriginalState(),
    metadataOnly: true,
  );
}

NarrativeEventAuthoringResult setNarrativeEventConditions({
  required NarrativeEventAuthoringContext context,
  required String expectedRevision,
  required String eventId,
  required List<NarrativeEventCondition> conditions,
}) {
  final target = _configurationTarget(
    context: context,
    expectedRevision: expectedRevision,
    eventId: eventId,
    mutation: NarrativeEventAuthoringMutation.setConditions,
  );
  if (target.rejection != null) return target.rejection!;
  final current = _EditableNarrativeEvent.fromRecord(target.record!);
  final unchanged = _conditionListsEqual(current.conditions, conditions);
  if (!unchanged && current.enabled) {
    return _mustDisableFirst(target, 'modifier ses conditions');
  }
  final issue = validateNarrativeEventAuthoringConditions(
    context: context,
    eventId: eventId,
    conditions: conditions,
  );
  if (issue != null) return _rejectConfiguration(target, issue);
  final nextRecord = unchanged
      ? target.record!
      : current.copyWith(conditions: conditions).toOriginalState();
  final catalogRejection = _configurationCatalogRejection(
    target,
    projectedRecord: nextRecord,
  );
  if (catalogRejection != null) return catalogRejection;
  if (unchanged) return _noOpConfiguration(target);
  return _applyConfiguration(target, nextRecord);
}

NarrativeEventAuthoringResult setNarrativeEventScene({
  required NarrativeEventAuthoringContext context,
  required String expectedRevision,
  required String eventId,
  required String sceneId,
}) {
  final target = _configurationTarget(
    context: context,
    expectedRevision: expectedRevision,
    eventId: eventId,
    mutation: NarrativeEventAuthoringMutation.setScene,
  );
  if (target.rejection != null) return target.rejection!;
  final current = _EditableNarrativeEvent.fromRecord(target.record!);
  final unchanged = current.sceneId == sceneId;
  if (!unchanged && current.enabled) {
    return _mustDisableFirst(target, 'changer sa Scene');
  }
  final issue = validateNarrativeEventAuthoringScene(
    context: context,
    sceneId: sceneId,
  );
  if (issue != null) return _rejectConfiguration(target, issue);
  final nextRecord = unchanged
      ? target.record!
      : current.copyWith(sceneId: sceneId).toOriginalState();
  final catalogRejection = _configurationCatalogRejection(
    target,
    projectedRecord: nextRecord,
  );
  if (catalogRejection != null) return catalogRejection;
  if (unchanged) return _noOpConfiguration(target);
  return _applyConfiguration(target, nextRecord);
}

NarrativeEventAuthoringResult removeNarrativeEventScene({
  required NarrativeEventAuthoringContext context,
  required String expectedRevision,
  required String eventId,
}) {
  final target = _configurationTarget(
    context: context,
    expectedRevision: expectedRevision,
    eventId: eventId,
    mutation: NarrativeEventAuthoringMutation.removeScene,
  );
  if (target.rejection != null) return target.rejection!;
  final current = _EditableNarrativeEvent.fromRecord(target.record!);
  final unchanged = current.sceneId == null;
  if (!unchanged && current.enabled) {
    return _mustDisableFirst(target, 'retirer sa Scene');
  }
  final nextRecord =
      unchanged ? target.record! : current.copyWith(sceneId: null).toDraft();
  final catalogRejection = _configurationCatalogRejection(
    target,
    projectedRecord: nextRecord,
  );
  if (catalogRejection != null) return catalogRejection;
  if (unchanged) return _noOpConfiguration(target);
  return _applyConfiguration(target, nextRecord);
}

NarrativeEventAuthoringResult setNarrativeEventReusePolicy({
  required NarrativeEventAuthoringContext context,
  required String expectedRevision,
  required String eventId,
  required NarrativeEventReusePolicy reusePolicy,
}) {
  final target = _configurationTarget(
    context: context,
    expectedRevision: expectedRevision,
    eventId: eventId,
    mutation: NarrativeEventAuthoringMutation.setReusePolicy,
  );
  if (target.rejection != null) return target.rejection!;
  final catalogRejection = _configurationCatalogRejection(target);
  if (catalogRejection != null) return catalogRejection;
  final current = _EditableNarrativeEvent.fromRecord(target.record!);
  if (current.reusePolicy == reusePolicy) return _noOpConfiguration(target);
  if (current.enabled) {
    return _mustDisableFirst(target, 'changer son comportement');
  }
  return _applyConfiguration(
    target,
    current.copyWith(reusePolicy: reusePolicy).toOriginalState(),
  );
}

NarrativeEventAuthoringResult setNarrativeEventPriority({
  required NarrativeEventAuthoringContext context,
  required String expectedRevision,
  required String eventId,
  required int priority,
}) {
  return _setNarrativeEventInteger(
    context: context,
    expectedRevision: expectedRevision,
    eventId: eventId,
    value: priority,
    mutation: NarrativeEventAuthoringMutation.setPriority,
    nonNegative: false,
    path: 'priority',
  );
}

NarrativeEventAuthoringResult setNarrativeEventOrder({
  required NarrativeEventAuthoringContext context,
  required String expectedRevision,
  required String eventId,
  required int order,
}) {
  return _setNarrativeEventInteger(
    context: context,
    expectedRevision: expectedRevision,
    eventId: eventId,
    value: order,
    mutation: NarrativeEventAuthoringMutation.setOrder,
    nonNegative: true,
    path: 'order',
  );
}

NarrativeEventAuthoringResult _setNarrativeEventInteger({
  required NarrativeEventAuthoringContext context,
  required String expectedRevision,
  required String eventId,
  required int value,
  required NarrativeEventAuthoringMutation mutation,
  required bool nonNegative,
  required String path,
}) {
  final target = _configurationTarget(
    context: context,
    expectedRevision: expectedRevision,
    eventId: eventId,
    mutation: mutation,
  );
  if (target.rejection != null) return target.rejection!;
  final catalogRejection = _configurationCatalogRejection(target);
  if (catalogRejection != null) return catalogRejection;
  final current = _EditableNarrativeEvent.fromRecord(target.record!);
  final currentValue = path == 'priority' ? current.priority : current.order;
  final unchanged = currentValue == value;
  if (!unchanged && current.enabled) {
    return _mustDisableFirst(target, 'changer sa priorité');
  }
  final issue = validateNarrativeEventAuthoringInteger(
    value: value,
    nonNegative: nonNegative,
    path: path,
  );
  if (issue != null) return _rejectConfiguration(target, issue);
  if (unchanged) return _noOpConfiguration(target);
  final next = path == 'priority'
      ? current.copyWith(priority: value)
      : current.copyWith(order: value);
  return _applyConfiguration(target, next.toOriginalState());
}

NarrativeEventAuthoringResult? _configurationCatalogRejection(
  _ConfigurationTarget target, {
  NarrativeEventRecord? projectedRecord,
}) {
  final issue = firstBlockingNarrativeEventCatalogIssue(target.context);
  if (issue != null &&
      projectedRecord != null &&
      narrativeEventRepairStrictlyReducesCatalogErrors(
        context: target.context,
        nextRecord: projectedRecord,
      )) {
    return null;
  }
  return issue == null ? null : _rejectConfiguration(target, issue);
}

_ConfigurationTarget _configurationTarget({
  required NarrativeEventAuthoringContext context,
  required String expectedRevision,
  required String eventId,
  required NarrativeEventAuthoringMutation mutation,
}) {
  final registry = context.registryOrNull;
  final record = findNarrativeEventRecord(registry, eventId);
  final contextRejection = rejectNarrativeEventAuthoringContextIssue(
    context: context,
    expectedRevision: expectedRevision,
    mutation: mutation,
    record: record,
  );
  if (contextRejection != null) {
    return _ConfigurationTarget(
      context: context,
      expectedRevision: expectedRevision,
      mutation: mutation,
      registry: registry,
      record: record,
      rejection: contextRejection,
    );
  }
  final missing = registry == null || record == null
      ? NarrativeEventAuthoringResult.rejected(
          status: NarrativeEventAuthoringStatus.rejected,
          mutation: mutation,
          registry: registry,
          record: record,
          expectedRevision: expectedRevision,
          code: 'eventMissing',
          message: 'L’événement à modifier n’existe pas.',
        )
      : null;
  return _ConfigurationTarget(
    context: context,
    expectedRevision: expectedRevision,
    mutation: mutation,
    registry: registry,
    record: record,
    rejection: missing,
  );
}

NarrativeEventAuthoringResult _mustDisableFirst(
  _ConfigurationTarget target,
  String action,
) {
  return NarrativeEventAuthoringResult.rejected(
    status: NarrativeEventAuthoringStatus.rejected,
    mutation: target.mutation,
    registry: target.registry,
    record: target.record,
    expectedRevision: target.expectedRevision,
    code: 'mustDisableFirst',
    message: 'Désactivez l’événement avant de $action.',
  );
}

NarrativeEventAuthoringResult _rejectConfiguration(
  _ConfigurationTarget target,
  NarrativeEventAuthoringDiagnostic issue,
) {
  return NarrativeEventAuthoringResult.rejected(
    status: NarrativeEventAuthoringStatus.rejected,
    mutation: target.mutation,
    registry: target.registry,
    record: target.record,
    expectedRevision: target.expectedRevision,
    code: issue.code,
    message: issue.message,
    path: issue.path,
  );
}

NarrativeEventAuthoringResult _noOpConfiguration(
  _ConfigurationTarget target,
) {
  return NarrativeEventAuthoringResult.noOp(
    mutation: target.mutation,
    registry: target.registry,
    record: target.record,
    expectedRevision: target.expectedRevision,
  );
}

NarrativeEventAuthoringResult _applyConfiguration(
  _ConfigurationTarget target,
  NarrativeEventRecord nextRecord, {
  bool metadataOnly = false,
  List<NarrativeEventAuthoringDiagnostic> diagnostics = const [],
}) {
  final nextRegistry = replaceNarrativeEventRecord(
    target.registry!,
    nextRecord,
  );
  return NarrativeEventAuthoringResult.applied(
    mutation: target.mutation,
    previousRegistry: target.registry,
    nextRegistry: nextRegistry,
    previousRecord: target.record,
    nextRecord: nextRecord,
    expectedRevision: target.expectedRevision,
    metadataOnly: metadataOnly,
    diagnostics: diagnostics,
  );
}

bool _conditionListsEqual(
  List<NarrativeEventCondition> left,
  List<NarrativeEventCondition> right,
) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

final class _ConfigurationTarget {
  const _ConfigurationTarget({
    required this.context,
    required this.expectedRevision,
    required this.mutation,
    required this.registry,
    required this.record,
    required this.rejection,
  });

  final NarrativeEventAuthoringContext context;
  final String expectedRevision;
  final NarrativeEventAuthoringMutation mutation;
  final NarrativeEventRegistry? registry;
  final NarrativeEventRecord? record;
  final NarrativeEventAuthoringResult? rejection;
}

final class _EditableNarrativeEvent {
  const _EditableNarrativeEvent({
    required this.id,
    required this.name,
    required this.source,
    required this.conditions,
    required this.sceneId,
    required this.reusePolicy,
    required this.priority,
    required this.order,
    required this.configured,
    required this.enabled,
  });

  factory _EditableNarrativeEvent.fromRecord(NarrativeEventRecord record) {
    return record.when(
      draft: (draft) => _EditableNarrativeEvent(
        id: draft.id,
        name: draft.name,
        source: draft.source,
        conditions: draft.conditions,
        sceneId: draft.sceneId,
        reusePolicy: draft.reusePolicy,
        priority: draft.priority,
        order: draft.order,
        configured: false,
        enabled: false,
      ),
      configured: (definition, enabled) => _EditableNarrativeEvent(
        id: definition.id,
        name: definition.name,
        source: definition.source,
        conditions: definition.conditions,
        sceneId: definition.sceneId,
        reusePolicy: definition.reusePolicy,
        priority: definition.priority,
        order: definition.order,
        configured: true,
        enabled: enabled,
      ),
    );
  }

  final String id;
  final String name;
  final NarrativeEventSourceRef? source;
  final List<NarrativeEventCondition> conditions;
  final String? sceneId;
  final NarrativeEventReusePolicy? reusePolicy;
  final int priority;
  final int order;
  final bool configured;
  final bool enabled;

  _EditableNarrativeEvent copyWith({
    String? name,
    List<NarrativeEventCondition>? conditions,
    Object? sceneId = _notSet,
    Object? reusePolicy = _notSet,
    int? priority,
    int? order,
  }) {
    return _EditableNarrativeEvent(
      id: id,
      name: name ?? this.name,
      source: source,
      conditions: List.unmodifiable(conditions ?? this.conditions),
      sceneId: identical(sceneId, _notSet) ? this.sceneId : sceneId as String?,
      reusePolicy: identical(reusePolicy, _notSet)
          ? this.reusePolicy
          : reusePolicy as NarrativeEventReusePolicy?,
      priority: priority ?? this.priority,
      order: order ?? this.order,
      configured: configured,
      enabled: enabled,
    );
  }

  NarrativeEventRecord toOriginalState() {
    if (!configured) return toDraft();
    return NarrativeEventRecord.configuredStructurallyUnchecked(
      NarrativeEventDefinition(
        id: id,
        name: name,
        source: source!,
        conditions: conditions,
        sceneId: sceneId!,
        reusePolicy: reusePolicy!,
        priority: priority,
        order: order,
      ),
      enabled: enabled,
    );
  }

  NarrativeEventRecord toDraft() {
    return NarrativeEventRecord.draft(
      NarrativeEventDraft(
        id: id,
        name: name,
        source: source,
        conditions: conditions,
        sceneId: sceneId,
        reusePolicy: reusePolicy,
        priority: priority,
        order: order,
      ),
    );
  }
}

const Object _notSet = Object();
