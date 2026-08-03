import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlayableMapGame World State V1', () {
    test('a matching World Rule removes a blocking non-NPC map entity',
        () async {
      final game = _TestPlayableMapGame(
        bundle: _bundle(
          facts: <NarrativeFactDefinition>[
            NarrativeFactDefinition(
              id: 'fact_gate_open',
              label: 'Gate open',
              defaultValue: true,
            ),
          ],
          worldRules: <WorldRuleDefinition>[
            _hideBarrierRule(
              source: const WorldRuleSource(
                kind: WorldRuleSourceKind.fact,
                sourceId: 'fact_gate_open',
                predicate: WorldRuleSourcePredicate.isTrue,
              ),
            ),
          ],
        ),
      );

      await _load(game);
      await _moveRight(game);

      expect(game.debugPlayerGridPosition, const GridPos(x: 1, y: 0));
    });

    test('save/load preserves the Story Step projection that opens a route',
        () async {
      final storyline = StorylineAsset(
        id: 'storyline_route',
        type: StorylineType.main,
        title: 'Route',
        chapters: <StorylineChapter>[
          StorylineChapter(
            id: 'chapter_route',
            title: 'Route',
            order: 0,
            steps: <StorylineStep>[
              StorylineStep(
                id: 'step_gate_open',
                title: 'Open the gate',
                order: 0,
              ),
            ],
          ),
        ],
      );
      final bundle = _bundle(
        storylines: <StorylineAsset>[storyline],
        worldRules: <WorldRuleDefinition>[
          _hideBarrierRule(
            source: const WorldRuleSource(
              kind: WorldRuleSourceKind.storyStepCompletion,
              sourceId: 'step_gate_open',
              predicate: WorldRuleSourcePredicate.completed,
            ),
          ),
        ],
      );
      final lockedGame = _TestPlayableMapGame(bundle: bundle);
      await _load(lockedGame);
      await _moveRight(lockedGame);
      expect(lockedGame.debugPlayerGridPosition, const GridPos(x: 0, y: 0));

      const completed = GameState(
        saveId: 'world-state-save',
        currentMapId: 'map_world_state',
        playerPosition: GridPos(x: 0, y: 0),
        playerFacing: EntityFacing.east,
        progression: PlayerProgression(
          completedStepIds: <String>['step_gate_open'],
        ),
      );
      final restoredState = gameStateFromSaveData(
        SaveData.fromJson(saveDataFromGameState(completed).toJson()),
      );
      final game = _TestPlayableMapGame(
        bundle: bundle,
        saveData: saveDataFromGameState(restoredState),
        initialMapActivationReason: MapActivationReason.saveRestore,
      );

      await _load(game);
      await _moveRight(game);

      expect(
        game.gameStateSnapshot.progression.completedStepIds,
        contains('step_gate_open'),
      );
      expect(game.debugPlayerGridPosition, const GridPos(x: 1, y: 0));
    });
  });
}

WorldRuleDefinition _hideBarrierRule({required WorldRuleSource source}) {
  return WorldRuleDefinition(
    id: 'world_rule_hide_barrier',
    label: 'Open route',
    source: source,
    target: const WorldRuleTarget(
      kind: WorldRuleTargetKind.mapEntity,
      mapId: 'map_world_state',
      entityId: 'route_barrier',
    ),
    effect: const WorldRuleEffect(kind: WorldRuleEffectKind.entityHidden),
  );
}

RuntimeMapBundle _bundle({
  List<NarrativeFactDefinition> facts = const <NarrativeFactDefinition>[],
  List<StorylineAsset> storylines = const <StorylineAsset>[],
  List<WorldRuleDefinition> worldRules = const <WorldRuleDefinition>[],
}) {
  return RuntimeMapBundle(
    manifest: ProjectManifest(
      name: 'World State V1',
      maps: const <ProjectMapEntry>[
        ProjectMapEntry(
          id: 'map_world_state',
          name: 'World state',
          relativePath: 'maps/world_state.json',
        ),
      ],
      tilesets: const <ProjectTilesetEntry>[],
      facts: facts,
      storylines: storylines,
      worldRules: worldRules,
    ),
    map: const MapData(
      id: 'map_world_state',
      name: 'World state',
      size: GridSize(width: 3, height: 2),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        MapEntity(
          id: 'spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 0, y: 0),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.east,
          ),
        ),
        MapEntity(
          id: 'route_barrier',
          name: 'Closed route',
          kind: MapEntityKind.item,
          pos: GridPos(x: 1, y: 0),
          blocksMovement: true,
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'spawn'),
    ),
    projectRootDirectory: '/tmp/world_state_v1',
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

class _TestPlayableMapGame extends PlayableMapGame {
  _TestPlayableMapGame({
    required super.bundle,
    super.saveData,
    super.initialMapActivationReason,
  }) : super(projectFilePath: '/tmp/world_state_v1/project.json');

  @override
  bool get isLoaded => true;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    for (var i = 0; i < 240; i++) {
      if (!debugIsMapActivationDispatchInFlight) {
        return;
      }
      await Future<void>.delayed(Duration.zero);
    }
    fail('Timed out waiting for the initial map activation dispatch.');
  }
}

Future<void> _load(_TestPlayableMapGame game) async {
  game.onGameResize(Vector2(640, 480));
  await game.onLoad();
}

Future<void> _moveRight(_TestPlayableMapGame game) async {
  expect(
    game.handleRuntimeInputEvent(
      const RuntimeInputEvent.press(RuntimeInputControl.right),
    ),
    isTrue,
  );
  game.update(0.016);
  expect(
    game.handleRuntimeInputEvent(
      const RuntimeInputEvent.release(RuntimeInputControl.right),
    ),
    isTrue,
  );
  for (var i = 0; i < 240; i++) {
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
    if (!game.debugIsPlayerStepping && !game.debugHasPendingMapTransition) {
      return;
    }
  }
  fail('Timed out waiting for movement.');
}
