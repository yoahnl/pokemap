import 'dart:convert';
import 'dart:typed_data';

import 'canonical_json.dart';
import 'game_package_format_exception.dart';
import 'strict_json_structure_validator.dart';

/// Relative, hash-bound handoff from the authoring app to PokeMap Hub.
final class GamePackageInstallRequest {
  GamePackageInstallRequest({
    this.schemaVersion = 1,
    required this.requestId,
    required this.packageFileName,
    required this.packageSha256,
    required DateTime createdAt,
  }) : createdAt = createdAt.toUtc();

  final int schemaVersion;
  final String requestId;
  final String packageFileName;
  final String packageSha256;
  final DateTime createdAt;

  Map<String, Object?> toJson() => <String, Object?>{
        'schemaVersion': schemaVersion,
        'requestId': requestId,
        'packageFileName': packageFileName,
        'packageSha256': packageSha256,
        'createdAt': createdAt.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      other is GamePackageInstallRequest &&
      schemaVersion == other.schemaVersion &&
      requestId == other.requestId &&
      packageFileName == other.packageFileName &&
      packageSha256 == other.packageSha256 &&
      createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        schemaVersion,
        requestId,
        packageFileName,
        packageSha256,
        createdAt,
      );
}

final class GamePackageInstallRequestCodec {
  const GamePackageInstallRequestCodec();

  Uint8List encodeCanonicalUtf8(GamePackageInstallRequest request) =>
      CanonicalJson.encodeUtf8(_validatedJson(request.toJson()));

  GamePackageInstallRequest decodeUtf8(List<int> bytes) {
    final String source;
    try {
      source = utf8.decode(bytes, allowMalformed: false);
      const StrictJsonStructureValidator().validate(
        source,
        path: r'$',
        maxDepth: 8,
        maxNodes: 64,
        duplicateCode: 'nonCanonicalInstallRequest',
      );
    } on GamePackageFormatException {
      rethrow;
    } on Object {
      _fail('invalidInstallRequest', r'$', 'Invalid request encoding.');
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on Object {
      _fail('invalidInstallRequest', r'$', 'Invalid request JSON.');
    }
    final request = decodeJson(decoded);
    if (source != CanonicalJson.encode(request.toJson())) {
      _fail(
        'nonCanonicalInstallRequest',
        r'$',
        'Install request must use canonical JSON.',
      );
    }
    return request;
  }

  GamePackageInstallRequest decodeJson(Object? value) {
    final json = _object(value);
    const expected = <String>{
      'schemaVersion',
      'requestId',
      'packageFileName',
      'packageSha256',
      'createdAt',
    };
    if (json.keys.toSet().length != expected.length ||
        !json.keys.toSet().containsAll(expected)) {
      _fail(
        'invalidInstallRequest',
        r'$',
        'Install request fields do not match schema version 1.',
      );
    }
    if (json['schemaVersion'] != 1) {
      _fail(
        'installRequestVersionUnsupported',
        r'$.schemaVersion',
        'Only install request schema version 1 is supported.',
      );
    }
    final requestId = _string(json['requestId'], r'$.requestId');
    if (!_requestId.hasMatch(requestId)) {
      _fail(
        'invalidInstallRequest',
        r'$.requestId',
        'Invalid install request ID.',
      );
    }
    final packageFileName =
        _string(json['packageFileName'], r'$.packageFileName');
    if (!_packageFileName.hasMatch(packageFileName)) {
      _fail(
        'unsafeInstallRequestPath',
        r'$.packageFileName',
        'Package filename must be a relative basename.',
      );
    }
    final packageSha256 = _string(json['packageSha256'], r'$.packageSha256');
    if (!_sha256.hasMatch(packageSha256)) {
      _fail(
        'invalidInstallRequest',
        r'$.packageSha256',
        'Package SHA-256 must be lowercase hexadecimal.',
      );
    }
    final createdAtSource = _string(json['createdAt'], r'$.createdAt');
    final createdAt = DateTime.tryParse(createdAtSource);
    if (createdAt == null ||
        !createdAt.isUtc ||
        !createdAtSource.endsWith('Z') ||
        createdAt.toIso8601String() != createdAtSource) {
      _fail(
        'invalidInstallRequest',
        r'$.createdAt',
        'Creation timestamp must be canonical UTC ISO-8601.',
      );
    }
    return GamePackageInstallRequest(
      requestId: requestId,
      packageFileName: packageFileName,
      packageSha256: packageSha256,
      createdAt: createdAt,
    );
  }

  Map<String, Object?> _validatedJson(Map<String, Object?> json) =>
      decodeJson(json).toJson();

  Map<String, Object?> _object(Object? value) {
    if (value is! Map) {
      _fail('invalidInstallRequest', r'$', 'Expected a JSON object.');
    }
    final result = <String, Object?>{};
    for (final entry in value.entries) {
      if (entry.key is! String) {
        _fail('invalidInstallRequest', r'$', 'Request keys must be strings.');
      }
      result[entry.key as String] = entry.value;
    }
    return result;
  }

  String _string(Object? value, String path) {
    if (value is! String || value.isEmpty) {
      _fail('invalidInstallRequest', path, 'Expected a non-empty string.');
    }
    return value;
  }

  Never _fail(String code, String path, String message) {
    throw GamePackageFormatException(
      code: code,
      path: path,
      message: message,
    );
  }

  static final RegExp _requestId = RegExp(r'^[a-z0-9][a-z0-9-]{2,63}$');
  static final RegExp _packageFileName =
      RegExp(r'^[a-z0-9][a-z0-9._-]{0,126}\.pokemapgame$');
  static final RegExp _sha256 = RegExp(r'^[0-9a-f]{64}$');
}
