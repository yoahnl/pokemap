import 'dart:convert';
import 'dart:typed_data';

import 'package:map_distribution/map_distribution.dart';
import 'package:pub_semver/pub_semver.dart';

import 'package:pokemap_hub/features/library/domain/entities/game_library.dart';

final class GameLibraryFormatException implements Exception {
  const GameLibraryFormatException({
    required this.code,
    required this.path,
    required this.message,
  });

  final String code;
  final String path;
  final String message;

  @override
  String toString() => 'GameLibraryFormatException($code at $path): $message';
}

final class GameLibraryCodec {
  const GameLibraryCodec();

  GameLibrary decodeUtf8(List<int> bytes) {
    late final String source;
    late final Object? json;
    try {
      source = utf8.decode(bytes, allowMalformed: false);
      json = jsonDecode(source);
    } on FormatException catch (error) {
      _fail('invalidJson', r'$', error.message);
    }
    final library = decodeJson(json);
    if (source != CanonicalJson.encode(library.toJson())) {
      _fail(
        'nonCanonicalLibrary',
        r'$',
        'Library must use canonical JSON bytes without duplicate keys.',
      );
    }
    return library;
  }

  GameLibrary decodeJson(Object? value) {
    final json = _object(value, r'$');
    _exactFields(
      json,
      required: const <String>{
        'schemaVersion',
        'revision',
        'updatedAt',
        'games',
      },
      path: r'$',
    );
    final schemaVersion = _integer(json['schemaVersion'], r'$.schemaVersion');
    if (schemaVersion != 1) {
      _fail(
        'unsupportedSchemaVersion',
        r'$.schemaVersion',
        'Only GameLibrary schema 1 is supported.',
      );
    }
    final revision = _integer(json['revision'], r'$.revision');
    if (revision < 0) {
      _fail('invalidRevision', r'$.revision', 'Revision cannot be negative.');
    }
    final updatedAt = _timestamp(json['updatedAt'], r'$.updatedAt');
    final gamesJson = _list(json['games'], r'$.games');
    final games = <InstalledGame>[];
    final gameIds = <String>{};
    for (var index = 0; index < gamesJson.length; index++) {
      final game = _game(gamesJson[index], '\$.games[$index]');
      if (!gameIds.add(game.gameId)) {
        _fail(
          'duplicateGame',
          '\$.games[$index].gameId',
          'A game identity can appear only once.',
        );
      }
      games.add(game);
    }
    return GameLibrary(
      schemaVersion: schemaVersion,
      revision: revision,
      updatedAt: updatedAt,
      games: games,
    );
  }

  Uint8List encodeCanonicalUtf8(GameLibrary library) =>
      CanonicalJson.encodeUtf8(decodeJson(library.toJson()).toJson());

  InstalledGame _game(Object? value, String path) {
    final json = _object(value, path);
    _exactFields(
      json,
      required: const <String>{
        'gameId',
        'title',
        'authorName',
        'defaultLocale',
        'supportedLocales',
        'current',
        'versions',
      },
      optional: const <String>{
        'description',
        'publisherName',
        'branding',
      },
      path: path,
    );
    final gameId = _string(json['gameId'], '$path.gameId');
    if (!_gameId.hasMatch(gameId) || utf8.encode(gameId).length > 128) {
      _fail('invalidGameId', '$path.gameId', 'Invalid stable game identity.');
    }
    final title = _nonEmpty(json['title'], '$path.title');
    final authorName = _nonEmpty(json['authorName'], '$path.authorName');
    final defaultLocale =
        _nonEmpty(json['defaultLocale'], '$path.defaultLocale');
    final supportedJson =
        _list(json['supportedLocales'], '$path.supportedLocales');
    final supportedLocales = <String>[
      for (var index = 0; index < supportedJson.length; index++)
        _nonEmpty(
          supportedJson[index],
          '$path.supportedLocales[$index]',
        ),
    ];
    if (supportedLocales.isEmpty ||
        supportedLocales.toSet().length != supportedLocales.length ||
        !supportedLocales.contains(defaultLocale)) {
      _fail(
        'invalidLocales',
        '$path.supportedLocales',
        'Locales must be unique and include the default locale.',
      );
    }
    final current = _pointer(json['current'], '$path.current');
    final versionsJson = _list(json['versions'], '$path.versions');
    if (versionsJson.isEmpty) {
      _fail(
        'missingVersion',
        '$path.versions',
        'An installed game needs at least one version.',
      );
    }
    final versions = <InstalledGameVersion>[];
    final versionNumbers = <Version>{};
    for (var index = 0; index < versionsJson.length; index++) {
      final version = _version(
        versionsJson[index],
        '$path.versions[$index]',
      );
      if (!versionNumbers.add(version.gameVersion)) {
        _fail(
          'duplicateVersion',
          '$path.versions[$index].gameVersion',
          'A game version can appear only once.',
        );
      }
      versions.add(version);
    }
    if (!versions.any((version) => version.pointer == current)) {
      _fail(
        'unknownCurrentVersion',
        '$path.current',
        'Current pointer must reference an installed version and tree.',
      );
    }
    return InstalledGame(
      gameId: gameId,
      title: title,
      description: _optionalString(json['description'], '$path.description'),
      authorName: authorName,
      publisherName:
          _optionalString(json['publisherName'], '$path.publisherName'),
      defaultLocale: defaultLocale,
      supportedLocales: supportedLocales,
      branding: json.containsKey('branding')
          ? _branding(json['branding'], '$path.branding')
          : null,
      current: current,
      versions: versions,
    );
  }

  InstalledGamePointer _pointer(Object? value, String path) {
    final json = _object(value, path);
    _exactFields(
      json,
      required: const <String>{'gameVersion', 'treeSha256'},
      path: path,
    );
    return InstalledGamePointer(
      gameVersion: _semVer(json['gameVersion'], '$path.gameVersion'),
      treeSha256: _hash(json['treeSha256'], '$path.treeSha256'),
    );
  }

  InstalledGameVersion _version(Object? value, String path) {
    final json = _object(value, path);
    _exactFields(
      json,
      required: const <String>{
        'gameVersion',
        'treeSha256',
        'installedAt',
        'receiptFileName',
        'source',
        'signatureStatus',
      },
      path: path,
    );
    final sourceName = _string(json['source'], '$path.source');
    final source = GamePackageInstallSource.values
        .where((candidate) => candidate.name == sourceName)
        .firstOrNull;
    if (source == null) {
      _fail('invalidSource', '$path.source', 'Unknown install source.');
    }
    final signatureName =
        _string(json['signatureStatus'], '$path.signatureStatus');
    final signatureStatus = PackageSignatureStatus.values
        .where((candidate) => candidate.name == signatureName)
        .firstOrNull;
    if (signatureStatus == null) {
      _fail(
        'invalidSignatureStatus',
        '$path.signatureStatus',
        'Unknown signature status.',
      );
    }
    final receiptFileName =
        _string(json['receiptFileName'], '$path.receiptFileName');
    if (!_receiptFileName.hasMatch(receiptFileName)) {
      _fail(
        'invalidReceiptFileName',
        '$path.receiptFileName',
        'Receipt filename must be a safe basename.',
      );
    }
    final gameVersion = _semVer(
      json['gameVersion'],
      '$path.gameVersion',
    );
    final treeSha256 = _hash(json['treeSha256'], '$path.treeSha256');
    if (receiptFileName != '$gameVersion-$treeSha256.json') {
      _fail(
        'receiptIdentityMismatch',
        '$path.receiptFileName',
        'Receipt filename must match the installed release identity.',
      );
    }
    return InstalledGameVersion(
      gameVersion: gameVersion,
      treeSha256: treeSha256,
      installedAt: _timestamp(json['installedAt'], '$path.installedAt'),
      receiptFileName: receiptFileName,
      source: source,
      signatureStatus: signatureStatus,
    );
  }

  InstalledGameBranding _branding(Object? value, String path) {
    final json = _object(value, path);
    _exactFields(
      json,
      required: const <String>{},
      optional: const <String>{
        'icon',
        'cover',
        'hero',
        'accentColor',
        'titleMusic',
        'layoutVariant',
      },
      path: path,
    );
    return InstalledGameBranding(
      icon: _optionalString(json['icon'], '$path.icon'),
      cover: _optionalString(json['cover'], '$path.cover'),
      hero: _optionalString(json['hero'], '$path.hero'),
      accentColor: _optionalString(json['accentColor'], '$path.accentColor'),
      titleMusic: _optionalString(json['titleMusic'], '$path.titleMusic'),
      layoutVariant:
          _optionalString(json['layoutVariant'], '$path.layoutVariant'),
    );
  }

  Map<String, Object?> _object(Object? value, String path) {
    if (value is! Map) _fail('invalidType', path, 'Expected an object.');
    final result = <String, Object?>{};
    for (final entry in value.entries) {
      if (entry.key is! String) {
        _fail('invalidType', path, 'Object keys must be strings.');
      }
      result[entry.key as String] = entry.value;
    }
    return result;
  }

  List<Object?> _list(Object? value, String path) {
    if (value is! List) _fail('invalidType', path, 'Expected an array.');
    return value.cast<Object?>();
  }

  void _exactFields(
    Map<String, Object?> json, {
    required Set<String> required,
    Set<String> optional = const <String>{},
    required String path,
  }) {
    for (final field in required) {
      if (!json.containsKey(field)) {
        _fail('missingField', '$path.$field', 'Required field is missing.');
      }
    }
    final allowed = <String>{...required, ...optional};
    for (final field in json.keys) {
      if (!allowed.contains(field)) {
        _fail('unknownField', '$path.$field', 'Unknown field "$field".');
      }
    }
  }

  int _integer(Object? value, String path) {
    if (value is! int) _fail('invalidType', path, 'Expected an integer.');
    return value;
  }

  String _string(Object? value, String path) {
    if (value is! String) _fail('invalidType', path, 'Expected a string.');
    return value;
  }

  String _nonEmpty(Object? value, String path) {
    final result = _string(value, path);
    if (result.trim().isEmpty || result != result.trim()) {
      _fail('invalidString', path, 'String must be non-empty and trimmed.');
    }
    return result;
  }

  String? _optionalString(Object? value, String path) =>
      value == null ? null : _nonEmpty(value, path);

  Version _semVer(Object? value, String path) {
    final source = _string(value, path);
    if (!_strictSemVer.hasMatch(source)) {
      _fail('invalidSemVer', path, 'Expected a strict semantic version.');
    }
    try {
      return Version.parse(source);
    } on FormatException {
      _fail('invalidSemVer', path, 'Expected a strict semantic version.');
    }
  }

  String _hash(Object? value, String path) {
    final result = _string(value, path);
    if (!_sha256.hasMatch(result)) {
      _fail('invalidSha256', path, 'Expected a lowercase SHA-256.');
    }
    return result;
  }

  DateTime _timestamp(Object? value, String path) {
    final source = _string(value, path);
    late final DateTime result;
    try {
      result = DateTime.parse(source);
    } on FormatException {
      _fail('invalidTimestamp', path, 'Expected a UTC timestamp.');
    }
    if (!source.endsWith('Z') ||
        !result.isUtc ||
        result.toIso8601String() != source) {
      _fail('invalidTimestamp', path, 'Expected exact UTC ISO-8601 form.');
    }
    return result;
  }

  Never _fail(String code, String path, String message) {
    throw GameLibraryFormatException(
      code: code,
      path: path,
      message: message,
    );
  }

  static final RegExp _gameId =
      RegExp(r'^[a-z][a-z0-9-]*(\.[a-z][a-z0-9-]*){2,}$');
  static final RegExp _sha256 = RegExp(r'^[0-9a-f]{64}$');
  static final RegExp _receiptFileName =
      RegExp(r'^[0-9A-Za-z.+-]+-[0-9a-f]{64}\.json$');
  static final RegExp _strictSemVer = RegExp(
    r'^(0|[1-9][0-9]*)\.'
    r'(0|[1-9][0-9]*)\.'
    r'(0|[1-9][0-9]*)'
    r'(?:-((?:0|[1-9][0-9]*|[0-9]*[A-Za-z-][0-9A-Za-z-]*)'
    r'(?:\.(?:0|[1-9][0-9]*|[0-9]*[A-Za-z-][0-9A-Za-z-]*))*))?'
    r'(?:\+([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?$',
  );
}
