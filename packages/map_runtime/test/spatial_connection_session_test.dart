import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_render_3d/map_render_3d.dart';

import 'session/spatial_exploration_game_session_runtime_test.dart' as fixture;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late RuntimeMapBundle source;
  late RuntimeMapBundle target;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('spatial-connections-');
    final path = '${root.path}/hero.png';
    await File(path)
        .writeAsBytes(image.encodePng(image.Image(width: 32, height: 32)));
    final manifest = ProjectManifest(
        version: ProjectVersion.v9,
        name: 'Connections',
        settings: const ProjectSettings(
            dimension: ProjectDimension.threeD,
            defaultPlayerCharacterId: 'hero'),
        maps: const [],
        tilesets: const [],
        characters: [
          ProjectCharacterEntry(
              id: 'hero',
              name: 'Hero',
              tilesetId: 'unused',
              animations: [
                for (final facing in EntityFacing.values)
                  CharacterAnimation(
                      state: CharacterAnimationState.walk,
                      direction: facing,
                      sourceAssetId: 'hero',
                      frames: const [
                        CharacterAnimationFrame(
                            source: TilesetSourceRect(
                                x: 0, y: 0, width: 32, height: 32),
                            durationMs: 100)
                      ])
              ])
        ]);
    source = RuntimeMapBundle(
        manifest: manifest,
        map: MapData(
            version: ProjectVersion.v9,
            id: 'source',
            name: 'Source',
            size: const GridSize(width: 8, height: 8),
            spatialScene: MapSpatialScene(
                width: 8,
                depth: 8,
                navigation: SpatialNavigationProfile(
                    spawn: SpatialSpawn(x: 4.5, z: 4.5)))),
        projectRootDirectory: root.path,
        tilesetAbsolutePathsById: const {},
        characterAnimationAbsolutePathsByAssetId: {'hero': path});
    target = source.copyWith(map: source.map.copyWith(id: 'target'));
  });
  tearDown(() async => root.delete(recursive: true));

  testWidgets(
      'connected viewport retains world placement, neighbors and smooth arrival',
      (tester) async {
    const forward = MapConnection(
        direction: MapConnectionDirection.east,
        targetMapId: 'target',
        offset: 2);
    const back = MapConnection(
        direction: MapConnectionDirection.west,
        targetMapId: 'source',
        offset: -2);
    source = source.copyWith(map: source.map.copyWith(connections: [forward]));
    target = target.copyWith(
        map: target.map.copyWith(connections: [
      back
    ], warps: [
      const MapWarp(
          id: 'door',
          pos: GridPos(x: 3, y: 3),
          targetMapId: 'source',
          targetPos: GridPos(x: 4, y: 4))
    ]));
    final loadedMaps = <String>[];
    final session = (await tester.runAsync(
        () => SpatialExplorationSession.load(source, loadMap: (id) async {
              loadedMaps.add(id);
              return id == 'target' ? target : source;
            })))!;
    await tester.pumpWidget(
        MaterialApp(home: SpatialExplorationView(session: session)));
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await tester.pump();
    var scene = tester.widget<SpatialSceneView>(find.byType(SpatialSceneView));
    final key = scene.key;
    expect(scene.neighbors.single.map.id, 'target');
    expect(scene.neighbors.single.offset, const Offset(8, 2));
    expect(scene.sceneOffset, Offset.zero);
    await tester.runAsync(() async {
      attemptExit(session, MapConnectionDirection.east);
      await settle(session);
    });
    final oldViewportHero = scene.actorFrames!(0)['hero']!;
    final connectionEntry = session.connectionEntry!;
    expect(oldViewportHero.x + scene.sceneOffset.dx,
        closeTo(connectionEntry.sourceX, .0001));
    expect(oldViewportHero.z + scene.sceneOffset.dy,
        closeTo(connectionEntry.sourceZ, .0001));
    await tester.pump();
    scene = tester.widget<SpatialSceneView>(find.byType(SpatialSceneView));
    expect(scene.key, key);
    expect(scene.groundMap!.id, 'target');
    expect(scene.sceneOffset, const Offset(8, 2));
    expect(scene.neighbors.single.map.id, 'source');
    expect(scene.neighbors.single.offset, const Offset(-8, -2));
    expect(loadedMaps.where((id) => id == 'source'), isEmpty);
    final entry = session.connectionEntry!;
    final first = scene.actorFrames!(0)['hero']!;
    expect(first.x + scene.sceneOffset.dx, closeTo(entry.sourceX, .0001));
    expect(first.z + scene.sceneOffset.dy, closeTo(entry.sourceZ, .0001));
    final arrived = scene.actorFrames!(.15)['hero']!;
    expect(arrived.x, session.movement.x);
    await tester.runAsync(() => session.enterWarp(target.map.warps.single));
    await tester.pump();
    scene = tester.widget<SpatialSceneView>(find.byType(SpatialSceneView));
    expect(scene.sceneOffset, Offset.zero);
    expect(scene.groundMap!.id, 'source');
    await tester.runAsync(() async {
      attemptExit(session, MapConnectionDirection.east);
      await settle(session);
    });
    await tester.pump();
    await tester.runAsync(() async {
      attemptExit(session, MapConnectionDirection.west);
      await settle(session);
    });
    await tester.pump();
    scene = tester.widget<SpatialSceneView>(find.byType(SpatialSceneView));
    expect(scene.sceneOffset, Offset.zero);
    await tester.pumpWidget(const SizedBox());
    session.dispose();
  });

  for (final direction in MapConnectionDirection.values) {
    for (final offset in [-2, 2]) {
      test(
          '${direction.name} connection offset $offset crosses only at edge and returns',
          () async {
        final forward = MapConnection(
            direction: direction, targetMapId: 'target', offset: offset);
        final back = MapConnection(
            direction: direction.opposite,
            targetMapId: 'source',
            offset: -offset);
        source =
            source.copyWith(map: source.map.copyWith(connections: [forward]));
        target = target.copyWith(map: target.map.copyWith(connections: [back]));
        var loads = 0;
        final session =
            await SpatialExplorationSession.load(source, loadMap: (id) async {
          loads++;
          return id == 'target' ? target : source;
        });
        addTearDown(session.dispose);
        final (dx, dz) = input(direction);
        session.movement.setInput(x: dx, z: dz, run: true);
        session.frame(.05);
        expect(loads, 0);
        attemptExit(session, direction);
        await settle(session);
        expect(session.bundle.map.id, 'target');
        expect(session.connectionEntry, isNotNull);
        expect(session.connectionEntry!.connection, forward);
        expect(session.connectionEntry!.sourceSize, source.map.size);
        final sourceCell = switch (direction) {
          MapConnectionDirection.north => const GridPos(x: 4, y: 0),
          MapConnectionDirection.south => const GridPos(x: 4, y: 7),
          MapConnectionDirection.east => const GridPos(x: 7, y: 4),
          MapConnectionDirection.west => const GridPos(x: 0, y: 4),
        };
        final expected = switch (direction) {
          MapConnectionDirection.north => GridPos(x: 4 - offset, y: 7),
          MapConnectionDirection.south => GridPos(x: 4 - offset, y: 0),
          MapConnectionDirection.east => GridPos(x: 0, y: 4 - offset),
          MapConnectionDirection.west => GridPos(x: 7, y: 4 - offset),
        };
        expect(session.movement.x, expected.x + .5);
        expect(session.movement.z, expected.y + .5);
        expect(session.movement.facing.name, direction.name);
        for (var i = 0; i < 30; i++) {
          session.frame(.05);
        }
        expect(loads, 1);
        expect(session.movement.running, isFalse);
        attemptExit(session, direction.opposite);
        await settle(session);
        expect(session.bundle.map.id, 'source');
        expect(session.movement.x, sourceCell.x + .5);
        expect(session.movement.z, sourceCell.y + .5);
        expect(loads, 2);
      });
    }
  }

  test(
      'neighbor loading validates the bundle without moving or validating its start',
      () async {
    const connection = MapConnection(
        direction: MapConnectionDirection.east, targetMapId: 'target');
    source =
        source.copyWith(map: source.map.copyWith(connections: [connection]));
    target = target.copyWith(
        map: target.map.copyWith(layers: [
      CollisionLayer(
          id: 'solid', name: 'Solid', collisions: List.filled(64, true))
    ]));
    final session = await SpatialExplorationSession.load(source,
        loadMap: (_) async => target);
    addTearDown(session.dispose);
    final movement = session.movement;
    final neighbor = await session.loadConnectionNeighbor(connection);
    expect(neighbor, same(target));
    expect(session.bundle, same(source));
    expect(session.movement, same(movement));
    expect(session.mapRevision.value, 0);
    expect(session.transitioning.value, isFalse);
    await expectLater(
        session.loadConnectionNeighbor(
            connection.copyWith(targetMapId: 'unknown')),
        throwsStateError);
  });

  for (final invalid in ['id', 'root', 'dimension', 'scene']) {
    test('neighbor loading rejects invalid $invalid', () async {
      const connection = MapConnection(
          direction: MapConnectionDirection.east, targetMapId: 'target');
      source =
          source.copyWith(map: source.map.copyWith(connections: [connection]));
      target = switch (invalid) {
        'id' => target.copyWith(map: target.map.copyWith(id: 'wrong')),
        'root' => target.copyWith(projectRootDirectory: '/different'),
        'dimension' => target.copyWith(
            manifest: target.manifest.copyWith(
                settings: target.manifest.settings
                    .copyWith(dimension: ProjectDimension.twoD))),
        _ => target.copyWith(map: target.map.copyWith(spatialScene: null)),
      };
      final session = await SpatialExplorationSession.load(source,
          loadMap: (_) async => target);
      addTearDown(session.dispose);
      await expectLater(
          session.loadConnectionNeighbor(connection), throwsStateError);
    });
  }

  test('a public connection request requires an outward edge attempt',
      () async {
    const connection = MapConnection(
        direction: MapConnectionDirection.east, targetMapId: 'target');
    source =
        source.copyWith(map: source.map.copyWith(connections: [connection]));
    var loads = 0;
    final session =
        await SpatialExplorationSession.load(source, loadMap: (_) async {
      loads++;
      return target;
    });
    addTearDown(session.dispose);
    await session.enterConnection(connection);
    expect(loads, 0);
    expect(session.connectionEntry, isNull);
  });

  test(
      'connection entry is published before activation and cleared by a successful warp',
      () async {
    const connection = MapConnection(
        direction: MapConnectionDirection.east, targetMapId: 'target');
    const warp = MapWarp(
        id: 'back',
        pos: GridPos(x: 3, y: 3),
        targetMapId: 'source',
        targetPos: GridPos(x: 4, y: 4));
    source =
        source.copyWith(map: source.map.copyWith(connections: [connection]));
    target = target.copyWith(map: target.map.copyWith(warps: [warp]));
    final session = await SpatialExplorationSession.load(source,
        loadMap: (id) async => id == 'target' ? target : source);
    addTearDown(session.dispose);
    Object? entryAtActivation;
    session.mapRevision.addListener(() {
      entryAtActivation = session.connectionEntry;
    });
    attemptExit(session, MapConnectionDirection.east);
    await settle(session);
    expect(entryAtActivation, isNotNull);
    expect(session.connectionEntry!.sourceX, 7.625);
    expect(session.connectionEntry!.sourceZ, 4.5);
    await session.enterWarp(warp);
    expect(session.bundle.map.id, 'source');
    expect(session.connectionEntry, isNull);
    expect(entryAtActivation, isNull);
  });

  for (final interruption in ['none', 'pause', 'lifecycle lock']) {
    test('adapter connection handles $interruption and clears held input',
        () async {
      const connection = MapConnection(
          direction: MapConnectionDirection.east, targetMapId: 'target');
      final manifest = source.manifest.copyWith(
          newGame:
              const ProjectNewGameConfig(enabled: true, startMapId: 'source'),
          tilesets: [
            const ProjectTilesetEntry(
                id: 'unused', name: 'Unused', relativePath: 'hero.png')
          ],
          maps: [
            const ProjectMapEntry(
                id: 'source', name: 'Source', relativePath: 'source.json'),
            const ProjectMapEntry(
                id: 'target', name: 'Target', relativePath: 'target.json'),
          ]);
      source = source.copyWith(
          manifest: manifest,
          map: source.map.copyWith(connections: [connection]));
      target = target.copyWith(
          manifest: manifest,
          map: target.map.copyWith(connections: [
            connection.copyWith(
                direction: MapConnectionDirection.west, targetMapId: 'source')
          ]));
      await File('${root.path}/target.json')
          .writeAsString(jsonEncode(target.map.toJson()));
      final png = await File('${root.path}/hero.png').readAsBytes();
      final artifact =
          ContentArtifactRef.fromBytes(png, mediaType: 'image/png');
      final blob = File('${root.path}/${assetBlobStorageKey(artifact)}');
      await blob.parent.create(recursive: true);
      await blob.writeAsBytes(png);
      final catalog = AssetCatalog(records: [
        AssetRecord(id: 'hero', logicalPath: 'hero.png', artifact: artifact)
      ]);
      final catalogFile = File('${root.path}/$assetCatalogStorageKey');
      await catalogFile.parent.create(recursive: true);
      await catalogFile.writeAsString(jsonEncode(catalog.toJson()));
      final runtime = SpatialExplorationGameSessionRuntime(
          descriptor: fixture.descriptor(
              initialState: GameState(
                  saveId: '018f255f-2d50-4f4f-8aa2-c893ae06b8c1',
                  currentMapId: 'source',
                  playerPosition: const GridPos(x: 4, y: 4),
                  playerSpatialPosition:
                      PlayerSpatialPosition(x: 4.5, z: 4.5))),
          projectFilePath: () async => '${root.path}/project.json',
          preloadedInitialMap: (
                  {required projectFilePath,
                  required descriptor,
                  required initialSave}) async =>
              RuntimeInitialMapPreloadResult(bundle: source),
          mountSession: (_) async {},
          unmountSession: (_) async {});
      addTearDown(runtime.dispose);
      await runtime.load((_) {});
      final session = runtime.session!;
      runtime.handleInput(
          const RuntimeInputEvent.press(RuntimeInputControl.right));
      runtime.handleInput(
          const RuntimeInputEvent.press(RuntimeInputControl.sprint));
      for (var i = 0; i < 100 && !session.transitioning.value; i++) {
        session.frame(.05);
      }
      expect(session.transitioning.value, isTrue);
      expect(runtime.inputAuthority.value.context, RuntimeInputContext.blocked);
      if (interruption == 'pause') await runtime.pause();
      if (interruption == 'lifecycle lock') {
        await runtime.setInputLock(RuntimeExternalInputLock.lifecycle,
            locked: true);
      }
      await settle(session);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(
          session.bundle.map.id, interruption == 'none' ? 'target' : 'source');
      expect(session.interactionError.value, isNull);
      final checkpoint = (await runtime.captureCheckpoint())!;
      final saved = gameStateFromStrictSaveJson(
          Map<String, dynamic>.from(checkpoint.state));
      expect(saved.currentMapId, session.bundle.map.id);
      expect(saved.playerSpatialPosition!.x, session.movement.x);
      expect(saved.playerSpatialPosition!.z, session.movement.z);
      if (interruption == 'pause') await runtime.resume();
      if (interruption == 'lifecycle lock') {
        await runtime.setInputLock(RuntimeExternalInputLock.lifecycle,
            locked: false);
      }
      expect(
          runtime.inputAuthority.value.context, RuntimeInputContext.overworld);
      final x = session.movement.x;
      runtime.handleInput(const RuntimeInputEvent.press(
          RuntimeInputControl.right,
          isRepeat: true));
      session.frame(.05);
      expect(session.movement.x, x);
      runtime.handleInput(
          const RuntimeInputEvent.press(RuntimeInputControl.right));
      if (interruption == 'none') {
        session.frame(.05);
        expect(session.movement.x, greaterThan(x));
      }
    });
  }

  test('an edge without a connection stays blocked', () async {
    var loads = 0;
    final session =
        await SpatialExplorationSession.load(source, loadMap: (_) async {
      loads++;
      return target;
    });
    addTearDown(session.dispose);
    attemptExit(session, MapConnectionDirection.east);
    expect(session.bundle.map.id, 'source');
    expect(session.movement.x, lessThan(8));
    expect(loads, 0);
  });

  for (final failure in [
    'loader',
    'blocked arrival',
    'height jump',
    'outside overlap',
    'wrong identity',
    '2D destination'
  ]) {
    test('$failure preserves the source and clears held input', () async {
      source = source.copyWith(
          map: source.map.copyWith(connections: [
        MapConnection(
            direction: MapConnectionDirection.east,
            targetMapId: 'target',
            offset: failure == 'outside overlap' ? 8 : 0)
      ]));
      if (failure == 'blocked arrival') {
        target = target.copyWith(
            map: target.map.copyWith(layers: [
          CollisionLayer(
              id: 'solid',
              name: 'Solid',
              collisions: [for (var i = 0; i < 64; i++) i == 32])
        ]));
      } else if (failure == 'height jump') {
        target = target.copyWith(
            map: target.map.copyWith(
                spatialScene: target.map.spatialScene!
                    .copyWith(heightLevels: List.filled(64, 2))));
      } else if (failure == 'wrong identity') {
        target = target.copyWith(map: target.map.copyWith(id: 'wrong'));
      } else if (failure == '2D destination') {
        target = target.copyWith(
            manifest: target.manifest.copyWith(
                settings: target.manifest.settings
                    .copyWith(dimension: ProjectDimension.twoD)),
            map: target.map.copyWith(spatialScene: null));
      }
      final session =
          await SpatialExplorationSession.load(source, loadMap: (_) async {
        if (failure == 'loader') throw const FileSystemException('missing');
        return target;
      });
      addTearDown(session.dispose);
      final movement = session.movement;
      attemptExit(session, MapConnectionDirection.east);
      await settle(session);
      expect(session.interactionError.value, isNotNull);
      expect(session.bundle.map.id, 'source');
      expect(session.movement, same(movement));
      expect(session.mapRevision.value, 0);
      final x = movement.x;
      session.frame(.05);
      expect(movement.x, x);
      expect(movement.paused, isFalse);
    });
  }

  for (final interruption in ['pause', 'cancel', 'dispose']) {
    test('$interruption discards a late connection load', () async {
      source = source.copyWith(
          map: source.map.copyWith(connections: [
        const MapConnection(
            direction: MapConnectionDirection.east, targetMapId: 'target')
      ]));
      final pending = Completer<RuntimeMapBundle>();
      final session = await SpatialExplorationSession.load(source,
          loadMap: (_) => pending.future);
      if (interruption != 'dispose') addTearDown(session.dispose);
      attemptExit(session, MapConnectionDirection.east);
      expect(session.transitioning.value, isTrue);
      if (interruption == 'pause') session.setLifecyclePaused(true);
      if (interruption == 'cancel') session.cancelPendingTransition();
      if (interruption == 'dispose') session.dispose();
      pending.complete(target);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(session.bundle.map.id, 'source');
      expect(session.movement.paused, isTrue);
      if (interruption == 'pause') {
        session.setLifecyclePaused(false);
        expect(session.movement.paused, isFalse);
        session.frame(.05);
        expect(session.movement.moving, isFalse);
      }
    });
  }
}

(int, int) input(MapConnectionDirection direction) => switch (direction) {
      MapConnectionDirection.north => (0, -1),
      MapConnectionDirection.south => (0, 1),
      MapConnectionDirection.east => (1, 0),
      MapConnectionDirection.west => (-1, 0),
    };

void attemptExit(
    SpatialExplorationSession session, MapConnectionDirection direction) {
  final (dx, dz) = input(direction);
  session.movement.setInput(x: dx, z: dz);
  for (var i = 0; i < 100 && !session.transitioning.value; i++) {
    session.frame(.05);
  }
}

Future<void> settle(SpatialExplorationSession session) async {
  for (var i = 0; i < 500 && session.transitioning.value; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 2));
  }
  expect(session.transitioning.value, isFalse);
}
