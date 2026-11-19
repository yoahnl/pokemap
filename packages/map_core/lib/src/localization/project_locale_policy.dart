import 'project_locale_resolver.dart';

final class ProjectLocalePolicy {
  ProjectLocalePolicy({
    required Iterable<String> supportedLocales,
    required String fallbackLocale,
  }) : supportedLocales = List.unmodifiable(supportedLocales),
       fallbackLocale = fallbackLocale.trim() {
    final normalized = this.supportedLocales.map(_normalize).toSet();
    if (normalized.isEmpty ||
        normalized.contains('') ||
        normalized.length != this.supportedLocales.length ||
        !normalized.contains(_normalize(this.fallbackLocale))) {
      throw ArgumentError(
        'Project locales require a unique set and a supported fallback.',
      );
    }
  }

  final List<String> supportedLocales;
  final String fallbackLocale;

  String resolve(String preferredLocale) => resolvePreferred([preferredLocale]);

  String resolvePreferred(Iterable<String> preferredLocales) =>
      ProjectLocaleResolver.resolvePreferred(
        preferredLocales: preferredLocales,
        supportedLocales: supportedLocales,
        fallbackLocale: fallbackLocale,
      );

  static String _normalize(String value) => normalizeProjectLocale(value);
}
