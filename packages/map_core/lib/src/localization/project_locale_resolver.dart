/// Resolves a player preference against the locales shipped by a project.
///
/// Matching is deliberately deterministic: exact tag, then language, then the
/// project-declared fallback. Authored locale spelling is preserved in the
/// returned value so it can be used directly by project content resolvers.
final class ProjectLocaleResolver {
  const ProjectLocaleResolver._();

  static String resolve({
    required String preferredLocale,
    required Iterable<String> supportedLocales,
    required String fallbackLocale,
  }) => resolvePreferred(
    preferredLocales: [preferredLocale],
    supportedLocales: supportedLocales,
    fallbackLocale: fallbackLocale,
  );

  static String resolvePreferred({
    required Iterable<String> preferredLocales,
    required Iterable<String> supportedLocales,
    required String fallbackLocale,
  }) {
    final supported = supportedLocales
        .map((locale) => locale.trim())
        .where((locale) => locale.isNotEmpty)
        .toList(growable: false);
    final fallback = fallbackLocale.trim();
    if (supported.isEmpty) return fallback;

    for (final preferred in preferredLocales) {
      final match = _match(supported, preferred);
      if (match != null) return match;
    }

    return _find(
          supported,
          (locale) => _normalize(locale) == _normalize(fallback),
        ) ??
        supported.first;
  }

  static String? _match(List<String> supported, String preferred) {
    final normalized = _normalize(preferred);
    final exact = _find(
      supported,
      (locale) => _normalize(locale) == normalized,
    );
    if (exact != null) return exact;

    final language = normalized.split('-').first;
    if (language.isEmpty) return null;
    return _find(supported, (locale) => _languageCode(locale) == language);
  }

  static String? _find(
    Iterable<String> values,
    bool Function(String value) predicate,
  ) {
    for (final value in values) {
      if (predicate(value)) return value;
    }
    return null;
  }

  static String _normalize(String locale) =>
      locale.trim().replaceAll('_', '-').toLowerCase();

  static String _languageCode(String locale) =>
      _normalize(locale).split('-').first;
}

String normalizeProjectLocale(String value) {
  final locale = value.trim().replaceAll('_', '-').toLowerCase();
  if (!RegExp(r'^[a-z]{2,3}(-[a-z0-9]{2,8})*$').hasMatch(locale)) {
    throw ArgumentError.value(value, 'locale', 'Invalid project locale');
  }
  return locale;
}
