import '../catalogs/narrative_event_project_catalog.dart';
import '../models/narrative_event_definition.dart';
import '../models/narrative_event_occurrence.dart';
import '../models/narrative_event_registry.dart';
import '../models/narrative_event_source_ref.dart';
import '../read_models/narrative_event_reachability_report.dart';
import '../read_models/narrative_event_source_index.dart';
import '../read_models/narrative_event_validation_read_model.dart';
import 'narrative_event_canonical_json.dart';
import 'narrative_event_dispatch_authority.dart';
import 'narrative_event_registry_codec.dart';

NarrativeEventReachabilityReport buildNarrativeEventReachabilityReport({
  required NarrativeEventRegistry registry,
  required NarrativeEventProjectCatalog catalog,
  NarrativeEventReachabilityRuntimeSnapshot runtime =
      const NarrativeEventReachabilityRuntimeSnapshot.unknown(),
}) {
  final sourceIndexResult = buildNarrativeEventSourceIndex(registry.records);
  final claimIndex = buildValidatedLegacyClaimIndex(registry);
  final sourcesByKey = <String, NarrativeEventSourceRef>{};
  for (final record in registry.records) {
    final source = _recordSource(record);
    if (source != null) sourcesByKey[_sourceKey(source)] = source;
  }
  for (final claim in registry.legacyClaims) {
    sourcesByKey[_sourceKey(claim.source)] = claim.source;
  }

  final diagnostics = <NarrativeEventValidationDiagnostic>[];
  final reports = <NarrativeEventSourceReachability>[];
  final sortedSources = sourcesByKey.entries.toList()
    ..sort((left, right) => left.key.compareTo(right.key));
  for (final entry in sortedSources) {
    final source = entry.value;
    final orderedRecords = sourceIndexResult.index.recordsFor(source);
    final allRecords = registry.records
        .where((record) => _recordSource(record) == source)
        .toList()
      ..sort((left, right) => compareNarrativeEventUtf16(left.id, right.id));
    final disabledIds = <String>[
      for (final record in allRecords)
        if (record.definitionOrNull != null && record.enabledOrNull != true)
          record.id,
    ];
    final draftIds = <String>[
      for (final record in allRecords)
        if (record.draftOrNull != null) record.id,
    ];
    final sourceConflicts = sourceIndexResult.conflicts
        .where((conflict) => conflict.source == source)
        .toList();
    final claimResolution = claimIndex.inspectSourceStructure(source);
    final claims = claimResolution is LegacyClaimSourceValid
        ? <LegacySourceClaim>[claimResolution.claim]
        : <LegacySourceClaim>[];
    final claimedTargetIds = <String>{
      for (final claim in claims) ...claim.targetEventIds,
    }.toList()
      ..sort(compareNarrativeEventUtf16);

    for (final conflict in sourceConflicts) {
      for (final record in conflict.records) {
        diagnostics.add(
          NarrativeEventValidationDiagnostic(
            code: 'sourceOrderingConflict',
            severity: NarrativeEventValidationSeverity.error,
            eventId: record.id,
            path: 'eventRegistry.sources.${entry.key}',
            message: conflict.diagnostic,
            action: _sourceAction(source),
            destination: _sourceDestination(source, record.id),
          ),
        );
      }
    }
    for (final claim in claims) {
      diagnostics.add(
        NarrativeEventValidationDiagnostic(
          code: 'sourceClaimedByV2',
          severity: NarrativeEventValidationSeverity.info,
          eventId: claim.targetEventIds.first,
          path: 'eventRegistry.legacyClaims.${claim.cohortId}',
          message: 'Cette source legacy est revendiquée par Event V2.',
          action: NarrativeEventValidationAction.reviewClaim,
          destination: NarrativeEventValidationDestination(
            kind: NarrativeEventValidationDestinationKind.claim,
            claimId: claim.cohortId,
            eventId: claim.targetEventIds.first,
          ),
        ),
      );
    }

    if (!runtime.isComplete) {
      final hasEnabledCandidates = orderedRecords.isNotEmpty;
      if (hasEnabledCandidates) {
        final eventId = orderedRecords.first.id;
        diagnostics.add(
          NarrativeEventValidationDiagnostic(
            code: 'runtimeUnknown',
            severity: NarrativeEventValidationSeverity.warning,
            eventId: eventId,
            path: 'eventRegistry.sources.${entry.key}.runtime',
            message:
                'L’état runtime est inconnu; l’atteignabilité finale ne peut pas être affirmée.',
            action: _sourceAction(source),
            destination: _sourceDestination(source, eventId),
          ),
        );
      }
      reports.add(
        NarrativeEventSourceReachability(
          source: source,
          orderedEventIds: [for (final record in orderedRecords) record.id],
          disabledEventIds: disabledIds,
          draftEventIds: draftIds,
          claimedTargetEventIds: claimedTargetIds,
          hasOrderingConflict: sourceConflicts.isNotEmpty,
          status: hasEnabledCandidates
              ? NarrativeEventReachabilityStatus.runtimeUnknown
              : NarrativeEventReachabilityStatus.unreachable,
          reasons: hasEnabledCandidates
              ? const ['runtimeUnknown']
              : [
                  if (disabledIds.isNotEmpty) 'disabled',
                  if (draftIds.isNotEmpty) 'draft',
                  'noEligibleCandidate',
                ],
        ),
      );
      continue;
    }

    final preparation = NarrativeEventDispatchAuthority.prepare(
      registryResult: EventRegistryDecodeResult.decoded(registry),
      occurrence: NarrativeEventOccurrence(source: source),
      factResolver: runtime.factResolver!,
      legacyClaimIndex: runtime.claimIndex,
      projectCatalog: catalog,
    );
    if (preparation is NarrativeEventDispatchAuthorityBlocked) {
      final reasons = <String>[
        'authorityBlocked:${preparation.reason.name}',
        ...preparation.diagnostics,
      ];
      diagnostics.add(
        NarrativeEventValidationDiagnostic(
          code: 'dispatchAuthorityBlocked',
          severity: NarrativeEventValidationSeverity.warning,
          eventId: allRecords.isEmpty ? null : allRecords.first.id,
          path: 'eventRegistry.sources.${entry.key}.runtime',
          message: reasons.join(' '),
          action: allRecords.isEmpty
              ? NarrativeEventValidationAction.reviewRegistry
              : _sourceAction(source),
          destination: allRecords.isEmpty
              ? NarrativeEventValidationDestination(
                  kind: NarrativeEventValidationDestinationKind.registry,
                )
              : _sourceDestination(source, allRecords.first.id),
        ),
      );
      reports.add(
        NarrativeEventSourceReachability(
          source: source,
          orderedEventIds: [for (final record in orderedRecords) record.id],
          disabledEventIds: disabledIds,
          draftEventIds: draftIds,
          claimedTargetEventIds: claimedTargetIds,
          hasOrderingConflict: sourceConflicts.isNotEmpty,
          status: NarrativeEventReachabilityStatus.blocked,
          reasons: reasons,
        ),
      );
      continue;
    }

    final decision = (preparation as NarrativeEventDispatchAuthorityReady).plan(
      gameState: runtime.gameState!,
      inFlightNarrativeEventIds: runtime.inFlightNarrativeEventIds,
    );
    final handled = decision is NarrativeEventDispatchHandled;
    final reasons = [for (final reason in decision.reasons) reason.name];
    reports.add(
      NarrativeEventSourceReachability(
        source: source,
        orderedEventIds: [for (final record in orderedRecords) record.id],
        disabledEventIds: disabledIds,
        draftEventIds: draftIds,
        claimedTargetEventIds: claimedTargetIds,
        hasOrderingConflict: sourceConflicts.isNotEmpty,
        status: handled
            ? NarrativeEventReachabilityStatus.reachable
            : NarrativeEventReachabilityStatus.unreachable,
        reasons: reasons,
        selectedEventId: handled ? decision.eventId : null,
      ),
    );
  }

  diagnostics.sort((left, right) {
    final severity = right.severity.index.compareTo(left.severity.index);
    if (severity != 0) return severity;
    return left.stableKey.compareTo(right.stableKey);
  });
  return NarrativeEventReachabilityReport(
    sources: reports,
    diagnostics: diagnostics,
  );
}

NarrativeEventSourceRef? _recordSource(NarrativeEventRecord record) {
  return record.when(
    draft: (draft) => draft.source,
    configured: (definition, _) => definition.source,
  );
}

String _sourceKey(NarrativeEventSourceRef source) =>
    canonicalizeNarrativeEventJson(source.toJson());

String? _mapId(NarrativeEventSourceRef source) => source.when(
      entityInteract: (mapId, _) => mapId,
      triggerEnter: (mapId, _) => mapId,
      mapEnter: (mapId) => mapId,
      outcomeReceived: (_) => null,
    );

String? _ownerId(NarrativeEventSourceRef source) => source.when(
      entityInteract: (_, entityId) => entityId,
      triggerEnter: (_, triggerId) => triggerId,
      mapEnter: (_) => null,
      outcomeReceived: (_) => null,
    );

NarrativeEventValidationAction _sourceAction(NarrativeEventSourceRef source) {
  return source.kind == NarrativeEventSourceKind.outcomeReceived
      ? NarrativeEventValidationAction.openEvent
      : NarrativeEventValidationAction.openMapSource;
}

NarrativeEventValidationDestination _sourceDestination(
  NarrativeEventSourceRef source,
  String eventId,
) {
  if (source.kind == NarrativeEventSourceKind.outcomeReceived) {
    return NarrativeEventValidationDestination(
      kind: NarrativeEventValidationDestinationKind.eventSource,
      eventId: eventId,
    );
  }
  return NarrativeEventValidationDestination(
    kind: NarrativeEventValidationDestinationKind.mapSource,
    eventId: eventId,
    mapId: _mapId(source),
    sourceOwnerId: _ownerId(source),
  );
}
