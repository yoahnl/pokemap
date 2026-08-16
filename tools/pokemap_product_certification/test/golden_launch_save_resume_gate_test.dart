import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/features/preferences/domain/entities/hub_preferences_read.dart';
import 'package:pokemap_hub/features/preferences/domain/repositories/player_preferences_repository_interface.dart';
import 'package:pokemap_hub/pokemap_hub_player.dart';
import 'package:pokemap_product_certification/pokemap_product_certification.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'golden journey: title, new game, checkpoint, title, continue',
    () async => HttpOverrides.runZoned(
      () async {
        final root = await Directory.systemTemp.createTemp(
          'pokemap-golden-launch-',
        );
        addTearDown(() async {
          if (await root.exists()) await root.delete(recursive: true);
        });
        final fixture = NeutralCertificationGameFixture();
        final authorRoot = Directory(p.join(root.path, 'author'));
        final supportRoot = Directory(p.join(root.path, 'support'));
        final packageFile = File(p.join(root.path, 'neutral.avelunegame'));
        await fixture.writeAuthorWorkspace(authorRoot);
        await fixture.export(authorRoot, packageFile);
        final installed = await _installer(
          supportRoot: supportRoot,
          fixture: fixture,
        ).install(packageFile, source: GamePackageInstallSource.localExport);
        await authorRoot.delete(recursive: true);
        await packageFile.delete();

        final launch = await InstalledGameLaunchResolver(
          supportRoot: supportRoot,
          hostCompatibility: fixture.hostCompatibility,
        ).resolve(installed.game);
        final projectFile = await launch.assets.resolveReference(launch.project);

        final store = HubSaveStore(
          supportRoot: supportRoot,
          identity: launch.identity,
        );
        final saveGateway = HubPlayerSaveGateway(store: store);
        final preferences = HubPlayerPreferencesGateway(
          store: _MemoryPreferencesStore(),
          fallbackLocale: 'en',
        );
        final preloader = RuntimeInitialMapPreloader(
          projectFilePath: () async => projectFile.path,
          loadSave: saveGateway.readLaunchableEnvelope,
        );
        PlayableMapGame? mounted;
        final sessions = GameSessionController(
          adapterFactory: HubInProcessSessionFactory(
            launch: launch,
            saves: store,
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
          saveGateway: saveGateway,
          preferencesGateway: preferences,
          newGameFlow: RuntimeProjectNewGameFlowPort(
            projectFilePath: () async => projectFile.path,
            initialMapPreloader: preloader,
          ),
          sessionController: sessions,
          externalExit: HubRuntimeExternalExit(() async {}),
        );
        addTearDown(coordinator.dispose);

        await coordinator.initialize();
        expect(coordinator.snapshot.phase, RuntimePlayerPhase.title);

        expect(
          (await coordinator.dispatch(
            RuntimePlayerCommand(
              action: RuntimePlayerAction.newGame,
              snapshotRevision: coordinator.snapshot.revision,
              payload: const RuntimePlayerLoadSlot(
                profileId: 'player1',
                slotId: 'slot1',
              ),
            ),
          ))
              .status,
          RuntimePlayerCommandStatus.accepted,
        );
        await _waitForPhase(coordinator, RuntimePlayerPhase.playing);
        final started = mounted!.gameStateSnapshot;
        expect(started.trainerProfile.name, 'Ari');
        expect(started.trainerProfile.money, 300);
        expect(started.party.members, hasLength(1));
        expect(started.currentMapId, fixture.mapId);

        await _openPause(coordinator);
        expect(
          (await coordinator.dispatch(
            RuntimePlayerCommand(
              action: RuntimePlayerAction.save,
              snapshotRevision: coordinator.snapshot.revision,
            ),
          ))
              .status,
          RuntimePlayerCommandStatus.accepted,
        );
        final persisted = (await store.read(
          SaveSlotAddress(
            gameId: launch.identity.gameId,
            profileId: 'player1',
            slotId: 'slot1',
          ),
        ))
            .envelope;
        expect(persisted, isNotNull);
        expect(persisted!.state['saveId'], started.saveId);
        expect(persisted.state['currentMapId'], started.currentMapId);
        expect(
          (persisted.state['trainerProfile']! as Map<String, Object?>)['money'],
          started.trainerProfile.money,
        );
        expect(
          (persisted.state['party']! as Map<String, Object?>)['members'],
          hasLength(started.party.members.length),
        );

        expect(
          (await coordinator.dispatch(
            RuntimePlayerCommand(
              action: RuntimePlayerAction.returnToTitle,
              snapshotRevision: coordinator.snapshot.revision,
            ),
          ))
              .status,
          RuntimePlayerCommandStatus.accepted,
        );
        await _waitForPhase(coordinator, RuntimePlayerPhase.title);
        expect(mounted, isNull, reason: 'the session must be torn down');

        expect(
          (await coordinator.dispatch(
            RuntimePlayerCommand(
              action: RuntimePlayerAction.continueGame,
              snapshotRevision: coordinator.snapshot.revision,
              payload: const RuntimePlayerLoadSlot(
                profileId: 'player1',
                slotId: 'slot1',
              ),
            ),
          ))
              .status,
          RuntimePlayerCommandStatus.accepted,
        );
        await _waitForPhase(coordinator, RuntimePlayerPhase.playing);

        final resumed = mounted!.gameStateSnapshot;
        expect(resumed.saveId, started.saveId);
        expect(resumed.currentMapId, started.currentMapId);
        expect(resumed.playerPosition, started.playerPosition);
        expect(resumed.playerFacing, started.playerFacing);
        expect(resumed.trainerProfile.name, started.trainerProfile.name);
        expect(resumed.trainerProfile.money, started.trainerProfile.money);
        expect(
          resumed.party.members.map((member) => member.speciesId),
          started.party.members.map((member) => member.speciesId),
        );
        expect(resumed.bag, started.bag);
        expect(
          resumed.progression.storyFlags,
          started.progression.storyFlags,
        );
        expect(
          resumed.narrativeFactRuntimeState,
          started.narrativeFactRuntimeState,
        );
        expect(
          resumed.trainerProfile.playtimeSeconds,
          greaterThanOrEqualTo(started.trainerProfile.playtimeSeconds),
        );
        expect(await authorRoot.exists(), isFalse);
        expect(await packageFile.exists(), isFalse);
      },
      createHttpClient: (_) {
        throw StateError('Network access is disabled for the golden journey.');
      },
    ),
  );
}

Future<void> _waitForPhase(
  RuntimePlayerCoordinator coordinator,
  RuntimePlayerPhase phase,
) async {
  for (var attempt = 0; attempt < 2000; attempt++) {
    if (coordinator.snapshot.phase == phase) return;
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  fail(
    'the player never reached $phase, '
    'last phase was ${coordinator.snapshot.phase}',
  );
}

Future<void> _openPause(RuntimePlayerCoordinator coordinator) async {
  final opened = await coordinator.dispatch(
    RuntimePlayerCommand(
      action: RuntimePlayerAction.openMenu,
      snapshotRevision: coordinator.snapshot.revision,
    ),
  );
  expect(opened.status, RuntimePlayerCommandStatus.accepted);
  expect(coordinator.snapshot.phase, RuntimePlayerPhase.paused);
}

final class _MemoryPreferencesStore
    implements PlayerPreferencesRepositoryInterface {
  PlayerPreferences _preferences = const PlayerPreferences();

  @override
  Future<HubPreferencesRead> load() async => HubPreferencesRead(
        preferences: _preferences,
        source: HubPreferencesSource.defaults,
        currentCorrupt: false,
        backupCorrupt: false,
      );

  @override
  Future<void> save(PlayerPreferences preferences) async {
    _preferences = preferences;
  }
}

GamePackageInstaller _installer({
  required Directory supportRoot,
  required NeutralCertificationGameFixture fixture,
}) => GamePackageInstaller(
  supportRoot: supportRoot,
  inspector: GamePackageInspector(hostCompatibility: fixture.hostCompatibility),
  availableDiskBytes: (_) async => 1024 * 1024 * 1024,
  prepareSavesForUpdate: (_, __) async =>
      const SaveUpdatePreparation(rollbackSnapshotAvailable: true),
  loadSmoke: (stagedVersionRoot, manifest) async {
    final projectFile = File(
      p.join(stagedVersionRoot.path, 'project', 'project.json'),
    );
    final decoded = jsonDecode(await projectFile.readAsString());
    final project = ProjectManifest.fromJson(decoded as Map<String, dynamic>);
    await loadRuntimeMapBundle(
      projectFilePath: projectFile.path,
      mapId: project.newGame.startMapId,
    );
  },
);
