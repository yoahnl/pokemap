import 'package:map_runtime/map_runtime.dart';

import 'player_preferences.dart';

final class PlayerLocaleResolution {
  const PlayerLocaleResolution._({
    required this.appLocale,
    required this.playerLocale,
    required this.preferredContentLocales,
  });

  final String appLocale;
  final String playerLocale;
  final List<String> preferredContentLocales;
}

PlayerLocaleResolution resolvePlayerLocales({
  required PlayerPreferences preferences,
  required Iterable<String> systemLocales,
  required Iterable<String> supportedAppLocales,
  required Iterable<String> supportedPlayerLocales,
}) {
  final appCandidates = preferences.language == PlayerLanguage.system
      ? _normalizeLocales(systemLocales).toList(growable: false)
      : [preferences.language.name];
  final explicitPlayerLocale = preferences.playerLanguage.languageTag;
  final playerCandidates = explicitPlayerLocale == null
      ? appCandidates
      : [explicitPlayerLocale];

  return PlayerLocaleResolution._(
    appLocale: _resolveInterfaceLocale(appCandidates, supportedAppLocales),
    playerLocale: _resolveInterfaceLocale(
      playerCandidates,
      supportedPlayerLocales,
    ),
    preferredContentLocales: List.unmodifiable(playerCandidates),
  );
}

Iterable<String> _normalizeLocales(Iterable<String> locales) =>
    locales.map(RuntimePlayerLanguageChoice.tryNormalizeLanguageTag).nonNulls;

String _resolveInterfaceLocale(
  Iterable<String> candidates,
  Iterable<String> supportedLocales,
) {
  final supported = _normalizeLocales(supportedLocales).toSet();
  for (final candidate in candidates) {
    if (supported.contains(candidate)) return candidate;
    final language = candidate.split('-').first;
    if (supported.contains(language)) return language;
  }
  return 'en';
}
