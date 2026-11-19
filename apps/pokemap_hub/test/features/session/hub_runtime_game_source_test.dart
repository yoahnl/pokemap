import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/core/config/avelune_host_compatibility.dart';
import 'package:pokemap_hub/features/installation/data/repositories/installed_project_smoke.dart';
import 'package:pokemap_hub/features/preferences/data/repositories/hub_preferences_repository_impl.dart';
import 'package:pokemap_hub/features/saves/data/repositories/game_save_update_preparation.dart';
import 'package:pokemap_hub/pokemap_hub_player.dart';

import '../../support/runtime_player_hub_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('hub-runtime-source-');
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test(
    'projects only the verified current install into a session descriptor',
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
      expect(
        descriptor.locales!.supportedLocales,
        launch.manifest.locales.supported,
      );
      expect(
        descriptor.locales!.fallbackLocale,
        launch.manifest.locales.defaultLocale,
      );
      expect(descriptor.accessibility.reducedMotion, isTrue);
      expect(descriptor.accessibility.textScale, 1.25);
      expect(descriptor.accessibility.hapticsEnabled, isFalse);
      expect(descriptor.saveReadHandle, 'opaque-save-handle');
      await preferences.save(
        const PlayerPreferencesSnapshot(
          locale: 'en',
          accessibility: GameSessionAccessibilityOptions(),
        ),
      );
      final next = await source.createSessionDescriptor(
        launchMode: GameSessionLaunchMode.continueGame,
        profileId: 'player-1',
        slotId: 'slot-2',
        saveReadHandle: 'opaque-save-handle',
      );
      expect(next.locale, 'en');
      expect(
        next.locales!.resolve('unsupported'),
        launch.manifest.locales.defaultLocale,
      );
    },
  );

  test(
    'continues a frozen Studio 0.3.31 export after changing Player language',
    () async {
      final fixture = File(
        '../../packages/map_distribution/test/fixtures/compatibility/'
        'avelune_studio_0_3_31_331/overworld.avelunegame.base64',
      );
      final bytes = base64Decode(
        (await fixture.readAsString()).replaceAll(RegExp(r'\s'), ''),
      );
      expect(
        sha256.convert(bytes).toString(),
        '889914c913424b9225afba1ce26593f9141d140be6e35938a95164a9788bd9ea',
      );
      final packageFile = File(p.join(root.path, 'baseline.avelunegame'));
      await packageFile.writeAsBytes(bytes);
      final supportRoot = Directory(p.join(root.path, 'support'));
      final compatibility = aveluneHostCompatibility();
      final installed = await GamePackageInstaller(
        supportRoot: supportRoot,
        inspector: GamePackageInspector(hostCompatibility: compatibility),
        availableDiskBytes: (_) async => 1024 * 1024 * 1024,
        loadSmoke: loadInstalledProjectSmoke,
        prepareSavesForUpdate: GameSaveUpdatePreparation(
          supportRoot: supportRoot,
        ).call,
      ).install(packageFile, source: GamePackageInstallSource.localFile);
      final launch = await InstalledGameLaunchResolver(
        supportRoot: supportRoot,
        hostCompatibility: compatibility,
      ).resolve(installed.game);
      expect(launch.identity.gameId, 'games.example.baseline');
      expect(launch.manifest.locales.supported, ['fr']);

      final projectFile = await launch.assets.resolveReference(launch.project);
      final saves = HubSaveStore(
        supportRoot: supportRoot,
        identity: launch.identity,
      );
      final saveGateway = HubPlayerSaveGateway(store: saves);
      final preferences = HubPlayerPreferencesGateway(
        store: HubPreferencesStore(supportRoot: supportRoot),
        fallbackLocale: launch.manifest.locales.defaultLocale,
        systemLocales: () => ['fr-CA'],
      );
      final preloader = RuntimeInitialMapPreloader(
        projectFilePath: () async => projectFile.path,
        loadSave: saveGateway.readLaunchableEnvelope,
      );
      PlayableMapGame? mounted;
      final sessions = GameSessionController(
        adapterFactory: HubInProcessSessionFactory(
          launch: launch,
          saves: saves,
          mountGame: (game) async => mounted = game,
          unmountGame: (_) async => mounted = null,
          preloadedInitialMap: preloader.resolveForSession,
        ).call,
        commitCheckpoint: saveGateway.commit,
      );
      final coordinator = RuntimePlayerCoordinator(
        gameSource: HubRuntimeGameSource(
          launch: launch,
          preferencesGateway: preferences,
        ),
        preferencesGateway: preferences,
        saveGateway: saveGateway,
        newGameFlow: RuntimeProjectNewGameFlowPort(
          projectFilePath: () async => projectFile.path,
          initialMapPreloader: preloader,
        ),
        sessionController: sessions,
        externalExit: HubRuntimeExternalExit(() async {}),
      );
      addTearDown(coordinator.dispose);

      Future<void> dispatch(
        RuntimePlayerAction action, {
        Object? payload,
      }) async {
        final result = await coordinator.dispatch(
          RuntimePlayerCommand(
            action: action,
            snapshotRevision: coordinator.snapshot.revision,
            payload: payload,
          ),
        );
        expect(
          result.status,
          RuntimePlayerCommandStatus.accepted,
          reason: result.safeMessage,
        );
      }

      Future<void> waitForPlay() async {
        final snapshot = coordinator.snapshot;
        final finished = switch (snapshot.phase) {
          RuntimePlayerPhase.playing || RuntimePlayerPhase.error => snapshot,
          _ =>
            await coordinator.snapshots
                .firstWhere(
                  (update) =>
                      update.phase == RuntimePlayerPhase.playing ||
                      update.phase == RuntimePlayerPhase.error,
                )
                .timeout(const Duration(seconds: 10)),
        };
        expect(
          finished.phase,
          RuntimePlayerPhase.playing,
          reason: finished.failure?.safeMessage,
        );
      }

      const slot = RuntimePlayerLoadSlot(profileId: 'player1', slotId: 'slot1');
      final address = SaveSlotAddress(
        gameId: launch.identity.gameId,
        profileId: slot.profileId,
        slotId: slot.slotId,
      );
      await coordinator.initialize();
      expect(coordinator.snapshot.preferences?.locale, 'fr');
      await dispatch(RuntimePlayerAction.newGame, payload: slot);
      await waitForPlay();
      final started = mounted!.gameStateSnapshot;
      expect(started.currentMapId, 'runtime_harbor');
      await dispatch(RuntimePlayerAction.openMenu);
      await dispatch(RuntimePlayerAction.save);
      final saved = await saveGateway.readLaunchableEnvelope(address);
      expect(saved?.saveFormat, SaveEnvelopeCodec.currentSaveFormat);
      expect(saved?.saveId, started.saveId);
      expect(const SaveEnvelopeCodec().verifyChecksum(saved!), isTrue);

      await dispatch(RuntimePlayerAction.openOptions);
      await dispatch(
        RuntimePlayerAction.updatePreferences,
        payload: coordinator.snapshot.preferences!.copyWith(
          languageChange: RuntimePlayerLanguageChoice.explicit('en'),
        ),
      );
      expect(coordinator.snapshot.preferences?.locale, 'en');
      expect(sessions.snapshot.descriptor?.locale, 'fr');
      await dispatch(RuntimePlayerAction.returnToPauseRoot);
      await dispatch(
        RuntimePlayerAction.returnToTitle,
        payload: const RuntimePlayerExitRequest(saveBeforeExit: false),
      );
      expect(coordinator.snapshot.phase, RuntimePlayerPhase.title);
      expect(mounted, isNull);
      expect(
        (await saveGateway.readLaunchableEnvelope(address))?.checksum,
        saved.checksum,
      );

      await dispatch(RuntimePlayerAction.continueGame, payload: slot);
      await waitForPlay();
      final resumed = mounted!.gameStateSnapshot;
      expect(coordinator.snapshot.preferences?.locale, 'en');
      expect(sessions.snapshot.descriptor?.locale, 'fr');
      expect(resumed.saveId, started.saveId);
      expect(resumed.currentMapId, started.currentMapId);
      expect(resumed.playerPosition, started.playerPosition);
      expect(resumed.playerFacing, started.playerFacing);
      expect(resumed.trainerProfile.name, started.trainerProfile.name);
      expect(resumed.trainerProfile.money, started.trainerProfile.money);
      expect(resumed.bag, started.bag);
      expect(resumed.storyFlags, started.storyFlags);
      expect(
        resumed.narrativeFactRuntimeState,
        started.narrativeFactRuntimeState,
      );
      expect(await packageFile.readAsBytes(), bytes);
    },
  );

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
