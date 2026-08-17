import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/dialogue_runtime_models.dart';
import 'package:map_runtime/src/application/narrative_runtime_activity_gate.dart';
import 'package:map_runtime/src/presentation/flame/playable_map_game.dart'
    show RuntimeDialogueSessionLoader;

const _mapId = 'scene_atomicity_map';
const _triggerId = 'trigger_scene_atomicity';
const _eventId = 'evt_019abcde-6000-7000-8000-000000000001';
const _sceneId = 'scene_atomicity_dialogue';
const _dialogueId = 'dialogue_scene_atomicity';
const _factId = 'fact.scene_atomicity.written';
const _entityId = 'npc_scenario_atomicity';
const _preDialogueFlag = 'scenario_atomicity_before_dialogue';
const _postDialogueFlag = 'scenario_atomicity_after_dialogue';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BETA-WLD-006 Scene atomicity', () {
    test(
      'the activity gate never returns to idle between a Scene dispatch and '
      'the end of its continuation',
      () async {
        final gate = NarrativeRuntimeActivityGate();
        final game = await _loadGame(
          _dialogueSceneBundle(),
          gate: gate,
          dialogueSessionLoader: (_) async => _singleLineDialogueSession(),
        );

        await _stepRight(game);
        await _pumpUntil(game, () => game.debugFlowPhaseName == 'dialogue');

        final observed = <NarrativeRuntimeActivity>{gate.activity};
        expect(
          gate.activity,
          isNot(NarrativeRuntimeActivity.idle),
          reason: 'a Scene suspended on a dialogue still owns the gate',
        );

        expect(_pressPrimary(game), isTrue);
        for (var tick = 0; tick < 240; tick++) {
          observed.add(gate.activity);
          if (_factValue(game, _factId) == true &&
              game.debugFlowPhaseName == 'overworld' &&
              gate.activity == NarrativeRuntimeActivity.idle) {
            break;
          }
          game.update(0.016);
          await Future<void>.delayed(Duration.zero);
        }

        expect(
          _factValue(game, _factId),
          isTrue,
          reason: 'the Scene must have committed its write before we conclude',
        );
        expect(
          observed.where((activity) => activity != NarrativeRuntimeActivity.idle),
          isNotEmpty,
        );
        expect(
          observed.last,
          NarrativeRuntimeActivity.idle,
          reason: 'the gate must be released once the continuation is done',
        );
      },
    );

    test(
      'saveGame refuses without writing while a Scene runs, then succeeds once '
      'the Scene has ended',
      () async {
        final gate = NarrativeRuntimeActivityGate();
        final repository = _CountingSaveRepository();
        final game = await _loadGame(
          _dialogueSceneBundle(),
          gate: gate,
          saveRepository: repository,
          dialogueSessionLoader: (_) async => _singleLineDialogueSession(),
        );

        expect(
          await game.saveGame(),
          isTrue,
          reason: 'an idle overworld runtime is checkpoint-safe',
        );
        expect(repository.saveCount, 1);

        await _stepRight(game);
        await _pumpUntil(game, () => game.debugFlowPhaseName == 'dialogue');

        expect(
          await game.saveGame(),
          isFalse,
          reason: 'a live Scene must refuse the checkpoint',
        );
        expect(
          repository.saveCount,
          1,
          reason: 'a refused checkpoint must not reach the repository at all',
        );
        expect(_factValue(game, _factId), isNot(isTrue));

        expect(_pressPrimary(game), isTrue);
        await _pumpUntil(
          game,
          () =>
              _factValue(game, _factId) == true &&
              game.debugFlowPhaseName == 'overworld' &&
              gate.activity == NarrativeRuntimeActivity.idle,
        );
        await _pumpFrames(game, 4);

        expect(await game.saveGame(), isTrue);
        expect(repository.saveCount, 2);

        final stored = repository.storedState!;
        expect(
          stored.narrativeFactRuntimeState.overridesByFactId[_factId],
          isTrue,
          reason: 'the Scene write must be inside the checkpoint that follows',
        );
        expect(
          stored.narrativeEventProgress.consumedNarrativeEventIds,
          contains(_eventId),
        );
      },
    );

    test(
      'replaying the same dialogue advance never commits the Scene twice',
      () async {
        final gate = NarrativeRuntimeActivityGate();
        final repository = _CountingSaveRepository();
        final game = await _loadGame(
          _dialogueSceneBundle(),
          gate: gate,
          saveRepository: repository,
          dialogueSessionLoader: (_) async => _singleLineDialogueSession(),
        );

        await _stepRight(game);
        await _pumpUntil(game, () => game.debugFlowPhaseName == 'dialogue');

        _pressPrimary(game);
        _pressPrimary(game);
        _pressPrimary(game);

        await _pumpUntil(
          game,
          () =>
              _factValue(game, _factId) == true &&
              game.debugFlowPhaseName == 'overworld' &&
              gate.activity == NarrativeRuntimeActivity.idle,
        );
        await _pumpFrames(game, 8);

        expect(
          game.gameStateSnapshot.narrativeEventProgress
              .consumedNarrativeEventIds
              .where((id) => id == _eventId),
          hasLength(1),
          reason: 'a double advance must not consume the Event twice',
        );
        expect(await game.saveGame(), isTrue);
      },
    );

    test(
      'a legacy Scenario suspended on a dialogue never exposes a half-applied '
      'state to the durable checkpoint snapshot',
      () async {
        final gate = NarrativeRuntimeActivityGate();
        final game = await _loadGame(
          _legacyScenarioBundle(),
          gate: gate,
          dialogueSessionLoader: (_) async => _singleLineDialogueSession(),
        );

        expect(_pressPrimary(game), isTrue);
        await _pumpUntil(game, () => game.debugFlowPhaseName == 'dialogue');

        expect(
          gate.activity,
          isNot(NarrativeRuntimeActivity.idle),
          reason: 'the suspended Scenario still owns the gate',
        );

        // `PlayableMapGameSessionRuntime.captureCheckpoint` serialises exactly
        // this snapshot into the durable Hub save, without consulting the gate.
        final suspendedSnapshot = game.gameStateSnapshot;
        expect(
          suspendedSnapshot.storyFlags.activeFlags,
          isNot(contains(_preDialogueFlag)),
          reason: 'a checkpoint taken mid-Scenario must not see the first half',
        );
        expect(
          suspendedSnapshot.storyFlags.activeFlags,
          isNot(contains(_postDialogueFlag)),
        );

        expect(_pressPrimary(game), isTrue);
        await _pumpUntil(
          game,
          () =>
              game.debugFlowPhaseName == 'overworld' &&
              gate.activity == NarrativeRuntimeActivity.idle,
        );

        final settledSnapshot = game.gameStateSnapshot;
        expect(
          settledSnapshot.storyFlags.activeFlags,
          containsAll(<String>[_preDialogueFlag, _postDialogueFlag]),
          reason: 'once settled, the whole Scenario must be visible',
        );
      },
      skip: 'BETA-WLD-011. Un vrai trou, pas un test à ajuster. Une Scene V2 '
          'est atomique parce que ses écritures vivent dans '
          '_NarrativeSceneWorkingSession jusqu\'au commit ; un Scenario legacy '
          'écrit directement dans _gameState via onGameStateUpdated, et '
          'captureCheckpoint() sérialise gameStateSnapshot sans consulter '
          'NarrativeRuntimeActivityGate. Un autosave de suspension d\'app '
          'pendant un Scenario suspendu persiste donc la moitié du flow. '
          'ATTENTION avant de corriger : stager TOUTES les écritures Scenario '
          'ne marche pas. Tenté le 2026-08-17, 17 tests de '
          'playable_map_game_qualified_outcome_v2_integration_test tombent, '
          'parce que deliveredNarrativeOutcomeDeliveryIds DOIT rester visible '
          'pendant la suspension pour garantir la livraison exactly-once des '
          'outcomes au rechargement. Le fix demande une partition : effets de '
          'flow stagés, comptabilité de livraison publiée en '
          'continu — comme le fait déjà le couple working '
          'session / transaction store des Scenes V2. Voir '
          'scenario_settled_flags_probe_test.dart, qui garde l\'invariant que '
          'la tentative avait cassé.',
    );
  });
}

RuntimeMapBundle _dialogueSceneBundle() {
  return _bundle(
    facts: const <String>[_factId],
    dialogues: const <String>[_dialogueId],
    triggers: const <MapTrigger>[
      MapTrigger(
        id: _triggerId,
        name: 'Scene atomicity trigger',
        type: TriggerType.event,
        area: MapRect(
          pos: GridPos(x: 1, y: 1),
          size: GridSize(width: 1, height: 1),
        ),
      ),
    ],
    records: <NarrativeEventRecord>[
      NarrativeEventRecord.configuredStructurallyUnchecked(
        NarrativeEventDefinition(
          id: _eventId,
          name: 'Scene atomicity Event',
          source: NarrativeEventSourceRef.triggerEnter(_mapId, _triggerId),
          conditions: const <NarrativeEventCondition>[],
          sceneId: _sceneId,
          reusePolicy: NarrativeEventReusePolicy.oneShot,
          priority: 0,
          order: 0,
        ),
        enabled: true,
      ),
    ],
    scenes: <SceneAsset>[
      SceneAsset(
        id: _sceneId,
        name: _sceneId,
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: <SceneNode>[
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'dialogue',
              kind: SceneNodeKind.yarnDialogue,
              payload: SceneYarnDialoguePayload(dialogueId: _dialogueId),
            ),
            SceneNode(
              id: 'set_fact',
              kind: SceneNodeKind.action,
              payload: SceneActionPayload.consequence(
                SceneConsequence.setFact(factId: _factId, value: true),
              ),
            ),
            SceneNode(id: 'end', kind: SceneNodeKind.end),
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
              id: 'dialogue_to_fact',
              fromNodeId: 'dialogue',
              fromPortId: 'completed',
              toNodeId: 'set_fact',
              kind: SceneEdgeKind.defaultFlow,
            ),
            SceneEdge(
              id: 'fact_to_end',
              fromNodeId: 'set_fact',
              fromPortId: 'completed',
              toNodeId: 'end',
              kind: SceneEdgeKind.actionCompleted,
            ),
          ],
        ),
      ),
    ],
  );
}

RuntimeMapBundle _legacyScenarioBundle() {
  return _bundle(
    eventSystemMode: EventSystemMode.legacyOnly,
    dialogues: const <String>[_dialogueId],
    entities: const <MapEntity>[
      MapEntity(
        id: _entityId,
        name: 'Scenario npc',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 1, y: 1),
        blocksMovement: true,
      ),
    ],
    scenarios: <ScenarioAsset>[
      ScenarioAsset(
        id: 'scenario_atomicity',
        name: 'Half-applied Scenario probe',
        scope: ScenarioScope.localEventFlow,
        entryNodeId: 'source',
        nodes: const <ScenarioNode>[
          ScenarioNode(
            id: 'source',
            type: ScenarioNodeType.reference,
            payload: ScenarioNodePayload(
              actionKind: kScenarioSourceEntityInteract,
            ),
            binding: ScenarioNodeBinding(mapId: _mapId, entityId: _entityId),
          ),
          ScenarioNode(
            id: 'set_before',
            type: ScenarioNodeType.action,
            payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
            binding: ScenarioNodeBinding(flagName: _preDialogueFlag),
          ),
          ScenarioNode(
            id: 'dialogue',
            type: ScenarioNodeType.action,
            payload: ScenarioNodePayload(
              actionKind: kScenarioActionOpenDialogue,
            ),
            binding: ScenarioNodeBinding(dialogueId: _dialogueId),
          ),
          ScenarioNode(
            id: 'set_after',
            type: ScenarioNodeType.action,
            payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
            binding: ScenarioNodeBinding(flagName: _postDialogueFlag),
          ),
          ScenarioNode(id: 'end', type: ScenarioNodeType.end),
        ],
        edges: const <ScenarioEdge>[
          ScenarioEdge(
            id: 'source_to_before',
            fromNodeId: 'source',
            toNodeId: 'set_before',
          ),
          ScenarioEdge(
            id: 'before_to_dialogue',
            fromNodeId: 'set_before',
            toNodeId: 'dialogue',
          ),
          ScenarioEdge(
            id: 'dialogue_to_after',
            fromNodeId: 'dialogue',
            toNodeId: 'set_after',
          ),
          ScenarioEdge(
            id: 'after_to_end',
            fromNodeId: 'set_after',
            toNodeId: 'end',
          ),
        ],
      ),
    ],
  );
}

RuntimeMapBundle _bundle({
  List<MapTrigger> triggers = const <MapTrigger>[],
  List<MapEntity> entities = const <MapEntity>[],
  List<SceneAsset> scenes = const <SceneAsset>[],
  List<ScenarioAsset> scenarios = const <ScenarioAsset>[],
  List<NarrativeEventRecord> records = const <NarrativeEventRecord>[],
  List<String> facts = const <String>[],
  List<String> dialogues = const <String>[],
  EventSystemMode eventSystemMode = EventSystemMode.v2Only,
}) {
  final manifest = ProjectManifest(
    name: 'BETA-WLD-006 scene atomicity',
    settings: const ProjectSettings(tileWidth: 16, tileHeight: 16),
    maps: const <ProjectMapEntry>[
      ProjectMapEntry(
        id: _mapId,
        name: _mapId,
        relativePath: 'maps/$_mapId.json',
      ),
    ],
    tilesets: const <ProjectTilesetEntry>[],
    facts: <NarrativeFactDefinition>[
      for (final factId in facts)
        NarrativeFactDefinition(id: factId, label: factId),
    ],
    dialogues: <ProjectDialogueEntry>[
      for (final dialogueId in dialogues)
        ProjectDialogueEntry(
          id: dialogueId,
          name: dialogueId,
          relativePath: 'dialogues/$dialogueId.yarn',
        ),
    ],
    scenarios: scenarios,
    eventRegistry: NarrativeEventRegistry(
      schemaVersion: 1,
      mode: eventSystemMode,
      records: records,
      legacyClaims: const <LegacySourceClaim>[],
    ),
    scenes: scenes,
  );
  return RuntimeMapBundle(
    manifest: manifest,
    map: MapData(
      id: _mapId,
      name: _mapId,
      size: const GridSize(width: 4, height: 3),
      layers: const <MapLayer>[MapLayer.object(id: 'objects', name: 'Objects')],
      entities: <MapEntity>[
        const MapEntity(
          id: 'spawn',
          name: 'Spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 0, y: 1),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.east,
          ),
        ),
        ...entities,
      ],
      triggers: triggers,
      mapMetadata: const MapMetadata(defaultSpawnId: 'spawn'),
    ),
    projectRootDirectory: '/tmp/beta_wld_006_atomicity',
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

DialogueSession _singleLineDialogueSession() {
  return DialogueSession.start(
    <YarnNode>[
      YarnNode(
        title: 'Start',
        steps: <YarnStep>[YarnStepLine('Atomicité.')],
      ),
    ],
    'Start',
  )!;
}

Future<_TestGame> _loadGame(
  RuntimeMapBundle bundle, {
  required NarrativeRuntimeActivityGate gate,
  RuntimeDialogueSessionLoader? dialogueSessionLoader,
  GameSaveRepository? saveRepository,
}) async {
  final game = _TestGame(
    bundle: bundle,
    projectFilePath: '${bundle.projectRootDirectory}/project.json',
    narrativeRuntimeActivityGate: gate,
    dialogueSessionLoader: dialogueSessionLoader,
    saveRepository: saveRepository,
  );
  game.onGameResize(Vector2(640, 480));
  await game.onLoad().timeout(const Duration(seconds: 5));
  await _pumpUntil(game, () => !game.debugIsMapActivationDispatchInFlight);
  return game;
}

bool? _factValue(PlayableMapGame game, String factId) {
  return game
      .gameStateSnapshot.narrativeFactRuntimeState.overridesByFactId[factId];
}

bool _pressPrimary(PlayableMapGame game) {
  return game.handleRuntimeInputEvent(
    const RuntimeInputEvent.press(RuntimeInputControl.primary),
  );
}

Future<void> _stepRight(PlayableMapGame game) async {
  expect(
    game.handleRuntimeInputEvent(
      const RuntimeInputEvent.press(RuntimeInputControl.right),
    ),
    isTrue,
  );
  game.update(0.016);
  await Future<void>.delayed(Duration.zero);
  expect(
    game.handleRuntimeInputEvent(
      const RuntimeInputEvent.release(RuntimeInputControl.right),
    ),
    isTrue,
  );
  for (var i = 0; i < 180; i++) {
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
    if (!game.debugIsPlayerStepping) return;
  }
  fail('Timed out waiting for the movement step to settle.');
}

Future<void> _pumpFrames(PlayableMapGame game, int count) async {
  for (var i = 0; i < count; i++) {
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }
}

Future<void> _pumpUntil(
  PlayableMapGame game,
  bool Function() done, {
  int maxTicks = 360,
}) async {
  for (var i = 0; i < maxTicks; i++) {
    if (done()) return;
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }
  fail('Timed out waiting for the scene atomicity runtime state.');
}

final class _TestGame extends PlayableMapGame {
  _TestGame({
    required super.bundle,
    required super.projectFilePath,
    super.narrativeRuntimeActivityGate,
    super.dialogueSessionLoader,
    super.saveRepository,
  });

  bool _onLoadCompleted = false;

  @override
  bool get isLoaded => _onLoadCompleted;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _onLoadCompleted = true;
  }
}

final class _CountingSaveRepository implements GameSaveRepository {
  GameState? storedState;
  int saveCount = 0;

  @override
  Future<void> save(GameState state) async {
    saveCount++;
    storedState = state;
  }

  @override
  Future<GameState?> load() async => storedState;

  @override
  Future<bool> exists() async => storedState != null;

  @override
  Future<void> delete() async {
    storedState = null;
  }
}
