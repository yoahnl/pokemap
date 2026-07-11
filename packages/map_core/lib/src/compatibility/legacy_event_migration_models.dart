import 'package:meta/meta.dart' show immutable;

import '../models/narrative_event_registry.dart';

enum LegacyMigrationClassification {
  autoSafe,
  assisted,
  blocked,
  unsupported,
  legacyOnly,
}

enum LegacyProjectionClaimStatus { absent, valid, invalid }

enum LegacyMigrationDiagnosticSeverity { info, warning, error }

enum LegacyEventReferenceKind {
  consumedEventState,
  scriptCondition,
  worldRuleSource,
  worldRuleTarget,
  sceneConsequence,
  scenarioNodeBinding,
  scriptCommand,
  metadata,
  validatorDiagnostic,
}

@immutable
final class LegacyMigrationDiagnostic {
  LegacyMigrationDiagnostic({
    required String code,
    required this.severity,
    required String message,
    required String path,
  })  : code = _nonEmpty(code, 'code'),
        message = _nonEmpty(message, 'message'),
        path = _nonEmpty(path, 'path');

  final String code;
  final LegacyMigrationDiagnosticSeverity severity;
  final String message;
  final String path;

  Map<String, Object?> toJson() => {
        'code': code,
        'severity': severity.name,
        'message': message,
        'path': path,
      };
}

@immutable
final class LegacyEventReference {
  LegacyEventReference({
    required this.kind,
    required String path,
    required String legacyEventId,
    String? mapId,
    required List<LegacySourceRef> candidateProvenances,
  })  : path = _nonEmpty(path, 'path'),
        legacyEventId = _nonEmpty(legacyEventId, 'legacyEventId'),
        mapId = _optionalNonEmpty(mapId, 'mapId'),
        candidateProvenances = List.unmodifiable(candidateProvenances);

  final LegacyEventReferenceKind kind;
  final String path;
  final String legacyEventId;
  final String? mapId;
  final List<LegacySourceRef> candidateProvenances;

  Map<String, Object?> toJson() => {
        'kind': kind.name,
        'path': path,
        'legacyEventId': legacyEventId,
        if (mapId != null) 'mapId': mapId,
        'candidateProvenances': [
          for (final provenance in candidateProvenances) provenance.toJson(),
        ],
      };
}

String _nonEmpty(String value, String name) {
  if (value.isEmpty || value.trim() != value) {
    throw ArgumentError.value(value, name, 'must be non-empty and trimmed');
  }
  return value;
}

String? _optionalNonEmpty(String? value, String name) {
  if (value == null) return null;
  return _nonEmpty(value, name);
}
