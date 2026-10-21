import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  test(
    'preloads and resolves the current map of the exact saved session',
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
        bundleLoader:
            ({
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
      expect(resolved?.bundle.map.id, 'p3_test_map');
      expect(anotherSlot, isNull);
      expect(consumed, isNull);
    },
  );

  test('preloads the authored new game map without reading a save', () async {
    final manifest =
        ProjectManifest.fromJson(
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
    expect(resolved?.bundle.map.id, 'p3_test_map');
  });

  test(
    'prepares the narrative map catalog before a saved session starts',
    () async {
      final save = _saveEnvelope(identity, mapId: 'p3_test_map');
      final manifest = (await loadProjectManifestFromFile(projectFile.path))
          .copyWith(
            eventRegistry: NarrativeEventRegistry(
              schemaVersion: 1,
              mode: EventSystemMode.dualRead,
              records: const [],
              legacyClaims: const [],
            ),
          );
      final progress = <RuntimeInitialMapPreloadProgress>[];
      final preloader = RuntimeInitialMapPreloader(
        projectFilePath: () async => projectFile.path,
        loadSave: (_) async => save,
        manifestLoader: (_) async => manifest,
      );

      await preloader.preloadInitialMap(
        RuntimeInitialMapPreloadRequest.continueGame(save.address),
        onProgress: progress.add,
      );
      final resolved = await preloader.resolveForSession(
        projectFilePath: projectFile.path,
        descriptor: _descriptor(
          identity,
          launchMode: GameSessionLaunchMode.continueGame,
        ),
        initialSave: save,
      );

      expect(resolved?.narrativeSnapshot?.mapsById.keys, ['p3_test_map']);
      expect(
        progress.map((step) => step.value),
        orderedEquals([...progress.map((step) => step.value)]..sort()),
      );
      expect(
        progress.any(
          (step) =>
              step.stage == RuntimeInitialMapPreloadStage.narrativeCatalog,
        ),
        isTrue,
      );
      expect(progress.last.value, 1);
      resolved?.dispose();
    },
  );

  for (final partitioned in [false, true]) {
    for (final validOffset in [false, true]) {
      test(
        'narrative map offsets use project tile dimensions, partitioned=$partitioned, valid=$validOffset',
        () async {
          final root = await Directory.systemTemp.createTemp(
            'preloader-narrative-offset-',
          );
          addTearDown(() => root.delete(recursive: true));
          final manifest = ProjectManifest(
            name: 'Narrative offsets',
            version: ProjectVersion.v8,
            settings: const ProjectSettings(tileWidth: 16, tileHeight: 24),
            maps: const [
              ProjectMapEntry(
                id: 'initial',
                name: 'Initial',
                relativePath: 'initial.json',
              ),
              ProjectMapEntry(
                id: 'other',
                name: 'Other',
                relativePath: 'other.json',
              ),
            ],
            tilesets: const [
              ProjectTilesetEntry(
                id: 'props',
                name: 'Props',
                relativePath: 'props.png',
              ),
            ],
            elementCategories: const [
              ProjectElementCategory(id: 'props', name: 'Props'),
            ],
            elements: const [
              ProjectElementEntry(
                id: 'prop',
                name: 'Prop',
                tilesetId: 'props',
                categoryId: 'props',
                frames: [
                  TilesetVisualFrame(
                    source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
                  ),
                ],
              ),
            ],
            newGame: const ProjectNewGameConfig(
              enabled: true,
              startMapId: 'initial',
            ),
            eventRegistry: NarrativeEventRegistry(
              schemaVersion: 1,
              mode: EventSystemMode.dualRead,
              records: const [],
              legacyClaims: const [],
            ),
          );
          const initialMap = MapData(
            id: 'initial',
            name: 'Initial',
            size: GridSize(width: 4, height: 4),
          );
          final otherMap = initialMap.copyWith(
            id: 'other',
            name: 'Other',
            layers: [
              MapLayer.tile(
                id: 'props',
                name: 'Props',
                cells: List.filled(16, 0),
              ),
            ],
            placedElements: [
              MapPlacedElement(
                id: 'placed-prop',
                layerId: 'props',
                elementId: 'prop',
                pos: const GridPos(x: 1, y: 1),
                pixelOffset: validOffset
                    ? const PixelOffset(x: 1, y: 23)
                    : const PixelOffset(x: 16, y: 0),
                properties: const {
                  pokemapPlacementOriginProperty:
                      pokemapPlacementOriginAuthored,
                },
              ),
            ],
          );
          final file = File('${root.path}/project.json');
          if (partitioned) {
            final publication = PortableCatalogPublication.encodeProject(
              manifest,
            );
            await file.writeAsString(jsonEncode(publication.descriptor));
            for (final object in publication.storage.objects.entries) {
              final target = File(
                '${root.path}/catalog/objects/${object.key}.json',
              );
              await target.parent.create(recursive: true);
              await target.writeAsBytes(object.value);
            }
          } else {
            await file.writeAsString(jsonEncode(manifest.toJson()));
          }
          await File('${root.path}/initial.json')
              .writeAsString(jsonEncode(initialMap.toJson()));
          await File('${root.path}/other.json')
              .writeAsString(jsonEncode(otherMap.toJson()));
          final preloader = RuntimeInitialMapPreloader(
            projectFilePath: () async => file.path,
            loadSave: (_) async => null,
          );
          addTearDown(preloader.clear);
          final preload = preloader.preloadInitialMap(
            const RuntimeInitialMapPreloadRequest.newGame(),
          );
          if (!validOffset) {
            await expectLater(
              preload,
              throwsA(
                isA<MapLoadException>().having(
                  (error) => error.message,
                  'message',
                  contains('Placed element pixel offsets must be normalized'),
                ),
              ),
            );
            return;
          }
          await preload;
          final resolved = await preloader.resolveForSession(
            projectFilePath: file.path,
            descriptor: _descriptor(
              identity,
              launchMode: GameSessionLaunchMode.newGame,
            ),
            initialSave: null,
          );
          addTearDown(() => resolved?.dispose());
          expect(
            resolved
                ?.narrativeSnapshot
                ?.mapsById['other']
                ?.placedElements
                .single
                .pixelOffset,
            const PixelOffset(x: 1, y: 23),
          );
        },
      );
    }
  }

  test(
    'rejects a missing or mismatched saved session before bundle loading',
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
        bundleLoader:
            ({
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
    },
  );

  test(
    'keeps an exact cache through divergent probes then consumes it once',
    () async {
      final save = _saveEnvelope(identity, mapId: 'p3_test_map');
      final divergentSave = _saveEnvelope(identity, mapId: 'another-map');
      final changedState = _saveEnvelope(
        identity,
        mapId: 'p3_test_map',
        money: 10,
      );
      final preloader = RuntimeInitialMapPreloader(
        expectedIdentity: identity,
        projectFilePath: () async => projectFile.path,
        loadSave: (_) async => save,
      );

      await preloader.preloadInitialMap(
        RuntimeInitialMapPreloadRequest.continueGame(save.address),
      );

      expect(
        await preloader.resolveForSession(
          projectFilePath: projectFile.path,
          descriptor: _descriptor(
            GameIdentity(
              gameId: identity.gameId,
              gameVersion: '2.0.0',
              projectFormat: identity.projectFormat,
              saveFormat: identity.saveFormat,
              compatibilityId: identity.compatibilityId,
            ),
            launchMode: GameSessionLaunchMode.continueGame,
          ),
          initialSave: save,
        ),
        isNull,
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

      expect(
        await preloader.resolveForSession(
          projectFilePath: projectFile.path,
          descriptor: _descriptor(
            identity,
            launchMode: GameSessionLaunchMode.continueGame,
          ),
          initialSave: changedState,
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

      expect(exact?.bundle.map.id, 'p3_test_map');
      expect(consumed, isNull);
    },
  );

  test(
    'late completion from an invalidated generation cannot restore cache',
    () async {
      final manifest =
          ProjectManifest.fromJson(
            jsonDecode(await projectFile.readAsString())
                as Map<String, dynamic>,
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
        bundleLoader:
            ({
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
      expect(exact?.bundle.map.id, 'p3_test_map');
      expect(resurrected, isNull);
    },
  );

  test('reports completed preload work as bounded monotone progress', () async {
    final manifest =
        ProjectManifest.fromJson(
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
      progress.map((item) => item.stage).toSet(),
      containsAllInOrder(const <RuntimeInitialMapPreloadStage>[
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
      orderedEquals(<double>[...progress.map((item) => item.value)]..sort()),
    );
    expect(progress.last.value, 1);
  });

  test('a failing ready callback discards its prepared result', () async {
    final manifest = ProjectManifest.fromJson(
      jsonDecode(await projectFile.readAsString()) as Map<String, dynamic>,
    ).copyWith(
      newGame: const ProjectNewGameConfig(
        enabled: true,
        startMapId: 'p3_test_map',
      ),
    );
    final preloader = RuntimeInitialMapPreloader(
      projectFilePath: () async => projectFile.path,
      loadSave: (_) async => null,
      manifestLoader: (_) async => manifest,
    );
    addTearDown(preloader.clear);
    await expectLater(
      preloader.preloadInitialMap(
        const RuntimeInitialMapPreloadRequest.newGame(),
        onProgress: (progress) {
          if (progress.stage == RuntimeInitialMapPreloadStage.ready) {
            throw StateError('progress failed');
          }
        },
      ),
      throwsStateError,
    );
    expect(await preloader.resolveForSession(
      projectFilePath: projectFile.path,
      descriptor: _descriptor(identity, launchMode: GameSessionLaunchMode.newGame),
      initialSave: null,
    ), isNull);
  });

  test(
    'warms first-frame tilesets and transfers them without a second load',
    () async {
      final manifest =
          ProjectManifest.fromJson(
            jsonDecode(await projectFile.readAsString())
                as Map<String, dynamic>,
          ).copyWith(
            newGame: const ProjectNewGameConfig(
              enabled: true,
              startMapId: 'p3_test_map',
            ),
          );
      final bundle =
          (await loadRuntimeMapBundle(
            projectFilePath: projectFile.path,
            mapId: 'p3_test_map',
            preloadedManifest: manifest,
          )).copyWith(
            tilesetAbsolutePathsById: const <String, String>{
              'world': '/virtual/tilesets/world.png',
            },
          );
      final image = await _runtimeTilesetImage();
      final loadStarted = Completer<void>();
      final releaseLoad = Completer<void>();
      final progress = <RuntimeInitialMapPreloadProgress>[];
      var batchLoads = 0;
      var preloadCompleted = false;
      final preloader = RuntimeInitialMapPreloader(
        projectFilePath: () async => projectFile.path,
        loadSave: (_) async => null,
        manifestLoader: (_) async => manifest,
        bundleLoader: ({
          required projectFilePath,
          required mapId,
          required preloadedManifest,
        }) async => bundle,
        tilesetImageLoader:
            (
              paths, {
              transparentColorByTilesetId =
                  const <String, TilesetTransparentColor>{},
              onProgress,
            }) async {
              batchLoads++;
              loadStarted.complete();
              await releaseLoad.future;
              onProgress?.call(paths.length, paths.length);
              return <String, RuntimeTilesetImage>{'world': image};
            },
      );

      final preload = preloader
          .preloadInitialMap(
            const RuntimeInitialMapPreloadRequest.newGame(),
            onProgress: progress.add,
          )
          .then((_) => preloadCompleted = true);
      await loadStarted.future;

      expect(preloadCompleted, isFalse);
      expect(progress.last.value, lessThan(1));

      releaseLoad.complete();
      await preload;
      final resolved = await preloader.resolveForSession(
        projectFilePath: projectFile.path,
        descriptor: _descriptor(
          identity,
          launchMode: GameSessionLaunchMode.newGame,
        ),
        initialSave: null,
      );
      final transferredCache = resolved!.takeTilesetImageCache();

      expect(resolved.bundle.map.id, 'p3_test_map');
      expect(batchLoads, 1);
      expect(progress.last.stage, RuntimeInitialMapPreloadStage.ready);
      await transferredCache!.loadById(bundle.tilesetAbsolutePathsById);
      expect(batchLoads, 1);

      transferredCache.dispose();
      expect(image.debugDisposed, isTrue);
    },
  );

  test(
    'retry disposes stale images and clear releases the current cache',
    () async {
      final manifest =
          ProjectManifest.fromJson(
            jsonDecode(await projectFile.readAsString())
                as Map<String, dynamic>,
          ).copyWith(
            newGame: const ProjectNewGameConfig(
              enabled: true,
              startMapId: 'p3_test_map',
            ),
          );
      final bundle =
          (await loadRuntimeMapBundle(
            projectFilePath: projectFile.path,
            mapId: 'p3_test_map',
            preloadedManifest: manifest,
          )).copyWith(
            tilesetAbsolutePathsById: const <String, String>{
              'world': '/virtual/tilesets/world.png',
            },
          );
      final staleImage = await _runtimeTilesetImage();
      final currentImage = await _runtimeTilesetImage();
      final staleLoadStarted = Completer<void>();
      final releaseStaleLoad = Completer<void>();
      var batchLoads = 0;
      final preloader = RuntimeInitialMapPreloader(
        projectFilePath: () async => projectFile.path,
        loadSave: (_) async => null,
        manifestLoader: (_) async => manifest,
        bundleLoader: ({
          required projectFilePath,
          required mapId,
          required preloadedManifest,
        }) async => bundle,
        tilesetImageLoader:
            (
              paths, {
              transparentColorByTilesetId =
                  const <String, TilesetTransparentColor>{},
              onProgress,
            }) async {
              batchLoads++;
              if (batchLoads == 1) {
                staleLoadStarted.complete();
                await releaseStaleLoad.future;
                onProgress?.call(paths.length, paths.length);
                return <String, RuntimeTilesetImage>{'world': staleImage};
              }
              onProgress?.call(paths.length, paths.length);
              return <String, RuntimeTilesetImage>{'world': currentImage};
            },
      );

      final stalePreload = preloader.preloadInitialMap(
        const RuntimeInitialMapPreloadRequest.newGame(),
      );
      await staleLoadStarted.future;
      await preloader.preloadInitialMap(
        const RuntimeInitialMapPreloadRequest.newGame(),
      );

      releaseStaleLoad.complete();
      await stalePreload;

      expect(batchLoads, 2);
      expect(staleImage.debugDisposed, isTrue);
      expect(currentImage.debugDisposed, isFalse);

      preloader.clear();

      expect(currentImage.debugDisposed, isTrue);
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
    },
  );

  test(
    'spatial preparation leaves texture decoding to the spatial owner',
    () async {
      final manifest =
          ProjectManifest.fromJson(
            jsonDecode(await projectFile.readAsString())
                as Map<String, dynamic>,
          ).copyWith(
            settings: const ProjectSettings(dimension: ProjectDimension.threeD),
            newGame: const ProjectNewGameConfig(
              enabled: true,
              startMapId: 'p3_test_map',
            ),
          );
      final bundle = RuntimeMapBundle(
        manifest: manifest,
        map: const MapData(
          id: 'p3_test_map',
          name: 'Spatial',
          size: GridSize(width: 2, height: 2),
        ),
        projectRootDirectory: projectFile.parent.path,
        tilesetAbsolutePathsById: const {'actor': '/virtual/actor.png'},
      );
      var decodes = 0;
      final preloader = RuntimeInitialMapPreloader(
        projectFilePath: () async => projectFile.path,
        loadSave: (_) async => null,
        manifestLoader: (_) async => manifest,
        bundleLoader: ({
          required projectFilePath,
          required mapId,
          required preloadedManifest,
        }) async => bundle,
        tilesetImageLoader:
            (
              paths, {
              transparentColorByTilesetId = const {},
              onProgress,
            }) async {
              decodes++;
              throw StateError('Spatial textures must have one owner.');
            },
      );
      await preloader.preloadInitialMap(
        const RuntimeInitialMapPreloadRequest.newGame(),
      );
      expect(decodes, 0);
      expect(bundle.resourceBudget.residentBytes, 0);
      preloader.clear();
    },
  );
}

Future<RuntimeTilesetImage> _runtimeTilesetImage() async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    const ui.Rect.fromLTWH(0, 0, 1, 1),
    ui.Paint()..color = const ui.Color(0xFFFFFFFF),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(1, 1);
  picture.dispose();
  return RuntimeTilesetImage(
    images: <ui.Image>[image],
    chunks: const <RuntimeTilesetChunk>[
      RuntimeTilesetChunk(top: 0, height: 1, width: 1),
    ],
    width: 1,
    height: 1,
  );
}

SaveEnvelope _saveEnvelope(
  GameIdentity identity, {
  required String mapId,
  int money = 0,
}) {
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
      trainerProfile: TrainerProfile(name: 'Player', money: money),
    ),
  );
}

GameSessionDescriptor _descriptor(
  GameIdentity identity, {
  required GameSessionLaunchMode launchMode,
  String slotId = 'slot-1',
}) => GameSessionDescriptor(
  sessionId: 'session-${launchMode.name}-$slotId',
  sessionToken: 'secret',
  identity: identity,
  profileId: 'player-1',
  slotId: slotId,
  launchMode: launchMode,
  installedVersionHandle: 'verified-fixture',
  saveReadHandle: launchMode == GameSessionLaunchMode.newGame
      ? null
      : 'opaque-save',
  runtimeApiVersion: '1.0.0',
  grantedCapabilities: const <String>{'map.v1'},
  locale: 'fr-FR',
  accessibility: const GameSessionAccessibilityOptions(),
  initialGameState: launchMode == GameSessionLaunchMode.newGame
      ? GameState(saveId: slotId, currentMapId: 'p3_test_map')
      : null,
);
