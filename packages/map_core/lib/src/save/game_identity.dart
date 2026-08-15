import 'save_contract_exception.dart';

enum ProjectFormat {
  v1,
  v2,
  v3,
  v4,
  v5,
  v6,
  v7;

  static ProjectFormat parse(String value) => switch (value) {
        'v1' => ProjectFormat.v1,
        'v2' => ProjectFormat.v2,
        'v3' => ProjectFormat.v3,
        'v4' => ProjectFormat.v4,
        'v5' => ProjectFormat.v5,
        'v6' => ProjectFormat.v6,
        'v7' => ProjectFormat.v7,
        _ => throw SaveContractException(
            SaveContractErrorCode.invalidField,
            'Unsupported project format "$value".',
            path: r'$.projectFormat',
          ),
      };
}

final RegExp _gameIdPattern =
    RegExp(r'^[a-z][a-z0-9-]*(\.[a-z][a-z0-9-]*){2,}$');
final RegExp _localIdPattern = RegExp(r'^[a-z0-9][a-z0-9_-]*$');
final RegExp _compatibilityIdPattern = RegExp(r'^[a-z0-9][a-z0-9._-]*$');
final RegExp _semverPattern = RegExp(
  r'^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)'
  r'(?:-((?:0|[1-9][0-9]*|[0-9]*[A-Za-z-][0-9A-Za-z-]*)'
  r'(?:\.(?:0|[1-9][0-9]*|[0-9]*[A-Za-z-][0-9A-Za-z-]*))*))?'
  r'(?:\+([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?$',
);

/// Stable identity supplied by a game package, never inferred from a title.
final class GameIdentity {
  GameIdentity({
    required this.gameId,
    required this.gameVersion,
    required this.projectFormat,
    required this.saveFormat,
    required this.compatibilityId,
  }) {
    validateGameId(gameId);
    validateSemver(gameVersion, path: r'$.gameVersion');
    if (saveFormat < 0) {
      throw const SaveContractException(
        SaveContractErrorCode.invalidField,
        'saveFormat must be non-negative.',
        path: r'$.saveFormat',
      );
    }
    validateCompatibilityId(compatibilityId);
  }

  final String gameId;
  final String gameVersion;
  final ProjectFormat projectFormat;
  final int saveFormat;
  final String compatibilityId;

  static void validateGameId(String value, {String path = r'$.gameId'}) {
    if (value.length < 3 ||
        value.length > 128 ||
        !_gameIdPattern.hasMatch(value)) {
      throw SaveContractException(
        SaveContractErrorCode.invalidIdentity,
        'Invalid stable gameId "$value".',
        path: path,
      );
    }
  }

  static void validateLocalId(String value, {required String path}) {
    if (value.isEmpty ||
        value.length > 64 ||
        !_localIdPattern.hasMatch(value)) {
      throw SaveContractException(
        SaveContractErrorCode.invalidIdentity,
        'Invalid local identifier "$value".',
        path: path,
      );
    }
  }

  static void validateCompatibilityId(
    String value, {
    String path = r'$.compatibilityId',
  }) {
    if (value.isEmpty ||
        value.length > 128 ||
        !_compatibilityIdPattern.hasMatch(value)) {
      throw SaveContractException(
        SaveContractErrorCode.invalidIdentity,
        'Invalid compatibilityId "$value".',
        path: path,
      );
    }
  }

  static void validateSemver(String value, {required String path}) {
    if (!_semverPattern.hasMatch(value)) {
      throw SaveContractException(
        SaveContractErrorCode.invalidField,
        'Invalid semantic version "$value".',
        path: path,
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameIdentity &&
          gameId == other.gameId &&
          gameVersion == other.gameVersion &&
          projectFormat == other.projectFormat &&
          saveFormat == other.saveFormat &&
          compatibilityId == other.compatibilityId;

  @override
  int get hashCode => Object.hash(
        gameId,
        gameVersion,
        projectFormat,
        saveFormat,
        compatibilityId,
      );
}

/// Filesystem-safe namespace for one save slot.
final class SaveSlotAddress {
  SaveSlotAddress({
    required this.gameId,
    required this.profileId,
    required this.slotId,
  }) {
    GameIdentity.validateGameId(gameId);
    GameIdentity.validateLocalId(profileId, path: r'$.profileId');
    GameIdentity.validateLocalId(slotId, path: r'$.slotId');
  }

  final String gameId;
  final String profileId;
  final String slotId;

  List<String> get pathSegments =>
      List<String>.unmodifiable(<String>[gameId, profileId, slotId]);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SaveSlotAddress &&
          gameId == other.gameId &&
          profileId == other.profileId &&
          slotId == other.slotId;

  @override
  int get hashCode => Object.hash(gameId, profileId, slotId);

  @override
  String toString() => '$gameId/$profileId/$slotId';
}
