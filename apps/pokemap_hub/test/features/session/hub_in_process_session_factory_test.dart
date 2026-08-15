import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/pokemap_hub_player.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

void main() {
  late Directory root;
  late InstalledGameLaunchContext launch;
  late HubSaveStore saves;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('in-process-factory-');
    launch = await _context(root);
    saves = HubSaveStore(supportRoot: root, identity: launch.identity);
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test(
    'builds a single-use adapter only for the verified launch handle',
    () async {
      final factory = HubInProcessSessionFactory(
        launch: launch,
        saves: saves,
        mountGame: (_) async {},
        unmountGame: (_) async {},
      );
      final descriptor = _descriptor(launch);
      final adapter = factory.call(descriptor);

      expect(adapter, isA<InProcessGameSessionAdapter>());
      await adapter.prepare(descriptor);
      await adapter.dispose();

      final wrong = GameSessionDescriptor(
        sessionId: 'session-other',
        sessionToken: 'secret-other',
        identity: launch.identity,
        profileId: 'player-1',
        slotId: 'slot-1',
        launchMode: GameSessionLaunchMode.newGame,
        installedVersionHandle: 'another-install',
        runtimeApiVersion: '1.0.0',
        grantedCapabilities: const <String>{},
        locale: 'fr-FR',
        accessibility: const GameSessionAccessibilityOptions(),
        initialGameState: const GameState(
          saveId: 'slot-1',
          currentMapId: 'map-start',
        ),
      );
      expect(() => factory.call(wrong), throwsStateError);
    },
  );

  test('forwards one exact preloaded bundle into the Hub session', () async {
    final projectFile =
        File(
          '../../packages/map_runtime/test/fixtures/'
          'p3_scenario_runtime_golden_path/project.json',
        ).absolute;
    final bundle = await loadRuntimeMapBundle(
      projectFilePath: projectFile.path,
      mapId: 'p3_test_map',
    );
    final timestamp = DateTime.utc(2026, 8, 9);
    final save = const GameStateSaveEnvelopeMapper().create(
      identity: launch.identity,
      profileId: 'player-1',
      slotId: 'slot-1',
      saveId: '123e4567-e89b-42d3-a456-426614174020',
      createdAt: timestamp,
      updatedAt: timestamp,
      status: SaveStatus.active,
      playTimeSeconds: 30,
      gameState: const GameState(
        saveId: '123e4567-e89b-42d3-a456-426614174020',
        currentMapId: 'p3_test_map',
      ),
    );
    await saves.write(save);
    var preloadReads = 0;
    var mountCount = 0;
    final factory = HubInProcessSessionFactory(
      launch: launch,
      saves: saves,
      preloadedInitialMap: ({
        required projectFilePath,
        required descriptor,
        required initialSave,
      }) async {
        preloadReads++;
        expect(descriptor.launchMode, GameSessionLaunchMode.continueGame);
        expect(initialSave?.saveId, save.saveId);
        return RuntimeInitialMapPreloadResult(bundle: bundle);
      },
      mountGame: (_) async => mountCount++,
      unmountGame: (_) async {},
    );
    final descriptor = GameSessionDescriptor(
      sessionId: 'session-preloaded',
      sessionToken: 'secret',
      identity: launch.identity,
      profileId: save.profileId,
      slotId: save.slotId,
      launchMode: GameSessionLaunchMode.continueGame,
      installedVersionHandle: launch.installedVersionHandle,
      saveReadHandle: hubSaveReadHandle(save),
      runtimeApiVersion: launch.runtimeApiVersion,
      grantedCapabilities: launch.grantedCapabilities,
      locale: 'fr-FR',
      accessibility: const GameSessionAccessibilityOptions(),
    );
    final adapter = factory.call(descriptor);

    await adapter.prepare(descriptor);
    await adapter.start();

    expect(preloadReads, 1);
    expect(mountCount, 1);
    await adapter.dispose();
  });
}

GameSessionDescriptor _descriptor(InstalledGameLaunchContext launch) =>
    GameSessionDescriptor(
      sessionId: 'session-1',
      sessionToken: 'secret',
      identity: launch.identity,
      profileId: 'player-1',
      slotId: 'slot-1',
      launchMode: GameSessionLaunchMode.newGame,
      installedVersionHandle: launch.installedVersionHandle,
      runtimeApiVersion: launch.runtimeApiVersion,
      grantedCapabilities: launch.grantedCapabilities,
      locale: 'fr-FR',
      accessibility: const GameSessionAccessibilityOptions(),
      initialGameState: const GameState(
        saveId: 'slot-1',
        currentMapId: 'map-start',
      ),
    );

Future<InstalledGameLaunchContext> _context(Directory root) async {
  final version = Directory(p.join(root.path, 'version'));
  await Directory(p.join(version.path, 'project')).create(recursive: true);
  await File(
    p.join(version.path, 'project', 'project.json'),
  ).writeAsString('{}');
  final manifest = GamePackageManifest(
    packageFormat: 1,
    gameId: 'org.example.adventure',
    gameVersion: Version.parse('1.0.0'),
    title: 'Adventure',
    author: const GamePackageParty(name: 'Example'),
    compatibility: GamePackageCompatibility(
      minHubVersion: Version.parse('1.0.0'),
      runtimeApiExpression: '^1.0.0',
      projectFormat: 'v2',
      saveFormat: 1,
      compatibilityId: 'story-v1',
      requiredCapabilities: const <String>[],
    ),
    locales: GamePackageLocales(
      defaultLocale: 'fr-FR',
      supported: const <String>['fr-FR'],
    ),
    content: GamePackageContent(
      fileCount: 1,
      totalBytes: 2,
      treeSha256: 'a' * 64,
      files: <GamePackageFileEntry>[
        GamePackageFileEntry(
          path: 'project/project.json',
          size: 2,
          sha256: 'b' * 64,
        ),
      ],
    ),
  );
  final assets = await PackageAssetResolver.create(
    versionRoot: version,
    manifest: manifest,
  );
  final identity = GameIdentity(
    gameId: manifest.gameId,
    gameVersion: manifest.gameVersion.toString(),
    projectFormat: ProjectFormat.v2,
    saveFormat: 1,
    compatibilityId: 'story-v1',
  );
  final pointer = InstalledGamePointer(
    gameVersion: manifest.gameVersion,
    treeSha256: manifest.content.treeSha256,
  );
  return InstalledGameLaunchContext(
    game: InstalledGame(
      gameId: manifest.gameId,
      title: manifest.title,
      authorName: manifest.author.name,
      defaultLocale: 'fr-FR',
      supportedLocales: const <String>['fr-FR'],
      current: pointer,
      versions: <InstalledGameVersion>[
        InstalledGameVersion(
          gameVersion: manifest.gameVersion,
          treeSha256: manifest.content.treeSha256,
          installedAt: DateTime.utc(2026, 7, 25),
          receiptFileName: 'receipt.json',
          source: GamePackageInstallSource.localFile,
          signatureStatus: PackageSignatureStatus.notPresent,
        ),
      ],
    ),
    manifest: manifest,
    identity: identity,
    assets: assets,
    project: assets.reference('project/project.json'),
    installedVersionHandle: 'verified-install',
    runtimeApiVersion: '1.0.0',
    grantedCapabilities: const <String>{},
  );
}
