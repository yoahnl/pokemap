import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

import '../ui/preferences/hub_preferences_store.dart';

/// Projects global Hub preferences into the runtime's data-only contract.
final class HubPlayerPreferencesGateway implements PlayerPreferencesGateway {
  HubPlayerPreferencesGateway({
    required this.store,
    required String fallbackLocale,
    this.audioMixer,
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
  final RuntimeAudioMixer? audioMixer;

  @override
  Future<PlayerPreferencesSnapshot> load() async {
    final preferences = (await store.load()).preferences;
    final audioMix = RuntimeAudioMix(
      masterVolume: preferences.masterVolume,
      musicVolume: preferences.musicVolume,
      effectsVolume: preferences.effectsVolume,
    );
    await audioMixer?.transitionTo(audioMix);
    return PlayerPreferencesSnapshot(
      locale: _runtimeLocale(preferences.language),
      accessibility: GameSessionAccessibilityOptions(
        reducedMotion: preferences.reducedMotion,
        textScale: preferences.textScale,
        hapticsEnabled: preferences.hapticsEnabled,
      ),
      touchControlsOpacity: preferences.touchControlsOpacity,
      audioMix: audioMix,
      highContrast: preferences.highContrast,
      showInputHints: preferences.showInputHints,
    );
  }

  @override
  Future<void> save(PlayerPreferencesSnapshot preferences) async {
    final current = (await store.load()).preferences;
    await audioMixer?.transitionTo(preferences.audioMix);
    await store.save(
      current.copyWith(
        language: _playerLanguage(preferences.locale),
        reducedMotion: preferences.accessibility.reducedMotion,
        textScale: preferences.accessibility.textScale,
        hapticsEnabled: preferences.accessibility.hapticsEnabled,
        touchControlsOpacity: preferences.touchControlsOpacity,
        masterVolume: preferences.audioMix.masterVolume,
        musicVolume: preferences.audioMix.musicVolume,
        effectsVolume: preferences.audioMix.effectsVolume,
        highContrast: preferences.highContrast,
        showInputHints: preferences.showInputHints,
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
