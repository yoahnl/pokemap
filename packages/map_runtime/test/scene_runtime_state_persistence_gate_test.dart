import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

const _saveId = 'save_scene_persistence_gate';
const _mapId = 'map_persistence_test';
const _sceneEventId = 'event_scene_persistence_test';
const _gateEventId = 'event_gate';
const _writeSceneId = 'scene_persistence_test';
const _factConditionSceneId = 'scene_condition_fact_after_reload_test';
const _consumedConditionSceneId = 'scene_condition_consumed_after_reload_test';
const _factId = 'fact_persistence_gate_open';
const _worldRuleFactId = 'world_rule_persistence_gate_visible';
const _worldRuleConsumedId = 'world_rule_persistence_event_consumed_visible';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Scene runtime state persistence gate', () {
    test('Scene-written setFact and markEventConsumed survive save and reload',
        () async {
      final result = await _runWriteSceneSaveAndReload();

      expect(result.hookResult.status, SceneEventRuntimeHookStatus.completed);
      expect(result.hookResult.updatedGameState, isNotNull);
      expect(result.originalGameState.storyFlags.activeFlags, isEmpty);
      expect(result.originalGameState.consumedEventIds, isEmpty);

      final updated = result.hookResult.updatedGameState!;
      expect(updated.storyFlags.activeFlags, contains(_factId));
      expect(updated.consumedEventIds, contains(_sceneEventId));
      expect(updated.currentMapId, _mapId);

      expect(result.reloadedGameState.saveId, _saveId);
      expect(result.reloadedGameState.currentMapId, _mapId);
      expect(
          result.reloadedGameState.storyFlags.activeFlags, contains(_factId));
      expect(
          result.reloadedGameState.progression.storyFlags, contains(_factId));
      expect(
          result.reloadedGameState.consumedEventIds, contains(_sceneEventId));

      final storyFlags = result.savedJson['storyFlags'] as Map<String, dynamic>;
      expect(storyFlags['activeFlags'], contains(_factId));
      final progression =
          result.savedJson['progression'] as Map<String, dynamic>;
      expect(progression['storyFlags'], contains(_factId));
      expect(result.savedJson['consumedEventIds'], contains(_sceneEventId));
    });

    test('Reloaded Scene-written Fact is readable by Scene condition source',
        () async {
      final persisted = await _runWriteSceneSaveAndReload();
      final calls = <String>[];

      final conditionResult = await SceneEventRuntimeHook(
        callbacks: _callbacks(
          calls: calls,
          evaluateCondition: (intent) {
            calls.add('condition:${intent.conditionSource?.sourceId}');
            return _evaluateConditionFromState(
              persisted.reloadedGameState,
              intent,
            );
          },
        ),
      ).runForEventPage(
        project: persisted.fixture.project,
        map: persisted.fixture.map,
        event: persisted.fixture.factConditionEvent,
        page: persisted.fixture.factConditionEvent.pages.single,
        gameState: persisted.reloadedGameState,
      );

      expect(conditionResult.status, SceneEventRuntimeHookStatus.completed);
      expect(conditionResult.executionResult?.finalNodeId, 'node_end_true');
      expect(calls, ['condition:$_factId']);
    });

    test(
        'Reloaded Scene-written consumed event is readable by condition source',
        () async {
      final persisted = await _runWriteSceneSaveAndReload();
      final calls = <String>[];

      final conditionResult = await SceneEventRuntimeHook(
        callbacks: _callbacks(
          calls: calls,
          evaluateCondition: (intent) {
            calls.add('condition:${intent.conditionSource?.sourceId}');
            return _evaluateConditionFromState(
              persisted.reloadedGameState,
              intent,
            );
          },
        ),
      ).runForEventPage(
        project: persisted.fixture.project,
        map: persisted.fixture.map,
        event: persisted.fixture.consumedConditionEvent,
        page: persisted.fixture.consumedConditionEvent.pages.single,
        gameState: persisted.reloadedGameState,
      );

      expect(conditionResult.status, SceneEventRuntimeHookStatus.completed);
      expect(conditionResult.executionResult?.finalNodeId, 'node_end_true');
      expect(calls, ['condition:$_sceneEventId']);
    });

    test(
        'Reloaded Scene-written Fact and consumed event are readable by pure World Rules projection',
        () async {
      final persisted = await _runWriteSceneSaveAndReload();

      final stateBeforeProjection = persisted.reloadedGameState.toJson();
      final effects = projectWorldRuleEffects(
        persisted.fixture.project,
        persisted.reloadedGameState,
        maps: [persisted.fixture.map],
        mapId: _mapId,
      );

      expect(effects.map((effect) => effect.ruleId), [
        _worldRuleConsumedId,
        _worldRuleFactId,
      ]);
      expect(
        effects
            .singleWhere((effect) => effect.ruleId == _worldRuleFactId)
            .target
            .eventId,
        _gateEventId,
      );
      expect(
        effects
            .singleWhere((effect) => effect.ruleId == _worldRuleConsumedId)
            .target
            .eventId,
        _gateEventId,
      );
      expect(persisted.reloadedGameState.toJson(), stateBeforeProjection);
    });
  });
}

Future<_PersistenceRunResult> _runWriteSceneSaveAndReload() async {
  final fixture = _fixture();
  const originalGameState = GameState(
    saveId: _saveId,
    currentMapId: _mapId,
    playerPosition: GridPos(x: 3, y: 4),
    playerFacing: EntityFacing.east,
  );

  final hookResult = await SceneEventRuntimeHook(
    callbacks: _callbacks(calls: <String>[]),
  ).runForEventPage(
    project: fixture.project,
    map: fixture.map,
    event: fixture.writeEvent,
    page: fixture.writeEvent.pages.single,
    gameState: originalGameState,
  );

  expect(hookResult.status, SceneEventRuntimeHookStatus.completed);
  final updated = hookResult.updatedGameState;
  expect(updated, isNotNull);

  final tempDirectory =
      await Directory.systemTemp.createTemp('scene_v1_33_persistence_');
  try {
    final repository = _TempFileGameSaveRepository(tempDirectory);
    final saveGame = SaveGameUseCase(repository);
    final loadGame = LoadGameUseCase(repository);

    expect(await saveGame.execute(updated!), isTrue);
    expect(await repository.exists(), isTrue);

    final saveFile = File(await repository.exposedSaveFilePath());
    expect(await saveFile.exists(), isTrue);
    final savedJson =
        jsonDecode(await saveFile.readAsString()) as Map<String, dynamic>;

    final loaded = await loadGame.execute();
    expect(loaded, isNotNull);
    final reloaded = normalizeLoadedGameState(loaded!);

    return _PersistenceRunResult(
      fixture: fixture,
      originalGameState: originalGameState,
      hookResult: hookResult,
      savedJson: savedJson,
      reloadedGameState: reloaded,
    );
  } finally {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  }
}

SceneRuntimeHostCallbacks _callbacks({
  required List<String> calls,
  SceneRuntimeIntentCallback? evaluateCondition,
}) {
  return SceneRuntimeHostCallbacks(
    evaluateCondition: evaluateCondition ??
        (intent) {
          calls.add('condition:${intent.conditionSource?.sourceId}');
          return 'false';
        },
    showDialogue: (intent) {
      calls.add('dialogue:${intent.dialogueId}');
      return 'completed';
    },
    startBattle: (intent) {
      calls.add('battle:${intent.trainerId}');
      return 'victory';
    },
    playCinematic: (intent) {
      calls.add('cinematic:${intent.cinematicId}');
      return 'completed';
    },
  );
}

String _evaluateConditionFromState(
  GameState state,
  SceneRuntimePlanIntent intent,
) {
  final source = intent.conditionSource;
  if (source == null) {
    throw StateError('Scene condition intent is missing a condition source.');
  }

  final value = switch (source.sourceKind) {
    SceneConditionSourceKind.factLikeStoryFlag =>
      state.storyFlags.activeFlags.contains(source.sourceId) ||
          state.progression.storyFlags.contains(source.sourceId),
    SceneConditionSourceKind.consumedEvent =>
      state.consumedEventIds.contains(source.sourceId),
    _ => throw UnsupportedError(
        'Condition source ${source.sourceKind.name} is outside V1-33 test.',
      ),
  };

  final matched = switch (source.operator) {
    SceneConditionOperator.isTrue => value,
    SceneConditionOperator.isFalse => !value,
    SceneConditionOperator.equals => switch (source.value) {
        'true' || SceneConditionValues.completed => value,
        'false' || SceneConditionValues.notCompleted => !value,
        _ => throw UnsupportedError(
            'Condition value ${source.value} is outside V1-33 test.',
          ),
      },
  };
  return matched ? 'true' : 'false';
}

_PersistenceFixture _fixture() {
  final writeEvent = _event(
    _sceneEventId,
    title: 'Scene persistence event',
    sceneId: _writeSceneId,
    x: 2,
    y: 2,
  );
  final gateEvent = _event(
    _gateEventId,
    title: 'Persistence gate target',
    x: 5,
    y: 2,
  );
  final factConditionEvent = _event(
    'event_condition_fact_persistence_test',
    title: 'Fact condition after reload',
    sceneId: _factConditionSceneId,
    x: 3,
    y: 3,
  );
  final consumedConditionEvent = _event(
    'event_condition_consumed_persistence_test',
    title: 'Consumed condition after reload',
    sceneId: _consumedConditionSceneId,
    x: 4,
    y: 3,
  );
  final map = MapData(
    id: _mapId,
    name: 'Persistence Test Map',
    size: const GridSize(width: 8, height: 8),
    layers: [
      MapLayer.tile(
        id: 'l_base',
        name: 'Base',
        tiles: List<int>.filled(64, 0),
      ),
    ],
    events: [
      writeEvent,
      gateEvent,
      factConditionEvent,
      consumedConditionEvent,
    ],
  );
  final project = ProjectManifest(
    name: 'Scene persistence gate test project',
    maps: const [
      ProjectMapEntry(
        id: _mapId,
        name: 'Persistence Test Map',
        relativePath: 'maps/map_persistence_test.json',
      ),
    ],
    tilesets: const [],
    facts: [
      NarrativeFactDefinition(
        id: _factId,
        label: 'Persistence gate open',
      ),
    ],
    worldRules: [
      WorldRuleDefinition(
        id: _worldRuleConsumedId,
        label: 'Consumed event keeps gate visible',
        source: const WorldRuleSource(
          kind: WorldRuleSourceKind.consumedEvent,
          sourceId: _sceneEventId,
          predicate: WorldRuleSourcePredicate.consumed,
        ),
        target: const WorldRuleTarget(
          kind: WorldRuleTargetKind.mapEvent,
          mapId: _mapId,
          eventId: _gateEventId,
        ),
        effect: const WorldRuleEffect(kind: WorldRuleEffectKind.eventEnabled),
        priority: 0,
      ),
      WorldRuleDefinition(
        id: _worldRuleFactId,
        label: 'Fact keeps gate visible',
        source: const WorldRuleSource(
          kind: WorldRuleSourceKind.fact,
          sourceId: _factId,
          predicate: WorldRuleSourcePredicate.isTrue,
        ),
        target: const WorldRuleTarget(
          kind: WorldRuleTargetKind.mapEvent,
          mapId: _mapId,
          eventId: _gateEventId,
        ),
        effect: const WorldRuleEffect(kind: WorldRuleEffectKind.eventEnabled),
        priority: 1,
      ),
    ],
    scenes: [
      _writeScene(),
      _conditionScene(
        id: _factConditionSceneId,
        source: SceneConditionSource(
          sourceKind: SceneConditionSourceKind.factLikeStoryFlag,
          sourceId: _factId,
          operator: SceneConditionOperator.isTrue,
          label: 'Persistence gate open',
        ),
      ),
      _conditionScene(
        id: _consumedConditionSceneId,
        source: SceneConditionSource(
          sourceKind: SceneConditionSourceKind.consumedEvent,
          sourceId: _sceneEventId,
          operator: SceneConditionOperator.isTrue,
          label: 'Scene persistence event consumed',
        ),
      ),
    ],
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
  );
  return _PersistenceFixture(
    project: project,
    map: map,
    writeEvent: writeEvent,
    factConditionEvent: factConditionEvent,
    consumedConditionEvent: consumedConditionEvent,
  );
}

MapEventDefinition _event(
  String id, {
  required String title,
  String? sceneId,
  required int x,
  required int y,
}) {
  return MapEventDefinition(
    id: id,
    title: title,
    position: EventPosition(layerId: 'l_base', x: x, y: y),
    pages: [
      MapEventPage(
        pageNumber: 0,
        sceneTarget:
            sceneId == null ? null : MapEventSceneTarget(sceneId: sceneId),
      ),
    ],
  );
}

SceneAsset _writeScene() {
  return SceneAsset(
    id: _writeSceneId,
    name: 'Scene persistence test',
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'node_action_set_fact',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.setFact(factId: _factId, value: true),
          ),
        ),
        SceneNode(
          id: 'node_action_mark_event_consumed',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.markEventConsumed(
              mapId: _mapId,
              eventId: _sceneEventId,
            ),
          ),
        ),
        SceneNode(id: 'node_end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'edge_start_set_fact',
          fromNodeId: 'node_start',
          fromPortId: 'completed',
          toNodeId: 'node_action_set_fact',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'edge_set_fact_mark_event',
          fromNodeId: 'node_action_set_fact',
          fromPortId: 'completed',
          toNodeId: 'node_action_mark_event_consumed',
          kind: SceneEdgeKind.actionCompleted,
        ),
        SceneEdge(
          id: 'edge_mark_event_end',
          fromNodeId: 'node_action_mark_event_consumed',
          fromPortId: 'completed',
          toNodeId: 'node_end',
          kind: SceneEdgeKind.actionCompleted,
        ),
      ],
    ),
  );
}

SceneAsset _conditionScene({
  required String id,
  required SceneConditionSource source,
}) {
  return SceneAsset(
    id: id,
    name: 'Scene condition after reload',
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'node_condition_after_reload',
          kind: SceneNodeKind.condition,
          payload: SceneConditionPayload(conditionSource: source),
        ),
        SceneNode(id: 'node_end_true', kind: SceneNodeKind.end),
        SceneNode(id: 'node_end_false', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'edge_start_condition',
          fromNodeId: 'node_start',
          fromPortId: 'completed',
          toNodeId: 'node_condition_after_reload',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'edge_condition_true',
          fromNodeId: 'node_condition_after_reload',
          fromPortId: 'true',
          toNodeId: 'node_end_true',
          kind: SceneEdgeKind.conditionTrue,
        ),
        SceneEdge(
          id: 'edge_condition_false',
          fromNodeId: 'node_condition_after_reload',
          fromPortId: 'false',
          toNodeId: 'node_end_false',
          kind: SceneEdgeKind.conditionFalse,
        ),
      ],
    ),
  );
}

final class _PersistenceFixture {
  const _PersistenceFixture({
    required this.project,
    required this.map,
    required this.writeEvent,
    required this.factConditionEvent,
    required this.consumedConditionEvent,
  });

  final ProjectManifest project;
  final MapData map;
  final MapEventDefinition writeEvent;
  final MapEventDefinition factConditionEvent;
  final MapEventDefinition consumedConditionEvent;
}

final class _PersistenceRunResult {
  const _PersistenceRunResult({
    required this.fixture,
    required this.originalGameState,
    required this.hookResult,
    required this.savedJson,
    required this.reloadedGameState,
  });

  final _PersistenceFixture fixture;
  final GameState originalGameState;
  final SceneEventRuntimeHookResult hookResult;
  final Map<String, dynamic> savedJson;
  final GameState reloadedGameState;
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
