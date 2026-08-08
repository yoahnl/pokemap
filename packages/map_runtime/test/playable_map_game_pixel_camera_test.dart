import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('playable camera quantizes resize and player tracking on Retina',
      () async {
    final game = _PixelCameraTestGame(
      bundle: _bundle(),
      projectFilePath: '/tmp/pixel_camera/project.json',
      devicePixelRatioProvider: () => 2,
    );
    final captureViewport = Vector2(469, 328.5);
    game.onGameResize(captureViewport);
    await game.onLoad();
    await _waitForInitialMapActivation(game);

    expect(game.camera.viewfinder.visibleGameSize, isNull);
    expect(game.camera.viewfinder.zoom, closeTo(0.5, 1e-12));
    expect(2 * game.camera.viewfinder.zoom * 2, closeTo(2, 1e-12));
    _expectPhysicalOriginAligned(game, captureViewport, dpr: 2);

    for (final position in const <GridPos>[
      GridPos(x: 11, y: 10),
      GridPos(x: 11, y: 11),
      GridPos(x: 12, y: 11),
    ]) {
      game.debugSetPlayerStateForTest(
        position: position,
        facing: Direction.south,
      );
      game.update(1 / 60);
      _expectPhysicalOriginAligned(game, captureViewport, dpr: 2);
    }

    final largerViewport = Vector2(720, 528);
    game.onGameResize(largerViewport);
    expect(game.camera.viewfinder.zoom, closeTo(0.75, 1e-12));
    expect(2 * game.camera.viewfinder.zoom * 2, closeTo(3, 1e-12));
    _expectPhysicalOriginAligned(game, largerViewport, dpr: 2);
    final stablePosition = game.camera.viewfinder.position.clone();

    for (var i = 0; i < 5; i++) {
      game.onGameResize(largerViewport);
      game.update(0);
      expect(game.camera.viewfinder.zoom, closeTo(0.75, 1e-12));
      expect(
          game.camera.viewfinder.position.x, closeTo(stablePosition.x, 1e-9));
      expect(
          game.camera.viewfinder.position.y, closeTo(stablePosition.y, 1e-9));
      _expectPhysicalOriginAligned(game, largerViewport, dpr: 2);
    }
  });

  test('focus and shake stay quantized and restore on completion or cancel',
      () async {
    final game = _PixelCameraTestGame(
      bundle: _bundle(includeCinematic: true),
      projectFilePath: '/tmp/pixel_camera/project.json',
      devicePixelRatioProvider: () => 2,
    );
    final viewport = Vector2(469, 328.5);
    game.onGameResize(viewport);
    await game.onLoad();
    await _waitForInitialMapActivation(game);

    final originalPosition = game.camera.viewfinder.position.clone();
    final originalZoom = game.camera.viewfinder.zoom;

    final completed = game.debugExecuteNarrativeSceneForTest(
      _sceneRequest('pixel_camera_completed'),
    );
    await _waitUntil(game, () => game.debugIsCinematicPlaying);
    await _pumpCinematicWithAlignment(game, viewport);

    expect(await completed, isA<NarrativeSceneExecutionCompleted>());
    expect(game.camera.viewfinder.zoom, closeTo(originalZoom, 1e-12));
    expect(
        game.camera.viewfinder.position.x, closeTo(originalPosition.x, 1e-9));
    expect(
        game.camera.viewfinder.position.y, closeTo(originalPosition.y, 1e-9));
    _expectPhysicalOriginAligned(game, viewport, dpr: 2);

    final cancelled = game.debugExecuteNarrativeSceneForTest(
      _sceneRequest('pixel_camera_cancelled'),
    );
    await _waitUntil(game, () => game.debugIsCinematicPlaying);
    game.update(0.025);
    _expectPhysicalOriginAligned(game, viewport, dpr: 2);

    game.debugResetBattleForTest();

    expect(await cancelled, isNot(isA<NarrativeSceneExecutionCompleted>()));
    expect(game.camera.viewfinder.zoom, closeTo(originalZoom, 1e-12));
    expect(
        game.camera.viewfinder.position.x, closeTo(originalPosition.x, 1e-9));
    expect(
        game.camera.viewfinder.position.y, closeTo(originalPosition.y, 1e-9));
    _expectPhysicalOriginAligned(game, viewport, dpr: 2);
  });
}

final class _PixelCameraTestGame extends PlayableMapGame {
  _PixelCameraTestGame({
    required super.bundle,
    required super.projectFilePath,
    required super.devicePixelRatioProvider,
  });

  @override
  bool get isLoaded => true;
}

void _expectPhysicalOriginAligned(
  PlayableMapGame game,
  Vector2 logicalViewport, {
  required double dpr,
}) {
  final zoom = game.camera.viewfinder.zoom;
  final position = game.camera.viewfinder.position;
  final physicalCenter = logicalViewport * (dpr / 2);
  final origin = physicalCenter - position * (zoom * dpr);
  expect(origin.x, closeTo(origin.x.roundToDouble(), 1e-9));
  expect(origin.y, closeTo(origin.y.roundToDouble(), 1e-9));
  expect(2 * zoom * dpr, closeTo((2 * zoom * dpr).roundToDouble(), 1e-9));
}

Future<void> _pumpCinematicWithAlignment(
  PlayableMapGame game,
  Vector2 viewport,
) async {
  for (var i = 0; i < 40 && game.debugIsCinematicPlaying; i++) {
    game.update(0.025);
    _expectPhysicalOriginAligned(game, viewport, dpr: 2);
    await Future<void>.value();
  }
  expect(game.debugIsCinematicPlaying, isFalse);
}

Future<void> _waitForInitialMapActivation(PlayableMapGame game) async {
  for (var i = 0; i < 100; i++) {
    if (!game.debugIsMapActivationDispatchInFlight) return;
    game.update(0);
    await Future<void>.value();
  }
  fail('Initial map activation did not settle.');
}

Future<void> _waitUntil(
  PlayableMapGame game,
  bool Function() condition,
) async {
  for (var i = 0; i < 100; i++) {
    if (condition()) return;
    game.update(0);
    await Future<void>.value();
  }
  fail('Runtime condition did not settle.');
}

NarrativeSceneExecutionRequest _sceneRequest(String executionId) {
  return NarrativeSceneExecutionRequest(
    eventId: 'event_pixel_camera',
    sceneId: 'scene_pixel_camera',
    executionId: executionId,
    gameState: const GameState(saveId: 'pixel_camera'),
  );
}

RuntimeMapBundle _bundle({bool includeCinematic = false}) {
  return RuntimeMapBundle(
    manifest: ProjectManifest(
      name: 'Pixel camera integration',
      settings: const ProjectSettings(
        tileWidth: 32,
        tileHeight: 32,
        displayScale: 2,
      ),
      maps: const <ProjectMapEntry>[
        ProjectMapEntry(
          id: 'map_pixel_camera',
          name: 'Pixel camera',
          relativePath: 'maps/pixel_camera.json',
        ),
      ],
      tilesets: const <ProjectTilesetEntry>[],
      cinematics: includeCinematic ? <CinematicAsset>[_cinematic()] : const [],
      scenes: includeCinematic ? <SceneAsset>[_scene()] : const [],
    ),
    map: const MapData(
      id: 'map_pixel_camera',
      name: 'Pixel camera',
      size: GridSize(width: 40, height: 30),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        MapEntity(
          id: 'spawn_start',
          name: 'Spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 10, y: 10),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.south,
          ),
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'spawn_start'),
    ),
    projectRootDirectory: '/tmp/pixel_camera',
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

CinematicAsset _cinematic() {
  return CinematicAsset(
    id: 'cinematic_pixel_camera',
    title: 'Pixel camera',
    mapId: 'map_pixel_camera',
    stageContext: CinematicStageContext(
      stagePoints: <CinematicStagePoint>[
        CinematicStagePoint(
          id: 'focus_target',
          label: 'Focus target',
          x: 25,
          y: 18,
        ),
      ],
    ),
    timeline: CinematicTimeline(
      steps: <CinematicTimelineStep>[
        CinematicTimelineStep(
          id: 'focus',
          kind: CinematicTimelineStepKind.camera,
          durationMs: 100,
          metadata: const <String, String>{
            cinematicTimelineCameraModeMetadataKey: 'focus',
            cinematicTimelineCameraTargetKindMetadataKey: 'stagePoint',
            cinematicTimelineCameraTargetStagePointIdMetadataKey:
                'focus_target',
            cinematicTimelineCameraZoomPresetMetadataKey: 'close',
          },
        ),
        CinematicTimelineStep(
          id: 'shake',
          kind: CinematicTimelineStepKind.shake,
          durationMs: 100,
        ),
      ],
    ),
  );
}

SceneAsset _scene() {
  return SceneAsset(
    id: 'scene_pixel_camera',
    name: 'Pixel camera scene',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: <SceneNode>[
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'cinematic',
          kind: SceneNodeKind.cinematic,
          payload: SceneCinematicPayload(
            cinematicId: 'cinematic_pixel_camera',
          ),
        ),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: <SceneEdge>[
        SceneEdge(
          id: 'start_to_cinematic',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'cinematic',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'cinematic_to_end',
          fromNodeId: 'cinematic',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.cinematicCompleted,
        ),
      ],
    ),
  );
}
