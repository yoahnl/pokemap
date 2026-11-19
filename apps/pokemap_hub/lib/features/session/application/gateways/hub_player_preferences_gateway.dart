import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

import 'package:pokemap_hub/features/preferences/domain/repositories/player_preferences_repository_interface.dart';

/// Projects global Hub preferences into the runtime's data-only contract.
final class HubPlayerPreferencesGateway implements PlayerPreferencesGateway {
  HubPlayerPreferencesGateway({
    required this.store,
    required String fallbackLocale,
    this.audioMixer,
    this.systemLocales,
  }) : fallbackLocale = fallbackLocale.trim() {
    if (this.fallbackLocale.isEmpty) {
      throw ArgumentError.value(
        fallbackLocale,
        'fallbackLocale',
        'must not be empty',
      );
    }
  }

  final PlayerPreferencesRepositoryInterface store;
  final String fallbackLocale;
  final RuntimeAudioMixer? audioMixer;
  final Iterable<String> Function()? systemLocales;

  @override
  PlayerPreferencesSnapshot get defaultPreferences =>
      project(const PlayerPreferences());

  PlayerPreferencesSnapshot project(PlayerPreferences preferences) {
    final snapshot = preferences.toRuntimeSnapshot(
      fallbackLocale: fallbackLocale,
    );
    final readSystemLocales = systemLocales;
    if (readSystemLocales == null) return snapshot;
    final supported = PokeMapPlayerLocalizations.supportedLocales.map(
      (locale) => locale.toLanguageTag(),
    );
    final locales = resolvePlayerLocales(
      preferences: preferences,
      systemLocales: readSystemLocales(),
      supportedAppLocales: supported,
      supportedPlayerLocales: supported,
    );
    return snapshot.copyWith(
      locale: locales.playerLocale,
      playerLanguage: preferences.playerLanguage,
      preferredContentLocales: locales.preferredContentLocales,
    );
  }

  @override
  Future<PlayerPreferencesSnapshot> load() async {
    final snapshot = await read();
    await audioMixer?.transitionTo(snapshot.audioMix);
    return snapshot;
  }

  Future<PlayerPreferencesSnapshot> read() async =>
      project((await store.load()).preferences);

  @override
  Future<void> save(PlayerPreferencesSnapshot preferences) async {
    final languageChange = preferences.languageChange;
    if (systemLocales != null && languageChange != null) {
      await store.update(
        (latest) => latest.copyWith(playerLanguage: languageChange),
      );
      return;
    }
    final current = (await store.load()).preferences;
    try {
      await audioMixer?.transitionTo(preferences.audioMix);
      await store.update((latest) {
        final edited = latest.copyWithRuntimeSnapshot(preferences);
        if (systemLocales == null) return edited;
        return edited.copyWith(language: latest.language);
      });
    } on Object {
      await audioMixer?.transitionTo(project(current).audioMix);
      rethrow;
    }
  }
}
