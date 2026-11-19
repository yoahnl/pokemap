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
  return (
    names: Map<String, String>.unmodifiable(names),
    legacyName: name is String && name.trim().isNotEmpty
        ? name
        : names['fr'] ?? names.values.firstOrNull,
  );
}

String _normalizeNameLocale(String locale) =>
    locale.trim().replaceAll('_', '-').toLowerCase();
