import '../catalogs/narrative_event_project_catalog.dart';
import '../models/narrative_event_definition.dart';
import '../models/narrative_event_registry.dart';
import '../models/narrative_event_source_ref.dart';
import '../read_models/narrative_event_validation_read_model.dart';
import 'narrative_event_canonical_json.dart';
import 'narrative_event_registry_codec.dart';

NarrativeEventValidationReport buildNarrativeEventValidationReport({
  required NarrativeEventRegistry registry,
  required NarrativeEventProjectCatalog catalog,
}) {
  return _buildNarrativeEventValidationReport(
    registry: registry,
    catalog: catalog,
  );
}

/// Reuses the canonical validation rules for a bounded Event subset.
///
/// This is intended for application-layer incremental caches. Passing an
/// empty [eventIds] set with [includeGlobalDiagnostics] enabled rebuilds only
/// registry-wide diagnostics.
NarrativeEventValidationReport buildNarrativeEventValidationReportSubset({
  required NarrativeEventRegistry registry,
  required NarrativeEventProjectCatalog catalog,
  required Set<String> eventIds,
  bool includeGlobalDiagnostics = false,
}) {
  return _buildNarrativeEventValidationReport(
    registry: registry,
    catalog: catalog,
    eventIds: eventIds,
    includeGlobalDiagnostics: includeGlobalDiagnostics,
  );
}

/// Applies the canonical deduplication and ordering to cached diagnostics.
NarrativeEventValidationReport normalizeNarrativeEventValidationReport(
  Iterable<NarrativeEventValidationDiagnostic> diagnostics,
) {
  final uniqueByKey = <String, NarrativeEventValidationDiagnostic>{};
  for (final diagnostic in diagnostics) {
    uniqueByKey.putIfAbsent(diagnostic.stableKey, () => diagnostic);
  }
  final sorted = uniqueByKey.values.toList()..sort(_compareDiagnostics);
  return NarrativeEventValidationReport(diagnostics: sorted);
}

NarrativeEventValidationReport _buildNarrativeEventValidationReport({
  required NarrativeEventRegistry registry,
  required NarrativeEventProjectCatalog catalog,
  Set<String>? eventIds,
  bool includeGlobalDiagnostics = true,
}) {
  final recordsById = {
    for (final record in registry.records) record.id: record,
  };
  final diagnostics = <NarrativeEventValidationDiagnostic>[];

  for (final diagnostic in catalog.diagnostics) {
    final eventId = _eventIdFromPath(diagnostic.path);
    if (!_includesDiagnostic(
      eventId,
      eventIds: eventIds,
      includeGlobalDiagnostics: includeGlobalDiagnostics,
    )) {
      continue;
    }
    diagnostics.add(
      _fromProjectDiagnostic(
        diagnostic,
        recordsById: recordsById,
      ),
    );
  }

  for (final record in registry.records) {
    if (eventIds != null && !eventIds.contains(record.id)) continue;
    final draft = record.draftOrNull;
    if (draft != null && draft.source == null) {
      diagnostics.add(
        NarrativeEventValidationDiagnostic(
          code: 'narrativeEventSourceMissing',
          severity: NarrativeEventValidationSeverity.error,
          eventId: record.id,
          path: 'eventRegistry.records.${record.id}.source',
          message: 'Cet Event ne possède pas encore de déclencheur.',
          action: NarrativeEventValidationAction.chooseSource,
          destination: NarrativeEventValidationDestination(
            kind: NarrativeEventValidationDestinationKind.eventSource,
            eventId: record.id,
          ),
        ),
      );
    }
  }

  final claimDiagnostics = <NarrativeEventValidationDiagnostic>[];
  _appendClaimDiagnostics(registry, claimDiagnostics);
  diagnostics.addAll(
    claimDiagnostics.where(
      (diagnostic) => _includesDiagnostic(
        diagnostic.eventId,
        eventIds: eventIds,
        includeGlobalDiagnostics: includeGlobalDiagnostics,
      ),
    ),
  );

  return normalizeNarrativeEventValidationReport(diagnostics);
}

bool _includesDiagnostic(
  String? eventId, {
  required Set<String>? eventIds,
  required bool includeGlobalDiagnostics,
}) {
  if (eventId == null) return includeGlobalDiagnostics;
  return eventIds == null || eventIds.contains(eventId);
}

NarrativeEventValidationDiagnostic _fromProjectDiagnostic(
  NarrativeEventProjectDiagnostic diagnostic, {
  required Map<String, NarrativeEventRecord> recordsById,
}) {
  final eventId = _eventIdFromPath(diagnostic.path);
  final record = eventId == null ? null : recordsById[eventId];
  final severity = switch (diagnostic.severity) {
    NarrativeEventProjectDiagnosticSeverity.info =>
      NarrativeEventValidationSeverity.info,
    NarrativeEventProjectDiagnosticSeverity.warning =>
      NarrativeEventValidationSeverity.warning,
    NarrativeEventProjectDiagnosticSeverity.error =>
      NarrativeEventValidationSeverity.error,
  };

  if (eventId != null && diagnostic.path.endsWith('.source')) {
    final source = _recordSource(record);
    final sourceIdentity = _sourceIdentity(source);
    return NarrativeEventValidationDiagnostic(
      code: diagnostic.code,
      severity: severity,
      eventId: eventId,
      path: diagnostic.path,
      message: diagnostic.message,
      action: NarrativeEventValidationAction.chooseSource,
      destination: NarrativeEventValidationDestination(
        kind: NarrativeEventValidationDestinationKind.eventSource,
        eventId: eventId,
        mapId: sourceIdentity?.mapId,
        sourceOwnerId: sourceIdentity?.ownerId,
      ),
    );
  }

  if (eventId != null && diagnostic.path.endsWith('.sceneId')) {
    final sceneId = _recordSceneId(record);
    return NarrativeEventValidationDiagnostic(
      code: diagnostic.code,
      severity: severity,
      eventId: eventId,
      path: diagnostic.path,
      message: diagnostic.message,
      action: NarrativeEventValidationAction.chooseScene,
      destination:
          sceneId == null || diagnostic.code == 'narrativeEventSceneMissing'
              ? NarrativeEventValidationDestination(
                  kind: NarrativeEventValidationDestinationKind.eventScene,
                  eventId: eventId,
                )
              : NarrativeEventValidationDestination(
                  kind: NarrativeEventValidationDestinationKind.scene,
                  eventId: eventId,
                  sceneId: sceneId,
                ),
    );
  }

  if (eventId != null) {
    return NarrativeEventValidationDiagnostic(
      code: diagnostic.code,
      severity: severity,
      eventId: eventId,
      path: diagnostic.path,
      message: diagnostic.message,
      action: NarrativeEventValidationAction.openEvent,
      destination: NarrativeEventValidationDestination(
        kind: NarrativeEventValidationDestinationKind.event,
        eventId: eventId,
      ),
    );
  }

  return NarrativeEventValidationDiagnostic(
    code: diagnostic.code,
    severity: severity,
    path: diagnostic.path,
    message: diagnostic.message,
    action: NarrativeEventValidationAction.reviewRegistry,
    destination: NarrativeEventValidationDestination(
      kind: NarrativeEventValidationDestinationKind.registry,
    ),
  );
}

void _appendClaimDiagnostics(
  NarrativeEventRegistry registry,
  List<NarrativeEventValidationDiagnostic> diagnostics,
) {
  if (registry.legacyClaims.isEmpty) return;
  final claimIndex = buildValidatedLegacyClaimIndex(registry);

  if (claimIndex.globalConflicts.isNotEmpty) {
    for (var index = 0; index < claimIndex.globalConflicts.length; index++) {
      diagnostics.add(
        NarrativeEventValidationDiagnostic(
          code: 'legacyClaimGlobalConflict',
          severity: NarrativeEventValidationSeverity.error,
          path: 'eventRegistry.legacyClaims',
          message: claimIndex.globalConflicts[index],
          action: NarrativeEventValidationAction.reviewRegistry,
          destination: NarrativeEventValidationDestination(
            kind: NarrativeEventValidationDestinationKind.registry,
          ),
        ),
      );
    }
    return;
  }

  for (final claim in registry.legacyClaims) {
    final resolution = claimIndex.inspectSourceStructure(claim.source);
    for (final issue in resolution.diagnostics) {
      diagnostics.add(
        NarrativeEventValidationDiagnostic(
          code: 'legacyClaim${_upperFirst(issue.code.code)}',
          severity: NarrativeEventValidationSeverity.error,
          eventId: issue.targetEventId,
          path: 'eventRegistry.legacyClaims.${claim.cohortId}',
          message: issue.message,
          action: NarrativeEventValidationAction.reviewClaim,
          destination: NarrativeEventValidationDestination(
            kind: NarrativeEventValidationDestinationKind.claim,
            eventId: issue.targetEventId,
            claimId: claim.cohortId,
          ),
        ),
      );
    }
  }
}

String? _eventIdFromPath(String path) {
  const prefix = 'eventRegistry.records.';
  if (!path.startsWith(prefix)) return null;
  final remainder = path.substring(prefix.length);
  final separator = remainder.indexOf('.');
  return separator < 0 ? remainder : remainder.substring(0, separator);
}

NarrativeEventSourceRef? _recordSource(NarrativeEventRecord? record) {
  return record?.when(
    draft: (draft) => draft.source,
    configured: (definition, _) => definition.source,
  );
}

String? _recordSceneId(NarrativeEventRecord? record) {
  return record?.when(
    draft: (draft) => draft.sceneId,
    configured: (definition, _) => definition.sceneId,
  );
}

({String? mapId, String? ownerId})? _sourceIdentity(
  NarrativeEventSourceRef? source,
) {
  return source?.when(
    entityInteract: (mapId, entityId) => (mapId: mapId, ownerId: entityId),
    triggerEnter: (mapId, triggerId) => (mapId: mapId, ownerId: triggerId),
    mapEnter: (mapId) => (mapId: mapId, ownerId: null),
    outcomeReceived: (_) => (mapId: null, ownerId: null),
  );
}

int _compareDiagnostics(
  NarrativeEventValidationDiagnostic left,
  NarrativeEventValidationDiagnostic right,
) {
  final severity = right.severity.index.compareTo(left.severity.index);
  if (severity != 0) return severity;
  for (final pair in <(String, String)>[
    (left.eventId ?? '', right.eventId ?? ''),
    (left.path, right.path),
    (left.code, right.code),
    (left.action.name, right.action.name),
    (left.message, right.message),
    (left.destination.stableKey, right.destination.stableKey),
  ]) {
    final comparison = compareNarrativeEventUtf16(pair.$1, pair.$2);
    if (comparison != 0) return comparison;
  }
  return 0;
}

String _upperFirst(String value) =>
    '${value.substring(0, 1).toUpperCase()}${value.substring(1)}';
