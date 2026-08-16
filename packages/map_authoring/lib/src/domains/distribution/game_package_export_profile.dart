import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';

final class GamePackageExportException implements Exception {
  const GamePackageExportException({
    required this.code,
    required this.message,
    this.path,
    this.cause,
    this.gameplayReadinessReport,
  });

  final String code;
  final String message;
  final String? path;
  final Object? cause;
  final NarrativeProjectValidationReport? gameplayReadinessReport;

  @override
  String toString() => 'GamePackageExportException($code): $message';
}

/// Persisted authoring metadata. It is never copied into the runtime project.
final class GamePackageExportProfile {
  GamePackageExportProfile({
    this.schemaVersion = 1,
    required this.gameId,
    required this.gameVersion,
    required this.title,
    this.description,
    required this.authorName,
    this.authorUrl,
    this.publisherName,
    this.publisherUrl,
    required this.defaultLocale,
    required List<String> supportedLocales,
    List<String> requiredCapabilities = const <String>[],
    this.iconPath,
    this.coverPath,
    this.heroPath,
    this.titleMusicPath,
    this.accentColor,
    this.layoutVariant,
    this.licensePath,
    this.creditsPath,
  })  : supportedLocales = List.unmodifiable(supportedLocales),
        requiredCapabilities = List.unmodifiable(requiredCapabilities) {
    _validate();
  }

  final int schemaVersion;
  final String gameId;
  final String gameVersion;
  final String title;
  final String? description;
  final String authorName;
  final String? authorUrl;
  final String? publisherName;
  final String? publisherUrl;
  final String defaultLocale;
  final List<String> supportedLocales;
  final List<String> requiredCapabilities;
  final String? iconPath;
  final String? coverPath;
  final String? heroPath;
  final String? titleMusicPath;
  final String? accentColor;
  final String? layoutVariant;
  final String? licensePath;
  final String? creditsPath;

  Version get parsedGameVersion => Version.parse(gameVersion);

  GamePackageExportProfile copyWith({
    String? gameId,
    String? gameVersion,
    String? title,
    String? description,
    String? authorName,
    String? authorUrl,
    String? publisherName,
    String? publisherUrl,
    String? defaultLocale,
    List<String>? supportedLocales,
    List<String>? requiredCapabilities,
    String? iconPath,
    String? coverPath,
    String? heroPath,
    String? titleMusicPath,
    String? accentColor,
    String? layoutVariant,
    String? licensePath,
    String? creditsPath,
  }) =>
      GamePackageExportProfile(
        schemaVersion: schemaVersion,
        gameId: gameId ?? this.gameId,
        gameVersion: gameVersion ?? this.gameVersion,
        title: title ?? this.title,
        description: description ?? this.description,
        authorName: authorName ?? this.authorName,
        authorUrl: authorUrl ?? this.authorUrl,
        publisherName: publisherName ?? this.publisherName,
        publisherUrl: publisherUrl ?? this.publisherUrl,
        defaultLocale: defaultLocale ?? this.defaultLocale,
        supportedLocales: supportedLocales ?? this.supportedLocales,
        requiredCapabilities: requiredCapabilities ?? this.requiredCapabilities,
        iconPath: iconPath ?? this.iconPath,
        coverPath: coverPath ?? this.coverPath,
        heroPath: heroPath ?? this.heroPath,
        titleMusicPath: titleMusicPath ?? this.titleMusicPath,
        accentColor: accentColor ?? this.accentColor,
        layoutVariant: layoutVariant ?? this.layoutVariant,
        licensePath: licensePath ?? this.licensePath,
        creditsPath: creditsPath ?? this.creditsPath,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'schemaVersion': schemaVersion,
        'gameId': gameId,
        'gameVersion': gameVersion,
        'title': title,
        if (description?.trim().isNotEmpty ?? false)
          'description': description!.trim(),
        'author': <String, Object?>{
          'name': authorName,
          if (authorUrl?.trim().isNotEmpty ?? false) 'url': authorUrl,
        },
        if (publisherName?.trim().isNotEmpty ?? false)
          'publisher': <String, Object?>{
            'name': publisherName,
            if (publisherUrl?.trim().isNotEmpty ?? false) 'url': publisherUrl,
          },
        'locales': <String, Object?>{
          'default': defaultLocale,
          'supported': supportedLocales,
        },
        'requiredCapabilities': requiredCapabilities,
        'branding': <String, Object?>{
          if (iconPath != null) 'iconPath': iconPath,
          if (coverPath != null) 'coverPath': coverPath,
          if (heroPath != null) 'heroPath': heroPath,
          if (titleMusicPath != null) 'titleMusicPath': titleMusicPath,
          if (accentColor != null) 'accentColor': accentColor,
          if (layoutVariant != null) 'layoutVariant': layoutVariant,
        },
        'legal': <String, Object?>{
          if (licensePath != null) 'licensePath': licensePath,
          if (creditsPath != null) 'creditsPath': creditsPath,
        },
      };

  factory GamePackageExportProfile.fromJson(Object? source) {
    final json = _profileObject(
      source,
      r'$',
      required: const <String>{
        'schemaVersion',
        'gameId',
        'gameVersion',
        'title',
        'author',
        'locales',
        'requiredCapabilities',
        'branding',
        'legal',
      },
      optional: const <String>{'description', 'publisher'},
    );
    if (json['schemaVersion'] != 1) {
      throw const GamePackageExportException(
        code: 'profileVersionUnsupported',
        message: 'Only export profile version 1 is supported.',
      );
    }
    final author = _profileObject(
      json['author'],
      r'$.author',
      required: const <String>{'name'},
      optional: const <String>{'url'},
    );
    final publisher = json.containsKey('publisher')
        ? _profileObject(
            json['publisher'],
            r'$.publisher',
            required: const <String>{'name'},
            optional: const <String>{'url'},
          )
        : null;
    final locales = _profileObject(
      json['locales'],
      r'$.locales',
      required: const <String>{'default', 'supported'},
    );
    final branding = _profileObject(
      json['branding'],
      r'$.branding',
      required: const <String>{},
      optional: const <String>{
        'iconPath',
        'coverPath',
        'heroPath',
        'titleMusicPath',
        'accentColor',
        'layoutVariant',
      },
    );
    final legal = _profileObject(
      json['legal'],
      r'$.legal',
      required: const <String>{},
      optional: const <String>{'licensePath', 'creditsPath'},
    );
    return GamePackageExportProfile(
      gameId: _profileString(json['gameId'], r'$.gameId'),
      gameVersion: _profileString(json['gameVersion'], r'$.gameVersion'),
      title: _profileString(json['title'], r'$.title'),
      description: _optionalProfileString(json['description']),
      authorName: _profileString(author['name'], r'$.author.name'),
      authorUrl: _optionalProfileString(author['url']),
      publisherName: _optionalProfileString(publisher?['name']),
      publisherUrl: _optionalProfileString(publisher?['url']),
      defaultLocale: _profileString(locales['default'], r'$.locales.default'),
      supportedLocales: _stringList(
        locales['supported'],
        r'$.locales.supported',
      ),
      requiredCapabilities: _stringList(
        json['requiredCapabilities'],
        r'$.requiredCapabilities',
      ),
      iconPath: _optionalProfileString(branding['iconPath']),
      coverPath: _optionalProfileString(branding['coverPath']),
      heroPath: _optionalProfileString(branding['heroPath']),
      titleMusicPath: _optionalProfileString(branding['titleMusicPath']),
      accentColor: _optionalProfileString(branding['accentColor']),
      layoutVariant: _optionalProfileString(branding['layoutVariant']),
      licensePath: _optionalProfileString(legal['licensePath']),
      creditsPath: _optionalProfileString(legal['creditsPath']),
    );
  }

  static GamePackageExportProfile decodeUtf8(List<int> bytes) {
    try {
      return GamePackageExportProfile.fromJson(
        jsonDecode(utf8.decode(bytes, allowMalformed: false)),
      );
    } on GamePackageExportException {
      rethrow;
    } on Object catch (error) {
      throw GamePackageExportException(
        code: 'invalidExportProfile',
        message: 'The export profile is not valid JSON.',
        cause: error,
      );
    }
  }

  void _validate() {
    if (schemaVersion != 1) {
      _invalid('profileVersionUnsupported', 'Unsupported profile version.');
    }
    if (!_gameId.hasMatch(gameId) || utf8.encode(gameId).length > 128) {
      _invalid(
        'invalidGameId',
        'Choose a stable gameId such as games.studio.author.game.',
      );
    }
    try {
      Version.parse(gameVersion);
    } on FormatException {
      _invalid('invalidGameVersion', 'Game version must be strict SemVer.');
    }
    if (title.trim().isEmpty || title.length > 120) {
      _invalid('invalidTitle', 'Game title must contain 1 to 120 characters.');
    }
    if (authorName.trim().isEmpty || authorName.length > 120) {
      _invalid('invalidAuthor', 'Author name is required.');
    }
    for (final value in <String?>[authorUrl, publisherUrl]) {
      if (value == null || value.trim().isEmpty) continue;
      final uri = Uri.tryParse(value);
      if (uri == null ||
          !uri.hasAuthority ||
          (uri.scheme != 'https' && uri.scheme != 'http') ||
          uri.userInfo.isNotEmpty) {
        _invalid('invalidUrl', 'Author and publisher URLs must use HTTP(S).');
      }
    }
    if (!_locale.hasMatch(defaultLocale) ||
        supportedLocales.isEmpty ||
        !supportedLocales.contains(defaultLocale) ||
        supportedLocales.toSet().length != supportedLocales.length ||
        supportedLocales.any((value) => !_locale.hasMatch(value))) {
      _invalid(
        'invalidLocales',
        'Supported locales must be unique and contain the default locale.',
      );
    }
    for (final capability in requiredCapabilities) {
      if (!_capability.hasMatch(capability)) {
        _invalid('invalidCapability', 'Invalid required capability.');
      }
    }
    for (final path in <String?>[
      iconPath,
      coverPath,
      heroPath,
      titleMusicPath,
      licensePath,
      creditsPath,
    ]) {
      if (path != null) _validateRelativePath(path);
    }
    if (accentColor != null &&
        !RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(accentColor!)) {
      _invalid('invalidAccentColor', 'Accent color must use #RRGGBB.');
    }
  }

  static void _validateRelativePath(String value) {
    final normalized = p.posix.normalize(value.replaceAll(r'\', '/'));
    if (value.trim().isEmpty ||
        p.posix.isAbsolute(normalized) ||
        normalized == '..' ||
        normalized.startsWith('../') ||
        normalized != value.replaceAll(r'\', '/')) {
      throw GamePackageExportException(
        code: 'unsafeAuthoringPath',
        path: value,
        message: 'Authoring asset paths must stay relative to the project.',
      );
    }
  }

  Never _invalid(String code, String message) {
    throw GamePackageExportException(code: code, message: message);
  }

  @override
  bool operator ==(Object other) =>
      other is GamePackageExportProfile &&
      CanonicalJson.encode(other.toJson()) == CanonicalJson.encode(toJson());

  @override
  int get hashCode => CanonicalJson.encode(toJson()).hashCode;

  static final RegExp _gameId =
      RegExp(r'^[a-z][a-z0-9-]*(\.[a-z][a-z0-9-]*){2,}$');
  static final RegExp _locale = RegExp(r'^[a-z]{2,3}(?:-[A-Z][A-Z])?$');
  static final RegExp _capability = RegExp(r'^[a-z][a-z0-9.-]*@[1-9][0-9]*$');
}

Map<String, Object?> _profileObject(
  Object? value,
  String path, {
  required Set<String> required,
  Set<String> optional = const <String>{},
}) {
  if (value is! Map) {
    throw GamePackageExportException(
      code: 'invalidExportProfile',
      path: path,
      message: 'Expected an object.',
    );
  }
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    if (entry.key is! String) {
      throw GamePackageExportException(
        code: 'invalidExportProfile',
        path: path,
        message: 'Profile keys must be strings.',
      );
    }
    result[entry.key as String] = entry.value;
  }
  if (!result.keys.toSet().containsAll(required) ||
      result.keys.any(
        (key) => !required.contains(key) && !optional.contains(key),
      )) {
    throw GamePackageExportException(
      code: 'invalidExportProfile',
      path: path,
      message: 'Profile fields do not match schema version 1.',
    );
  }
  return result;
}

String _profileString(Object? value, String path) {
  if (value is! String || value.trim().isEmpty) {
    throw GamePackageExportException(
      code: 'invalidExportProfile',
      path: path,
      message: 'Expected a non-empty string.',
    );
  }
  return value;
}

String? _optionalProfileString(Object? value) {
  if (value == null) return null;
  if (value is! String) {
    throw const GamePackageExportException(
      code: 'invalidExportProfile',
      message: 'Expected an optional string.',
    );
  }
  return value.trim().isEmpty ? null : value;
}

List<String> _stringList(Object? value, String path) {
  if (value is! List || value.any((entry) => entry is! String)) {
    throw GamePackageExportException(
      code: 'invalidExportProfile',
      path: path,
      message: 'Expected a string list.',
    );
  }
  return value.cast<String>();
}
