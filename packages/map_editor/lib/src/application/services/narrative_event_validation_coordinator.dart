import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';

enum NarrativeEventValidationNavigationStatus {
  ready,
  staleDestination,
  unavailable,
}

enum NarrativeEventValidationNavigationKind {
  selectEvent,
  openMapSource,
  openScene,
  reviewClaim,
  reviewRegistry,
}

enum NarrativeEventValidationSection { overview, source, scene, claim }

@immutable
final class NarrativeEventIncrementalValidationCache {
  NarrativeEventIncrementalValidationCache({
    required Map<String, String> eventFingerprints,
    required Map<String, List<NarrativeEventValidationDiagnostic>>
        diagnosticsByEvent,
    required List<NarrativeEventValidationDiagnostic> globalDiagnostics,
    required Map<String, Set<String>> dependenciesByEvent,
    required this.globalFingerprint,
  })  : eventFingerprints = Map<String, String>.unmodifiable(eventFingerprints),
        diagnosticsByEvent =
            Map<String, List<NarrativeEventValidationDiagnostic>>.unmodifiable({
          for (final entry in diagnosticsByEvent.entries)
            entry.key: List<NarrativeEventValidationDiagnostic>.unmodifiable(
              entry.value,
            ),
        }),
        globalDiagnostics =
            List<NarrativeEventValidationDiagnostic>.unmodifiable(
          globalDiagnostics,
        ),
        dependenciesByEvent = Map<String, Set<String>>.unmodifiable({
          for (final entry in dependenciesByEvent.entries)
            entry.key: Set<String>.unmodifiable(entry.value),
        });

  final Map<String, String> eventFingerprints;
  final Map<String, List<NarrativeEventValidationDiagnostic>>
      diagnosticsByEvent;
  final List<NarrativeEventValidationDiagnostic> globalDiagnostics;
  final Map<String, Set<String>> dependenciesByEvent;
  final String globalFingerprint;
}

@immutable
final class NarrativeEventIncrementalValidationResult {
  NarrativeEventIncrementalValidationResult({
    required this.report,
    required this.cache,
    required Set<String> recalculatedEventIds,
  }) : recalculatedEventIds = Set<String>.unmodifiable(recalculatedEventIds);

  final NarrativeEventValidationReport report;
  final NarrativeEventIncrementalValidationCache cache;
  final Set<String> recalculatedEventIds;
}

@immutable
final class NarrativeEventValidationNavigationCommand {
  const NarrativeEventValidationNavigationCommand({
    required this.kind,
    required this.section,
    this.eventId,
    this.mapId,
    this.sourceOwnerId,
    this.sceneId,
    this.claimId,
  });

  final NarrativeEventValidationNavigationKind kind;
  final NarrativeEventValidationSection section;
  final String? eventId;
  final String? mapId;
  final String? sourceOwnerId;
  final String? sceneId;
  final String? claimId;

  String? get selectedStableKey => eventId == null ? null : 'v2:$eventId';
}

@immutable
final class NarrativeEventValidationNavigationResult {
  const NarrativeEventValidationNavigationResult._({
    required this.status,
    required this.message,
    this.command,
  });

  const NarrativeEventValidationNavigationResult.ready(
    NarrativeEventValidationNavigationCommand command,
  ) : this._(
          status: NarrativeEventValidationNavigationStatus.ready,
          message: '',
          command: command,
        );

  const NarrativeEventValidationNavigationResult.stale(String message)
      : this._(
          status: NarrativeEventValidationNavigationStatus.staleDestination,
          message: message,
        );

  const NarrativeEventValidationNavigationResult.unavailable(String message)
      : this._(
          status: NarrativeEventValidationNavigationStatus.unavailable,
          message: message,
        );

  final NarrativeEventValidationNavigationStatus status;
  final String message;
  final NarrativeEventValidationNavigationCommand? command;
}

final class NarrativeEventValidationCoordinator {
  const NarrativeEventValidationCoordinator();

  /// Reuses core-produced diagnostics for Events whose attested inputs did not
  /// change, while always invalidating transitive Event dependents.
  ///
  /// The coordinator owns cache policy only: scoped and merged reports still
  /// pass through map_core so the editor cannot introduce a second validator
  /// or a competing diagnostic order.
  NarrativeEventIncrementalValidationResult rebuildIncrementally({
    required NarrativeEventRegistry registry,
    required NarrativeEventProjectCatalog catalog,
    NarrativeEventIncrementalValidationCache? previous,
  }) {
    final recordsById = {
      for (final record in registry.records) record.id: record,
    };
    final catalogDiagnosticsByEvent =
        <String, List<NarrativeEventProjectDiagnostic>>{};
    for (final diagnostic in catalog.diagnostics) {
      final eventId = _eventIdFromDiagnosticPath(diagnostic.path);
      if (eventId == null) continue;
      catalogDiagnosticsByEvent
          .putIfAbsent(eventId, () => <NarrativeEventProjectDiagnostic>[])
          .add(diagnostic);
    }
    for (final diagnostics in catalogDiagnosticsByEvent.values) {
      diagnostics.sort(
        (left, right) => compareNarrativeEventUtf16(
          canonicalizeNarrativeEventJson(left.toDebugJson()),
          canonicalizeNarrativeEventJson(right.toDebugJson()),
        ),
      );
    }
    final catalogEntriesByEvent =
        <String, List<NarrativeEventProjectEventEntry>>{};
    for (final entry in catalog.events) {
      catalogEntriesByEvent
          .putIfAbsent(
            entry.record.id,
            () => <NarrativeEventProjectEventEntry>[],
          )
          .add(entry);
    }
    final claimsByTargetEvent = <String, List<LegacySourceClaim>>{};
    for (final claim in registry.legacyClaims) {
      for (final targetEventId in claim.targetEventIds) {
        claimsByTargetEvent
            .putIfAbsent(targetEventId, () => <LegacySourceClaim>[])
            .add(claim);
      }
    }
    final claimUniverse = registry.legacyClaims.isEmpty
        ? null
        : [for (final claim in registry.legacyClaims) claim.toJson()];
    final currentFingerprints = {
      for (final record in registry.records)
        record.id: _eventValidationFingerprint(
          record,
          catalogDiagnostics: catalogDiagnosticsByEvent[record.id] ?? const [],
          eventEntries: catalogEntriesByEvent[record.id] ?? const [],
          claims: claimsByTargetEvent[record.id] ?? const [],
          claimUniverse: claimUniverse,
        ),
    };
    final currentDependencies = {
      for (final record in registry.records)
        record.id: _recordEventDependencies(record),
    };
    final globalFingerprint = _globalValidationFingerprint(
      registry: registry,
      catalog: catalog,
    );

    if (previous == null) {
      final report = buildNarrativeEventValidationReport(
        registry: registry,
        catalog: catalog,
      );
      final partition = _partitionDiagnostics(
        report.diagnostics,
        eventIds: recordsById.keys.toSet(),
      );
      return NarrativeEventIncrementalValidationResult(
        report: report,
        cache: NarrativeEventIncrementalValidationCache(
          eventFingerprints: currentFingerprints,
          diagnosticsByEvent: partition.byEvent,
          globalDiagnostics: partition.global,
          dependenciesByEvent: currentDependencies,
          globalFingerprint: globalFingerprint,
        ),
        recalculatedEventIds: recordsById.keys.toSet(),
      );
    }

    if (!_sameStringSet(
      previous.eventFingerprints.keys,
      currentFingerprints.keys,
    )) {
      return rebuildIncrementally(registry: registry, catalog: catalog);
    }

    final directlyChanged = <String>{};
    for (final eventId in {
      ...previous.eventFingerprints.keys,
      ...currentFingerprints.keys,
    }) {
      if (previous.eventFingerprints[eventId] != currentFingerprints[eventId]) {
        directlyChanged.add(eventId);
      }
    }
    final invalidated = _withTransitiveDependents(
      directlyChanged,
      currentDependencies: currentDependencies,
      previousDependencies: previous.dependenciesByEvent,
    );
    final recalculatedEventIds =
        invalidated.intersection(recordsById.keys.toSet());

    final recalculatedReport = buildNarrativeEventValidationReportSubset(
      registry: registry,
      catalog: catalog,
      eventIds: recalculatedEventIds,
    );
    final recalculatedPartition = _partitionDiagnostics(
      recalculatedReport.diagnostics,
      eventIds: recalculatedEventIds,
    );
    final diagnosticsByEvent =
        <String, List<NarrativeEventValidationDiagnostic>>{
      for (final eventId in recordsById.keys)
        eventId: recalculatedEventIds.contains(eventId)
            ? recalculatedPartition.byEvent[eventId] ?? const []
            : previous.diagnosticsByEvent[eventId] ?? const [],
    };

    final globalDiagnostics = globalFingerprint == previous.globalFingerprint
        ? previous.globalDiagnostics
        : buildNarrativeEventValidationReportSubset(
            registry: registry,
            catalog: catalog,
            eventIds: const {},
            includeGlobalDiagnostics: true,
          ).diagnostics;
    final report = normalizeNarrativeEventValidationReport([
      ...globalDiagnostics,
      for (final diagnostics in diagnosticsByEvent.values) ...diagnostics,
    ]);

    return NarrativeEventIncrementalValidationResult(
      report: report,
      cache: NarrativeEventIncrementalValidationCache(
        eventFingerprints: currentFingerprints,
        diagnosticsByEvent: diagnosticsByEvent,
        globalDiagnostics: globalDiagnostics,
        dependenciesByEvent: currentDependencies,
        globalFingerprint: globalFingerprint,
      ),
      recalculatedEventIds: recalculatedEventIds,
    );
  }

  NarrativeEventValidationNavigationResult resolve({
    required NarrativeEventValidationDiagnostic diagnostic,
    required NarrativeEventRegistry registry,
    required NarrativeEventProjectCatalog catalog,
  }) {
    final destination = diagnostic.destination;
    final eventId = destination.eventId ?? diagnostic.eventId;
    final record = eventId == null
        ? null
        : registry.records.where((record) => record.id == eventId).firstOrNull;

    switch (destination.kind) {
      case NarrativeEventValidationDestinationKind.unavailable:
        return const NarrativeEventValidationNavigationResult.unavailable(
          'Ce diagnostic ne possède pas de destination ouvrable.',
        );
      case NarrativeEventValidationDestinationKind.registry:
        return const NarrativeEventValidationNavigationResult.ready(
          NarrativeEventValidationNavigationCommand(
            kind: NarrativeEventValidationNavigationKind.reviewRegistry,
            section: NarrativeEventValidationSection.overview,
          ),
        );
      case NarrativeEventValidationDestinationKind.event:
      case NarrativeEventValidationDestinationKind.eventSource:
      case NarrativeEventValidationDestinationKind.eventScene:
        if (record == null) return _staleEvent();
        return NarrativeEventValidationNavigationResult.ready(
          NarrativeEventValidationNavigationCommand(
            kind: NarrativeEventValidationNavigationKind.selectEvent,
            section: switch (destination.kind) {
              NarrativeEventValidationDestinationKind.eventSource =>
                NarrativeEventValidationSection.source,
              NarrativeEventValidationDestinationKind.eventScene =>
                NarrativeEventValidationSection.scene,
              _ => NarrativeEventValidationSection.overview,
            },
            eventId: eventId,
          ),
        );
      case NarrativeEventValidationDestinationKind.mapSource:
        if (record == null) return _staleEvent();
        final source = _recordSource(record);
        if (source == null ||
            catalog.resolveSource(source).status !=
                NarrativeEventProjectResolutionStatus.found ||
            !_matchesSpatialDestination(source, destination)) {
          return const NarrativeEventValidationNavigationResult.stale(
            'L’élément de map ciblé n’existe plus dans le projet courant.',
          );
        }
        return NarrativeEventValidationNavigationResult.ready(
          NarrativeEventValidationNavigationCommand(
            kind: NarrativeEventValidationNavigationKind.openMapSource,
            section: NarrativeEventValidationSection.source,
            eventId: eventId,
            mapId: destination.mapId,
            sourceOwnerId: destination.sourceOwnerId,
          ),
        );
      case NarrativeEventValidationDestinationKind.scene:
        final sceneId = destination.sceneId;
        if (sceneId == null ||
            catalog.resolveScene(sceneId).status !=
                NarrativeEventProjectResolutionStatus.found) {
          return const NarrativeEventValidationNavigationResult.stale(
            'La Scene ciblée n’existe plus dans le projet courant.',
          );
        }
        if (eventId != null && record == null) return _staleEvent();
        return NarrativeEventValidationNavigationResult.ready(
          NarrativeEventValidationNavigationCommand(
            kind: NarrativeEventValidationNavigationKind.openScene,
            section: NarrativeEventValidationSection.scene,
            eventId: eventId,
            sceneId: sceneId,
          ),
        );
      case NarrativeEventValidationDestinationKind.claim:
        final claimId = destination.claimId;
        final exists = claimId != null &&
            registry.legacyClaims.any((claim) => claim.cohortId == claimId);
        if (!exists) {
          return const NarrativeEventValidationNavigationResult.stale(
            'Le lien de migration ciblé n’existe plus.',
          );
        }
        return NarrativeEventValidationNavigationResult.ready(
          NarrativeEventValidationNavigationCommand(
            kind: NarrativeEventValidationNavigationKind.reviewClaim,
            section: NarrativeEventValidationSection.claim,
            eventId: eventId,
            claimId: claimId,
          ),
        );
    }
  }
}

({
  Map<String, List<NarrativeEventValidationDiagnostic>> byEvent,
  List<NarrativeEventValidationDiagnostic> global,
}) _partitionDiagnostics(
  Iterable<NarrativeEventValidationDiagnostic> diagnostics, {
  required Set<String> eventIds,
}) {
  final byEvent = {
    for (final eventId in eventIds)
      eventId: <NarrativeEventValidationDiagnostic>[],
  };
  final global = <NarrativeEventValidationDiagnostic>[];
  for (final diagnostic in diagnostics) {
    final eventId = diagnostic.eventId;
    if (eventId == null || !byEvent.containsKey(eventId)) {
      global.add(diagnostic);
    } else {
      byEvent[eventId]!.add(diagnostic);
    }
  }
  return (byEvent: byEvent, global: global);
}

String _eventValidationFingerprint(
  NarrativeEventRecord record, {
  required List<NarrativeEventProjectDiagnostic> catalogDiagnostics,
  required List<NarrativeEventProjectEventEntry> eventEntries,
  required List<LegacySourceClaim> claims,
  required List<Map<String, dynamic>>? claimUniverse,
}) {
  return narrativeEventCanonicalSha256({
    'record': record.toJson(),
    'catalogDiagnostics': [
      for (final diagnostic in catalogDiagnostics) diagnostic.toDebugJson(),
    ],
    'eventEntries': [for (final entry in eventEntries) entry.toDebugJson()],
    'claims': [for (final claim in claims) claim.toJson()],
    if (claims.isNotEmpty) 'claimUniverse': claimUniverse,
  });
}

String _globalValidationFingerprint({
  required NarrativeEventRegistry registry,
  required NarrativeEventProjectCatalog catalog,
}) {
  return narrativeEventCanonicalSha256({
    'schemaVersion': registry.schemaVersion,
    'mode': registry.mode.name,
    'legacyClaims': [
      for (final claim in registry.legacyClaims) claim.toJson(),
    ],
    'catalogDiagnostics': [
      for (final diagnostic in catalog.diagnostics)
        if (_eventIdFromDiagnosticPath(diagnostic.path) == null)
          diagnostic.toDebugJson(),
    ],
  });
}

Set<String> _recordEventDependencies(NarrativeEventRecord record) {
  final conditions = record.when(
    draft: (draft) => draft.conditions,
    configured: (definition, _) => definition.conditions,
  );
  return {
    for (final condition in conditions)
      ...condition.when(
        fact: (_, __) => const <String>{},
        narrativeEventConsumed: (eventId, _) => {eventId},
      ),
  };
}

Set<String> _withTransitiveDependents(
  Set<String> directlyChanged, {
  required Map<String, Set<String>> currentDependencies,
  required Map<String, Set<String>> previousDependencies,
}) {
  final dependentsByEvent = <String, Set<String>>{};
  for (final dependencies in [currentDependencies, previousDependencies]) {
    for (final entry in dependencies.entries) {
      for (final dependencyId in entry.value) {
        dependentsByEvent
            .putIfAbsent(dependencyId, () => <String>{})
            .add(entry.key);
      }
    }
  }
  final invalidated = {...directlyChanged};
  final pending = [...directlyChanged];
  while (pending.isNotEmpty) {
    final eventId = pending.removeLast();
    for (final dependentId in dependentsByEvent[eventId] ?? const <String>{}) {
      if (invalidated.add(dependentId)) pending.add(dependentId);
    }
  }
  return invalidated;
}

String? _eventIdFromDiagnosticPath(String path) {
  const prefix = 'eventRegistry.records.';
  if (!path.startsWith(prefix)) return null;
  final remainder = path.substring(prefix.length);
  final separator = remainder.indexOf('.');
  return separator < 0 ? remainder : remainder.substring(0, separator);
}

bool _sameStringSet(Iterable<String> left, Iterable<String> right) {
  final leftSet = left.toSet();
  final rightSet = right.toSet();
  return leftSet.length == rightSet.length && leftSet.containsAll(rightSet);
}

NarrativeEventValidationNavigationResult _staleEvent() {
  return const NarrativeEventValidationNavigationResult.stale(
    'L’événement ciblé n’existe plus dans le projet courant.',
  );
}

NarrativeEventSourceRef? _recordSource(NarrativeEventRecord record) {
  return record.when(
    draft: (draft) => draft.source,
    configured: (definition, _) => definition.source,
  );
}

bool _matchesSpatialDestination(
  NarrativeEventSourceRef source,
  NarrativeEventValidationDestination destination,
) {
  return source.when(
    entityInteract: (mapId, entityId) =>
        destination.mapId == mapId && destination.sourceOwnerId == entityId,
    triggerEnter: (mapId, triggerId) =>
        destination.mapId == mapId && destination.sourceOwnerId == triggerId,
    mapEnter: (mapId) =>
        destination.mapId == mapId && destination.sourceOwnerId == null,
    outcomeReceived: (_) => false,
  );
}
