import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
      'PlayableMapGame renders and awaits a cinematic before restoring input and camera',
      () async {
    final game = _LifecycleTestPlayableMapGame(
      bundle: _bundle(),
      projectFilePath: '/tmp/cinematic_runtime/project.json',
      devicePixelRatioProvider: () => 2,
    );
    game.onGameResize(Vector2(320, 240));
    await game.onLoad();
    await _waitForInitialMapActivation(game);
    final originalCameraTopLeft = game.debugCameraWorldTopLeft.clone();
    final originalPlayerPosition = game.debugPlayerGridPosition;

    final completion = game.debugExecuteNarrativeSceneForTest(
      NarrativeSceneExecutionRequest(
        eventId: 'event_cinematic_runtime',
        sceneId: 'scene_cinematic_runtime',
        executionId: 'execution_cinematic_runtime',
        gameState: game.gameStateSnapshot,
      ),
    );
    await _waitUntil(game, () => game.debugIsCinematicPlaying);

    expect(game.debugIsCinematicPlaying, isTrue);
    expect(game.debugIsGameplayInputLocked, isTrue);
    expect(await game.saveGame(), isFalse);
    expect(await game.loadGame(), isFalse);
    expect(
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(RuntimeInputControl.right),
      ),
      isTrue,
    );

    game.update(0.05);
    expect(game.debugCameraWorldTopLeft, isNot(originalCameraTopLeft));
    expect(game.debugPlayerGridPosition, originalPlayerPosition);

    game.update(0.05);
    expect(game.debugCinematicDialogueLine, 'Le phare nous attend.');
    expect(game.debugIsCinematicPlaying, isTrue);

    expect(
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(RuntimeInputControl.primary),
      ),
      isTrue,
    );
    expect(game.debugCinematicDialogueLine, isNull);
    expect(game.debugCinematicFadeOpacity, 0);

    game.update(0.05);
    expect(game.debugCinematicFadeOpacity, closeTo(0.5, 0.001));
    game.update(0.05);
    final result = await completion;

    expect(result, isA<NarrativeSceneExecutionCompleted>());
    expect(game.debugIsCinematicPlaying, isFalse);
    expect(game.debugIsGameplayInputLocked, isFalse);
    expect(game.debugCinematicFadeOpacity, isNull);
    expect(game.debugCameraWorldTopLeft, originalCameraTopLeft);
    expect(game.debugPlayerGridPosition, originalPlayerPosition);
  });
}

final class _LifecycleTestPlayableMapGame extends PlayableMapGame {
  _LifecycleTestPlayableMapGame({
    required super.bundle,
    required super.projectFilePath,
    required super.devicePixelRatioProvider,
  });

  @override
  bool get isLoaded => true;
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

RuntimeMapBundle _bundle() {
  return RuntimeMapBundle(
    manifest: ProjectManifest(
      name: 'Cinematic runtime integration',
      maps: const <ProjectMapEntry>[
        ProjectMapEntry(
          id: 'map_port',
          name: 'Port',
          relativePath: 'maps/port.json',
        ),
      ],
      tilesets: const <ProjectTilesetEntry>[],
      cinematics: <CinematicAsset>[_cinematic()],
      scenes: <SceneAsset>[_scene()],
    ),
    map: const MapData(
      id: 'map_port',
      name: 'Port',
      size: GridSize(width: 20, height: 15),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        MapEntity(
          id: 'spawn_start',
          name: 'Spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 1, y: 1),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.south,
          ),
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'spawn_start'),
    ),
    projectRootDirectory: '/tmp/cinematic_runtime',
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

CinematicAsset _cinematic() {
  return CinematicAsset(
    id: 'cinematic_lighthouse',
    title: 'Lighthouse reveal',
    mapId: 'map_port',
    stageContext: CinematicStageContext(
      stagePoints: <CinematicStagePoint>[
        CinematicStagePoint(
          id: 'lighthouse',
          label: 'Phare',
          x: 15,
          y: 10,
        ),
      ],
    ),
    timeline: CinematicTimeline(
      steps: <CinematicTimelineStep>[
        CinematicTimelineStep(
          id: 'focus_lighthouse',
          kind: CinematicTimelineStepKind.camera,
          durationMs: 100,
          metadata: const <String, String>{
            cinematicTimelineCameraModeMetadataKey: 'focus',
            cinematicTimelineCameraTargetKindMetadataKey: 'stagePoint',
            cinematicTimelineCameraTargetStagePointIdMetadataKey: 'lighthouse',
            cinematicTimelineCameraZoomPresetMetadataKey: 'close',
          },
        ),
        CinematicTimelineStep(
          id: 'line',
          kind: CinematicTimelineStepKind.dialogueLine,
          dialogueText: 'Le phare nous attend.',
        ),
        CinematicTimelineStep(
          id: 'fade_out',
          kind: CinematicTimelineStepKind.fade,
          durationMs: 100,
          metadata: const <String, String>{
            cinematicTimelineFadeModeMetadataKey: 'fadeOut',
          },
        ),
      ],
    ),
  );
}

SceneAsset _scene() {
  return SceneAsset(
    id: 'scene_cinematic_runtime',
    name: 'Cinematic runtime Scene',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: <SceneNode>[
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'cinematic',
          kind: SceneNodeKind.cinematic,
          payload: SceneCinematicPayload(cinematicId: 'cinematic_lighthouse'),
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
