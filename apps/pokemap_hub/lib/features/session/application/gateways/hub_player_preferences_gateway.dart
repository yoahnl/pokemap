import 'package:map_player_ui/map_player_ui.dart' show PlayerPreferences;
import 'package:map_runtime/map_runtime.dart';

import 'package:pokemap_hub/features/preferences/domain/repositories/player_preferences_repository_interface.dart';

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

  final PlayerPreferencesRepositoryInterface store;
  final String fallbackLocale;
  final RuntimeAudioMixer? audioMixer;

  @override
  PlayerPreferencesSnapshot get defaultPreferences =>
      const PlayerPreferences().toRuntimeSnapshot(fallbackLocale: fallbackLocale);

  @override
  Future<PlayerPreferencesSnapshot> load() async {
    final preferences = (await store.load()).preferences;
    final snapshot = preferences.toRuntimeSnapshot(fallbackLocale: fallbackLocale);
    await audioMixer?.transitionTo(snapshot.audioMix);
    return snapshot;
  }

  @override
  Future<void> save(PlayerPreferencesSnapshot preferences) async {
    final current = (await store.load()).preferences;
    try {
      await audioMixer?.transitionTo(preferences.audioMix);
      await store.save(current.copyWithRuntimeSnapshot(preferences));
    } on Object {
      await audioMixer?.transitionTo(
        current.toRuntimeSnapshot(fallbackLocale: fallbackLocale).audioMix,
      );
      rethrow;
    }
  }
}
