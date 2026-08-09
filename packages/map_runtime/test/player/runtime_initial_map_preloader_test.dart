import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  final projectFile = File(
    'test/fixtures/p3_scenario_runtime_golden_path/project.json',
  ).absolute;
  final identity = GameIdentity(
    gameId: 'org.example.runtime-fixture',
    gameVersion: '1.0.0',
    projectFormat: ProjectFormat.v1,
    saveFormat: 1,
    compatibilityId: 'fixture-v1',
  );

  test('preloads and resolves the current map of the exact saved session',
      () async {
    final timestamp = DateTime.utc(2026, 8, 9);
    final save = const GameStateSaveEnvelopeMapper().create(
      identity: identity,
      profileId: 'player-1',
      slotId: 'slot-1',
      saveId: '123e4567-e89b-42d3-a456-426614174010',
      createdAt: timestamp,
      updatedAt: timestamp,
      status: SaveStatus.active,
      playTimeSeconds: 42,
      gameState: const GameState(
        saveId: '123e4567-e89b-42d3-a456-426614174010',
        currentMapId: 'p3_test_map',
      ),
    );
    final loadedMapIds = <String>[];
    final preloader = RuntimeInitialMapPreloader(
      projectFilePath: () async => projectFile.path,
      loadSave: (address) async => address == save.address ? save : null,
      bundleLoader: ({
        required projectFilePath,
        required mapId,
        required preloadedManifest,
      }) {
        loadedMapIds.add(mapId);
        return loadRuntimeMapBundle(
          projectFilePath: projectFilePath,
          mapId: mapId,
          preloadedManifest: preloadedManifest,
        );
      },
    );

    await preloader.preloadInitialMap(
      RuntimeInitialMapPreloadRequest.continueGame(save.address),
    );
    final resolved = await preloader.resolveForSession(
      projectFilePath: projectFile.path,
      descriptor: _descriptor(
        identity,
        launchMode: GameSessionLaunchMode.continueGame,
      ),
      initialSave: save,
    );
    final anotherSlot = await preloader.resolveForSession(
      projectFilePath: projectFile.path,
      descriptor: _descriptor(
        identity,
        launchMode: GameSessionLaunchMode.load,
        slotId: 'slot-2',
      ),
      initialSave: save,
    );
    final consumed = await preloader.resolveForSession(
      projectFilePath: projectFile.path,
      descriptor: _descriptor(
        identity,
        launchMode: GameSessionLaunchMode.continueGame,
      ),
      initialSave: save,
    );

    expect(loadedMapIds, <String>['p3_test_map']);
    expect(resolved?.map.id, 'p3_test_map');
    expect(anotherSlot, isNull);
    expect(consumed, isNull);
  });

  test('preloads the authored new game map without reading a save', () async {
    final manifest = ProjectManifest.fromJson(
      jsonDecode(await projectFile.readAsString()) as Map<String, dynamic>,
    ).copyWith(
      newGame: const ProjectNewGameConfig(
        enabled: true,
        startMapId: 'p3_test_map',
      ),
    );
    var saveReads = 0;
    final preloader = RuntimeInitialMapPreloader(
      projectFilePath: () async => projectFile.path,
      loadSave: (_) async {
        saveReads++;
        return null;
      },
      manifestLoader: (_) async => manifest,
    );

    await preloader.preloadInitialMap(
      const RuntimeInitialMapPreloadRequest.newGame(),
    );
    final resolved = await preloader.resolveForSession(
      projectFilePath: projectFile.path,
      descriptor: _descriptor(
        identity,
        launchMode: GameSessionLaunchMode.newGame,
      ),
      initialSave: null,
    );

    expect(saveReads, 0);
    expect(resolved?.map.id, 'p3_test_map');
  });

  test('rejects a missing or mismatched saved session before bundle loading',
      () async {
    final address = SaveSlotAddress(
      gameId: identity.gameId,
      profileId: 'player-1',
      slotId: 'slot-1',
    );
    var bundleLoads = 0;
    final preloader = RuntimeInitialMapPreloader(
      projectFilePath: () async => projectFile.path,
      loadSave: (_) async => null,
      bundleLoader: ({
        required projectFilePath,
        required mapId,
        required preloadedManifest,
      }) async {
        bundleLoads++;
        return loadRuntimeMapBundle(
          projectFilePath: projectFilePath,
          mapId: mapId,
          preloadedManifest: preloadedManifest,
        );
      },
    );

    await expectLater(
      preloader.preloadInitialMap(
        RuntimeInitialMapPreloadRequest.continueGame(address),
      ),
      throwsStateError,
    );

    expect(bundleLoads, 0);
  });

  test('keeps an exact cache through divergent probes then consumes it once',
      () async {
    final save = _saveEnvelope(identity, mapId: 'p3_test_map');
    final divergentSave = _saveEnvelope(identity, mapId: 'another-map');
    final preloader = RuntimeInitialMapPreloader(
      projectFilePath: () async => projectFile.path,
      loadSave: (_) async => save,
    );

    await preloader.preloadInitialMap(
      RuntimeInitialMapPreloadRequest.continueGame(save.address),
    );

    expect(
      await preloader.resolveForSession(
        projectFilePath: '${projectFile.parent.path}/another-project.json',
        descriptor: _descriptor(
          identity,
          launchMode: GameSessionLaunchMode.continueGame,
        ),
        initialSave: save,
      ),
      isNull,
    );
    expect(
      await preloader.resolveForSession(
        projectFilePath: projectFile.path,
        descriptor: _descriptor(
          identity,
          launchMode: GameSessionLaunchMode.newGame,
        ),
        initialSave: null,
      ),
      isNull,
    );
    expect(
      await preloader.resolveForSession(
        projectFilePath: projectFile.path,
        descriptor: _descriptor(
          identity,
          launchMode: GameSessionLaunchMode.load,
          slotId: 'slot-2',
        ),
        initialSave: save,
      ),
      isNull,
    );
    expect(
      await preloader.resolveForSession(
        projectFilePath: projectFile.path,
        descriptor: _descriptor(
          identity,
          launchMode: GameSessionLaunchMode.continueGame,
        ),
        initialSave: divergentSave,
      ),
      isNull,
    );

    final exact = await preloader.resolveForSession(
      projectFilePath: projectFile.path,
      descriptor: _descriptor(
        identity,
        launchMode: GameSessionLaunchMode.continueGame,
      ),
      initialSave: save,
    );
    final consumed = await preloader.resolveForSession(
      projectFilePath: projectFile.path,
      descriptor: _descriptor(
        identity,
        launchMode: GameSessionLaunchMode.continueGame,
      ),
      initialSave: save,
    );

    expect(exact?.map.id, 'p3_test_map');
    expect(consumed, isNull);
  });

  test('late completion from an invalidated generation cannot restore cache',
      () async {
    final manifest = ProjectManifest.fromJson(
      jsonDecode(await projectFile.readAsString()) as Map<String, dynamic>,
    ).copyWith(
      newGame: const ProjectNewGameConfig(
        enabled: true,
        startMapId: 'p3_test_map',
      ),
    );
    final bundle = await loadRuntimeMapBundle(
      projectFilePath: projectFile.path,
      mapId: 'p3_test_map',
      preloadedManifest: manifest,
    );
    final firstStarted = Completer<void>();
    final firstGate = Completer<void>();
    var bundleLoads = 0;
    final preloader = RuntimeInitialMapPreloader(
      projectFilePath: () async => projectFile.path,
      loadSave: (_) async => null,
      manifestLoader: (_) async => manifest,
      bundleLoader: ({
        required projectFilePath,
        required mapId,
        required preloadedManifest,
      }) async {
        bundleLoads++;
        if (bundleLoads == 1) {
          firstStarted.complete();
          await firstGate.future;
        }
        return bundle;
      },
    );

    final first = preloader.preloadInitialMap(
      const RuntimeInitialMapPreloadRequest.newGame(),
    );
    await firstStarted.future;
    await preloader.preloadInitialMap(
      const RuntimeInitialMapPreloadRequest.newGame(),
    );
    final exact = await preloader.resolveForSession(
      projectFilePath: projectFile.path,
      descriptor: _descriptor(
        identity,
        launchMode: GameSessionLaunchMode.newGame,
      ),
      initialSave: null,
    );

    firstGate.complete();
    await first;
    final resurrected = await preloader.resolveForSession(
      projectFilePath: projectFile.path,
      descriptor: _descriptor(
        identity,
        launchMode: GameSessionLaunchMode.newGame,
      ),
      initialSave: null,
    );

    expect(bundleLoads, 2);
    expect(exact?.map.id, 'p3_test_map');
    expect(resurrected, isNull);
  });

  test('reports completed preload work as bounded monotone progress', () async {
    final manifest = ProjectManifest.fromJson(
      jsonDecode(await projectFile.readAsString()) as Map<String, dynamic>,
    ).copyWith(
      newGame: const ProjectNewGameConfig(
        enabled: true,
        startMapId: 'p3_test_map',
      ),
    );
    final progress = <RuntimeInitialMapPreloadProgress>[];
    final preloader = RuntimeInitialMapPreloader(
      projectFilePath: () async => projectFile.path,
      loadSave: (_) async => null,
      manifestLoader: (_) async => manifest,
    );

    await preloader.preloadInitialMap(
      const RuntimeInitialMapPreloadRequest.newGame(),
      onProgress: progress.add,
    );

    expect(
      progress.map((item) => item.stage),
      orderedEquals(const <RuntimeInitialMapPreloadStage>[
        RuntimeInitialMapPreloadStage.projectResolution,
        RuntimeInitialMapPreloadStage.manifest,
        RuntimeInitialMapPreloadStage.mapSelection,
        RuntimeInitialMapPreloadStage.mapData,
        RuntimeInitialMapPreloadStage.assetCatalog,
        RuntimeInitialMapPreloadStage.tilesets,
        RuntimeInitialMapPreloadStage.worldPreparation,
        RuntimeInitialMapPreloadStage.ready,
      ]),
    );
    expect(
      progress.map((item) => item.value),
      orderedEquals(
        <double>[...progress.map((item) => item.value)]..sort(),
      ),
    );
    expect(progress.last.value, 1);
  });
}

SaveEnvelope _saveEnvelope(GameIdentity identity, {required String mapId}) {
  final timestamp = DateTime.utc(2026, 8, 9);
  return const GameStateSaveEnvelopeMapper().create(
    identity: identity,
    profileId: 'player-1',
    slotId: 'slot-1',
    saveId: '123e4567-e89b-42d3-a456-426614174011',
    createdAt: timestamp,
    updatedAt: timestamp,
    status: SaveStatus.active,
    playTimeSeconds: 42,
    gameState: GameState(
      saveId: '123e4567-e89b-42d3-a456-426614174011',
      currentMapId: mapId,
    ),
  );
}

GameSessionDescriptor _descriptor(
  GameIdentity identity, {
  required GameSessionLaunchMode launchMode,
  String slotId = 'slot-1',
}) =>
    GameSessionDescriptor(
      sessionId: 'session-${launchMode.name}-$slotId',
      sessionToken: 'secret',
      identity: identity,
      profileId: 'player-1',
      slotId: slotId,
      launchMode: launchMode,
      installedVersionHandle: 'verified-fixture',
      saveReadHandle:
          launchMode == GameSessionLaunchMode.newGame ? null : 'opaque-save',
      runtimeApiVersion: '1.0.0',
      grantedCapabilities: const <String>{'map.v1'},
      locale: 'fr-FR',
      accessibility: const GameSessionAccessibilityOptions(),
    );
