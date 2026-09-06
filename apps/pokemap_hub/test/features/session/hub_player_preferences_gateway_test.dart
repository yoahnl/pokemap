import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:pokemap_hub/features/session/application/gateways/hub_player_preferences_gateway.dart';
import 'package:pokemap_hub/features/preferences/data/repositories/hub_preferences_repository_impl.dart';

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
    expect(snapshot.highContrast, isFalse);
    expect(snapshot.showInputHints, isTrue);
    expect(snapshot.touchControlsOpacity, 0.82);
    expect(snapshot.audioMix.masterVolume, 1);
    expect(snapshot.audioMix.musicVolume, 0.8);
    expect(snapshot.audioMix.effectsVolume, 0.8);
  });

  test('storage rejection restores the confirmed mix and preferences', () async {
    if (Platform.isWindows) return;
    await store.save(const PlayerPreferences());
    final mixer = RuntimeAudioMixer();
    final live = HubPlayerPreferencesGateway(
      store: store,
      fallbackLocale: 'fr',
      audioMixer: mixer,
    );
    final confirmed = await live.load();
    try {
      expect((await Process.run('chmod', ['a-w', root.path])).exitCode, 0);
      await expectLater(
        live.save(confirmed.copyWith(
          audioMix: const RuntimeAudioMix(masterVolume: 0),
        )),
        throwsA(isA<Object>()),
      );
      expect(mixer.mix.masterVolume, confirmed.audioMix.masterVolume);
      expect((await store.load()).preferences.masterVolume, 1);
    } finally {
      await Process.run('chmod', ['u+w', root.path]);
    }
  });

  test('host defaults keep the system locale and Hub mix after user changes',
      () async {
    final english = HubPlayerPreferencesGateway(
      store: store,
      fallbackLocale: 'en-GB',
    );
    await english.save((await english.load()).copyWith(
      locale: 'fr',
      audioMix: const RuntimeAudioMix(masterVolume: 0.2, musicVolume: 0),
    ));
    final defaults = english.defaultPreferences;
    expect(defaults.locale, 'en-GB');
    expect(defaults.audioMix.masterVolume, 1);
    expect(defaults.audioMix.musicVolume, 0.8);
    expect(defaults.audioMix.effectsVolume, 0.8);
    expect((await english.load()).locale, 'fr');
    await english.save(defaults);
    final restored = await english.load();
    expect(restored.locale, 'en');
    expect(restored.audioMix.masterVolume, 1);
    expect(restored.audioMix.musicVolume, 0.8);
    expect(restored.audioMix.effectsVolume, 0.8);
  });

  test('persists runtime accessibility and every audio bus', () async {
    await store.save(
      const PlayerPreferences(
        language: PlayerLanguage.en,
        masterVolume: 0.4,
        musicVolume: 0.3,
        effectsVolume: 0.2,
        touchControlsOpacity: 0.6,
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
        touchControlsOpacity: 0.45,
        highContrast: true,
        showInputHints: false,
        audioMix: RuntimeAudioMix(
          masterVolume: 0.9,
          musicVolume: 0.7,
          effectsVolume: 0.5,
        ),
      ),
    );

    final persisted = (await store.load()).preferences;
    expect(persisted.language, PlayerLanguage.fr);
    expect(persisted.reducedMotion, isTrue);
    expect(persisted.textScale, 1.4);
    expect(persisted.hapticsEnabled, isFalse);
    expect(persisted.highContrast, isTrue);
    expect(persisted.showInputHints, isFalse);
    expect(persisted.masterVolume, 0.9);
    expect(persisted.musicVolume, 0.7);
    expect(persisted.effectsVolume, 0.5);
    expect(persisted.touchControlsOpacity, 0.45);
  });

  test('projects persisted bus transitions into active runtime channels',
      () async {
    final mixer = RuntimeAudioMixer();
    final volumes = <double>[];
    await mixer.register(
      channel: 'title',
      route: RuntimeAudioRoute.title,
      setVolume: (volume) async => volumes.add(volume),
    );
    final liveGateway = HubPlayerPreferencesGateway(
      store: store,
      fallbackLocale: 'fr-FR',
      audioMixer: mixer,
    );
    await store.save(
      const PlayerPreferences(
        masterVolume: 0.5,
        musicVolume: 0.4,
        effectsVolume: 0.2,
      ),
    );

    final loaded = await liveGateway.load();
    expect(loaded.audioMix.musicVolume, 0.4);
    expect(volumes.last, 0.2);

    await liveGateway.save(
      loaded.copyWith(
        audioMix: const RuntimeAudioMix(
          masterVolume: 0.8,
          musicVolume: 0.5,
          effectsVolume: 0.25,
        ),
      ),
    );
    expect(volumes.last, 0.4);
  });
}
