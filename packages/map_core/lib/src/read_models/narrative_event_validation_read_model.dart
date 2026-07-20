import 'package:meta/meta.dart' show immutable;

import '../models/narrative_event_definition.dart';
import '../models/narrative_event_registry.dart';
import '../models/narrative_event_source_ref.dart';

enum NarrativeEventValidationSeverity { info, warning, error }

/// Closed result space for the Event Builder simulator.
///
/// This read model deliberately mirrors the canonical dispatch decision rather
/// than introducing editor-only eligibility semantics.
enum NarrativeEventSimulationStatus {
  sourceMissing,
  authorityBlocked,
  handled,
  claimedButIneligible,
  noMatch,
}

enum NarrativeEventSimulationReason {
  sourceMissing,
  eventMissing,
  authorityBlocked,
  draft,
  disabled,
  sourceMismatch,
  factConditionFalse,
  narrativeEventConsumedConditionFalse,
  eventConsumed,
  eventInFlight,
  claimTombstone,
  claimTargetsIneligible,
  noEligibleCandidate,
  runtimeReferenceUnavailable,
}

enum NarrativeEventSimulationConditionKind { fact, narrativeEventConsumed }

@immutable
final class NarrativeEventSimulationInput {
  NarrativeEventSimulationInput({
    required String targetEventId,
    this.source,
    Map<String, bool> factValues = const {},
    Set<String> consumedNarrativeEventIds = const {},
    Set<String> inFlightNarrativeEventIds = const {},
  })  : targetEventId = _identity(targetEventId, 'targetEventId'),
        factValues = Map.unmodifiable(factValues),
        consumedNarrativeEventIds = Set.unmodifiable(consumedNarrativeEventIds),
        inFlightNarrativeEventIds = Set.unmodifiable(inFlightNarrativeEventIds);

  final String targetEventId;
  final NarrativeEventSourceRef? source;
  final Map<String, bool> factValues;
  final Set<String> consumedNarrativeEventIds;
  final Set<String> inFlightNarrativeEventIds;
}

@immutable
final class NarrativeEventSimulationConditionTrace {
  NarrativeEventSimulationConditionTrace({
    required this.index,
    required this.kind,
    required String targetId,
    required this.expectedValue,
    required this.actualValue,
    required this.passed,
    required this.reason,
  }) : targetId = _identity(targetId, 'targetId');

  final int index;
  final NarrativeEventSimulationConditionKind kind;
  final String targetId;
  final bool expectedValue;
  final bool? actualValue;
  final bool passed;
  final NarrativeEventSimulationReason? reason;
}

@immutable
final class NarrativeEventSimulationCandidateTrace {
  NarrativeEventSimulationCandidateTrace({
    required String eventId,
    required String name,
    required this.configured,
    required this.enabled,
    required this.sourceMatches,
    required this.reusePolicy,
    required this.priority,
    required this.order,
    required this.selected,
    required List<NarrativeEventSimulationReason> reasons,
    required List<NarrativeEventSimulationConditionTrace> conditions,
  })  : eventId = _identity(eventId, 'eventId'),
        name = _identity(name, 'name'),
        reasons = List.unmodifiable(reasons),
        conditions = List.unmodifiable(conditions);

  final String eventId;
  final String name;
  final bool configured;
  final bool enabled;
  final bool sourceMatches;
  final NarrativeEventReusePolicy? reusePolicy;
  final int priority;
  final int order;
  final bool selected;
  final List<NarrativeEventSimulationReason> reasons;
  final List<NarrativeEventSimulationConditionTrace> conditions;

  bool get eligible =>
      configured && enabled && sourceMatches && reasons.isEmpty;
}

@immutable
final class NarrativeEventSimulationReport {
  NarrativeEventSimulationReport({
    required this.status,
    required this.targetEventId,
    required this.source,
    required this.mode,
    required this.handledEventId,
    required this.sceneId,
    required this.legacyFallbackAllowed,
    required List<NarrativeEventSimulationReason> reasons,
    required List<NarrativeEventSimulationCandidateTrace> candidates,
    required List<String> diagnostics,
  })  : reasons = List.unmodifiable(reasons),
        candidates = List.unmodifiable(candidates),
        diagnostics = List.unmodifiable(diagnostics);

  final NarrativeEventSimulationStatus status;
  final String targetEventId;
  final NarrativeEventSourceRef? source;
  final EventSystemMode? mode;
  final String? handledEventId;
  final String? sceneId;
  final bool legacyFallbackAllowed;
  final List<NarrativeEventSimulationReason> reasons;
  final List<NarrativeEventSimulationCandidateTrace> candidates;
  final List<String> diagnostics;

  NarrativeEventSimulationCandidateTrace? get targetCandidate {
    for (final candidate in candidates) {
      if (candidate.eventId == targetEventId) return candidate;
    }
    return null;
  }
}

enum NarrativeEventValidationAction {
  none,
  openEvent,
  chooseSource,
  openMapSource,
  chooseScene,
  reviewClaim,
  reviewRegistry,
}

enum NarrativeEventValidationDestinationKind {
  unavailable,
  registry,
  event,
  eventSource,
  eventScene,
  mapSource,
  scene,
  claim,
}

@immutable
final class NarrativeEventValidationDestination {
  NarrativeEventValidationDestination({
    required this.kind,
    this.eventId,
    this.mapId,
    this.sourceOwnerId,
    this.sceneId,
    this.claimId,
  }) {
    if (kind == NarrativeEventValidationDestinationKind.event &&
        eventId == null) {
      throw ArgumentError('An Event destination requires eventId.');
    }
    if (kind == NarrativeEventValidationDestinationKind.eventSource &&
        eventId == null) {
      throw ArgumentError('An Event source destination requires eventId.');
    }
    if (kind == NarrativeEventValidationDestinationKind.eventScene &&
        eventId == null) {
      throw ArgumentError('An Event Scene destination requires eventId.');
    }
    if (kind == NarrativeEventValidationDestinationKind.mapSource &&
        mapId == null) {
      throw ArgumentError('A map source destination requires mapId.');
    }
    if (kind == NarrativeEventValidationDestinationKind.scene &&
        sceneId == null) {
      throw ArgumentError('A Scene destination requires sceneId.');
    }
    if (kind == NarrativeEventValidationDestinationKind.claim &&
        claimId == null) {
      throw ArgumentError('A claim destination requires claimId.');
    }
  }

  final NarrativeEventValidationDestinationKind kind;
  final String? eventId;
  final String? mapId;
  final String? sourceOwnerId;
  final String? sceneId;
  final String? claimId;

  String get stableKey => <String?>[
        kind.name,
        eventId,
        mapId,
        sourceOwnerId,
        sceneId,
        claimId,
      ].map((value) => value ?? '').join('\u001f');

  Map<String, Object?> toDebugJson() => {
        'kind': kind.name,
        if (eventId != null) 'eventId': eventId,
        if (mapId != null) 'mapId': mapId,
        if (sourceOwnerId != null) 'sourceOwnerId': sourceOwnerId,
        if (sceneId != null) 'sceneId': sceneId,
        if (claimId != null) 'claimId': claimId,
      };
}

@immutable
final class NarrativeEventValidationDiagnostic {
  NarrativeEventValidationDiagnostic({
    required String code,
    required this.severity,
    required String path,
    required String message,
    required this.action,
    required this.destination,
    this.eventId,
  })  : code = _identity(code, 'code'),
        path = _identity(path, 'path'),
        message = _identity(message, 'message');

  final String code;
  final NarrativeEventValidationSeverity severity;
  final String? eventId;
  final String path;
  final String message;
  final NarrativeEventValidationAction action;
  final NarrativeEventValidationDestination destination;

  String get stableKey => <String?>[
        severity.name,
        eventId,
        path,
        code,
        action.name,
        message,
        destination.stableKey,
      ].map((value) => value ?? '').join('\u001e');

  Map<String, Object?> toDebugJson() => {
        'stableKey': stableKey,
        'code': code,
        'severity': severity.name,
        if (eventId != null) 'eventId': eventId,
        'path': path,
        'message': message,
        'action': action.name,
        'destination': destination.toDebugJson(),
      };
}

@immutable
final class NarrativeEventValidationReport {
  NarrativeEventValidationReport({
    required List<NarrativeEventValidationDiagnostic> diagnostics,
  }) : diagnostics = List.unmodifiable(diagnostics);

  final List<NarrativeEventValidationDiagnostic> diagnostics;

  int get errorCount => diagnostics
      .where(
        (diagnostic) =>
            diagnostic.severity == NarrativeEventValidationSeverity.error,
      )
      .length;

  int get warningCount => diagnostics
      .where(
        (diagnostic) =>
            diagnostic.severity == NarrativeEventValidationSeverity.warning,
      )
      .length;

  bool get hasBlockingDiagnostics => errorCount != 0;

  Map<String, Object?> toDebugJson() => {
        'errorCount': errorCount,
        'warningCount': warningCount,
        'diagnostics': [
          for (final diagnostic in diagnostics) diagnostic.toDebugJson(),
        ],
      };
}

String _identity(String value, String name) {
  if (value.isEmpty || value.trim() != value) {
    throw ArgumentError.value(value, name, 'must be non-empty and trimmed');
  }
  return value;
}
