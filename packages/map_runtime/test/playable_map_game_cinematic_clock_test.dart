import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

const _frame = 1 / 60;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a runtime cinematic advances exactly the simulated time, frame after frame', () async {
    final game = await _loadedGame();
    final completion = await _start(game, 'first');
    for (var i = 0; i < 30; i++) {
      game.update(_frame);
    }
    expect(game.debugCinematicFadeOpacity, closeTo(.5, 1e-7));
    game.update(0);
    expect(game.debugCinematicFadeOpacity, closeTo(.5, 1e-7));
    for (var i = 0; i < 29; i++) {
      game.update(_frame);
    }
    expect(game.debugIsCinematicPlaying, isTrue);
    expect(
      game.debugCinematicFadeOpacity,
      closeTo((59 / 60 * 1e6).round() / 1e6, 1e-7),
    );
    game.update(_frame);
    expect(await completion, isA<NarrativeSceneExecutionCompleted>());
    expect(game.debugIsCinematicPlaying, isFalse);
  });

  test(
    'a cinematic played after an uneven one starts from zero and stays exact',
    () async {
      final game = await _loadedGame();
      final first = await _start(game, 'first');
      for (var i = 0; game.debugIsCinematicPlaying; i++) {
        expect(i, lessThan(200));
        game.update(.0123453);
        await Future<void>.value();
      }
      expect(await first, isA<NarrativeSceneExecutionCompleted>());
      game.update(_frame);
      final second = await _start(game, 'second');
      game.update(_frame);
      expect(game.debugCinematicFadeOpacity, closeTo(.016667, 1e-7));
      for (var i = 1; i < 30; i++) {
        game.update(_frame);
      }
      expect(game.debugCinematicFadeOpacity, closeTo(.5, 1e-7));
      for (var i = 0; i < 30; i++) {
        game.update(_frame);
      }
      expect(await second, isA<NarrativeSceneExecutionCompleted>());
    },
  );
}

Future<PlayableMapGame> _loadedGame() async {
  final game = _LoadedPlayableMapGame(
    bundle: _bundle(),
    projectFilePath: '/tmp/cinematic_clock/project.json',
    devicePixelRatioProvider: () => 1,
  );
  game.onGameResize(Vector2(320, 240));
  await game.onLoad();
  await _settle(game, () => !game.debugIsMapActivationDispatchInFlight);
  return game;
}

Future<Future<NarrativeSceneExecutionResult>> _start(
  PlayableMapGame game,
  String executionId,
) async {
  final completion = game.debugExecuteNarrativeSceneForTest(
    NarrativeSceneExecutionRequest(
      eventId: 'event_fade',
      sceneId: 'scene_fade',
      executionId: executionId,
      gameState: game.gameStateSnapshot,
    ),
  );
  await _settle(game, () => game.debugIsCinematicPlaying);
  expect(game.debugCinematicFadeOpacity ?? 0, 0);
  return completion;
}

Future<void> _settle(PlayableMapGame game, bool Function() condition) async {
  for (var i = 0; i < 100; i++) {
    if (condition()) return;
    game.update(0);
    await Future<void>.value();
  }
  fail('Runtime condition did not settle.');
}

final class _LoadedPlayableMapGame extends PlayableMapGame {
  _LoadedPlayableMapGame({
    required super.bundle,
    required super.projectFilePath,
    required super.devicePixelRatioProvider,
  });

  @override
  bool get isLoaded => true;
}

RuntimeMapBundle _bundle() => RuntimeMapBundle(
  manifest: ProjectManifest(
    name: 'Cinematic clock',
    maps: const [
      ProjectMapEntry(
        id: 'map_port',
        name: 'Port',
        relativePath: 'maps/port.json',
      ),
    ],
    tilesets: const [],
    cinematics: [
      CinematicAsset(
        id: 'cinematic_fade',
        title: 'Fondu',
        mapId: 'map_port',
        timeline: CinematicTimeline(
          steps: [
            CinematicTimelineStep(
              id: 'fade_out',
              kind: CinematicTimelineStepKind.fade,
              durationMs: 1000,
              metadata: const {cinematicTimelineFadeModeMetadataKey: 'fadeOut'},
            ),
          ],
        ),
      ),
    ],
    scenes: [
      SceneAsset(
        id: 'scene_fade',
        name: 'Fondu',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'cinematic',
              kind: SceneNodeKind.cinematic,
              payload: SceneCinematicPayload(cinematicId: 'cinematic_fade'),
            ),
            SceneNode(id: 'end', kind: SceneNodeKind.end),
          ],
          edges: [
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
      ),
    ],
  ),
  map: const MapData(
    id: 'map_port',
    name: 'Port',
    size: GridSize(width: 20, height: 15),
    layers: [MapLayer.object(id: 'objects', name: 'Objects')],
    entities: [
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
  projectRootDirectory: '/tmp/cinematic_clock',
  tilesetAbsolutePathsById: const {},
);
