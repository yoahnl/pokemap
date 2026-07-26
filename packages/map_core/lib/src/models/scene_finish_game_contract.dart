import 'dart:collection';

import 'package:meta/meta.dart' show immutable;

const int sceneFinishGameContractVersion = 1;

enum SceneGameCompletionOutcome { completed, victory, alternateEnding }

enum SceneFinishGameCommitPolicy { persistBeforePresentation }

enum ScenePostGamePolicy { continueGame, returnToTitle, returnToHub }

/// Authorable text with a mandatory fallback and optional locale overrides.
///
/// Resolution prefers an exact locale, then its language subtag, and finally
/// [fallback]. Locale keys are normalized so `fr_FR` and `fr-FR` are
/// equivalent.
@immutable
final class SceneLocalizedText {
  SceneLocalizedText({
    required String fallback,
    Map<String, String> translations = const {},
  })  : fallback = fallback.trim(),
        translations = UnmodifiableMapView(
          _normalizeTranslations(translations),
        );

  factory SceneLocalizedText.fromJson(Object? json) {
    // V0 legacy authoring stored localizable values as plain strings.
    if (json is String) {
      return SceneLocalizedText(fallback: json);
    }
    if (json is! Map<String, dynamic>) {
      throw const FormatException(
        'SceneLocalizedText must be a string or an object.',
      );
    }
    final fallback = json['fallback'];
    if (fallback is! String) {
      throw const FormatException(
        'SceneLocalizedText.fallback must be a string.',
      );
    }
    final rawTranslations = json['translations'];
    if (rawTranslations != null && rawTranslations is! Map) {
      throw const FormatException(
        'SceneLocalizedText.translations must be an object.',
      );
    }
    final translations = <String, String>{};
    if (rawTranslations is Map) {
      for (final entry in rawTranslations.entries) {
        if (entry.key is! String || entry.value is! String) {
          throw const FormatException(
            'SceneLocalizedText translations must map strings to strings.',
          );
        }
        translations[entry.key as String] = entry.value as String;
      }
    }
    return SceneLocalizedText(
      fallback: fallback,
      translations: translations,
    );
  }

  final String fallback;
  final Map<String, String> translations;

  String resolve(String locale) {
    final normalized = _normalizeLocale(locale);
    final exact = translations[normalized];
    if (exact != null && exact.isNotEmpty) return exact;
    final separator = normalized.indexOf('-');
    if (separator > 0) {
      final language = translations[normalized.substring(0, separator)];
      if (language != null && language.isNotEmpty) return language;
    }
    return fallback;
  }

  Map<String, dynamic> toJson() => {
        'fallback': fallback,
        if (translations.isNotEmpty) 'translations': translations,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneLocalizedText &&
          other.fallback == fallback &&
          _mapsEqual(other.translations, translations);

  @override
  int get hashCode => Object.hash(fallback, _mapHash(translations));
}

@immutable
final class SceneFinishGameResult {
  SceneFinishGameResult({
    required this.title,
    required this.summary,
    List<SceneLocalizedText> details = const [],
  }) : details = List.unmodifiable(details);

  factory SceneFinishGameResult.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Finish Game result must be an object.');
    }
    final details = json['details'];
    if (details != null && details is! List) {
      throw const FormatException('Finish Game result.details must be a list.');
    }
    return SceneFinishGameResult(
      title: SceneLocalizedText.fromJson(json['title']),
      summary: SceneLocalizedText.fromJson(json['summary']),
      details: [
        for (final detail in (details as List? ?? const []))
          SceneLocalizedText.fromJson(detail),
      ],
    );
  }

  final SceneLocalizedText title;
  final SceneLocalizedText summary;
  final List<SceneLocalizedText> details;

  Map<String, dynamic> toJson() => {
        'title': title.toJson(),
        'summary': summary.toJson(),
        if (details.isNotEmpty)
          'details': [for (final detail in details) detail.toJson()],
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneFinishGameResult &&
          other.title == title &&
          other.summary == summary &&
          _listsEqual(other.details, details);

  @override
  int get hashCode => Object.hash(title, summary, Object.hashAll(details));
}

@immutable
final class SceneFinishGameCredits {
  SceneFinishGameCredits({
    required this.title,
    required String author,
    List<String> contributors = const [],
    List<String> licenses = const [],
    required this.endingLabel,
    this.skippable = true,
  })  : author = author.trim(),
        contributors = List.unmodifiable(
          contributors.map((value) => value.trim()),
        ),
        licenses = List.unmodifiable(licenses.map((value) => value.trim()));

  factory SceneFinishGameCredits.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Finish Game credits must be an object.');
    }
    return SceneFinishGameCredits(
      title: SceneLocalizedText.fromJson(json['title']),
      author: _readString(json, 'author'),
      contributors: _readStringList(json, 'contributors'),
      licenses: _readStringList(json, 'licenses'),
      endingLabel: SceneLocalizedText.fromJson(json['endingLabel']),
      skippable: _readBool(json, 'skippable', fallback: true),
    );
  }

  final SceneLocalizedText title;
  final String author;
  final List<String> contributors;
  final List<String> licenses;
  final SceneLocalizedText endingLabel;
  final bool skippable;

  Map<String, dynamic> toJson() => {
        'title': title.toJson(),
        'author': author,
        if (contributors.isNotEmpty) 'contributors': contributors,
        if (licenses.isNotEmpty) 'licenses': licenses,
        'endingLabel': endingLabel.toJson(),
        'skippable': skippable,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneFinishGameCredits &&
          other.title == title &&
          other.author == author &&
          _listsEqual(other.contributors, contributors) &&
          _listsEqual(other.licenses, licenses) &&
          other.endingLabel == endingLabel &&
          other.skippable == skippable;

  @override
  int get hashCode => Object.hash(
        title,
        author,
        Object.hashAll(contributors),
        Object.hashAll(licenses),
        endingLabel,
        skippable,
      );
}

Map<String, String> _normalizeTranslations(Map<String, String> values) {
  return {
    for (final entry in values.entries)
      if (entry.key.trim().isNotEmpty && entry.value.trim().isNotEmpty)
        _normalizeLocale(entry.key): entry.value.trim(),
  };
}

String _normalizeLocale(String value) =>
    value.trim().replaceAll('_', '-').toLowerCase();

String _readString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) {
    throw FormatException('Finish Game $key must be a string.');
  }
  return value;
}

List<String> _readStringList(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return const [];
  if (value is! List || value.any((entry) => entry is! String)) {
    throw FormatException('Finish Game $key must be a list of strings.');
  }
  return value.cast<String>();
}

bool _readBool(
  Map<String, dynamic> json,
  String key, {
  required bool fallback,
}) {
  final value = json[key];
  if (value == null) return fallback;
  if (value is! bool) {
    throw FormatException('Finish Game $key must be a boolean.');
  }
  return value;
}

bool _mapsEqual<K, V>(Map<K, V> left, Map<K, V> right) {
  if (left.length != right.length) return false;
  for (final entry in left.entries) {
    if (!right.containsKey(entry.key) || right[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}

int _mapHash(Map<String, String> values) {
  final keys = values.keys.toList()..sort();
  return Object.hashAll(
    keys.map((key) => Object.hash(key, values[key])),
  );
}

bool _listsEqual<T>(List<T> left, List<T> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
