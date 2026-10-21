import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/infrastructure/tile_image_loader.dart';

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
  })
>
_mount(
  WidgetTester tester, {
  required bool blockedArrival,
  required bool neighborVisible,
  Future<void> Function(String mapId)? beforeMapMount,
}) async {
  final root = await Directory.systemTemp.createTemp('transfer-image-budget-');
  addTearDown(() => root.delete(recursive: true));
  final sizes = {'source': 32, 'east': 32, 'house': 16};
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
          for (final visual in id == 'house' ? ['source', 'house'] : [id])
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
        connections: id == 'source'
            ? const [
                MapConnection(
                  direction: MapConnectionDirection.east,
                  targetMapId: 'east',
                ),
              ]
            : const [],
        warps: [
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
    profile: const RuntimeResourceProfile(
      maximumResidentBytes: 8192,
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
    loader: loadTilesetImagesById,
    resourceBudget: budget,
    identity: bundle.projectCatalog!.identity,
  );
  final game = PlayableMapGame(
    bundle: bundle,
    projectFilePath: projectPath,
    initialTilesetImageCache: images,
    beforeMapMount: beforeMapMount,
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
