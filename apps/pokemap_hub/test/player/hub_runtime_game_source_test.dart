import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:pokemap_hub/src/player/hub_player_preferences_gateway.dart';
import 'package:pokemap_hub/src/player/hub_runtime_external_exit.dart';
import 'package:pokemap_hub/src/player/hub_runtime_game_source.dart';
import 'package:pokemap_hub/src/ui/preferences/hub_preferences_store.dart';

import '../support/runtime_player_hub_fixture.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('hub-runtime-source-');
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('projects only the verified current install into a session descriptor',
      () async {
    final launch = await createRuntimePlayerLaunchContext(root);
    final preferences = HubPlayerPreferencesGateway(
      store: HubPreferencesStore(supportRoot: root),
      fallbackLocale: launch.manifest.locales.defaultLocale,
    );
    await preferences.save(
      const PlayerPreferencesSnapshot(
        locale: 'fr',
        accessibility: GameSessionAccessibilityOptions(
          reducedMotion: true,
          textScale: 1.25,
          hapticsEnabled: false,
        ),
      ),
    );
    final source = HubRuntimeGameSource(
      launch: launch,
      preferencesGateway: preferences,
      sessionIdFactory: () => 'session-from-hub',
      sessionTokenFactory: () => 'secret-from-hub',
    );

    final descriptor = await source.createSessionDescriptor(
      launchMode: GameSessionLaunchMode.continueGame,
      profileId: 'player-1',
      slotId: 'slot-2',
      saveReadHandle: 'opaque-save-handle',
    );

    expect(source.identity, launch.identity);
    expect(source.displayTitle, launch.manifest.title);
    expect(descriptor.identity, launch.identity);
    expect(descriptor.sessionId, 'session-from-hub');
    expect(descriptor.sessionToken, 'secret-from-hub');
    expect(descriptor.installedVersionHandle, launch.installedVersionHandle);
    expect(descriptor.runtimeApiVersion, launch.runtimeApiVersion);
    expect(descriptor.grantedCapabilities, launch.grantedCapabilities);
    expect(descriptor.locale, 'fr-FR');
    expect(descriptor.accessibility.reducedMotion, isTrue);
    expect(descriptor.accessibility.textScale, 1.25);
    expect(descriptor.accessibility.hapticsEnabled, isFalse);
    expect(descriptor.saveReadHandle, 'opaque-save-handle');
  });

  test('external exit awaits the Hub callback', () async {
    var returned = false;
    final exit = HubRuntimeExternalExit(() async {
      await Future<void>.delayed(Duration.zero);
      returned = true;
    });

    await exit.returnToHost();

    expect(returned, isTrue);
  });
}
