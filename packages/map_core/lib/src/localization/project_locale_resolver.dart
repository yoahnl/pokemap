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
  }) {
    final supported = supportedLocales
        .map((locale) => locale.trim())
        .where((locale) => locale.isNotEmpty)
        .toList(growable: false);
    if (supported.isEmpty) return fallbackLocale.trim();

    final preferred = preferredLocale.trim();
    final exact = _find(
      supported,
      (locale) => _normalize(locale) == _normalize(preferred),
    );
    if (exact != null) return exact;

    final language = _languageCode(preferred);
    if (language.isNotEmpty) {
      final languageMatch = _find(
        supported,
        (locale) => _languageCode(locale) == language,
      );
      if (languageMatch != null) return languageMatch;
    }

    final fallback = fallbackLocale.trim();
    return _find(
          supported,
          (locale) => _normalize(locale) == _normalize(fallback),
        ) ??
        supported.first;
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
