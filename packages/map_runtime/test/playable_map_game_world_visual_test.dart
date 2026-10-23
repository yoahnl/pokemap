import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Player keeps map pictures after Scene completion and clears them on transfer', () async {
    final fixture = await _fixture();
    final game = fixture.game;
    addTearDown(() async {
      game.onRemove();
      await fixture.directory.delete(recursive: true);
    });
    final completion = _execute(game, 'map_picture');
    await _until(game, () => game.debugPendingSceneWaitCount > 0);
    expect(
      game.debugWorldPresentationFrame.pictures.single.scope,
      SceneVisualScope.map,
    );
    expect(game.debugWorldPresentationVisible, isTrue);
    await _until(game, () => game.debugPendingSceneWaitCount == 0);
    expect(await completion, isA<NarrativeSceneExecutionCompleted>());
    expect(
      game.debugWorldPresentationFrame.pictures.single.mediaAssetId,
      'portrait',
    );
    var done = false;
    final transfer = game
        .debugExecuteSceneInteractiveCommand(
          SceneInteractiveCommand.warp(
            destinationMapId: 'target',
            warpId: 'arrival',
          ),
        )
        .whenComplete(() => done = true);
    await _until(game, () => done);
    expect(await transfer, 'completed');
    expect(game.gameStateSnapshot.currentMapId, 'target');
    expect(game.debugWorldPresentationFrame.pictures, isEmpty);
  });

  test('Player clears scene pictures and interruption never restores a removed map owner', () async {
    final fixture = await _fixture();
    final game = fixture.game;
    addTearDown(() async {
      if (!game.removedForTest) {
        game.onRemove();
      }
      await fixture.directory.delete(recursive: true);
    });
    final scene = _execute(game, 'scene_picture');
    await _until(game, () => game.debugPendingSceneWaitCount > 0);
    expect(
      game.debugWorldPresentationFrame.pictures.single.scope,
      SceneVisualScope.scene,
    );
    await _until(game, () => game.debugPendingSceneWaitCount == 0);
    expect(await scene, isA<NarrativeSceneExecutionCompleted>());
    expect(game.debugWorldPresentationFrame.pictures, isEmpty);
    final interrupted = _execute(game, 'long_picture');
    await _until(game, () => game.debugPendingSceneWaitCount > 0);
    expect(game.debugWorldPresentationFrame.pictures, hasLength(1));
    game.onRemove();
    await interrupted;
    expect(game.debugWorldPresentationFrame.pictures, isEmpty);
  });
}

Future<NarrativeSceneExecutionResult> _execute(
  PlayableMapGame game,
  String sceneId,
) => game.debugExecuteNarrativeSceneForTest(
  NarrativeSceneExecutionRequest(
    eventId: 'visual_event',
    sceneId: sceneId,
    executionId: 'visual:$sceneId',
    gameState: game.gameStateSnapshot,
  ),
);

Future<void> _until(PlayableMapGame game, bool Function() done) async {
  for (var index = 0; index < 240; index++) {
    if (done()) {
      return;
    }
    game.update(.016);
    await Future<void>.delayed(Duration.zero);
  }
  fail('Player visual state did not settle.');
}

Future<({Directory directory, _VisualTestGame game})> _fixture() async {
  final directory = await Directory.systemTemp.createTemp(
    'world_visual_player_',
  );
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    const ui.Rect.fromLTWH(0, 0, 4, 4),
    ui.Paint()..color = const ui.Color(0xff00ff00),
  );
  final image = await recorder.endRecording().toImage(4, 4);
  final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer
      .asUint8List();
  image.dispose();
  final artifact = ContentArtifactRef.fromBytes(bytes, mediaType: 'image/png');
  final blob = File('${directory.path}/${assetBlobStorageKey(artifact)}');
  await blob.parent.create(recursive: true);
  await blob.writeAsBytes(bytes);
  await File('${directory.path}/$assetCatalogStorageKey').writeAsString(
    jsonEncode(
      AssetCatalog(
        records: [
          AssetRecord(
            id: 'portrait_source',
            logicalPath: assetBlobStorageKey(artifact),
            artifact: artifact,
          ),
        ],
      ).toJson(),
    ),
  );
  await File('${directory.path}/$projectMediaCatalogStorageKey').writeAsBytes(
    encodeProjectMediaCatalogBytes(
      ProjectMediaCatalog(
        entries: [
          ProjectMediaAsset(
            id: 'portrait',
            label: 'Portrait',
            kind: ProjectMediaKind.image,
            sourceAssetId: 'portrait_source',
            technicalMetadata: ProjectMediaTechnicalMetadata(
              mediaType: 'image/png',
              container: 'png',
              codec: 'png',
              sizeBytes: bytes.length,
              width: 4,
              height: 4,
            ),
          ),
        ],
      ),
    ),
  );
  final project = ProjectManifest(
    name: 'World visual test',
    settings: const ProjectSettings(tileWidth: 32, tileHeight: 32),
    maps: const [
      ProjectMapEntry(
        id: 'source',
        name: 'Source',
        relativePath: 'maps/source.json',
      ),
      ProjectMapEntry(
        id: 'target',
        name: 'Target',
        relativePath: 'maps/target.json',
      ),
    ],
    tilesets: const [],
    scenes: [
      _scene('map_picture', SceneVisualScope.map, 100),
      _scene('scene_picture', SceneVisualScope.scene, 100),
      _scene('long_picture', SceneVisualScope.map, 5000),
    ],
  );
  RuntimeMapBundle bundle(String id) => RuntimeMapBundle(
    manifest: project,
    map: MapData(
      id: id,
      name: id,
      size: const GridSize(width: 8, height: 8),
      layers: const [MapLayer.object(id: 'objects', name: 'Objects')],
      entities: const [
        MapEntity(
          id: 'spawn',
          name: 'Spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 2, y: 2),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.south,
          ),
        ),
      ],
      warps: [
        MapWarp(
          id: 'arrival',
          pos: const GridPos(x: 3, y: 3),
          targetMapId: id,
          targetPos: const GridPos(x: 3, y: 3),
          triggerMode: MapWarpTriggerMode.onBump,
        ),
      ],
      mapMetadata: const MapMetadata(defaultSpawnId: 'spawn'),
    ),
    projectRootDirectory: directory.path,
    tilesetAbsolutePathsById: const {},
  );
  final game = _VisualTestGame(
    bundle: bundle('source'),
    projectFilePath: '${directory.path}/project.json',
    runtimeMapBundleLoader: ({
      required projectFilePath,
      required mapId,
    }) async => bundle(mapId),
  );
  game.onGameResize(Vector2(512, 384));
  await game.onLoad();
  await _until(game, () => !game.debugIsMapActivationDispatchInFlight);
  return (directory: directory, game: game);
}

SceneAsset _scene(String id, SceneVisualScope scope, int waitMs) => SceneAsset(
  id: id,
  name: id,
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'show',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.interactive(
          SceneInteractiveCommand.worldPresentation(
            operation: SceneWorldPresentationOperation.showPicture,
            scope: scope,
            slotId: 1,
            mediaAssetId: 'portrait',
            referenceWidth: 512,
            referenceHeight: 384,
            x: 25,
            y: 25,
          ),
        ),
      ),
      SceneNode(
        id: 'wait',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.interactive(
          SceneInteractiveCommand.wait(durationMs: waitMs),
        ),
      ),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
    edges: [
      SceneEdge(
        id: 'start_show',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'show',
        kind: SceneEdgeKind.defaultFlow,
      ),
      SceneEdge(
        id: 'show_wait',
        fromNodeId: 'show',
        fromPortId: 'completed',
        toNodeId: 'wait',
        kind: SceneEdgeKind.defaultFlow,
      ),
      SceneEdge(
        id: 'wait_end',
        fromNodeId: 'wait',
        fromPortId: 'completed',
        toNodeId: 'end',
        kind: SceneEdgeKind.defaultFlow,
      ),
    ],
  ),
);

final class _VisualTestGame extends PlayableMapGame {
  _VisualTestGame({
    required super.bundle,
    required super.projectFilePath,
    required super.runtimeMapBundleLoader,
  });
  bool removedForTest = false;
  @override
  bool get isLoaded => true;
  @override
  void onRemove() {
    removedForTest = true;
    super.onRemove();
  }
}
