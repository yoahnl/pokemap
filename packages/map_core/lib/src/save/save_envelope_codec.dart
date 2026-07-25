import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'game_identity.dart';
import 'save_contract_exception.dart';
import 'save_envelope.dart';

/// Strict codec for PokeMap SaveEnvelope v1.
final class SaveEnvelopeCodec {
  const SaveEnvelopeCodec({this.maxEncodedBytes = 64 * 1024 * 1024});

  static const int currentSchemaVersion = 1;
  static const int currentSaveFormat = 1;

  final int maxEncodedBytes;

  SaveEnvelope create({
    required GameIdentity identity,
    required String profileId,
    required String slotId,
    required String saveId,
    required DateTime createdAt,
    required DateTime updatedAt,
    required SaveStatus status,
    required int playTimeSeconds,
    required Map<String, Object?> state,
    DateTime? completedAt,
    SaveOrigin? origin,
  }) {
    final unsigned = <String, Object?>{
      'schemaVersion': currentSchemaVersion,
      'gameId': identity.gameId,
      'profileId': profileId,
      'slotId': slotId,
      'saveId': saveId,
      'createdAt': _formatUtc(createdAt),
      'updatedAt': _formatUtc(updatedAt),
      'gameVersion': identity.gameVersion,
      'projectFormat': identity.projectFormat.name,
      'saveFormat': identity.saveFormat,
      'compatibilityId': identity.compatibilityId,
      'status': status.name,
      if (completedAt != null) 'completedAt': _formatUtc(completedAt),
      'playTimeSeconds': playTimeSeconds,
      if (origin != null)
        'origin': <String, Object?>{
          'kind': origin.kind.jsonValue,
          'importedAt': _formatUtc(origin.importedAt),
        },
      'state': state,
    };
    final signed = <String, Object?>{
      ...unsigned,
      'checksum': <String, Object?>{
        'algorithm': 'sha256',
        'value': computeChecksum(unsigned),
      },
    };
    return decodeJson(
      signed,
      acceptedSaveFormats: <int>{identity.saveFormat},
    );
  }

  String encode(SaveEnvelope envelope) =>
      const JsonEncoder.withIndent('  ').convert(toJson(envelope));

  Uint8List encodeUtf8(SaveEnvelope envelope) =>
      Uint8List.fromList(utf8.encode(encode(envelope)));

  SaveEnvelope decode(
    String source, {
    SaveSlotAddress? expectedAddress,
    Set<int> acceptedSaveFormats = const <int>{currentSaveFormat},
  }) {
    final bytes = utf8.encode(source).length;
    if (bytes > maxEncodedBytes) {
      throw SaveContractException(
        SaveContractErrorCode.sizeLimitExceeded,
        'Save exceeds the $maxEncodedBytes byte limit.',
      );
    }
    Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException catch (error) {
      throw SaveContractException(
        SaveContractErrorCode.invalidField,
        'Invalid save JSON: ${error.message}',
      );
    }
    if (decoded is! Map<String, dynamic>) {
      throw const SaveContractException(
        SaveContractErrorCode.invalidField,
        'Save root must be a JSON object.',
        path: r'$',
      );
    }
    return decodeJson(
      decoded,
      expectedAddress: expectedAddress,
      acceptedSaveFormats: acceptedSaveFormats,
    );
  }

  SaveEnvelope decodeUtf8(
    List<int> bytes, {
    SaveSlotAddress? expectedAddress,
    Set<int> acceptedSaveFormats = const <int>{currentSaveFormat},
  }) {
    if (bytes.length > maxEncodedBytes) {
      throw SaveContractException(
        SaveContractErrorCode.sizeLimitExceeded,
        'Save exceeds the $maxEncodedBytes byte limit.',
      );
    }
    late final String source;
    try {
      source = utf8.decode(bytes);
    } on FormatException catch (error) {
      throw SaveContractException(
        SaveContractErrorCode.invalidField,
        'Save is not valid UTF-8: ${error.message}',
      );
    }
    return decode(
      source,
      expectedAddress: expectedAddress,
      acceptedSaveFormats: acceptedSaveFormats,
    );
  }

  SaveEnvelope decodeJson(
    Map<String, Object?> json, {
    SaveSlotAddress? expectedAddress,
    Set<int> acceptedSaveFormats = const <int>{currentSaveFormat},
  }) {
    _checkKeys(json, _rootKeys, r'$');
    final schemaVersion = _requiredInt(json, 'schemaVersion');
    if (schemaVersion != currentSchemaVersion) {
      throw SaveContractException(
        SaveContractErrorCode.unsupportedSchema,
        'Unsupported save envelope schema $schemaVersion.',
        path: r'$.schemaVersion',
      );
    }

    final gameId = _requiredString(json, 'gameId');
    final profileId = _requiredString(json, 'profileId');
    final slotId = _requiredString(json, 'slotId');
    final address = SaveSlotAddress(
      gameId: gameId,
      profileId: profileId,
      slotId: slotId,
    );
    if (expectedAddress != null && address != expectedAddress) {
      throw SaveContractException(
        SaveContractErrorCode.addressMismatch,
        'Save address $address does not match $expectedAddress.',
      );
    }

    final saveId = _requiredString(json, 'saveId');
    if (!_uuidPattern.hasMatch(saveId)) {
      throw const SaveContractException(
        SaveContractErrorCode.invalidIdentity,
        'saveId must be an RFC 4122 UUID.',
        path: r'$.saveId',
      );
    }
    final createdAt = _requiredUtc(json, 'createdAt');
    final updatedAt = _requiredUtc(json, 'updatedAt');
    if (createdAt.isAfter(updatedAt)) {
      throw const SaveContractException(
        SaveContractErrorCode.invalidTimeline,
        'createdAt must not be after updatedAt.',
      );
    }
    final gameVersion = _requiredString(json, 'gameVersion');
    GameIdentity.validateSemver(gameVersion, path: r'$.gameVersion');
    final projectFormat =
        ProjectFormat.parse(_requiredString(json, 'projectFormat'));
    final saveFormat = _requiredInt(json, 'saveFormat');
    if (!acceptedSaveFormats.contains(saveFormat)) {
      throw SaveContractException(
        SaveContractErrorCode.unsupportedSaveFormat,
        'Unsupported save format $saveFormat.',
        path: r'$.saveFormat',
      );
    }
    final compatibilityId = _requiredString(json, 'compatibilityId');
    GameIdentity.validateCompatibilityId(compatibilityId);
    final statusName = _requiredString(json, 'status');
    final status = switch (statusName) {
      'active' => SaveStatus.active,
      'completed' => SaveStatus.completed,
      _ => throw SaveContractException(
          SaveContractErrorCode.invalidField,
          'Unknown save status "$statusName".',
          path: r'$.status',
        ),
    };
    final completedAt = json.containsKey('completedAt')
        ? _requiredUtc(json, 'completedAt')
        : null;
    if ((status == SaveStatus.completed) != (completedAt != null)) {
      throw const SaveContractException(
        SaveContractErrorCode.invalidCompletion,
        'completed saves require completedAt; active saves forbid it.',
      );
    }
    if (completedAt != null &&
        (completedAt.isBefore(createdAt) || completedAt.isAfter(updatedAt))) {
      throw const SaveContractException(
        SaveContractErrorCode.invalidTimeline,
        'completedAt must be between createdAt and updatedAt.',
        path: r'$.completedAt',
      );
    }
    final playTimeSeconds = _requiredInt(json, 'playTimeSeconds');
    if (playTimeSeconds < 0 || playTimeSeconds > 3155760000) {
      throw const SaveContractException(
        SaveContractErrorCode.invalidField,
        'playTimeSeconds is outside the supported range.',
        path: r'$.playTimeSeconds',
      );
    }
    final state = _requiredMap(json, 'state');
    final origin = json.containsKey('origin')
        ? _decodeOrigin(_requiredMap(json, 'origin'))
        : null;
    final checksumJson = _requiredMap(json, 'checksum');
    _checkKeys(checksumJson, _checksumKeys, r'$.checksum');
    final algorithm = _requiredString(checksumJson, 'algorithm');
    final checksumValue = _requiredString(checksumJson, 'value');
    if (algorithm != 'sha256' || !_sha256Pattern.hasMatch(checksumValue)) {
      throw const SaveContractException(
        SaveContractErrorCode.invalidChecksum,
        'checksum must contain a lowercase SHA-256 digest.',
        path: r'$.checksum',
      );
    }
    final expectedChecksum = computeChecksum(json);
    if (checksumValue != expectedChecksum) {
      throw const SaveContractException(
        SaveContractErrorCode.checksumMismatch,
        'Save checksum mismatch.',
        path: r'$.checksum.value',
      );
    }

    return SaveEnvelope(
      schemaVersion: schemaVersion,
      gameId: gameId,
      profileId: profileId,
      slotId: slotId,
      saveId: saveId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      gameVersion: gameVersion,
      projectFormat: projectFormat,
      saveFormat: saveFormat,
      compatibilityId: compatibilityId,
      status: status,
      completedAt: completedAt,
      playTimeSeconds: playTimeSeconds,
      origin: origin,
      state: state,
      checksum: SaveChecksum(algorithm: algorithm, value: checksumValue),
    );
  }

  Map<String, Object?> toJson(SaveEnvelope envelope) => <String, Object?>{
        'schemaVersion': envelope.schemaVersion,
        'gameId': envelope.gameId,
        'profileId': envelope.profileId,
        'slotId': envelope.slotId,
        'saveId': envelope.saveId,
        'createdAt': _formatUtc(envelope.createdAt),
        'updatedAt': _formatUtc(envelope.updatedAt),
        'gameVersion': envelope.gameVersion,
        'projectFormat': envelope.projectFormat.name,
        'saveFormat': envelope.saveFormat,
        'compatibilityId': envelope.compatibilityId,
        'status': envelope.status.name,
        if (envelope.completedAt != null)
          'completedAt': _formatUtc(envelope.completedAt!),
        'playTimeSeconds': envelope.playTimeSeconds,
        if (envelope.origin case final origin?)
          'origin': <String, Object?>{
            'kind': origin.kind.jsonValue,
            'importedAt': _formatUtc(origin.importedAt),
          },
        'state': envelope.state,
        'checksum': <String, Object?>{
          'algorithm': envelope.checksum.algorithm,
          'value': envelope.checksum.value,
        },
      };

  bool verifyChecksum(SaveEnvelope envelope) =>
      envelope.checksum.algorithm == 'sha256' &&
      envelope.checksum.value == computeChecksum(toJson(envelope));

  String computeChecksum(Map<String, Object?> json) {
    final unsigned = <String, Object?>{
      for (final entry in json.entries)
        if (entry.key != 'checksum') entry.key: entry.value,
    };
    try {
      return sha256.convert(utf8.encode(_canonicalJson(unsigned))).toString();
    } on SaveContractException {
      rethrow;
    } catch (error) {
      throw SaveContractException(
        SaveContractErrorCode.invalidField,
        'Save cannot be canonicalized: $error',
      );
    }
  }

  SaveOrigin _decodeOrigin(Map<String, Object?> json) {
    _checkKeys(json, _originKeys, r'$.origin');
    SaveOriginKind kind;
    try {
      kind = SaveOriginKind.parse(_requiredString(json, 'kind'));
    } on ArgumentError {
      throw const SaveContractException(
        SaveContractErrorCode.invalidField,
        'Unknown save origin kind.',
        path: r'$.origin.kind',
      );
    }
    return SaveOrigin(
      kind: kind,
      importedAt: _requiredUtc(json, 'importedAt', prefix: r'$.origin'),
    );
  }
}

const Set<String> _rootKeys = <String>{
  'schemaVersion',
  'gameId',
  'profileId',
  'slotId',
  'saveId',
  'createdAt',
  'updatedAt',
  'gameVersion',
  'projectFormat',
  'saveFormat',
  'compatibilityId',
  'status',
  'completedAt',
  'playTimeSeconds',
  'origin',
  'state',
  'checksum',
};
const Set<String> _originKeys = <String>{'kind', 'importedAt'};
const Set<String> _checksumKeys = <String>{'algorithm', 'value'};
final RegExp _uuidPattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-'
  r'[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);
final RegExp _sha256Pattern = RegExp(r'^[0-9a-f]{64}$');

void _checkKeys(
  Map<String, Object?> json,
  Set<String> allowed,
  String path,
) {
  for (final key in json.keys) {
    if (!allowed.contains(key)) {
      throw SaveContractException(
        SaveContractErrorCode.unknownField,
        'Unknown field "$key".',
        path: '$path.$key',
      );
    }
  }
}

String _requiredString(
  Map<String, Object?> json,
  String key, {
  String prefix = r'$',
}) {
  final value = json[key];
  if (value is! String) {
    throw SaveContractException(
      SaveContractErrorCode.invalidField,
      '"$key" must be a string.',
      path: '$prefix.$key',
    );
  }
  return value;
}

int _requiredInt(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! int) {
    throw SaveContractException(
      SaveContractErrorCode.invalidField,
      '"$key" must be an integer.',
      path: r'$.' + key,
    );
  }
  return value;
}

Map<String, Object?> _requiredMap(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! Map) {
    throw SaveContractException(
      SaveContractErrorCode.invalidField,
      '"$key" must be an object.',
      path: r'$.' + key,
    );
  }
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    if (entry.key is! String) {
      throw SaveContractException(
        SaveContractErrorCode.invalidField,
        '"$key" contains a non-string key.',
      );
    }
    result[entry.key as String] = entry.value;
  }
  return result;
}

DateTime _requiredUtc(
  Map<String, Object?> json,
  String key, {
  String prefix = r'$',
}) {
  final source = _requiredString(json, key, prefix: prefix);
  if (!source.endsWith('Z')) {
    throw SaveContractException(
      SaveContractErrorCode.invalidField,
      '"$key" must be an explicit UTC timestamp.',
      path: '$prefix.$key',
    );
  }
  try {
    final parsed = DateTime.parse(source);
    if (!parsed.isUtc) throw const FormatException();
    return parsed;
  } on FormatException {
    throw SaveContractException(
      SaveContractErrorCode.invalidField,
      '"$key" is not a valid UTC timestamp.',
      path: '$prefix.$key',
    );
  }
}

String _formatUtc(DateTime value) {
  if (!value.isUtc) {
    throw const SaveContractException(
      SaveContractErrorCode.invalidField,
      'Save timestamps must be UTC.',
    );
  }
  var source = value.toIso8601String();
  source = source.replaceFirst(RegExp(r'\.000Z$'), 'Z');
  source = source.replaceFirstMapped(
    RegExp(r'\.(\d*[1-9])0+Z$'),
    (match) => '.${match.group(1)}Z',
  );
  return source;
}

String _canonicalJson(Object? value) {
  final output = StringBuffer();
  _writeCanonical(value, output);
  return output.toString();
}

void _writeCanonical(Object? value, StringBuffer output) {
  switch (value) {
    case null:
      output.write('null');
    case bool():
      output.write(value ? 'true' : 'false');
    case int():
      if (value < -9007199254740991 || value > 9007199254740991) {
        throw const SaveContractException(
          SaveContractErrorCode.invalidField,
          'Integer is outside the canonical JSON safe range.',
        );
      }
      output.write(value);
    case double():
      if (!value.isFinite) {
        throw const SaveContractException(
          SaveContractErrorCode.invalidField,
          'Non-finite numbers are not valid JSON.',
        );
      }
      if (value == 0) {
        output.write('0');
      } else if (value == value.truncateToDouble() &&
          value.abs() <= 9007199254740991) {
        output.write(value.toInt());
      } else {
        output.write(jsonEncode(value).replaceFirst('e+', 'e'));
      }
    case String():
      output.write(jsonEncode(value));
    case List():
      output.write('[');
      for (var index = 0; index < value.length; index++) {
        if (index > 0) output.write(',');
        _writeCanonical(value[index], output);
      }
      output.write(']');
    case Map():
      final entries = <MapEntry<String, Object?>>[];
      for (final entry in value.entries) {
        if (entry.key is! String) {
          throw const SaveContractException(
            SaveContractErrorCode.invalidField,
            'Canonical JSON object keys must be strings.',
          );
        }
        entries
            .add(MapEntry<String, Object?>(entry.key as String, entry.value));
      }
      entries.sort((left, right) => _compareUtf16(left.key, right.key));
      output.write('{');
      for (var index = 0; index < entries.length; index++) {
        if (index > 0) output.write(',');
        output
          ..write(jsonEncode(entries[index].key))
          ..write(':');
        _writeCanonical(entries[index].value, output);
      }
      output.write('}');
    default:
      throw SaveContractException(
        SaveContractErrorCode.invalidField,
        'Unsupported JSON value ${value.runtimeType}.',
      );
  }
}

int _compareUtf16(String left, String right) {
  final shared = left.length < right.length ? left.length : right.length;
  for (var index = 0; index < shared; index++) {
    final comparison =
        left.codeUnitAt(index).compareTo(right.codeUnitAt(index));
    if (comparison != 0) return comparison;
  }
  return left.length.compareTo(right.length);
}
