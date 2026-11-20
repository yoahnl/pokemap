/// Résout un nom localisé depuis une map de traductions.
///
/// La sémantique reprend celle déjà retenue par `SceneLocalizedText.resolve` :
/// correspondance exacte, puis code langue, puis repli. Une traduction vide est
/// traitée comme absente afin qu'une entrée mal renseignée n'efface jamais un
/// libellé affichable.
String resolveLocalizedName({
  required Map<String, String> names,
  required String locale,
  required String fallback,
}) {
  final normalized = _normalizeNameLocale(locale);
  if (normalized.isEmpty) {
    return fallback;
  }

  final exact = names[normalized];
  if (exact != null && exact.trim().isNotEmpty) {
    return exact;
  }

  final separator = normalized.indexOf('-');
  if (separator > 0) {
    final language = names[normalized.substring(0, separator)];
    if (language != null && language.trim().isNotEmpty) {
      return language;
    }
  }

  return fallback;
}

String resolvePokemonSpeciesName({
  required Map<String, String> names,
  required String locale,
  required String fallback,
}) {
  final english = resolveLocalizedName(
    names: names,
    locale: 'en',
    fallback: fallback,
  );
  return resolveLocalizedName(names: names, locale: locale, fallback: english);
}

({Map<String, String> names, String? legacyName}) readPokemonSpeciesNames(
  Map<String, dynamic> json,
) {
  final names = <String, String>{};
  final rawNames = json['names'];
  if (rawNames is Map) {
    for (final MapEntry(:key, :value) in rawNames.entries) {
      if (key is! String || value is! String || value.trim().isEmpty) continue;
      final locale = _normalizeNameLocale(key);
      if (locale.isEmpty) continue;
      if (key == locale || !names.containsKey(locale)) {
        names[locale] = value;
      }
    }
  }
  final name = json['name'];
  final legacyName = name is String && name.trim().isNotEmpty
      ? name
      : names['fr'] ?? names.values.firstOrNull;
  if (!names.containsKey('en')) {
    final english = _legacyHeartGoldEnglishName(json);
    if (english != null) names['en'] = english;
  }
  return (
    names: Map<String, String>.unmodifiable(names),
    legacyName: legacyName,
  );
}

final _plainHeartGoldSpeciesSlug = RegExp(r'^[a-z][a-z0-9]*$');
final _heartGoldUnownFormSlug = RegExp(r'^unown-[a-z]$');

String? _legacyHeartGoldEnglishName(Map<String, dynamic> json) {
  final source = json['sourceMeta'];
  if (source is! Map || source['seedVersion'] != 1) return null;
  final seededBy = source['seededBy'];
  if (seededBy is! String || seededBy.split(':').first != 'heartgold-fr-rom') {
    return null;
  }
  final slug = json['slug'];
  if (slug is! String || slug != json['id']) return null;
  return switch (slug) {
    'farfetchd' => 'Farfetch’d',
    'ho_oh' => 'Ho-Oh',
    'mime_jr' => 'Mime Jr.',
    'mr_mime' => 'Mr. Mime',
    'nidoran_f' => 'Nidoran♀',
    'nidoran_m' => 'Nidoran♂',
    'porygon_z' => 'Porygon-Z',
    _ when _heartGoldUnownFormSlug.hasMatch(slug) => 'Unown',
    _ when _plainHeartGoldSpeciesSlug.hasMatch(slug) =>
      '${slug[0].toUpperCase()}${slug.substring(1)}',
    _ => null,
  };
}

String _normalizeNameLocale(String locale) =>
    locale.trim().replaceAll('_', '-').toLowerCase();
