import 'dart:async';
import 'dart:ui' show Color;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/dialogue_runtime_models.dart';
import 'package:map_runtime/src/application/narrative_runtime_activity_gate.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:map_runtime/src/presentation/flame/playable_map_game.dart'
    show
        RuntimeDialogueSessionLoader,
        RuntimeMapBundleLoader,
        RuntimeTilesetImageLoader;

import 'surface/surface_runtime_test_support.dart' show runtimeTilesetImage;

const _sourceMapId = 'checkpoint_source';
const _restoredMapId = 'checkpoint_restored';
const _legacyBlockedFlag = 'legacy.must_not_run_during_checkpoint';
const _staleCutsceneFlag = 'cutscene.must_not_resume_after_checkpoint';
const _followScenarioId = 'legacy_follow_before_load';
const _trainerId = 'checkpoint_trainer';

const _battleStats = BattleStatsSnapshot(
  attack: 10,
  defense: 10,
  specialAttack: 10,
  specialDefense: 10,
  speed: 10,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlayableMapGame checkpoint/load safety', () {
    test(
      'checkpoint already in progress refuses an atomic Cutscene start',
      () async {
        final gate = NarrativeRuntimeActivityGate();
        final game = _game(
          bundle: _bundle(map: _plainMap(_sourceMapId)),
          initialState: _state(mapId: _sourceMapId),
          narrativeRuntimeActivityGate: gate,
        );
        await _load(game);

        final checkpointStarted = Completer<void>();
        final releaseCheckpoint = Completer<void>();
        final checkpoint = gate.runCheckpoint<void>(
          NarrativeRuntimeCheckpointOperation.save,
          () async {
            checkpointStarted.complete();
            await releaseCheckpoint.future;
          },
        );
        await checkpointStarted.future;

        expect(
          game.startCutscene(_waitThenFlagCutscene('checkpoint_refused')),
          isFalse,
        );
        game.update(20);
        expect(game.isCutsceneRunning, isFalse);
        expect(
          game.gameStateSnapshot.storyFlags.activeFlags,
          isNot(contains(_staleCutsceneFlag)),
        );

        releaseCheckpoint.complete();
        await checkpoint;
        expect(gate.activity, NarrativeRuntimeActivity.idle);
      },
    );

    for (final fixture in <({
      String name,
      RuntimeCutsceneAsset cutscene,
      List<ProjectDialogueEntry> dialogues,
      RuntimeDialogueSessionLoader? dialogueLoader,
    })>[
      (
        name: 'wait',
        cutscene: _waitThenFlagCutscene('wait_before_load'),
        dialogues: const <ProjectDialogueEntry>[],
        dialogueLoader: null,
      ),
      (
        name: 'choice',
        cutscene: const RuntimeCutsceneAsset(
          id: 'choice_before_load',
          name: 'Choice before load',
          steps: <RuntimeCutsceneStep>[
            CutsceneChoiceStep(
              choiceId: 'checkpoint_choice',
              prompt: 'Choose',
              options: <CutsceneChoiceOption>[
                CutsceneChoiceOption(value: 'yes', label: 'Yes'),
              ],
            ),
            CutsceneSetFlagStep(flagName: _staleCutsceneFlag),
          ],
        ),
        dialogues: const <ProjectDialogueEntry>[],
        dialogueLoader: null,
      ),
      (
        name: 'dialogue',
        cutscene: const RuntimeCutsceneAsset(
          id: 'dialogue_before_load',
          name: 'Dialogue before load',
          steps: <RuntimeCutsceneStep>[
            CutsceneDialogueStep(dialogueId: 'cutscene_dialogue'),
            CutsceneSetFlagStep(flagName: _staleCutsceneFlag),
          ],
        ),
        dialogues: const <ProjectDialogueEntry>[
          ProjectDialogueEntry(
            id: 'cutscene_dialogue',
            name: 'Cutscene dialogue',
            relativePath: 'dialogues/cutscene_dialogue.yarn',
          ),
        ],
        dialogueLoader: (_) async => _singleLineDialogue(),
      ),
    ]) {
      test(
        '${fixture.name} Cutscene owns sceneSuspended, blocks checkpoints and '
        'cannot mutate after cancellation/load',
        () async {
          final gate = NarrativeRuntimeActivityGate();
          final repository = _GateMemoryRepository(gate)
            ..storedState = _state(
              mapId: _sourceMapId,
              position: const GridPos(x: 2, y: 2),
            );
          final game = _game(
            bundle: _bundle(
              map: _plainMap(_sourceMapId),
              dialogues: fixture.dialogues,
            ),
            initialState: _state(mapId: _sourceMapId),
            narrativeRuntimeActivityGate: gate,
            saveRepository: repository,
            dialogueSessionLoader: fixture.dialogueLoader,
          );
          await _load(game);

          expect(game.startCutscene(fixture.cutscene), isTrue);
          game.update(0.016);
          await Future<void>.delayed(Duration.zero);

          expect(game.isCutsceneRunning, isTrue);
          expect(gate.activity, NarrativeRuntimeActivity.sceneSuspended);
          if (fixture.name == 'choice') {
            expect(game.hasPendingCutsceneChoice, isTrue);
          }
          expect(await game.saveGame(), isFalse);
          expect(await game.loadGame(), isFalse);
          expect(repository.saveCount, 0);
          expect(repository.loadCount, 0);

          expect(game.cancelCutscene(), isTrue);
          expect(game.isCutsceneRunning, isFalse);
          expect(game.pendingCutsceneChoiceRequest, isNull);
          expect(gate.activity, NarrativeRuntimeActivity.idle);

          expect(await game.loadGame(), isTrue);
          for (var i = 0; i < 8; i++) {
            game.update(1);
            await Future<void>.delayed(Duration.zero);
          }
          final state = game.gameStateSnapshot;
          expect(state.playerPosition, const GridPos(x: 2, y: 2));
          expect(
            state.storyFlags.activeFlags,
            isNot(contains(_staleCutsceneFlag)),
          );
          expect(game.isCutsceneRunning, isFalse);
        },
      );
    }

    test(
      'battle handoff blocks load until async setup terminates',
      () async {
        final gate = NarrativeRuntimeActivityGate();
        final repository = _GateMemoryRepository(gate)
          ..storedState = _state(
            mapId: _sourceMapId,
            position: const GridPos(x: 3, y: 3),
          );
        final setupStarted = Completer<void>();
        final releaseSetup = Completer<void>();
        final game = _game(
          bundle: _sceneBundle(),
          initialState: _battleReadyState(),
          narrativeRuntimeActivityGate: gate,
          saveRepository: repository,
          beforeBattleHandoffPreparation: () async {
            setupStarted.complete();
            await releaseSetup.future;
          },
        );
        await _load(game);

        final handoff = game.debugOpenBattleForTest(_trainerContext().request);
        await setupStarted.future;

        expect(game.debugFlowPhaseName, 'battleTransition');
        expect(await game.saveGame(), isFalse);
        expect(await game.loadGame(), isFalse);
        expect(repository.saveCount, 0);
        expect(repository.loadCount, 0);

        releaseSetup.complete();
        await handoff;
        expect(game.debugFlowPhaseName, isNot('battleTransition'));
        expect(game.gameStateSnapshot.currentMapId, _sourceMapId);
        expect(
          game.gameStateSnapshot.playerPosition,
          isNot(const GridPos(x: 3, y: 3)),
        );
      },
    );

    test(
      'Cutscene outcome source is refused while a checkpoint owns the '
      'narrative gate',
      () async {
        final gate = NarrativeRuntimeActivityGate();
        final game = _game(
          bundle: _bundle(
            map: _plainMap(_sourceMapId),
            scenarios: <ScenarioAsset>[_outcomeFlagScenario()],
          ),
          initialState: _state(mapId: _sourceMapId),
          narrativeRuntimeActivityGate: gate,
        );
        await _load(game);

        final checkpointStarted = Completer<void>();
        final releaseCheckpoint = Completer<void>();
        final checkpoint = gate.runCheckpoint<void>(
          NarrativeRuntimeCheckpointOperation.load,
          () async {
            checkpointStarted.complete();
            await releaseCheckpoint.future;
          },
        );
        await checkpointStarted.future;

        expect(
          game.startCutscene(
            const RuntimeCutsceneAsset(
              id: 'emit_during_checkpoint',
              name: 'Emit during checkpoint',
              steps: <RuntimeCutsceneStep>[
                CutsceneEmitOutcomeStep(outcomeId: 'checkpoint.seed'),
              ],
            ),
          ),
          isFalse,
        );
        expect(() => game.update(0.016), returnsNormally);

        expect(gate.checkpointInProgress, isTrue);
        expect(game.isCutsceneRunning, isFalse);
        expect(
          game.gameStateSnapshot.storyFlags.activeFlags,
          isNot(contains(_legacyBlockedFlag)),
        );

        releaseCheckpoint.complete();
        await checkpoint;
        expect(gate.activity, NarrativeRuntimeActivity.idle);
      },
    );

    test(
      'successful load discards queued Scenario completion and follow work '
      'before the restored state can be mutated',
      () async {
        final gate = NarrativeRuntimeActivityGate();
        final restoredState = _state(
          mapId: _restoredMapId,
          position: const GridPos(x: 1, y: 1),
        );
        final repository = _GateMemoryRepository(gate)
          ..storedState = restoredState;
        final restoredBundle = _bundle(map: _plainMap(_restoredMapId));
        final game = _game(
          bundle: _bundle(
            map: _followMap(),
            scenarios: <ScenarioAsset>[_mapEnterFollowScenario()],
          ),
          initialState: _state(mapId: _sourceMapId),
          narrativeRuntimeActivityGate: gate,
          saveRepository: repository,
          runtimeMapBundleLoader: ({required projectFilePath, required mapId}) {
            expect(mapId, _restoredMapId);
            return Future<RuntimeMapBundle>.value(restoredBundle);
          },
        );
        await _load(game);
        expect(game.debugHasActiveScenarioFollow, isTrue);

        expect(await game.loadGame(), isTrue);
        expect(
          game.debugHasActiveScenarioFollow,
          isFalse,
          reason: 'A successful load must purge the old map follow owner.',
        );
        for (var i = 0; i < 80; i++) {
          game.update(0.016);
          await Future<void>.delayed(Duration.zero);
        }

        final state = game.gameStateSnapshot;
        expect(state.currentMapId, _restoredMapId);
        expect(state.progression.completedCutsceneIds, isEmpty);
        expect(
          state.storyFlags.activeFlags,
          isNot(contains(scenarioOutcomeFlagName(_followScenarioId))),
        );
        expect(game.debugHasActiveScenarioFollow, isFalse);
        expect(game.debugHasPendingLeaderWarpHandoff, isFalse);
      },
    );

    test(
      'successful load purges an old-map Scenario NPC warp entry',
      () async {
        final gate = NarrativeRuntimeActivityGate();
        final repository = _GateMemoryRepository(gate)
          ..storedState = _state(mapId: _restoredMapId);
        final restoredBundle = _bundle(map: _plainMap(_restoredMapId));
        final game = _game(
          bundle: _leaderWarpBundle(),
          initialState: _state(mapId: _sourceMapId),
          narrativeRuntimeActivityGate: gate,
          saveRepository: repository,
          runtimeTilesetImageLoader: _leaderTilesetLoader,
          runtimeMapBundleLoader: ({required projectFilePath, required mapId}) {
            expect(mapId, _restoredMapId);
            return Future<RuntimeMapBundle>.value(restoredBundle);
          },
        );
        await _load(game);

        expect(
          game.debugRunScenarioMoveCharacterToWarp(
            entityId: 'leader',
            warpId: 'leader_exit',
          ),
          isTrue,
        );
        expect(game.debugPendingScenarioNpcWarpEntryCount, 1);

        expect(await game.loadGame(), isTrue);

        expect(game.debugPendingScenarioNpcWarpEntryCount, 0);
        expect(game.gameStateSnapshot.currentMapId, _restoredMapId);
      },
    );

    test(
      'successful load purges a leader warp handoff and its active follow',
      () async {
        final gate = NarrativeRuntimeActivityGate();
        final repository = _GateMemoryRepository(gate)
          ..storedState = _state(mapId: _restoredMapId);
        final restoredBundle = _bundle(map: _plainMap(_restoredMapId));
        final game = _game(
          bundle: _leaderWarpBundle(),
          initialState: _state(mapId: _sourceMapId),
          narrativeRuntimeActivityGate: gate,
          saveRepository: repository,
          runtimeTilesetImageLoader: _leaderTilesetLoader,
          runtimeMapBundleLoader: ({required projectFilePath, required mapId}) {
            expect(mapId, _restoredMapId);
            return Future<RuntimeMapBundle>.value(restoredBundle);
          },
        );
        await _load(game);

        expect(game.debugStartScenarioFollow('leader'), isTrue);
        expect(
          game.debugRunScenarioMoveCharacterToWarp(
            entityId: 'leader',
            warpId: 'leader_exit',
          ),
          isTrue,
        );
        await _waitUntil(game, () => game.debugHasPendingLeaderWarpHandoff);
        expect(game.debugHasActiveScenarioFollow, isTrue);

        expect(await game.loadGame(), isTrue);

        expect(game.debugHasPendingLeaderWarpHandoff, isFalse);
        expect(game.debugHasActiveScenarioFollow, isFalse);
        expect(game.gameStateSnapshot.currentMapId, _restoredMapId);
      },
    );

    test(
      'direct MapEvent Scene holds sceneActive through dialogue and hosted '
      'Battle then releases it terminally',
      () async {
        final gate = NarrativeRuntimeActivityGate();
        final repository = _GateMemoryRepository(gate)
          ..storedState = _battleReadyState();
        final game = _game(
          bundle: _sceneBundle(),
          initialState: _battleReadyState(),
          narrativeRuntimeActivityGate: gate,
          saveRepository: repository,
          dialogueSessionLoader: (_) async => _singleLineDialogue(),
        );
        await _load(game);

        expect(_press(game, RuntimeInputControl.primary), isTrue);
        await _waitUntilWithoutUpdate(
          () => game.debugFlowPhaseName == 'dialogue',
        );

        expect(gate.activity, NarrativeRuntimeActivity.sceneActive);
        expect(await game.saveGame(), isFalse);
        expect(await game.loadGame(), isFalse);
        expect(repository.saveCount, 0);
        expect(repository.loadCount, 0);

        expect(_press(game, RuntimeInputControl.primary), isTrue);
        await _waitUntilWithoutUpdate(() => game.debugHasPendingSceneBattle);

        expect(gate.activity, NarrativeRuntimeActivity.sceneActive);
        expect(await game.saveGame(), isFalse);
        expect(await game.loadGame(), isFalse);
        expect(repository.saveCount, 0);
        expect(repository.loadCount, 0);

        game.debugApplyBattleOutcomeForTest(
          context: _trainerContext(),
          outcome: _victoryOutcome(),
        );
        await _waitUntilWithoutUpdate(
          () => gate.activity == NarrativeRuntimeActivity.idle,
        );

        expect(await game.saveGame(), isTrue);
        expect(repository.saveCount, 1);
      },
    );
  });
}

PlayableMapGame _game({
  required RuntimeMapBundle bundle,
  required GameState initialState,
  NarrativeRuntimeActivityGate? narrativeRuntimeActivityGate,
  GameSaveRepository? saveRepository,
  RuntimeDialogueSessionLoader? dialogueSessionLoader,
  RuntimeMapBundleLoader? runtimeMapBundleLoader,
  RuntimeTilesetImageLoader? runtimeTilesetImageLoader,
  Future<void> Function()? beforeBattleHandoffPreparation,
}) {
  return _TestPlayableMapGame(
    bundle: bundle,
    projectFilePath: '/tmp/checkpoint_load_safety/project.json',
    saveData: saveDataFromGameState(initialState),
    narrativeRuntimeActivityGate: narrativeRuntimeActivityGate,
    saveRepository: saveRepository,
    dialogueSessionLoader: dialogueSessionLoader,
    runtimeMapBundleLoader: runtimeMapBundleLoader,
    runtimeTilesetImageLoader: runtimeTilesetImageLoader,
    runtimePlayerPokemonProgressionCatalogLoader:
        _loadCheckpointProgressionCatalogs,
    beforeBattleHandoffPreparation: beforeBattleHandoffPreparation,
  );
}

final class _TestPlayableMapGame extends PlayableMapGame {
  _TestPlayableMapGame({
    required super.bundle,
    required super.projectFilePath,
    super.saveData,
    super.narrativeRuntimeActivityGate,
    super.saveRepository,
    super.dialogueSessionLoader,
    super.runtimeMapBundleLoader,
    super.runtimeTilesetImageLoader,
    super.runtimePlayerPokemonProgressionCatalogLoader,
    super.beforeBattleHandoffPreparation,
  });

  @override
  bool get isLoaded => true;
}

Future<RuntimePlayerPokemonProgressionCatalogs>
    _loadCheckpointProgressionCatalogs({
  required GameState gameState,
  required String projectRootDirectory,
  required ProjectPokemonConfig pokemonConfig,
}) async {
  return const RuntimePlayerPokemonProgressionCatalogs(
    speciesById: <String, PlayerPokemonHydrationSpecies>{
      'aquafi': PlayerPokemonHydrationSpecies(
        id: 'aquafi',
        baseStats: PokemonBaseStats(
          hp: 44,
          attack: 48,
          defense: 65,
          specialAttack: 50,
          specialDefense: 64,
          speed: 43,
        ),
        primaryAbilityId: 'torrent',
        abilityIds: <String>['torrent'],
        growthRateId: 'medium_slow',
      ),
      'sproutle': PlayerPokemonHydrationSpecies(
        id: 'sproutle',
        baseStats: PokemonBaseStats(
          hp: 45,
          attack: 49,
          defense: 49,
          specialAttack: 65,
          specialDefense: 65,
          speed: 45,
        ),
        primaryAbilityId: 'overgrow',
        abilityIds: <String>['overgrow'],
        growthRateId: 'medium_slow',
      ),
    },
    maxPpByMoveId: <String, int>{
      'surf': 15,
      'tackle': 35,
    },
  );
}

Future<void> _load(PlayableMapGame game) async {
  game.onGameResize(Vector2(320, 240));
  await game.onLoad();
  await _waitUntilWithoutUpdate(
    () => !game.debugIsMapActivationDispatchInFlight,
  );
}

bool _press(PlayableMapGame game, RuntimeInputControl control) {
  return game.handleRuntimeInputEvent(RuntimeInputEvent.press(control));
}

Future<void> _waitUntil(
  PlayableMapGame game,
  bool Function() done, {
  int maxTicks = 360,
}) async {
  for (var i = 0; i < maxTicks; i++) {
    if (done()) return;
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }
  fail(
    'Timed out: flow=${game.debugFlowPhaseName} '
    'activation=${game.debugIsMapActivationDispatchInFlight}.',
  );
}

Future<void> _waitUntilWithoutUpdate(
  bool Function() done, {
  int maxTurns = 360,
}) async {
  for (var i = 0; i < maxTurns; i++) {
    if (done()) return;
    await Future<void>.delayed(Duration.zero);
  }
  fail('Timed out waiting for an asynchronous runtime condition.');
}

RuntimeMapBundle _bundle({
  required MapData map,
  List<ScenarioAsset> scenarios = const <ScenarioAsset>[],
  List<ProjectDialogueEntry> dialogues = const <ProjectDialogueEntry>[],
  List<ProjectScriptEntry> scripts = const <ProjectScriptEntry>[],
  List<ProjectTrainerEntry> trainers = const <ProjectTrainerEntry>[],
  List<SceneAsset> scenes = const <SceneAsset>[],
}) {
  return RuntimeMapBundle(
    manifest: ProjectManifest(
      name: 'Checkpoint Load Safety',
      maps: <ProjectMapEntry>[
        ProjectMapEntry(
          id: map.id,
          name: map.name,
          relativePath: 'maps/${map.id}.json',
        ),
      ],
      tilesets: const <ProjectTilesetEntry>[],
      dialogues: dialogues,
      scripts: scripts,
      trainers: trainers,
      scenarios: scenarios,
      scenes: scenes,
    ),
    map: map,
    projectRootDirectory: '/tmp/checkpoint_load_safety',
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

MapData _plainMap(String id) {
  return MapData(
    id: id,
    name: id,
    size: const GridSize(width: 6, height: 6),
    layers: const <MapLayer>[
      MapLayer.object(id: 'objects', name: 'Objects'),
    ],
    entities: <MapEntity>[
      MapEntity(
        id: 'spawn_$id',
        name: 'Spawn',
        kind: MapEntityKind.spawn,
        pos: const GridPos(x: 0, y: 0),
        blocksMovement: false,
        spawn: const MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.east,
        ),
      ),
    ],
    mapMetadata: MapMetadata(defaultSpawnId: 'spawn_$id'),
  );
}

MapData _followMap() {
  return const MapData(
    id: _sourceMapId,
    name: 'Follow source',
    size: GridSize(width: 6, height: 6),
    layers: <MapLayer>[
      MapLayer.object(id: 'objects', name: 'Objects'),
    ],
    entities: <MapEntity>[
      MapEntity(
        id: 'spawn_follow',
        name: 'Spawn',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 0, y: 0),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.east,
        ),
      ),
      MapEntity(
        id: 'leader',
        name: 'Leader',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 4, y: 4),
        npc: MapEntityNpcData(displayName: 'Leader'),
      ),
    ],
    mapMetadata: MapMetadata(defaultSpawnId: 'spawn_follow'),
  );
}

MapData _leaderWarpMap() {
  return const MapData(
    id: _sourceMapId,
    name: 'Leader warp source',
    size: GridSize(width: 6, height: 4),
    layers: <MapLayer>[
      MapLayer.object(id: 'objects', name: 'Objects'),
    ],
    warps: <MapWarp>[
      MapWarp(
        id: 'leader_exit',
        pos: GridPos(x: 4, y: 1),
        targetMapId: _restoredMapId,
        targetPos: GridPos(x: 1, y: 1),
      ),
    ],
    entities: <MapEntity>[
      MapEntity(
        id: 'spawn_leader_warp',
        name: 'Spawn',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 0, y: 1),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.east,
        ),
      ),
      MapEntity(
        id: 'leader',
        name: 'Leader',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 2, y: 1),
        npc: MapEntityNpcData(
          displayName: 'Leader',
          characterId: 'leader_character',
        ),
      ),
    ],
    mapMetadata: MapMetadata(defaultSpawnId: 'spawn_leader_warp'),
  );
}

RuntimeMapBundle _leaderWarpBundle() {
  final map = _leaderWarpMap();
  return RuntimeMapBundle(
    manifest: const ProjectManifest(
      name: 'Leader warp checkpoint fixture',
      maps: <ProjectMapEntry>[
        ProjectMapEntry(
          id: _sourceMapId,
          name: 'Leader warp source',
          relativePath: 'maps/$_sourceMapId.json',
        ),
      ],
      tilesets: <ProjectTilesetEntry>[
        ProjectTilesetEntry(
          id: 'leader_tiles',
          name: 'Leader tiles',
          relativePath: 'tilesets/leader.png',
        ),
      ],
      characters: <ProjectCharacterEntry>[
        ProjectCharacterEntry(
          id: 'leader_character',
          name: 'Leader character',
          tilesetId: 'leader_tiles',
          frameWidth: 8,
          frameHeight: 8,
        ),
      ],
    ),
    map: map,
    projectRootDirectory: '/tmp/checkpoint_load_safety',
    tilesetAbsolutePathsById: const <String, String>{
      'leader_tiles': '/tmp/checkpoint_load_safety/tilesets/leader.png',
    },
  );
}

Future<Map<String, RuntimeTilesetImage>> _leaderTilesetLoader(
  Map<String, String> absolutePathByTilesetId, {
  Map<String, TilesetTransparentColor> transparentColorByTilesetId =
      const <String, TilesetTransparentColor>{},
}) async {
  return <String, RuntimeTilesetImage>{
    for (final id in absolutePathByTilesetId.keys)
      id: await runtimeTilesetImage(
        List<Color>.filled(4, const Color(0xFF4060A0)),
      ),
  };
}

ScenarioAsset _outcomeFlagScenario() {
  return const ScenarioAsset(
    id: 'blocked_checkpoint_scenario',
    name: 'Blocked checkpoint scenario',
    scope: ScenarioScope.globalStory,
    entryNodeId: 'source',
    nodes: <ScenarioNode>[
      ScenarioNode(
        id: 'source',
        type: ScenarioNodeType.reference,
        payload: ScenarioNodePayload(actionKind: kScenarioSourceOutcome),
        binding: ScenarioNodeBinding(outcomeId: 'checkpoint.seed'),
      ),
      ScenarioNode(
        id: 'set_flag',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
        binding: ScenarioNodeBinding(flagName: _legacyBlockedFlag),
      ),
      ScenarioNode(id: 'end', type: ScenarioNodeType.end),
    ],
    edges: <ScenarioEdge>[
      ScenarioEdge(
        id: 'source_to_flag',
        fromNodeId: 'source',
        toNodeId: 'set_flag',
      ),
      ScenarioEdge(
        id: 'flag_to_end',
        fromNodeId: 'set_flag',
        toNodeId: 'end',
      ),
    ],
  );
}

ScenarioAsset _mapEnterFollowScenario() {
  return const ScenarioAsset(
    id: _followScenarioId,
    name: 'Follow before load',
    scope: ScenarioScope.localEventFlow,
    entryNodeId: 'source',
    nodes: <ScenarioNode>[
      ScenarioNode(
        id: 'source',
        type: ScenarioNodeType.reference,
        payload: ScenarioNodePayload(actionKind: kScenarioSourceMapEnter),
        binding: ScenarioNodeBinding(mapId: _sourceMapId),
      ),
      ScenarioNode(
        id: 'follow',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(
          actionKind: kScenarioActionFollowCharacter,
          params: <String, String>{'leaderId': 'leader'},
        ),
      ),
      ScenarioNode(id: 'end', type: ScenarioNodeType.end),
    ],
    edges: <ScenarioEdge>[
      ScenarioEdge(
        id: 'source_to_follow',
        fromNodeId: 'source',
        toNodeId: 'follow',
      ),
      ScenarioEdge(
        id: 'follow_to_end',
        fromNodeId: 'follow',
        toNodeId: 'end',
      ),
    ],
  );
}

RuntimeMapBundle _sceneBundle() {
  return _bundle(
    map: _sceneMap(),
    dialogues: const <ProjectDialogueEntry>[
      ProjectDialogueEntry(
        id: 'scene_dialogue',
        name: 'Scene dialogue',
        relativePath: 'dialogues/scene_dialogue.yarn',
      ),
    ],
    trainers: const <ProjectTrainerEntry>[
      ProjectTrainerEntry(
        id: _trainerId,
        name: 'Checkpoint Trainer',
        trainerClass: 'Tester',
        team: <ProjectTrainerPokemonEntry>[
          ProjectTrainerPokemonEntry(speciesId: 'embercub', level: 5),
        ],
      ),
    ],
    scenes: <SceneAsset>[_dialogueBattleScene()],
  );
}

MapData _sceneMap() {
  return const MapData(
    id: _sourceMapId,
    name: 'Scene map',
    size: GridSize(width: 4, height: 4),
    layers: <MapLayer>[
      MapLayer.object(id: 'objects', name: 'Objects'),
    ],
    entities: <MapEntity>[
      MapEntity(
        id: 'spawn_scene',
        name: 'Spawn',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 0, y: 0),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.east,
        ),
      ),
      MapEntity(
        id: 'trainer_npc',
        name: 'Trainer NPC',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 2, y: 2),
        npc: MapEntityNpcData(
          displayName: 'Trainer NPC',
          trainerId: _trainerId,
        ),
      ),
    ],
    events: <MapEventDefinition>[
      MapEventDefinition(
        id: 'scene_event',
        title: 'Scene event',
        position: EventPosition(layerId: 'objects', x: 1, y: 0),
        pages: <MapEventPage>[
          MapEventPage(
            pageNumber: 0,
            sceneTarget: MapEventSceneTarget(sceneId: 'dialogue_battle_scene'),
          ),
        ],
      ),
    ],
    mapMetadata: MapMetadata(defaultSpawnId: 'spawn_scene'),
  );
}

SceneAsset _dialogueBattleScene() {
  return SceneAsset(
    id: 'dialogue_battle_scene',
    name: 'Dialogue and hosted battle',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: <SceneNode>[
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'dialogue',
          kind: SceneNodeKind.yarnDialogue,
          payload: SceneYarnDialoguePayload(dialogueId: 'scene_dialogue'),
        ),
        SceneNode(
          id: 'battle',
          kind: SceneNodeKind.battle,
          payload: SceneBattlePayload(
            battleKind: 'trainer',
            trainerId: _trainerId,
            npcEntityId: 'trainer_npc',
            declaredOutcomes: const <String>['victory', 'defeat'],
          ),
        ),
        SceneNode(id: 'victory_end', kind: SceneNodeKind.end),
        SceneNode(id: 'defeat_end', kind: SceneNodeKind.end),
      ],
      edges: <SceneEdge>[
        SceneEdge(
          id: 'start_to_dialogue',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'dialogue',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'dialogue_to_battle',
          fromNodeId: 'dialogue',
          fromPortId: 'completed',
          toNodeId: 'battle',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'battle_victory',
          fromNodeId: 'battle',
          fromPortId: 'victory',
          toNodeId: 'victory_end',
          kind: SceneEdgeKind.battleVictory,
        ),
        SceneEdge(
          id: 'battle_defeat',
          fromNodeId: 'battle',
          fromPortId: 'defeat',
          toNodeId: 'defeat_end',
          kind: SceneEdgeKind.battleDefeat,
        ),
      ],
    ),
  );
}

GameState _state({
  required String mapId,
  GridPos position = const GridPos(x: 0, y: 0),
}) {
  return GameState(
    saveId: 'checkpoint-load-safety',
    currentMapId: mapId,
    playerPosition: position,
    playerFacing: EntityFacing.east,
  );
}

GameState _battleReadyState() {
  return const GameState(
    saveId: 'checkpoint-scene',
    currentMapId: _sourceMapId,
    playerPosition: GridPos(x: 0, y: 0),
    playerFacing: EntityFacing.east,
    party: PlayerParty(
      members: <PlayerPokemon>[
        PlayerPokemon(
          speciesId: 'sproutle',
          natureId: 'hardy',
          abilityId: 'overgrow',
          level: 5,
          knownMoveIds: <String>['tackle'],
          currentHp: 20,
        ),
      ],
    ),
  );
}

DialogueSession _singleLineDialogue() {
  return DialogueSession.start(
    <YarnNode>[
      YarnNode(
        title: 'Start',
        steps: <YarnStep>[YarnStepLine('Checkpoint dialogue')],
      ),
    ],
    'Start',
  )!;
}

RuntimeCutsceneAsset _waitThenFlagCutscene(String id) {
  return RuntimeCutsceneAsset(
    id: id,
    name: 'Wait then flag',
    steps: const <RuntimeCutsceneStep>[
      CutsceneWaitStep(durationMs: 10000),
      CutsceneSetFlagStep(flagName: _staleCutsceneFlag),
    ],
  );
}

RuntimeActiveBattleContext _trainerContext() {
  return const RuntimeActiveBattleContext(
    request: TrainerBattleStartRequest(
      requestId: 'checkpoint-scene-battle',
      createdAtEpochMs: 1,
      returnContext: OverworldReturnContext(
        mapId: _sourceMapId,
        playerPos: GridPos(x: 0, y: 0),
        playerFacing: Direction.east,
      ),
      trainerId: _trainerId,
      npcEntityId: 'trainer_npc',
      mapId: _sourceMapId,
      playerPos: GridPos(x: 0, y: 0),
    ),
    playerPartyIndex: 0,
  );
}

BattleOutcome _victoryOutcome() {
  return BattleOutcome(
    type: BattleOutcomeType.victory,
    finalState: BattleState(
      phase: BattlePhase.finished,
      player: const BattleCombatant(
        speciesId: 'sproutle',
        level: 5,
        currentHp: 12,
        maxHp: 20,
        stats: _battleStats,
        moves: <BattleMove>[
          BattleMove(id: 'tackle', name: 'Tackle', power: 10),
        ],
      ),
      enemy: const BattleCombatant(
        speciesId: 'embercub',
        level: 5,
        currentHp: 0,
        maxHp: 18,
        stats: _battleStats,
        moves: <BattleMove>[
          BattleMove(id: 'scratch', name: 'Scratch', power: 10),
        ],
      ),
      currentTurn: null,
      outcome: null,
    ),
  );
}

final class _GateMemoryRepository implements GameSaveRepository {
  _GateMemoryRepository(this.gate);

  final NarrativeRuntimeActivityGate gate;
  GameState? storedState;
  int saveCount = 0;
  int loadCount = 0;

  @override
  Future<void> save(GameState state) {
    return gate.runCheckpoint(
      NarrativeRuntimeCheckpointOperation.save,
      () async {
        saveCount++;
        storedState = state;
      },
    );
  }

  @override
  Future<GameState?> load() {
    return gate.runCheckpoint(
      NarrativeRuntimeCheckpointOperation.load,
      () async {
        loadCount++;
        return storedState;
      },
    );
  }

  @override
  Future<bool> exists() async => storedState != null;

  @override
  Future<void> delete() async {
    storedState = null;
  }
}
