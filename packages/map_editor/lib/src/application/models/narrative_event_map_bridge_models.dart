import 'package:map_core/map_core.dart';

import 'narrative_event_registry_persistence_models.dart';

enum NarrativeEventGroupContextKind { map, global }

/// Exact Event Builder group restored after a Map Editor round trip.
///
/// A spatial group owns one map identity. Global Events deliberately carry no
/// map field so a non-spatial source cannot accidentally acquire a map picker.
final class NarrativeEventGroupContext {
  const NarrativeEventGroupContext.map(this.mapId)
      : kind = NarrativeEventGroupContextKind.map;

  const NarrativeEventGroupContext.global()
      : kind = NarrativeEventGroupContextKind.global,
        mapId = null;

  final NarrativeEventGroupContextKind kind;
  final String? mapId;

  @override
  bool operator ==(Object other) {
    return other is NarrativeEventGroupContext &&
        other.kind == kind &&
        other.mapId == mapId;
  }

  @override
  int get hashCode => Object.hash(kind, mapId);
}

enum NarrativeEventMapNavigationMode { view, choose, create }

final class NarrativeEventMapReturnToken {
  const NarrativeEventMapReturnToken({
    required this.requestId,
    required this.eventId,
    required this.groupContext,
    required this.expectedSource,
  });

  final String requestId;
  final String eventId;
  final NarrativeEventGroupContext groupContext;

  /// Exact source observed before leaving the Event Builder.
  ///
  /// The source is nullable for a future source-creation round trip, but an
  /// owner change on the same map is still a mismatch at return time.
  final NarrativeEventSourceRef? expectedSource;
}

final class NarrativeEventMapFocusRequest {
  const NarrativeEventMapFocusRequest({
    required this.requestId,
    required this.navigation,
    required this.returnToken,
    required this.source,
    required this.mode,
    this.cameraApplied = false,
  });

  final String requestId;
  final NarrativeEventNavigationIntent navigation;
  final NarrativeEventMapReturnToken returnToken;
  final NarrativeEventSourceRef source;
  final NarrativeEventMapNavigationMode mode;
  final bool cameraApplied;

  NarrativeEditorFocusTarget get focusTarget => navigation.focusTarget!;

  NarrativeEventMapFocusRequest markCameraApplied() {
    if (cameraApplied) return this;
    return NarrativeEventMapFocusRequest(
      requestId: requestId,
      navigation: navigation,
      returnToken: returnToken,
      source: source,
      mode: mode,
      cameraApplied: true,
    );
  }
}

enum NarrativeEventMapNavigationStatus {
  ready,
  blockedDirtyMap,
  unavailable,
  sourceMismatch,
  eventMissing,
  activationFailed,
  focusFailed,
}

final class NarrativeEventMapNavigationResult {
  const NarrativeEventMapNavigationResult({
    required this.status,
    required this.message,
    this.navigation,
  });

  final NarrativeEventMapNavigationStatus status;
  final String message;
  final NarrativeEventNavigationIntent? navigation;

  bool get succeeded => status == NarrativeEventMapNavigationStatus.ready;
}

/// Atomic request emitted by the Map Editor for an already existing source.
///
/// The source owns its map and owner identities. No parallel map, layer or
/// coordinate fields are intentionally exposed here.
final class NarrativeEventMapCreationIntent {
  NarrativeEventMapCreationIntent({
    required this.source,
    required String humanName,
  }) : humanName = _humanName(humanName) {
    if (source.kind == NarrativeEventSourceKind.outcomeReceived) {
      throw ArgumentError.value(
        source,
        'source',
        'must be an entity, trigger, or map source',
      );
    }
  }

  final NarrativeEventSourceRef source;
  final String humanName;
}

enum NarrativeEventMapCreationStatus {
  blocked,
  existingLinks,
  committed,
  committedOutOfSync,
  authoringRejected,
  persistenceRejected,
  preflightRejected,
}

final class NarrativeEventMapLinkedEvent {
  const NarrativeEventMapLinkedEvent({
    required this.eventId,
    required this.name,
    required this.order,
    required this.enabled,
  });

  final String eventId;
  final String name;
  final int order;

  /// `null` identifies a draft; configured records carry their active state.
  final bool? enabled;
}

final class NarrativeEventMapCreationResult {
  NarrativeEventMapCreationResult._({
    required this.status,
    required this.code,
    required this.message,
    List<NarrativeEventMapLinkedEvent> linkedEvents = const [],
    this.eventId,
    this.nextRegistry,
    this.previousRegistry,
    this.authoringResult,
    this.persistenceResult,
  }) : linkedEvents = List.unmodifiable(linkedEvents);

  factory NarrativeEventMapCreationResult.blocked({
    required String code,
    required String message,
  }) {
    return NarrativeEventMapCreationResult._(
      status: NarrativeEventMapCreationStatus.blocked,
      code: code,
      message: message,
    );
  }

  factory NarrativeEventMapCreationResult.existingLinks(
    List<NarrativeEventMapLinkedEvent> linkedEvents,
  ) {
    return NarrativeEventMapCreationResult._(
      status: NarrativeEventMapCreationStatus.existingLinks,
      code: 'existingLinks',
      message: linkedEvents.length == 1
          ? 'Un Event utilise déjà cette source.'
          : '${linkedEvents.length} Events utilisent déjà cette source.',
      linkedEvents: linkedEvents,
    );
  }

  factory NarrativeEventMapCreationResult.committed({
    required String eventId,
    required NarrativeEventRegistry nextRegistry,
    required NarrativeEventRegistry? previousRegistry,
    required NarrativeEventAuthoringResult authoringResult,
    required NarrativeEventRegistryPersistenceResult persistenceResult,
  }) {
    return NarrativeEventMapCreationResult._(
      status: NarrativeEventMapCreationStatus.committed,
      code: persistenceResult.code,
      message: persistenceResult.message,
      eventId: eventId,
      nextRegistry: nextRegistry,
      previousRegistry: previousRegistry,
      authoringResult: authoringResult,
      persistenceResult: persistenceResult,
    );
  }

  factory NarrativeEventMapCreationResult.committedOutOfSync(
    NarrativeEventMapCreationResult committed,
  ) {
    if (committed.status != NarrativeEventMapCreationStatus.committed) {
      throw ArgumentError.value(
        committed.status,
        'committed',
        'must be a committed result',
      );
    }
    return NarrativeEventMapCreationResult._(
      status: NarrativeEventMapCreationStatus.committedOutOfSync,
      code: 'committedOutOfSync',
      message: 'L’Event est enregistré sur disque, mais l’éditeur n’est plus '
          'synchronisé. Rechargez le projet avant de continuer.',
      eventId: committed.eventId,
      nextRegistry: committed.nextRegistry,
      previousRegistry: committed.previousRegistry,
      authoringResult: committed.authoringResult,
      persistenceResult: committed.persistenceResult,
    );
  }

  factory NarrativeEventMapCreationResult.authoringRejected(
    NarrativeEventAuthoringResult result,
  ) {
    return NarrativeEventMapCreationResult._(
      status: NarrativeEventMapCreationStatus.authoringRejected,
      code: result.rejectionCode ?? result.status.name,
      message: result.humanReason ??
          'La création de l’Event a été refusée par le projet.',
      authoringResult: result,
    );
  }

  factory NarrativeEventMapCreationResult.persistenceRejected({
    required NarrativeEventAuthoringResult authoringResult,
    required NarrativeEventRegistryPersistenceResult persistenceResult,
  }) {
    return NarrativeEventMapCreationResult._(
      status: NarrativeEventMapCreationStatus.persistenceRejected,
      code: persistenceResult.code,
      message: persistenceResult.message,
      authoringResult: authoringResult,
      persistenceResult: persistenceResult,
    );
  }

  factory NarrativeEventMapCreationResult.persistenceException(
    NarrativeEventAuthoringResult authoringResult,
  ) {
    return NarrativeEventMapCreationResult._(
      status: NarrativeEventMapCreationStatus.persistenceRejected,
      code: 'persistenceException',
      message: 'L’Event n’a pas pu être enregistré. Vérifiez le projet puis '
          'réessayez.',
      authoringResult: authoringResult,
    );
  }

  factory NarrativeEventMapCreationResult.preflightRejected(Object error) {
    return NarrativeEventMapCreationResult._(
      status: NarrativeEventMapCreationStatus.preflightRejected,
      code: 'preflightRejected',
      message: 'La session Event ne peut pas être préparée: $error',
    );
  }

  factory NarrativeEventMapCreationResult.unexpectedBridgeFailure() {
    return NarrativeEventMapCreationResult._(
      status: NarrativeEventMapCreationStatus.preflightRejected,
      code: 'unexpectedBridgeFailure',
      message: 'L’opération Event a été interrompue. Vous pouvez réessayer '
          'sans modifier la map.',
    );
  }

  final NarrativeEventMapCreationStatus status;
  final String code;
  final String message;
  final List<NarrativeEventMapLinkedEvent> linkedEvents;
  final String? eventId;
  final NarrativeEventRegistry? nextRegistry;
  final NarrativeEventRegistry? previousRegistry;
  final NarrativeEventAuthoringResult? authoringResult;
  final NarrativeEventRegistryPersistenceResult? persistenceResult;
}

String _humanName(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, 'humanName', 'must not be empty');
  }
  return normalized;
}
