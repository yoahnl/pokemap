import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart' show Direction;
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/infrastructure/tile_image_loader.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final (blockedArrival, neighborVisible) in [
    (false, false),
    (true, false),
    (false, true),
  ]) {
    testWidgets(
      'warp demand preserves required images, blocked=$blockedArrival, visibleNeighbor=$neighborVisible',
      (tester) async {
        await tester.runAsync(() async {
          final fixture = await _mount(
            tester,
            blockedArrival: blockedArrival,
            neighborVisible: neighborVisible,
          );
          final game = fixture.game;
          await _until(
            game,
            () =>
                game.debugIsMapLoaded('east') &&
                !game.debugIsMapActivationDispatchInFlight &&
                fixture.budget.activeDecodes == 0,
          );
          expect(fixture.budget.residentBytes, 8192);
          expect(
            game.camera.visibleWorldRect.overlaps(
              ui.Rect.fromLTWH(neighborVisible ? 160 : 3200, 0, 160, 160),
            ),
            neighborVisible,
          );
          final sourceImage = fixture.images.imagesForRequest({
            'source': fixture.sourcePath,
          }).single;
          final neighborImage = fixture.images.imagesForRequest({
            'east': fixture.neighborPath,
          }).single;
          expect(sourceImage.debugDisposed, isFalse);
          final before = game.gameStateSnapshot;
          var completed = false;
          final transfer = game
              .debugExecuteSceneInteractiveCommand(
                SceneInteractiveCommand.warp(
                  destinationMapId: 'house',
                  warpId: 'arrival',
                  presentation: SceneWarpPresentation(
                    mode: SceneWarpPresentationMode.fade,
                  ),
                ),
              )
              .whenComplete(() => completed = true);
          await _until(game, () => completed);
          final remainsOnSource = blockedArrival || neighborVisible;
          expect(await transfer, remainsOnSource ? 'blocked' : 'completed');
          expect(
            game.gameStateSnapshot.currentMapId,
            remainsOnSource ? 'source' : 'house',
          );
          expect(game.debugIsGameplayInputLocked, isFalse);
          expect(
            game.debugIsMapLoaded(remainsOnSource ? 'source' : 'house'),
            isTrue,
          );
          expect(sourceImage.debugDisposed, isFalse);
          expect(
            fixture.images.imagesForRequest({
              'source': fixture.sourcePath,
            }).single,
            same(sourceImage),
          );
          expect(fixture.budget.residentBytes, lessThanOrEqualTo(8192));
          expect(fixture.budget.activeDecodes, 0);
          expect(fixture.budget.pendingDecodes, 0);
          if (neighborVisible) {
            expect(game.debugIsMapLoaded('east'), isTrue);
            expect(neighborImage.debugDisposed, isFalse);
          } else if (!blockedArrival) {
            expect(game.debugIsMapLoaded('east'), isFalse);
            expect(neighborImage.debugDisposed, isTrue);
          }
          if (remainsOnSource) {
            expect(game.gameStateSnapshot.toJson(), before.toJson());
          }
        });
      },
    );
  }

  for (final warpPrefetch in [false, true]) {
    testWidgets(
      'warp demand bypasses a blocked optional bundle, warpPrefetch=$warpPrefetch',
      (tester) async {
        await tester.runAsync(() async {
          final entered = Completer<void>();
          final release = Completer<void>();
          var neighborMounts = 0;
          final fixture = await _mount(
            tester,
            blockedArrival: false,
            neighborVisible: false,
            connectionPrefetch: !warpPrefetch,
            warpPrefetch: warpPrefetch,
            beforeBundleLoad: (id) async {
              if (id != 'east') return;
              if (!entered.isCompleted) entered.complete();
              await release.future;
            },
            beforeMapMount: (id) async {
              if (id == 'east') neighborMounts++;
            },
          );
          final game = fixture.game;
          try {
            await _until(
              game,
              () =>
                  entered.isCompleted &&
                  !game.debugIsMapActivationDispatchInFlight,
            );
            final sourceImage = fixture.images.imagesForRequest({
              'source': fixture.sourcePath,
            }).single;
            var completed = false;
            final transfer = game
                .debugExecuteSceneInteractiveCommand(
                  SceneInteractiveCommand.warp(
                    destinationMapId: 'house',
                    warpId: 'arrival',
                    presentation: SceneWarpPresentation(
                      mode: SceneWarpPresentationMode.fade,
                    ),
                  ),
                )
                .whenComplete(() => completed = true);
            try {
              await _until(game, () => completed);
              expect(await transfer, 'completed');
              expect(release.isCompleted, isFalse);
              expect(game.gameStateSnapshot.currentMapId, 'house');
              expect(game.debugIsGameplayInputLocked, isFalse);
              expect(sourceImage.debugDisposed, isFalse);
            } finally {
              if (!release.isCompleted) release.complete();
              await _until(game, () => completed);
              await transfer;
            }
            await game.debugLoadRuntimeMapBundleCachedForTest('east');
            for (var i = 0; i < 20; i++) {
              game.update(.025);
              await Future<void>.delayed(const Duration(milliseconds: 1));
            }
            expect(neighborMounts, 0);
            expect(game.debugIsMapLoaded('east'), isFalse);
            expect(
              fixture.images.imagesForRequest({'east': fixture.neighborPath}),
              isEmpty,
            );
            expect(fixture.budget.residentBytes, lessThanOrEqualTo(8192));
            expect(
              fixture.budget.activeDecodes + fixture.budget.pendingDecodes,
              0,
            );
            expect(sourceImage.debugDisposed, isFalse);
          } finally {
            if (!release.isCompleted) release.complete();
          }
        });
      },
    );
  }

  testWidgets(
    'connection demand retries a previously invalidated neighbor prefetch',
    (tester) async {
      await tester.runAsync(() async {
        final entered = Completer<void>();
        final release = Completer<void>();
        final fixture = await _mount(
          tester,
          blockedArrival: false,
          neighborVisible: false,
          beforeBundleLoad: (id) async {
            if (id != 'east') return;
            if (!entered.isCompleted) entered.complete();
            await release.future;
          },
        );
        final game = fixture.game;
        try {
          await _until(
            game,
            () =>
                entered.isCompleted &&
                !game.debugIsMapActivationDispatchInFlight,
          );
          final sourceImage = fixture.images.imagesForRequest({
            'source': fixture.sourcePath,
          }).single;
          expect(await _warpTo(game, 'house'), 'completed');
          expect(await _warpTo(game, 'source'), 'completed');
          expect(release.isCompleted, isFalse);
          expect(game.debugIsMapLoaded('east'), isFalse);
          game.debugSetPlayerStateForTest(
            position: const GridPos(x: 99, y: 1),
            facing: Direction.east,
          );
          expect(
            game.handleRuntimeInputEvent(
              const RuntimeInputEvent.press(RuntimeInputControl.right),
            ),
            isTrue,
          );
          for (var i = 0; i < 20; i++) {
            game.update(.025);
            await Future<void>.delayed(const Duration(milliseconds: 1));
          }
          expect(game.gameStateSnapshot.currentMapId, 'source');
          release.complete();
          await _until(
            game,
            () =>
                game.gameStateSnapshot.currentMapId == 'east' &&
                !game.debugIsGameplayInputLocked &&
                !game.debugIsMapActivationDispatchInFlight,
          );
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.release(RuntimeInputControl.right),
          );
          expect(game.debugIsMapLoaded('east'), isTrue);
          expect(sourceImage.debugDisposed, isFalse);
          expect(fixture.budget.residentBytes, lessThanOrEqualTo(8192));
          expect(
            fixture.budget.activeDecodes + fixture.budget.pendingDecodes,
            0,
          );
        } finally {
          if (!release.isCompleted) release.complete();
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.release(RuntimeInputControl.right),
          );
        }
      });
    },
  );

  testWidgets(
    'runtime removal rejects a late optional bundle without acquiring images',
    (tester) async {
      await tester.runAsync(() async {
        final entered = Completer<void>();
        final release = Completer<void>();
        final fixture = await _mount(
          tester,
          blockedArrival: false,
          neighborVisible: false,
          beforeBundleLoad: (id) async {
            if (id != 'east') return;
            if (!entered.isCompleted) entered.complete();
            await release.future;
          },
        );
        final game = fixture.game;
        try {
          await _until(
            game,
            () =>
                entered.isCompleted &&
                !game.debugIsMapActivationDispatchInFlight,
          );
          final sourceImage = fixture.images.imagesForRequest({
            'source': fixture.sourcePath,
          }).single;
          final pendingBundle = game.debugLoadRuntimeMapBundleCachedForTest(
            'east',
          );
          game.onRemove();
          expect(sourceImage.debugDisposed, isTrue);
          release.complete();
          await expectLater(pendingBundle, throwsStateError);
          await Future<void>.delayed(Duration.zero);
          expect(game.debugIsMapLoaded('east'), isFalse);
          expect(game.runtimeNotificationListenable.value, isNull);
          expect(
            fixture.images.imagesForRequest({'east': fixture.neighborPath}),
            isEmpty,
          );
          expect(fixture.budget.residentBytes, 0);
          expect(fixture.budget.transientBytes, 0);
          expect(
            fixture.budget.activeDecodes + fixture.budget.pendingDecodes,
            0,
          );
        } finally {
          if (!release.isCompleted) release.complete();
        }
      });
    },
  );

  testWidgets('optional neighbor retries admission by evicting warm images', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final entered = Completer<void>();
      final release = Completer<void>();
      final fixture = await _mount(
        tester,
        blockedArrival: false,
        neighborVisible: false,
        housePixelSide: 32,
        beforeBundleLoad: (id) async {
          if (id != 'east') return;
          if (!entered.isCompleted) entered.complete();
          await release.future;
        },
      );
      final game = fixture.game;
      try {
        await _until(game, () => entered.isCompleted);
        final sourceImage = fixture.images.imagesForRequest({
          'source': fixture.sourcePath,
        }).single;
        final houseImage = (await fixture.images.loadById({
          'house': fixture.housePath,
        }))['house']!;
        expect(fixture.budget.residentBytes, 8192);
        release.complete();
        await _until(game, () => game.debugIsMapLoaded('east'));
        expect(houseImage.debugDisposed, isTrue);
        expect(sourceImage.debugDisposed, isFalse);
        expect(
          fixture.images.imagesForRequest({'house': fixture.housePath}),
          isEmpty,
        );
        expect(
          fixture.images.imagesForRequest({'east': fixture.neighborPath}),
          hasLength(1),
        );
        expect(fixture.budget.residentBytes, 8192);
        expect(fixture.budget.transientBytes, 0);
        expect(fixture.budget.activeDecodes + fixture.budget.pendingDecodes, 0);
      } finally {
        if (!release.isCompleted) release.complete();
      }
    });
  });

  for (final journey in [
    (pressure: false, detour: false),
    (pressure: true, detour: false),
    (pressure: false, detour: true),
  ]) {
    final pressure = journey.pressure;
    testWidgets(
      'optional neighbor preserves a warm house outside the required image bytes, pressure=$pressure, detour=${journey.detour}',
      (tester) async {
        await tester.runAsync(() async {
          final entered = Completer<void>();
          final release = Completer<void>();
          var houseLoads = 0;
          final fixture = await _mount(
            tester,
            blockedArrival: false,
            neighborVisible: false,
            maximumResidentBytes: 256 * 1024 * 1024,
            neighborSharesSource: true,
            beforeBundleLoad: (id) async {
              if (id != 'east') return;
              if (!entered.isCompleted) entered.complete();
              await release.future;
            },
            imageLoader:
                (paths, {transparentColorByTilesetId = const {}}) async {
                  final result = <String, RuntimeTilesetImage>{};
                  for (final id in paths.keys) {
                    if (id == 'house') houseLoads++;
                    result[id] = await _warmBudgetImage(
                      id == 'house' ? 16 : 32,
                      accountedSide: id == 'source' ? 4097 : null,
                    );
                  }
                  return result;
                },
          );
          final game = fixture.game;
          try {
            await _until(
              game,
              () =>
                  entered.isCompleted &&
                  !game.debugIsMapActivationDispatchInFlight,
            );
            final sourceImage = fixture.images.imagesForRequest({
              'source': fixture.sourcePath,
            }).single;
            expect(
              sourceImage.width * sourceImage.height * 4,
              greaterThan(64 * 1024 * 1024),
            );
            final houseImage = (await fixture.images.loadById({
              'house': fixture.housePath,
            }))['house']!;
            expect(houseLoads, 1);
            release.complete();
            await _until(game, () => game.debugIsMapLoaded('east'));
            for (var i = 0; i < 20; i++) {
              game.update(.025);
              await Future<void>.delayed(const Duration(milliseconds: 1));
            }
            expect(houseImage.debugDisposed, isFalse);
            expect(
              fixture.images.imagesForRequest({
                'house': fixture.housePath,
              }).single,
              same(houseImage),
            );
            if (journey.detour) {
              expect(await _warpTo(game, 'east'), 'completed');
              expect(await _warpTo(game, 'source'), 'completed');
              expect(houseImage.debugDisposed, isFalse);
              expect(houseLoads, 1);
            }
            if (pressure) {
              game.didHaveMemoryPressure();
              expect(houseImage.debugDisposed, isTrue);
            }
            expect(sourceImage.debugDisposed, isFalse);
            expect(await _warpTo(game, 'house'), 'completed');
            final demanded = fixture.images.imagesForRequest({
              'house': fixture.housePath,
            }).single;
            expect(identical(demanded, houseImage), !pressure);
            expect(houseLoads, pressure ? 2 : 1);
            expect(sourceImage.debugDisposed, isFalse);
            expect(game.debugIsGameplayInputLocked, isFalse);
          } finally {
            if (!release.isCompleted) release.complete();
          }
        });
      },
    );
  }

  testWidgets('warp demand drains an in-flight neighbor before reclaiming it', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final entered = Completer<void>();
      final release = Completer<void>();
      var neighborMounts = 0;
      final fixture = await _mount(
        tester,
        blockedArrival: false,
        neighborVisible: false,
        beforeMapMount: (mapId) async {
          if (mapId != 'east') return;
          neighborMounts++;
          if (!entered.isCompleted) entered.complete();
          await release.future;
        },
      );
      addTearDown(() {
        if (!release.isCompleted) release.complete();
      });
      final game = fixture.game;
      await _until(
        game,
        () => entered.isCompleted && !game.debugIsMapActivationDispatchInFlight,
      );
      expect(fixture.budget.residentBytes, 8192);
      final sourceImage = fixture.images.imagesForRequest({
        'source': fixture.sourcePath,
      }).single;
      final neighborImage = fixture.images.imagesForRequest({
        'east': fixture.neighborPath,
      }).single;
      await game.debugLoadRuntimeMapBundleCachedForTest('house');
      var completed = false;
      final transfer = game
          .debugExecuteSceneInteractiveCommand(
            SceneInteractiveCommand.warp(
              destinationMapId: 'house',
              warpId: 'arrival',
              presentation: SceneWarpPresentation(
                mode: SceneWarpPresentationMode.fade,
              ),
            ),
          )
          .whenComplete(() => completed = true);
      for (var i = 0; i < 20; i++) {
        game.update(.025);
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
      expect(completed, isFalse);
      expect(game.gameStateSnapshot.currentMapId, 'source');
      expect(game.debugIsMapLoaded('east'), isFalse);
      expect(sourceImage.debugDisposed, isFalse);
      expect(neighborMounts, 1);
      release.complete();
      await _until(game, () => completed);
      expect(await transfer, 'completed');
      expect(game.gameStateSnapshot.currentMapId, 'house');
      expect(game.debugIsMapLoaded('east'), isFalse);
      expect(neighborImage.debugDisposed, isTrue);
      expect(neighborMounts, 1);
      expect(sourceImage.debugDisposed, isFalse);
      expect(game.debugIsGameplayInputLocked, isFalse);
      expect(fixture.budget.residentBytes, lessThanOrEqualTo(8192));
      expect(fixture.budget.activeDecodes + fixture.budget.pendingDecodes, 0);
    });
  });

  testWidgets(
    'return journeys preserve the shared source atlas within budget',
    (tester) async {
      await tester.runAsync(() async {
        final fixture = await _mount(
          tester,
          blockedArrival: false,
          neighborVisible: false,
        );
        final game = fixture.game;
        await _until(
          game,
          () =>
              game.debugIsMapLoaded('east') &&
              !game.debugIsMapActivationDispatchInFlight,
        );
        final sourceImage = fixture.images.imagesForRequest({
          'source': fixture.sourcePath,
        }).single;
        for (var trip = 0; trip < 2; trip++) {
          expect(await _warpTo(game, 'house'), 'completed');
          expect(game.gameStateSnapshot.currentMapId, 'house');
          expect(await _warpTo(game, 'source'), 'completed');
          expect(game.gameStateSnapshot.currentMapId, 'source');
          expect(game.debugIsGameplayInputLocked, isFalse);
          expect(sourceImage.debugDisposed, isFalse);
          expect(
            fixture.images.imagesForRequest({
              'source': fixture.sourcePath,
            }).single,
            same(sourceImage),
          );
          expect(fixture.budget.residentBytes, lessThanOrEqualTo(8192));
        }
      });
    },
  );
}

Future<
  ({
    PlayableMapGame game,
    RuntimeTilesetImageSingleFlightCache images,
    RuntimeResourceBudget budget,
    String sourcePath,
    String neighborPath,
    String housePath,
  })
>
_mount(
  WidgetTester tester, {
  required bool blockedArrival,
  required bool neighborVisible,
  Future<void> Function(String mapId)? beforeMapMount,
  Future<void> Function(String mapId)? beforeBundleLoad,
  bool connectionPrefetch = true,
  bool warpPrefetch = false,
  RuntimeTilesetImageBatchLoader? imageLoader,
  int housePixelSide = 16,
  int maximumResidentBytes = 8192,
  bool neighborSharesSource = false,
}) async {
  final root = await Directory.systemTemp.createTemp('transfer-image-budget-');
  addTearDown(() => root.delete(recursive: true));
  final sizes = {'source': 32, 'east': 32, 'house': housePixelSide};
  for (final entry in sizes.entries) {
    await File('${root.path}/${entry.key}.png').writeAsBytes(
      img.encodePng(img.Image(width: entry.value, height: entry.value)),
    );
  }
  final maps = [
    for (final id in ['source', 'east', 'house'])
      MapData(
        id: id,
        name: id,
        size: id == 'source' && !neighborVisible
            ? const GridSize(width: 100, height: 30)
            : const GridSize(width: 5, height: 5),
        layers: [
          MapLayer.tile(
            id: 'props',
            name: 'Props',
            cells: List.filled(
              id == 'source' && !neighborVisible ? 3000 : 25,
              0,
            ),
          ),
          if (id == 'house' && blockedArrival)
            MapLayer.collision(
              id: 'blocked-arrival',
              name: 'Blocked arrival',
              collisions: List.generate(25, (index) => index == 12),
            ),
        ],
        placedElements: [
          for (final visual in id == 'house' || id == 'east' && neighborSharesSource
              ? ['source', id]
              : [id])
            MapPlacedElement(
              id: '$id-$visual',
              layerId: 'props',
              elementId: visual,
              pos: GridPos(x: visual == 'house' ? 4 : 3, y: 3),
              applyCollision: false,
            ),
        ],
        entities: [
          MapEntity(
            id: 'spawn',
            kind: MapEntityKind.spawn,
            pos: id == 'source' && !neighborVisible
                ? const GridPos(x: 10, y: 10)
                : id == 'source'
                ? const GridPos(x: 2, y: 1)
                : const GridPos(x: 1, y: 1),
            blocksMovement: false,
            spawn: MapEntitySpawnData(role: EntitySpawnRole.playerStart),
          ),
        ],
        mapMetadata: const MapMetadata(defaultSpawnId: 'spawn'),
        connections: id == 'source' && connectionPrefetch
            ? const [
                MapConnection(
                  direction: MapConnectionDirection.east,
                  targetMapId: 'east',
                ),
              ]
            : const [],
        warps: [
          if (id == 'source' && warpPrefetch)
            const MapWarp(
              id: 'optional',
              pos: GridPos(x: 0, y: 0),
              targetMapId: 'east',
              targetPos: GridPos(x: 1, y: 1),
              triggerMode: MapWarpTriggerMode.onEnter,
            ),
          MapWarp(
            id: 'arrival',
            pos: const GridPos(x: 2, y: 2),
            targetMapId: id,
            targetPos: const GridPos(x: 2, y: 2),
            triggerMode: MapWarpTriggerMode.sceneOnly,
          ),
        ],
      ),
  ];
  final manifest = ProjectManifest(
    name: 'Transfer image budget',
    settings: const ProjectSettings(
      tileWidth: 32,
      tileHeight: 32,
      displayScale: 1,
    ),
    maps: [
      for (final map in maps)
        ProjectMapEntry(
          id: map.id,
          name: map.name,
          relativePath: '${map.id}.json',
        ),
    ],
    tilesets: [
      for (final entry in sizes.entries)
        ProjectTilesetEntry(
          id: entry.key,
          name: entry.key,
          relativePath: '${entry.key}.png',
          source: ProjectRegularAtlasTilesetSource(
            assetId: entry.key,
            pixelWidth: entry.value,
            pixelHeight: entry.value,
            tileWidth: entry.value,
            tileHeight: entry.value,
          ),
        ),
    ],
    elementCategories: const [
      ProjectElementCategory(id: 'props', name: 'Props'),
    ],
    elements: [
      for (final id in sizes.keys)
        ProjectElementEntry(
          id: id,
          name: id,
          tilesetId: id,
          categoryId: 'props',
          frames: const [
            TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
          ],
        ),
    ],
  );
  final projectPath = '${root.path}/project.json';
  await File(projectPath).writeAsString(jsonEncode(manifest.toJson()));
  for (final map in maps) {
    await File('${root.path}/${map.id}.json')
        .writeAsString(jsonEncode(map.toJson()));
  }
  final budget = RuntimeResourceBudget(
    profile: RuntimeResourceProfile(
      maximumResidentBytes: maximumResidentBytes,
      maximumTransientBytes: 16384,
      maximumConcurrentDecodes: 1,
    ),
  );
  addTearDown(budget.dispose);
  final bundle = await loadRuntimeMapBundle(
    projectFilePath: projectPath,
    mapId: 'source',
    resourceBudget: budget,
  );
  addTearDown(bundle.projectCatalog!.dispose);
  final images = RuntimeTilesetImageSingleFlightCache(
    loader: imageLoader ?? loadTilesetImagesById,
    resourceBudget: budget,
    identity: bundle.projectCatalog!.identity,
  );
  final game = PlayableMapGame(
    bundle: bundle,
    projectFilePath: projectPath,
    initialTilesetImageCache: images,
    beforeMapMount: beforeMapMount,
    runtimeMapBundleLoader: beforeBundleLoad == null
        ? null
        : ({required projectFilePath, required mapId}) async {
            await beforeBundleLoad(mapId);
            return loadRuntimeMapBundle(
              projectFilePath: projectFilePath,
              mapId: mapId,
              projectCatalog: bundle.projectCatalog,
              resourceBudget: budget,
            );
          },
  );
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: GameWidget(game: game),
    ),
  );
  await game.loaded;
  await tester.pump();
  addTearDown(game.onRemove);
  game.pauseEngine();
  return (
    game: game,
    images: images,
    budget: budget,
    sourcePath: bundle.tilesetAbsolutePathsById['source']!,
    neighborPath: '${bundle.projectRootDirectory}/east.png',
    housePath: '${bundle.projectRootDirectory}/house.png',
  );
}

Future<void> _until(PlayableMapGame game, bool Function() condition) async {
  for (var i = 0; i < 400 && !condition(); i++) {
    game.update(.025);
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  game.update(0);
  expect(condition(), isTrue);
}

Future<String> _warpTo(PlayableMapGame game, String mapId) async {
  var completed = false;
  final transfer = game
      .debugExecuteSceneInteractiveCommand(
        SceneInteractiveCommand.warp(
          destinationMapId: mapId,
          warpId: 'arrival',
          presentation: SceneWarpPresentation(
            mode: SceneWarpPresentationMode.fade,
          ),
        ),
      )
      .whenComplete(() => completed = true);
  await _until(game, () => completed);
  return transfer;
}

Future<RuntimeTilesetImage> _warmBudgetImage(
  int pixelSide, {
  int? accountedSide,
}) async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawColor(const ui.Color(0xFF3366FF), ui.BlendMode.src);
  final picture = recorder.endRecording();
  try {
    final image = await picture.toImage(pixelSide, pixelSide);
    return RuntimeTilesetImage(
      images: [image],
      chunks: [
        RuntimeTilesetChunk(top: 0, width: pixelSide, height: pixelSide),
      ],
      width: accountedSide ?? pixelSide,
      height: accountedSide ?? pixelSide,
    );
  } finally {
    picture.dispose();
  }
}
