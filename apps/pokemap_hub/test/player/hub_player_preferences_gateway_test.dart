import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:pokemap_hub/src/player/hub_player_preferences_gateway.dart';
import 'package:pokemap_hub/src/ui/preferences/hub_preferences_store.dart';

void main() {
  late Directory root;
  late HubPreferencesStore store;
  late HubPlayerPreferencesGateway gateway;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('hub-player-preferences-');
    store = HubPreferencesStore(supportRoot: root);
    gateway = HubPlayerPreferencesGateway(
      store: store,
      fallbackLocale: 'fr-FR',
    );
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('projects safe defaults when no preferences were persisted', () async {
    final snapshot = await gateway.load();

    expect(snapshot.locale, 'fr-FR');
    expect(snapshot.accessibility.reducedMotion, isFalse);
    expect(snapshot.accessibility.textScale, 1);
    expect(snapshot.accessibility.hapticsEnabled, isTrue);
  });

  test('persists runtime accessibility without losing global audio settings',
      () async {
    await store.save(
      const PlayerPreferences(
        language: PlayerLanguage.en,
        masterVolume: 0.4,
        musicVolume: 0.3,
        effectsVolume: 0.2,
      ),
    );

    await gateway.save(
      const PlayerPreferencesSnapshot(
        locale: 'fr',
        accessibility: GameSessionAccessibilityOptions(
          reducedMotion: true,
          textScale: 1.4,
          hapticsEnabled: false,
        ),
      ),
    );

    final persisted = (await store.load()).preferences;
    expect(persisted.language, PlayerLanguage.fr);
    expect(persisted.reducedMotion, isTrue);
    expect(persisted.textScale, 1.4);
    expect(persisted.hapticsEnabled, isFalse);
    expect(persisted.masterVolume, 0.4);
    expect(persisted.musicVolume, 0.3);
    expect(persisted.effectsVolume, 0.2);
  });
}
