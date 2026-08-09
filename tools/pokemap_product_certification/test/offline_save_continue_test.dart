import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/pokemap_hub_player.dart';
import 'package:pokemap_product_certification/pokemap_product_certification.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'installed neutral game saves, unloads and continues without source',
    () async => HttpOverrides.runZoned(
      () async {
        final root = await Directory.systemTemp.createTemp(
          'pokemap-phase8-offline-',
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
        final installer = _installer(
          supportRoot: supportRoot,
          fixture: fixture,
        );
        final installed = await installer.install(
          packageFile,
          source: GamePackageInstallSource.localExport,
        );
        await authorRoot.delete(recursive: true);
        await packageFile.delete();

        final launch = await InstalledGameLaunchResolver(
          supportRoot: supportRoot,
          hostCompatibility: fixture.hostCompatibility,
        ).resolve(installed.game);
        final store = HubSaveStore(
          supportRoot: supportRoot,
          identity: launch.identity,
        );
        final newGame = _descriptor(
          launch,
          mode: GameSessionLaunchMode.newGame,
          sessionId: 'neutral-new-game',
        );
        var mountCount = 0;
        var unmountCount = 0;
        final firstAdapter = HubInProcessSessionFactory(
          launch: launch,
          saves: store,
          mountGame: (_) async => mountCount++,
          unmountGame: (_) async => unmountCount++,
          saveIdFactory: () => '123e4567-e89b-42d3-a456-426614174000',
          now: () => DateTime.utc(2026, 7, 25, 12),
        ).call(newGame);
        await firstAdapter.prepare(newGame);
        await firstAdapter.start();
        final checkpoint = await firstAdapter.captureCheckpoint();
        expect(checkpoint, isNotNull);
        expect(checkpoint!.state['currentMapId'], fixture.mapId);
        await HubSessionCheckpointCommitter(store: store).commit(
          GameSessionCheckpointCommit(
            descriptor: newGame.publicContext,
            checkpoint: checkpoint,
            status: SaveStatus.active,
          ),
        );
        await firstAdapter.stop(GameSessionExitReason.hub);
        await firstAdapter.dispose();
        expect(mountCount, 1);
        expect(unmountCount, 1);

        final saved = await store.findContinue(profileId: 'player1');
        expect(saved?.canContinue, isTrue);
        final continued = _descriptor(
          launch,
          mode: GameSessionLaunchMode.continueGame,
          sessionId: 'neutral-continue',
          saveReadHandle: hubSaveReadHandle(saved!.envelope!),
        );
        final secondAdapter = HubInProcessSessionFactory(
          launch: launch,
          saves: store,
          mountGame: (_) async => mountCount++,
          unmountGame: (_) async => unmountCount++,
          now: () => DateTime.utc(2026, 7, 25, 12, 1),
        ).call(continued);
        await secondAdapter.prepare(continued);
        await secondAdapter.start();
        final resumed = await secondAdapter.captureCheckpoint();

        expect(resumed?.saveId, checkpoint.saveId);
        expect(resumed?.state['currentMapId'], fixture.mapId);
        expect(await authorRoot.exists(), isFalse);
        expect(await packageFile.exists(), isFalse);
        await secondAdapter.stop(GameSessionExitReason.hub);
        await secondAdapter.dispose();
        expect(mountCount, 2);
        expect(unmountCount, 2);
      },
      createHttpClient: (_) {
        throw StateError('Network access is disabled for the offline journey.');
      },
    ),
  );
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

GameSessionDescriptor _descriptor(
  InstalledGameLaunchContext launch, {
  required GameSessionLaunchMode mode,
  required String sessionId,
  String? saveReadHandle,
}) => GameSessionDescriptor(
  sessionId: sessionId,
  sessionToken: 'opaque-session-token',
  identity: launch.identity,
  profileId: 'player1',
  slotId: 'slot1',
  launchMode: mode,
  installedVersionHandle: launch.installedVersionHandle,
  saveReadHandle: saveReadHandle,
  runtimeApiVersion: launch.runtimeApiVersion,
  grantedCapabilities: launch.grantedCapabilities,
  locale: 'en',
  accessibility: const GameSessionAccessibilityOptions(),
);
