import 'package:meta/meta.dart' show immutable;

enum NarrativeEventValidationSeverity { info, warning, error }

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
