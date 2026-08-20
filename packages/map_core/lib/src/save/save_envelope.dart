import 'dart:collection';

import 'game_identity.dart';

enum SaveStatus { active, completed }

enum SaveOriginKind {
  legacyGlobalSave('legacy-global-save'),
  manualImport('manual-import');

  const SaveOriginKind(this.jsonValue);
  final String jsonValue;

  static SaveOriginKind parse(String value) => switch (value) {
        'legacy-global-save' => SaveOriginKind.legacyGlobalSave,
        'manual-import' => SaveOriginKind.manualImport,
        _ => throw ArgumentError.value(value, 'value', 'Unknown save origin'),
      };
}

final class SaveOrigin {
  SaveOrigin({required this.kind, required this.importedAt});

  final SaveOriginKind kind;
  final DateTime importedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SaveOrigin &&
          kind == other.kind &&
          importedAt == other.importedAt;

  @override
  int get hashCode => Object.hash(kind, importedAt);
}

/// Décision d'intégrité des sauvegardes — BETA-ITM-002, figée.
///
/// Le checksum vit dans l'ENVELOPPE de transport, jamais dans [SaveData] :
/// l'intégrité est une préoccupation du stockage, pas du modèle de jeu. Le
/// codec le calcule en SHA-256 du JSON canonique non signé et REFUSE tout
/// autre algorithme à la lecture — le champ [algorithm] versionne la
/// décision, il n'ouvre pas une négociation. Le store du hub le vérifie à
/// chaque écriture (writeVerified), avant toute migration (le snapshot
/// pré-migration doit correspondre à la source) et à la restauration d'un
/// backup ; un mismatch met le fichier en quarantaine au lieu de le lire.
final class SaveChecksum {
  const SaveChecksum({required this.algorithm, required this.value});

  final String algorithm;
  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SaveChecksum &&
          algorithm == other.algorithm &&
          value == other.value;

  @override
  int get hashCode => Object.hash(algorithm, value);
}

/// Versioned, checksummed boundary around runtime-owned game state.
final class SaveEnvelope {
  SaveEnvelope({
    required this.schemaVersion,
    required this.gameId,
    required this.profileId,
    required this.slotId,
    required this.saveId,
    required this.createdAt,
    required this.updatedAt,
    required this.gameVersion,
    required this.projectFormat,
    required this.saveFormat,
    required this.compatibilityId,
    required this.status,
    required this.playTimeSeconds,
    required Map<String, Object?> state,
    required this.checksum,
    this.completedAt,
    this.origin,
  }) : state = _freezeMap(state);

  final int schemaVersion;
  final String gameId;
  final String profileId;
  final String slotId;
  final String saveId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String gameVersion;
  final ProjectFormat projectFormat;
  final int saveFormat;
  final String compatibilityId;
  final SaveStatus status;
  final DateTime? completedAt;
  final int playTimeSeconds;
  final SaveOrigin? origin;
  final Map<String, Object?> state;
  final SaveChecksum checksum;

  SaveSlotAddress get address => SaveSlotAddress(
        gameId: gameId,
        profileId: profileId,
        slotId: slotId,
      );

  SaveCompatibilityDescriptor get compatibility => SaveCompatibilityDescriptor(
        gameId: gameId,
        saveFormat: saveFormat,
        compatibilityId: compatibilityId,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SaveEnvelope &&
          schemaVersion == other.schemaVersion &&
          gameId == other.gameId &&
          profileId == other.profileId &&
          slotId == other.slotId &&
          saveId == other.saveId &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          gameVersion == other.gameVersion &&
          projectFormat == other.projectFormat &&
          saveFormat == other.saveFormat &&
          compatibilityId == other.compatibilityId &&
          status == other.status &&
          completedAt == other.completedAt &&
          playTimeSeconds == other.playTimeSeconds &&
          origin == other.origin &&
          _deepEquals(state, other.state) &&
          checksum == other.checksum;

  @override
  int get hashCode => Object.hash(
        schemaVersion,
        gameId,
        profileId,
        slotId,
        saveId,
        createdAt,
        updatedAt,
        gameVersion,
        projectFormat,
        saveFormat,
        compatibilityId,
        status,
        completedAt,
        playTimeSeconds,
        origin,
        checksum,
      );
}

Map<String, Object?> _freezeMap(Map<String, Object?> source) =>
    UnmodifiableMapView<String, Object?>(
      source.map(
        (key, value) => MapEntry<String, Object?>(key, _freezeJson(value)),
      ),
    );

Object? _freezeJson(Object? value) => switch (value) {
      Map<String, Object?>() => _freezeMap(value),
      Map() => _freezeMap(
          value.map((key, nested) {
            if (key is! String) {
              throw ArgumentError.value(key, 'state', 'JSON keys are strings');
            }
            return MapEntry<String, Object?>(key, nested);
          }),
        ),
      List() => List<Object?>.unmodifiable(value.map(_freezeJson)),
      null || bool() || num() || String() => value,
      _ => throw ArgumentError.value(value, 'state', 'Not a JSON value'),
    };

bool _deepEquals(Object? left, Object? right) {
  if (identical(left, right) || left == right) return true;
  if (left is List && right is List && left.length == right.length) {
    for (var index = 0; index < left.length; index++) {
      if (!_deepEquals(left[index], right[index])) return false;
    }
    return true;
  }
  if (left is Map && right is Map && left.length == right.length) {
    for (final entry in left.entries) {
      if (!right.containsKey(entry.key) ||
          !_deepEquals(entry.value, right[entry.key])) {
        return false;
      }
    }
    return true;
  }
  return false;
}

/// Minimal save-side input for compatibility evaluation.
final class SaveCompatibilityDescriptor {
  const SaveCompatibilityDescriptor({
    required this.gameId,
    required this.saveFormat,
    required this.compatibilityId,
  });

  final String gameId;
  final int saveFormat;
  final String compatibilityId;
}
