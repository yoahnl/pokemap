import 'dart:convert';
import 'dart:typed_data';

import 'package:pub_semver/pub_semver.dart';

import 'canonical_json.dart';
import 'game_package_format_exception.dart';
import 'game_package_install_receipt.dart';
import 'game_package_security_policy.dart';
import 'strict_json_structure_validator.dart';

final class GamePackageInstallReceiptCodec {
  const GamePackageInstallReceiptCodec();

  GamePackageInstallReceipt decodeUtf8(List<int> bytes) {
    late final String source;
    late final Object? value;
    try {
      source = utf8.decode(bytes, allowMalformed: false);
      const StrictJsonStructureValidator().validate(
        source,
        path: r'$',
        maxDepth: 8,
        maxNodes: 100,
        duplicateCode: 'nonCanonicalReceipt',
      );
      value = jsonDecode(source);
    } on GamePackageFormatException {
      rethrow;
    } on FormatException catch (error) {
      _fail('invalidReceiptJson', r'$', error.message);
    }
    final receipt = decodeJson(value);
    if (source != CanonicalJson.encode(receipt.toJson())) {
      _fail(
        'nonCanonicalReceipt',
        r'$',
        'Install receipt must use canonical JSON bytes.',
      );
    }
    return receipt;
  }

  GamePackageInstallReceipt decodeJson(Object? value) {
    if (value is! Map) {
      _fail('invalidType', r'$', 'Expected a JSON object.');
    }
    final json = <String, Object?>{};
    for (final entry in value.entries) {
      if (entry.key is! String) {
        _fail('invalidType', r'$', 'Receipt keys must be strings.');
      }
      json[entry.key as String] = entry.value;
    }
    const fields = <String>{
      'receiptFormat',
      'securityPolicyVersion',
      'gameId',
      'gameVersion',
      'treeSha256',
      'manifestSha256',
      'packageSha256',
      'validatedAt',
      'installedAt',
      'source',
      'signatureStatus',
      'validation',
    };
    for (final field in fields) {
      if (!json.containsKey(field)) {
        _fail('missingField', '\$.$field', 'Receipt field is required.');
      }
    }
    for (final field in json.keys) {
      if (!fields.contains(field)) {
        _fail('unknownField', r'$', 'Unknown receipt field "$field".');
      }
    }
    final receiptFormat = _integer(json['receiptFormat'], r'$.receiptFormat');
    if (receiptFormat != 1) {
      _fail(
        'unsupportedReceiptFormat',
        r'$.receiptFormat',
        'Only install receipt format 1 is supported.',
      );
    }
    final securityPolicyVersion = _integer(
      json['securityPolicyVersion'],
      r'$.securityPolicyVersion',
    );
    if (securityPolicyVersion != 1) {
      _fail(
        'unsupportedSecurityPolicy',
        r'$.securityPolicyVersion',
        'Only security policy version 1 is supported.',
      );
    }
    final gameId = _string(json['gameId'], r'$.gameId');
    if (!_gameId.hasMatch(gameId) || utf8.encode(gameId).length > 128) {
      _fail('invalidGameId', r'$.gameId', 'Invalid stable game identity.');
    }
    final gameVersionSource = _string(json['gameVersion'], r'$.gameVersion');
    if (!_strictSemVer.hasMatch(gameVersionSource)) {
      _fail('invalidSemVer', r'$.gameVersion', 'Invalid game version.');
    }
    late final Version gameVersion;
    try {
      gameVersion = Version.parse(gameVersionSource);
    } on FormatException {
      _fail('invalidSemVer', r'$.gameVersion', 'Invalid game version.');
    }
    final treeSha256 = _hash(json['treeSha256'], r'$.treeSha256');
    final manifestSha256 = _hash(json['manifestSha256'], r'$.manifestSha256');
    final packageSha256 = _hash(json['packageSha256'], r'$.packageSha256');
    final validatedAt = _utcTimestamp(
      json['validatedAt'],
      r'$.validatedAt',
      'invalidValidatedAt',
    );
    final installedAt = _utcTimestamp(
      json['installedAt'],
      r'$.installedAt',
      'invalidInstalledAt',
    );
    if (validatedAt.isAfter(installedAt)) {
      _fail(
        'invalidReceiptDates',
        r'$.validatedAt',
        'Validation cannot happen after installation.',
      );
    }
    final sourceName = _string(json['source'], r'$.source');
    final source = GamePackageInstallSource.values
        .where((value) => value.name == sourceName)
        .firstOrNull;
    if (source == null) {
      _fail(
        'invalidInstallSource',
        r'$.source',
        'Unknown installation source.',
      );
    }
    final signatureName =
        _string(json['signatureStatus'], r'$.signatureStatus');
    final signatureStatus = PackageSignatureStatus.values
        .where((value) => value.name == signatureName)
        .firstOrNull;
    if (signatureStatus == null) {
      _fail(
        'invalidSignatureStatus',
        r'$.signatureStatus',
        'Unknown signature status.',
      );
    }
    if (source == GamePackageInstallSource.publicCatalog &&
        signatureStatus != PackageSignatureStatus.verified) {
      _fail(
        'invalidReceiptTrust',
        r'$.signatureStatus',
        'Public catalog receipts require a verified signature.',
      );
    }
    final validationValue = json['validation'];
    if (validationValue is! Map) {
      _fail('invalidType', r'$.validation', 'Expected an object.');
    }
    final validationJson = <String, Object?>{
      for (final entry in validationValue.entries)
        if (entry.key is String) entry.key as String: entry.value,
    };
    const validationFields = <String>{
      'packageInspection',
      'projectValidation',
      'loadSmoke',
      'compatibility',
    };
    if (validationJson.length != validationValue.length ||
        validationJson.keys.toSet().difference(validationFields).isNotEmpty ||
        validationFields.difference(validationJson.keys.toSet()).isNotEmpty) {
      _fail(
        'invalidReceiptValidation',
        r'$.validation',
        'Validation evidence fields are incomplete or unknown.',
      );
    }
    for (final field in <String>[
      'packageInspection',
      'projectValidation',
      'loadSmoke',
    ]) {
      if (_string(validationJson[field], '\$.validation.$field') != 'passed') {
        _fail(
          'invalidReceiptValidation',
          '\$.validation.$field',
          'Install receipts can only record passed validation gates.',
        );
      }
    }
    final compatibilityName = _string(
      validationJson['compatibility'],
      r'$.validation.compatibility',
    );
    final validationCompatibility = GamePackageInstallCompatibility.values
        .where((value) => value.name == compatibilityName)
        .firstOrNull;
    if (validationCompatibility == null) {
      _fail(
        'invalidReceiptValidation',
        r'$.validation.compatibility',
        'Unknown compatibility validation decision.',
      );
    }
    return GamePackageInstallReceipt(
      receiptFormat: receiptFormat,
      securityPolicyVersion: securityPolicyVersion,
      gameId: gameId,
      gameVersion: gameVersion,
      treeSha256: treeSha256,
      manifestSha256: manifestSha256,
      packageSha256: packageSha256,
      validatedAt: validatedAt,
      installedAt: installedAt,
      source: source,
      signatureStatus: signatureStatus,
      validation: GamePackageInstallValidation(
        compatibility: validationCompatibility,
      ),
    );
  }

  Uint8List encodeCanonicalUtf8(GamePackageInstallReceipt receipt) =>
      CanonicalJson.encodeUtf8(decodeJson(receipt.toJson()).toJson());

  String _hash(Object? value, String path) {
    final result = _string(value, path);
    if (!_sha256.hasMatch(result)) {
      _fail('invalidSha256', path, 'Invalid SHA-256 digest.');
    }
    return result;
  }

  DateTime _utcTimestamp(Object? value, String path, String code) {
    final source = _string(value, path);
    late final DateTime result;
    try {
      result = DateTime.parse(source);
    } on FormatException {
      _fail(code, path, 'Invalid UTC timestamp.');
    }
    if (!source.endsWith('Z') ||
        !result.isUtc ||
        result.toIso8601String() != source) {
      _fail(code, path, 'Timestamp must use exact UTC ISO-8601 form.');
    }
    return result;
  }

  int _integer(Object? value, String path) {
    if (value is! int) _fail('invalidType', path, 'Expected an integer.');
    return value;
  }

  String _string(Object? value, String path) {
    if (value is! String) _fail('invalidType', path, 'Expected a string.');
    return value;
  }

  Never _fail(String code, String path, String message) {
    throw GamePackageFormatException(
      code: code,
      path: path,
      message: message,
    );
  }

  static final RegExp _gameId =
      RegExp(r'^[a-z][a-z0-9-]*(\.[a-z][a-z0-9-]*){2,}$');
  static final RegExp _strictSemVer = RegExp(
    r'^(0|[1-9][0-9]*)\.'
    r'(0|[1-9][0-9]*)\.'
    r'(0|[1-9][0-9]*)'
    r'(?:-((?:0|[1-9][0-9]*|[0-9]*[A-Za-z-][0-9A-Za-z-]*)'
    r'(?:\.(?:0|[1-9][0-9]*|[0-9]*[A-Za-z-][0-9A-Za-z-]*))*))?'
    r'(?:\+([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?$',
  );
  static final RegExp _sha256 = RegExp(r'^[0-9a-f]{64}$');
}
