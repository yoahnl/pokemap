import 'dart:convert';
import 'dart:io';

import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart' show Direction;
import 'package:map_runtime/map_runtime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('hit test uses canvas camera and project display scale without effects',
      () async {
    final game = await _load();
    _configureCamera(game);
    final action = game.overworldInteractionSnapshot.primaryAction!;
    final state = game.gameStateSnapshot;
    final revision = game.debugGameStateRevision;
    expect(game.hitTestOverworldInteraction(const Offset(180, 220)),
        same(action.request));
    expect(game.debugGameStateRevision, revision);
    expect(game.gameStateSnapshot, state);
    expect(game.debugIsNarrativeSpatialDispatchInFlight, isFalse);
    expect(game.debugNotificationText, isNull);
  });

  test(
      'hit test only accepts the current target bounds with exclusive far edges',
      () async {
    final game = await _load();
    _configureCamera(game);
    final request = game.overworldInteractionSnapshot.primaryAction!.request;
    expect(game.hitTestOverworldInteraction(const Offset(120, 160)), request);
    expect(game.hitTestOverworldInteraction(const Offset(239, 279)), request);
    for (final point in [
      const Offset(119, 220),
      const Offset(240, 220),
      const Offset(180, 159),
      const Offset(180, 280),
      const Offset(360, 220),
      const Offset(double.nan, 220),
      const Offset(180, double.infinity),
    ]) {
      expect(game.hitTestOverworldInteraction(point), isNull, reason: '$point');
    }
  });

  test('viewport letterbox rejects a target projected into its clipped band',
      () async {
    final game = await _load();
    _configureCamera(game);
    game.camera.viewfinder.position = Vector2(40, 80);
    expect(game.camera.localToGlobal(Vector2(100, 60)).toOffset(),
        const Offset(180, 40));
    expect(game.overworldInteractionSnapshot.primaryAction, isNotNull);
    expect(game.hitTestOverworldInteraction(const Offset(180, 40)), isNull);
    game.camera.viewfinder.position = Vector2(40, 20);
    expect(game.hitTestOverworldInteraction(const Offset(180, 220)), isNotNull);
  });

  test('authority and facing changes revoke hit tests and captured requests',
      () async {
    final game = await _load();
    _configureCamera(game);
    final request = game.hitTestOverworldInteraction(const Offset(180, 220))!;
    game.setExternalInputLock(RuntimeExternalInputLock.pauseMenu, locked: true);
    expect(game.hitTestOverworldInteraction(const Offset(180, 220)), isNull);
    expect(game.dispatchOverworldInteraction(request), isFalse);
    game.setExternalInputLock(RuntimeExternalInputLock.pauseMenu,
        locked: false);
    game.debugSetPlayerStateForTest(
        position: const GridPos(x: 1, y: 1), facing: Direction.south);
    expect(game.hitTestOverworldInteraction(const Offset(180, 220)), isNull);
    expect(game.dispatchOverworldInteraction(request), isFalse);
    expect(game.debugIsNarrativeSpatialDispatchInFlight, isFalse);
  });

  test('hidden item accepts a tap only on the facing cell without a hint',
      () async {
    final game = await _load(hidden: true);
    _configureCamera(game);
    expect(game.overworldInteractionSnapshot.primaryAction, isNull);
    final request = game.hitTestOverworldInteraction(const Offset(180, 220));
    expect(request, isNotNull);
    expect(request!.targetId, 'target-source');
    expect(game.hitTestOverworldInteraction(const Offset(60, 220)), isNull);
    expect(game.hitTestOverworldInteraction(const Offset(300, 220)), isNull);
    expect(game.debugIsNarrativeSpatialDispatchInFlight, isFalse);
    expect(game.debugNotificationText, isNull);
    game.setExternalInputLock(RuntimeExternalInputLock.pauseMenu, locked: true);
    expect(game.hitTestOverworldInteraction(const Offset(180, 220)), isNull);
    expect(game.dispatchOverworldInteraction(request), isFalse);
    game.setExternalInputLock(RuntimeExternalInputLock.pauseMenu, locked: false);
    game.debugSetPlayerStateForTest(
        position: const GridPos(x: 1, y: 1), facing: Direction.south);
    expect(game.hitTestOverworldInteraction(const Offset(180, 220)), isNull);
    expect(game.dispatchOverworldInteraction(request), isFalse);
  });

  test('connected map interaction removes the active map world origin',
      () async {
    final root = await Directory.systemTemp.createTemp('ow006_connected_');
    addTearDown(() => root.delete(recursive: true));
    final source = _map('source',
        spawn: const GridPos(x: 3, y: 1),
        target: false,
        connections: const [
          MapConnection(
              direction: MapConnectionDirection.east,
              targetMapId: 'target',
              offset: 0)
        ]);
    final target = _map('target', targetPosition: const GridPos(x: 1, y: 1));
    final manifest = _manifest([source, target]);
    await Directory('${root.path}/maps').create();
    for (final map in [source, target]) {
      await File('${root.path}/maps/${map.id}.json')
          .writeAsString(jsonEncode(map.toJson()));
    }
    final project = File('${root.path}/project.json');
    await project.writeAsString(jsonEncode(manifest.toJson()));
    final bundle = await loadRuntimeMapBundle(
        projectFilePath: project.path, mapId: 'source');
    final game = _HitTestGame(bundle: bundle, projectFilePath: project.path);
    await _start(game);
    expect(
        game.handleRuntimeInputEvent(
            const RuntimeInputEvent.press(RuntimeInputControl.right)),
        isTrue);
    game.update(.016);
    game.handleRuntimeInputEvent(
        const RuntimeInputEvent.release(RuntimeInputControl.right));
    await _settle(
        game,
        () =>
            game.gameStateSnapshot.currentMapId == 'target' &&
            !game.debugIsMapActivationDispatchInFlight &&
            !game.debugIsPlayerStepping &&
            !game.debugHasPendingMapTransition);
    expect(game.debugMapOriginWorldTopLeft, Vector2(160, 0));
    expect(game.debugPlayerGridPosition, const GridPos(x: 0, y: 1));
    _configureCamera(game);
    game.camera.viewfinder.position = Vector2(160, 20);
    final action = game.overworldInteractionSnapshot.primaryAction!;
    expect(action.request.mapId, 'target');
    expect(action.targetBounds.leftPx, 16);
    expect(game.hitTestOverworldInteraction(const Offset(180, 220)),
        action.request);
    expect(game.hitTestOverworldInteraction(const Offset(60, 220)), isNull);
  });
}

void _configureCamera(PlayableMapGame game) {
  game.camera.viewport = FixedResolutionViewport(resolution: Vector2(200, 100));
  game.camera.viewport.onGameResize(Vector2(400, 400));
  game.camera.viewfinder.anchor = Anchor.topLeft;
  game.camera.viewfinder.position = Vector2(40, 20);
  game.camera.viewfinder.zoom = 1.5;
}

Future<_HitTestGame> _load({bool hidden = false}) async {
  final map = _map('source', hidden: hidden);
  final game = _HitTestGame(
      bundle: RuntimeMapBundle(
          manifest: _manifest([map]),
          map: map,
          projectRootDirectory: '/tmp/ow006_hit_test',
          tilesetAbsolutePathsById: const {}),
      projectFilePath: '/tmp/ow006_hit_test/project.json');
  await _start(game);
  return game;
}

Future<void> _start(PlayableMapGame game) async {
  addTearDown(game.onRemove);
  game.onGameResize(Vector2(400, 400));
  await game.onLoad();
  await _settle(game, () => !game.debugIsMapActivationDispatchInFlight);
}

Future<void> _settle(PlayableMapGame game, bool Function() done) async {
  for (var i = 0; i < 240; i++) {
    if (done()) return;
    game.update(.016);
    await Future<void>.delayed(Duration.zero);
  }
  fail('Runtime did not settle.');
}

ProjectManifest _manifest(List<MapData> maps) => ProjectManifest(
    name: 'Interaction canvas hit test',
    settings:
        const ProjectSettings(tileWidth: 16, tileHeight: 16, displayScale: 2.5),
    maps: maps
        .map((map) => ProjectMapEntry(
            id: map.id, name: map.name, relativePath: 'maps/${map.id}.json'))
        .toList(),
    tilesets: const []);

MapData _map(
  String id, {
  GridPos spawn = const GridPos(x: 1, y: 1),
  GridPos targetPosition = const GridPos(x: 2, y: 1),
  bool target = true,
  bool hidden = false,
  List<MapConnection> connections = const [],
}) =>
    MapData(
        id: id,
        name: id,
        size: const GridSize(width: 4, height: 3),
        layers: const [MapLayer.object(id: 'objects', name: 'Objects')],
        connections: connections,
        entities: [
          MapEntity(
              id: 'spawn',
              name: 'Spawn',
              kind: MapEntityKind.spawn,
              pos: spawn,
              blocksMovement: false,
              spawn: const MapEntitySpawnData(
                  role: EntitySpawnRole.playerStart,
                  facing: EntityFacing.east)),
          if (target)
            MapEntity(
                id: 'target-$id',
                name: 'Target',
                kind: hidden ? MapEntityKind.item : MapEntityKind.custom,
                pos: targetPosition,
                size: GridSize(width: hidden ? 2 : 1, height: 1),
                item: hidden
                    ? const MapEntityItemData(
                        gameItemId: 'hidden-item',
                        visibility: MapEntityItemVisibility.hidden)
                    : null),
        ],
        mapMetadata: const MapMetadata(defaultSpawnId: 'spawn'));

final class _HitTestGame extends PlayableMapGame {
  _HitTestGame({required super.bundle, required super.projectFilePath});
  @override
  bool get isLoaded => true;
}
