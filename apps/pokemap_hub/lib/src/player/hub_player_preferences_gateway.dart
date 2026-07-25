import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

import '../ui/preferences/hub_preferences_store.dart';

/// Projects global Hub preferences into the runtime's data-only contract.
final class HubPlayerPreferencesGateway implements PlayerPreferencesGateway {
  HubPlayerPreferencesGateway({
    required this.store,
    required String fallbackLocale,
  }) : fallbackLocale = fallbackLocale.trim() {
    if (this.fallbackLocale.isEmpty) {
      throw ArgumentError.value(
        fallbackLocale,
        'fallbackLocale',
        'must not be empty',
      );
    }
  }

  final HubPreferencesStore store;
  final String fallbackLocale;

  @override
  Future<PlayerPreferencesSnapshot> load() async {
    final preferences = (await store.load()).preferences;
    return PlayerPreferencesSnapshot(
      locale: _runtimeLocale(preferences.language),
      accessibility: GameSessionAccessibilityOptions(
        reducedMotion: preferences.reducedMotion,
        textScale: preferences.textScale,
        hapticsEnabled: preferences.hapticsEnabled,
      ),
    );
  }

  @override
  Future<void> save(PlayerPreferencesSnapshot preferences) async {
    final current = (await store.load()).preferences;
    await store.save(
      current.copyWith(
        language: _playerLanguage(preferences.locale),
        reducedMotion: preferences.accessibility.reducedMotion,
        textScale: preferences.accessibility.textScale,
        hapticsEnabled: preferences.accessibility.hapticsEnabled,
      ),
    );
  }

  String _runtimeLocale(PlayerLanguage language) => switch (language) {
        PlayerLanguage.system => fallbackLocale,
        PlayerLanguage.fr => 'fr',
        PlayerLanguage.en => 'en',
      };
}

PlayerLanguage _playerLanguage(String locale) =>
    switch (locale.split(RegExp('[-_]')).first.toLowerCase()) {
      'fr' => PlayerLanguage.fr,
      'en' => PlayerLanguage.en,
      _ => PlayerLanguage.system,
    };
