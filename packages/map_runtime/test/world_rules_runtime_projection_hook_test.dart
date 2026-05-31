import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

const _saveId = 'save_world_rules_runtime_projection';
const _mapId = 'map_runtime_world_rules';
const _otherMapId = 'map_other_world_rules';
const _npcId = 'npc_gate_keeper';
const _eventId = 'event_gate';
const _factId = 'fact_gate_closed';
const _sceneId = 'scene_close_gate';
const _sceneEventId = 'event_scene_closes_gate';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RuntimeWorldRuleProjectionHook', () {
    test('reads Fact-backed entityHidden without mutating inputs', () {
      final fixture = _fixture(
        worldRules: [
          _entityRule(
            id: 'world_rule_hide_npc',
            effect: const WorldRuleEffect(
              kind: WorldRuleEffectKind.entityHidden,
            ),
          ),
        ],
      );
      const state = GameState(
        saveId: _saveId,
        storyFlags: StoryFlags(activeFlags: {_factId}),
      );
      final projectBefore = fixture.project.toJson();
      final mapBefore = fixture.map.toJson();
      final stateBefore = state.toJson();

      final projection = const RuntimeWorldRuleProjectionHook().resolve(
        project: fixture.project,
        gameState: state,
        map: fixture.map,
      );

      expect(projection.hiddenEntityIds, contains(_npcId));
      expect(
        projection.isMapEntityVisible(fixture.npcEntity),
        isFalse,
      );
      expect(fixture.project.toJson(), projectBefore);
      expect(fixture.map.toJson(), mapBefore);
      expect(state.toJson(), stateBefore);
    });

    test('supports entityVisible as an explicit runtime visibility override',
        () {
      final fixture = _fixture(
        worldRules: [
          _entityRule(
            id: 'world_rule_show_npc',
            effect: const WorldRuleEffect(
              kind: WorldRuleEffectKind.entityVisible,
            ),
          ),
        ],
      );

      final projection = const RuntimeWorldRuleProjectionHook().resolve(
        project: fixture.project,
        gameState: const GameState(
          saveId: _saveId,
          storyFlags: StoryFlags(activeFlags: {_factId}),
        ),
        map: fixture.map,
      );

      expect(projection.visibleEntityIds, contains(_npcId));
      expect(
        projection.isMapEntityVisible(
          fixture.npcEntity,
          defaultVisible: false,
        ),
        isTrue,
      );
    });

    test('disables map events from Fact-backed eventDisabled rules', () {
      final fixture = _fixture(
        worldRules: [
          _eventRule(
            id: 'world_rule_disable_event',
            effect: const WorldRuleEffect(
              kind: WorldRuleEffectKind.eventDisabled,
            ),
          ),
        ],
      );

      final projection = const RuntimeWorldRuleProjectionHook().resolve(
        project: fixture.project,
        gameState: const GameState(
          saveId: _saveId,
          storyFlags: StoryFlags(activeFlags: {_factId}),
        ),
        map: fixture.map,
      );

      expect(projection.disabledEventIds, contains(_eventId));
      expect(projection.canTriggerMapEvent(fixture.gateEvent), isFalse);
      expect(projection.isMapEventHidden(fixture.gateEvent), isFalse);
    });

    test('supports eventEnabled as an explicit runtime activation override',
        () {
      final fixture = _fixture(
        worldRules: [
          _eventRule(
            id: 'world_rule_enable_event',
            effect: const WorldRuleEffect(
              kind: WorldRuleEffectKind.eventEnabled,
            ),
          ),
        ],
      );

      final projection = const RuntimeWorldRuleProjectionHook().resolve(
        project: fixture.project,
        gameState: const GameState(
          saveId: _saveId,
          storyFlags: StoryFlags(activeFlags: {_factId}),
        ),
        map: fixture.map,
      );

      expect(projection.enabledEventIds, contains(_eventId));
      expect(
        projection.canTriggerMapEvent(
          fixture.gateEvent,
          defaultEnabled: false,
        ),
        isTrue,
      );
    });

    test('hides map events from consumed-event-backed eventHidden rules', () {
      final fixture = _fixture(
        worldRules: [
          _eventRule(
            id: 'world_rule_hide_consumed_event',
            source: const WorldRuleSource(
              kind: WorldRuleSourceKind.consumedEvent,
              sourceId: _sceneEventId,
              predicate: WorldRuleSourcePredicate.consumed,
            ),
            effect: const WorldRuleEffect(
              kind: WorldRuleEffectKind.eventHidden,
            ),
          ),
        ],
      );

      final projection = const RuntimeWorldRuleProjectionHook().resolve(
        project: fixture.project,
        gameState: const GameState(
          saveId: _saveId,
          consumedEventIds: {_sceneEventId},
        ),
        map: fixture.map,
      );

      expect(projection.hiddenEventIds, contains(_eventId));
      expect(projection.isMapEventHidden(fixture.gateEvent), isTrue);
      expect(projection.canTriggerMapEvent(fixture.gateEvent), isFalse);
    });

    test('projects npc dialogue overrides as a runtime read model', () {
      final fixture = _fixture(
        dialogues: const [
          ProjectDialogueEntry(
            id: 'dialogue_gate_after',
            name: 'Gate after',
            relativePath: 'dialogues/gate_after.yarn',
          ),
        ],
        worldRules: [
          _npcDialogueRule(
            id: 'world_rule_dialogue_override',
            effect: const WorldRuleEffect(
              kind: WorldRuleEffectKind.npcDialogueOverride,
              dialogueId: 'dialogue_gate_after',
            ),
          ),
        ],
      );

      final projection = const RuntimeWorldRuleProjectionHook().resolve(
        project: fixture.project,
        gameState: const GameState(
          saveId: _saveId,
          storyFlags: StoryFlags(activeFlags: {_factId}),
        ),
        map: fixture.map,
      );

      expect(
        projection.npcDialogueOverrides,
        containsPair(_npcId, 'dialogue_gate_after'),
      );
      expect(
        projection.dialogueOverrideForEntity(_npcId),
        'dialogue_gate_after',
      );
    });

    test('ignores rules targeting other maps', () {
      final fixture = _fixture(
        worldRules: [
          _eventRule(
            id: 'world_rule_other_map_event',
            mapId: _otherMapId,
            effect: const WorldRuleEffect(
              kind: WorldRuleEffectKind.eventDisabled,
            ),
          ),
        ],
      );

      final projection = const RuntimeWorldRuleProjectionHook().resolve(
        project: fixture.project,
        gameState: const GameState(
          saveId: _saveId,
          storyFlags: StoryFlags(activeFlags: {_factId}),
        ),
        map: fixture.map,
      );

      expect(projection.isEmpty, isTrue);
      expect(projection.canTriggerMapEvent(fixture.gateEvent), isTrue);
    });

    test('respects disabled World Rules', () {
      final fixture = _fixture(
        worldRules: [
          _eventRule(
            id: 'world_rule_disabled',
            enabled: false,
            effect: const WorldRuleEffect(
              kind: WorldRuleEffectKind.eventDisabled,
            ),
          ),
        ],
      );

      final projection = const RuntimeWorldRuleProjectionHook().resolve(
        project: fixture.project,
        gameState: const GameState(
          saveId: _saveId,
          storyFlags: StoryFlags(activeFlags: {_factId}),
        ),
        map: fixture.map,
      );

      expect(projection.isEmpty, isTrue);
    });

    test('handles empty World Rules', () {
      final fixture = _fixture();

      final projection = const RuntimeWorldRuleProjectionHook().resolve(
        project: fixture.project,
        gameState: const GameState(saveId: _saveId),
        map: fixture.map,
      );

      expect(projection.isEmpty, isTrue);
      expect(projection.canTriggerMapEvent(fixture.gateEvent), isTrue);
      expect(projection.isMapEntityVisible(fixture.npcEntity), isTrue);
    });

    test(
        'Scene-written Fact disables a map event through World Rule projection',
        () async {
      final fixture = _fixture(
        scenes: [_setFactScene()],
        worldRules: [
          _eventRule(
            id: 'world_rule_disable_after_scene_fact',
            effect: const WorldRuleEffect(
              kind: WorldRuleEffectKind.eventDisabled,
            ),
          ),
        ],
      );

      final hookResult = await _runScene(fixture);
      final projection = const RuntimeWorldRuleProjectionHook().resolve(
        project: fixture.project,
        gameState: hookResult.updatedGameState!,
        map: fixture.map,
      );

      expect(hookResult.status, SceneEventRuntimeHookStatus.completed);
      expect(
        hookResult.updatedGameState!.storyFlags.activeFlags,
        contains(_factId),
      );
      expect(projection.canTriggerMapEvent(fixture.gateEvent), isFalse);
    });

    test('Scene-written Fact hides a map entity through World Rule projection',
        () async {
      final fixture = _fixture(
        scenes: [_setFactScene()],
        worldRules: [
          _entityRule(
            id: 'world_rule_hide_after_scene_fact',
            effect: const WorldRuleEffect(
              kind: WorldRuleEffectKind.entityHidden,
            ),
          ),
        ],
      );

      final hookResult = await _runScene(fixture);
      final projection = const RuntimeWorldRuleProjectionHook().resolve(
        project: fixture.project,
        gameState: hookResult.updatedGameState!,
        map: fixture.map,
      );

      expect(hookResult.status, SceneEventRuntimeHookStatus.completed);
      expect(
        projection.isMapEntityVisible(fixture.npcEntity),
        isFalse,
      );
    });

    test(
        'Scene consequence updates GameState then World Rule projection changes runtime state',
        () async {
      final fixture = _fixture(
        scenes: [_setFactScene()],
        worldRules: [
          _eventRule(
            id: 'world_rule_disable_after_game_state_update',
            effect: const WorldRuleEffect(
              kind: WorldRuleEffectKind.eventDisabled,
            ),
          ),
        ],
      );
      const originalState = GameState(saveId: _saveId);

      final beforeProjection = const RuntimeWorldRuleProjectionHook().resolve(
        project: fixture.project,
        gameState: originalState,
        map: fixture.map,
      );
      final hookResult = await _runScene(fixture, gameState: originalState);
      final afterProjection = const RuntimeWorldRuleProjectionHook().resolve(
        project: fixture.project,
        gameState: hookResult.updatedGameState!,
        map: fixture.map,
      );

      expect(beforeProjection.canTriggerMapEvent(fixture.gateEvent), isTrue);
      expect(afterProjection.canTriggerMapEvent(fixture.gateEvent), isFalse);
      expect(originalState.storyFlags.activeFlags, isEmpty);
    });

    test('Reloaded Scene-written Fact applies World Rule runtime projection',
        () async {
      final fixture = _fixture(
        scenes: [_setFactScene()],
        worldRules: [
          _eventRule(
            id: 'world_rule_disable_after_reloaded_fact',
            effect: const WorldRuleEffect(
              kind: WorldRuleEffectKind.eventDisabled,
            ),
          ),
        ],
      );
      final hookResult = await _runScene(fixture);
      final reloaded = await _saveAndReload(hookResult.updatedGameState!);

      final projection = const RuntimeWorldRuleProjectionHook().resolve(
        project: fixture.project,
        gameState: reloaded,
        map: fixture.map,
      );

      expect(reloaded.storyFlags.activeFlags, contains(_factId));
      expect(projection.disabledEventIds, contains(_eventId));
      expect(projection.canTriggerMapEvent(fixture.gateEvent), isFalse);
    });
  });
}

Future<SceneEventRuntimeHookResult> _runScene(
  _ProjectionFixture fixture, {
  GameState gameState = const GameState(saveId: _saveId),
}) {
  return SceneEventRuntimeHook(
    callbacks: SceneRuntimeHostCallbacks(
      evaluateCondition: (_) => 'false',
      showDialogue: (_) => 'completed',
      startBattle: (_) => 'victory',
      playCinematic: (_) => 'completed',
    ),
  ).runForEventPage(
    project: fixture.project,
    map: fixture.map,
    event: fixture.sceneEvent,
    page: fixture.sceneEvent.pages.single,
    gameState: gameState,
  );
}

Future<GameState> _saveAndReload(GameState state) async {
  final tempDirectory =
      await Directory.systemTemp.createTemp('scene_v1_34_world_rules_');
  try {
    final repository = _TempFileGameSaveRepository(tempDirectory);
    final saveGame = SaveGameUseCase(repository);
    final loadGame = LoadGameUseCase(repository);

    expect(await saveGame.execute(state), isTrue);
    final saveFile = File(await repository.exposedSaveFilePath());
    expect(await saveFile.exists(), isTrue);
    final savedJson =
        jsonDecode(await saveFile.readAsString()) as Map<String, dynamic>;
    expect(savedJson['storyFlags'], isA<Map<String, dynamic>>());

    final loaded = await loadGame.execute();
    expect(loaded, isNotNull);
    return normalizeLoadedGameState(loaded!);
  } finally {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  }
}

_ProjectionFixture _fixture({
  List<ProjectDialogueEntry> dialogues = const [],
  List<SceneAsset> scenes = const [],
  List<WorldRuleDefinition> worldRules = const [],
}) {
  const npc = MapEntity(
    id: _npcId,
    name: 'Gate keeper',
    kind: MapEntityKind.npc,
    pos: GridPos(x: 2, y: 2),
    npc: MapEntityNpcData(displayName: 'Gate keeper'),
  );
  const gateEvent = MapEventDefinition(
    id: _eventId,
    title: 'Gate event',
    position: EventPosition(layerId: 'events', x: 4, y: 2),
    pages: [
      MapEventPage(pageNumber: 0),
    ],
  );
  const sceneEvent = MapEventDefinition(
    id: _sceneEventId,
    title: 'Scene closes gate',
    position: EventPosition(layerId: 'events', x: 1, y: 1),
    pages: [
      MapEventPage(
        pageNumber: 0,
        sceneTarget: MapEventSceneTarget(sceneId: _sceneId),
      ),
    ],
  );
  const map = MapData(
    id: _mapId,
    name: 'Runtime World Rules Map',
    size: GridSize(width: 8, height: 8),
    entities: [npc],
    events: [gateEvent, sceneEvent],
  );
  final project = ProjectManifest(
    name: 'Runtime World Rules Projection Hook project',
    maps: const [
      ProjectMapEntry(
        id: _mapId,
        name: 'Runtime World Rules Map',
        relativePath: 'maps/runtime_world_rules.json',
      ),
      ProjectMapEntry(
        id: _otherMapId,
        name: 'Other Runtime World Rules Map',
        relativePath: 'maps/other_runtime_world_rules.json',
      ),
    ],
    tilesets: const [],
    facts: [
      NarrativeFactDefinition(
        id: _factId,
        label: 'Gate closed',
      ),
    ],
    dialogues: dialogues,
    scenes: scenes,
    worldRules: worldRules,
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
  );
  return _ProjectionFixture(
    project: project,
    map: map,
    npcEntity: npc,
    gateEvent: gateEvent,
    sceneEvent: sceneEvent,
  );
}

WorldRuleDefinition _entityRule({
  required String id,
  bool enabled = true,
  String mapId = _mapId,
  WorldRuleSource source = const WorldRuleSource(
    kind: WorldRuleSourceKind.fact,
    sourceId: _factId,
    predicate: WorldRuleSourcePredicate.isTrue,
  ),
  required WorldRuleEffect effect,
  int priority = 0,
}) {
  return WorldRuleDefinition(
    id: id,
    label: 'Readable $id',
    enabled: enabled,
    source: source,
    target: WorldRuleTarget(
      kind: WorldRuleTargetKind.mapEntity,
      mapId: mapId,
      entityId: _npcId,
    ),
    effect: effect,
    priority: priority,
  );
}

WorldRuleDefinition _npcDialogueRule({
  required String id,
  bool enabled = true,
  String mapId = _mapId,
  required WorldRuleEffect effect,
}) {
  return WorldRuleDefinition(
    id: id,
    label: 'Readable $id',
    enabled: enabled,
    source: const WorldRuleSource(
      kind: WorldRuleSourceKind.fact,
      sourceId: _factId,
      predicate: WorldRuleSourcePredicate.isTrue,
    ),
    target: WorldRuleTarget(
      kind: WorldRuleTargetKind.npcDialogue,
      mapId: mapId,
      entityId: _npcId,
    ),
    effect: effect,
  );
}

WorldRuleDefinition _eventRule({
  required String id,
  bool enabled = true,
  String mapId = _mapId,
  WorldRuleSource source = const WorldRuleSource(
    kind: WorldRuleSourceKind.fact,
    sourceId: _factId,
    predicate: WorldRuleSourcePredicate.isTrue,
  ),
  required WorldRuleEffect effect,
  int priority = 0,
}) {
  return WorldRuleDefinition(
    id: id,
    label: 'Readable $id',
    enabled: enabled,
    source: source,
    target: WorldRuleTarget(
      kind: WorldRuleTargetKind.mapEvent,
      mapId: mapId,
      eventId: _eventId,
    ),
    effect: effect,
    priority: priority,
  );
}

SceneAsset _setFactScene() {
  return SceneAsset(
    id: _sceneId,
    name: 'Set Fact scene',
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'node_set_fact',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.setFact(factId: _factId, value: true),
          ),
        ),
        SceneNode(id: 'node_end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'edge_start_set_fact',
          fromNodeId: 'node_start',
          fromPortId: 'completed',
          toNodeId: 'node_set_fact',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'edge_set_fact_end',
          fromNodeId: 'node_set_fact',
          fromPortId: 'completed',
          toNodeId: 'node_end',
          kind: SceneEdgeKind.actionCompleted,
        ),
      ],
    ),
  );
}

final class _ProjectionFixture {
  const _ProjectionFixture({
    required this.project,
    required this.map,
    required this.npcEntity,
    required this.gateEvent,
    required this.sceneEvent,
  });

  final ProjectManifest project;
  final MapData map;
  final MapEntity npcEntity;
  final MapEventDefinition gateEvent;
  final MapEventDefinition sceneEvent;
}

class _TempFileGameSaveRepository extends FileGameSaveRepository {
  _TempFileGameSaveRepository(this._testDirectory);

  final Directory _testDirectory;

  Future<String> exposedSaveFilePath() => getSaveFilePath();

  @override
  Future<String> getSaveFilePath() async {
    final saveDir = Directory('${_testDirectory.path}/pokemonProject');
    if (!await saveDir.exists()) {
      await saveDir.create(recursive: true);
    }
    return '${saveDir.path}/game_save.json';
  }
}
