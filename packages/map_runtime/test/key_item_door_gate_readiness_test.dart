import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/global_story_chapter_runtime.dart';
import 'package:map_runtime/src/application/map_entity_runtime_predicate_evaluator.dart';

const String _testMapId = 'test_map';
const String _testLockedGateId = 'test_locked_gate';
const String _testKeyPickupId = 'test_key_pickup';
const String _testItemKeyId = 'test_item_key';
const String _testKeyFact = 'test_key_fact';
const String _testGateUnlockedFact = 'test_gate_unlocked_fact';
const String _testGateUnlockedStep = 'test_step_gate_unlocked';

void main() {
  group('Key Item / Door Gate authoring readiness', () {
    const executor = ScenarioRuntimeExecutor();

    test('door gate stays blocked without required key fact', () {
      var state = createNewGameState(startMapId: _testMapId);
      final messages = <String>[];

      final result = _dispatchGate(
        executor,
        state: state,
        onUpdate: (next) => state = next,
        messages: messages,
      );

      expect(result.status, ScenarioRuntimeExecutionStatus.executedEffect);
      expect(result.effect.type, ScenarioRuntimeEffectType.message);
      expect(result.stopNodeId, 'test_gate_blocked_message');
      expect(messages, ['test_blocked_dialogue']);
      expect(
          state.storyFlags.activeFlags, isNot(contains(_testGateUnlockedFact)));
      expect(
        state.progression.completedStepIds,
        isNot(contains(_testGateUnlockedStep)),
      );
    });

    test('bag key alone does not satisfy the derived fact gate', () {
      var state = const GameState(
        saveId: 'test_save',
        currentMapId: _testMapId,
        bag: Bag(
          entries: [
            BagEntry(
              itemId: _testItemKeyId,
              categoryId: 'items',
              quantity: 1,
            ),
          ],
        ),
      );
      final messages = <String>[];

      final result = _dispatchGate(
        executor,
        state: state,
        onUpdate: (next) => state = next,
        messages: messages,
      );

      expect(result.status, ScenarioRuntimeExecutionStatus.executedEffect);
      expect(result.stopNodeId, 'test_gate_blocked_message');
      expect(messages, ['test_blocked_dialogue']);
      expect(
          state.storyFlags.activeFlags, isNot(contains(_testGateUnlockedFact)));
    });

    test('door gate opens with required key fact', () {
      var state = _stateWithKeyFact();

      final result = _dispatchGate(
        executor,
        state: state,
        onUpdate: (next) => state = next,
      );

      expect(result.status, ScenarioRuntimeExecutionStatus.reachedEnd);
      expect(state.storyFlags.activeFlags, contains(_testGateUnlockedFact));
    });

    test('door gate can set unlock fact and complete step', () {
      var state = _stateWithKeyFact();

      _dispatchGate(
        executor,
        state: state,
        onUpdate: (next) => state = next,
      );

      expect(state.storyFlags.activeFlags, contains(_testGateUnlockedFact));
      expect(
          state.progression.completedStepIds, contains(_testGateUnlockedStep));
    });

    test('key pickup gives item and derives key fact', () {
      var state = createNewGameState(startMapId: _testMapId);

      final result = _dispatchKeyPickup(
        executor,
        state: state,
        onUpdate: (next) => state = next,
      );

      expect(result.status, ScenarioRuntimeExecutionStatus.reachedEnd);
      expect(state.bag.entries.single.itemId, _testItemKeyId);
      expect(state.bag.entries.single.quantity, 1);
      expect(state.storyFlags.activeFlags, contains(_testKeyFact));
    });

    test('scenario can use giveItem result to unlock gate via fact pattern',
        () {
      var state = createNewGameState(startMapId: _testMapId);

      _dispatchKeyPickup(
        executor,
        state: state,
        onUpdate: (next) => state = next,
      );
      final gateResult = _dispatchGate(
        executor,
        state: state,
        onUpdate: (next) => state = next,
      );

      expect(gateResult.status, ScenarioRuntimeExecutionStatus.reachedEnd);
      expect(state.bag.entries.single.itemId, _testItemKeyId);
      expect(state.storyFlags.activeFlags, contains(_testGateUnlockedFact));
      expect(
          state.progression.completedStepIds, contains(_testGateUnlockedStep));
    });

    test('save/load preserves key item, key fact, and gate unlock state', () {
      var state = createNewGameState(startMapId: _testMapId);
      _dispatchKeyPickup(
        executor,
        state: state,
        onUpdate: (next) => state = next,
      );
      _dispatchGate(
        executor,
        state: state,
        onUpdate: (next) => state = next,
      );

      final reloaded = normalizeLoadedGameState(
        gameStateFromSaveData(saveDataFromGameState(state)),
      );

      expect(reloaded.bag.entries.single.itemId, _testItemKeyId);
      expect(reloaded.bag.entries.single.quantity, 1);
      expect(reloaded.storyFlags.activeFlags, contains(_testKeyFact));
      expect(reloaded.storyFlags.activeFlags, contains(_testGateUnlockedFact));
      expect(
        reloaded.progression.completedStepIds,
        contains(_testGateUnlockedStep),
      );
    });

    test(
        'world rule pattern switches from closed gate proxy to open gate proxy',
        () {
      final closedGate = _closedGateProxy();
      final openGate = _openGateProxy();
      final before = createNewGameState(startMapId: _testMapId);
      final after = before.copyWith(
        storyFlags: const StoryFlags(activeFlags: {_testGateUnlockedFact}),
      );

      expect(_evaluator(before).isNpcPresentOnMap(closedGate), isTrue);
      expect(_evaluator(before).isNpcPresentOnMap(openGate), isFalse);
      expect(_evaluator(after).isNpcPresentOnMap(closedGate), isFalse);
      expect(_evaluator(after).isNpcPresentOnMap(openGate), isTrue);
    });

    test('world rule pattern can project completed gate step', () {
      final closedGate = _stepClosedGateProxy();
      final openGate = _stepOpenGateProxy();
      final before = createNewGameState(startMapId: _testMapId);
      final after = before.copyWith(
        progression: const PlayerProgression(
          completedStepIds: [_testGateUnlockedStep],
        ),
      );

      expect(_evaluator(before).isNpcPresentOnMap(closedGate), isTrue);
      expect(_evaluator(before).isNpcPresentOnMap(openGate), isFalse);
      expect(_evaluator(after).isNpcPresentOnMap(closedGate), isFalse);
      expect(_evaluator(after).isNpcPresentOnMap(openGate), isTrue);
    });

    test('blocked branch is deterministic and does not mutate state', () {
      var state = createNewGameState(startMapId: _testMapId);
      final messages = <String>[];

      final first = _dispatchGate(
        executor,
        state: state,
        onUpdate: (next) => state = next,
        messages: messages,
      );
      final second = _dispatchGate(
        executor,
        state: state,
        onUpdate: (next) => state = next,
        messages: messages,
      );

      expect(first.stopNodeId, 'test_gate_blocked_message');
      expect(second.stopNodeId, 'test_gate_blocked_message');
      expect(messages, ['test_blocked_dialogue', 'test_blocked_dialogue']);
      expect(state.storyFlags.activeFlags, isEmpty);
      expect(state.progression.completedStepIds, isEmpty);
      expect(state.bag.entries, isEmpty);
    });

    test('fixtures use only generic test ids', () {
      final ids = <String>[
        _testMapId,
        _testLockedGateId,
        _testKeyPickupId,
        _testItemKeyId,
        _testKeyFact,
        _testGateUnlockedFact,
        _testGateUnlockedStep,
        _gateScenario().id,
        _keyPickupScenario().id,
        for (final node in _gateScenario().nodes) node.id,
        for (final node in _keyPickupScenario().nodes) node.id,
      ];

      expect(ids, everyElement(startsWith('test_')));
    });
  });
}

ScenarioRuntimeExecutionResult _dispatchGate(
  ScenarioRuntimeExecutor executor, {
  required GameState state,
  required void Function(GameState) onUpdate,
  List<String>? messages,
}) {
  return executor.dispatch(
    scenarios: [_gateScenario()],
    sourceEvent: ScenarioRuntimeSourceEvent.entityInteract(
      mapId: _testMapId,
      entityId: _testLockedGateId,
    ),
    context: _context(state: state, onUpdate: onUpdate, messages: messages),
  );
}

ScenarioRuntimeExecutionResult _dispatchKeyPickup(
  ScenarioRuntimeExecutor executor, {
  required GameState state,
  required void Function(GameState) onUpdate,
}) {
  return executor.dispatch(
    scenarios: [_keyPickupScenario()],
    sourceEvent: ScenarioRuntimeSourceEvent.entityInteract(
      mapId: _testMapId,
      entityId: _testKeyPickupId,
    ),
    context: _context(state: state, onUpdate: onUpdate),
  );
}

ScenarioRuntimeExecutionContext _context({
  required GameState state,
  required void Function(GameState) onUpdate,
  List<String>? messages,
}) {
  return ScenarioRuntimeExecutionContext(
    gameState: state,
    onGameStateUpdated: onUpdate,
    openDialogue: (_, {startNode, runtimeSourceId}) => false,
    runScript: (_, {startNode, runtimeSourceId}) => false,
    showMessage: (message) => messages?.add(message),
  );
}

GameState _stateWithKeyFact() {
  return const GameState(
    saveId: 'test_save',
    currentMapId: _testMapId,
    storyFlags: StoryFlags(activeFlags: {_testKeyFact}),
  );
}

ScenarioAsset _gateScenario() {
  return ScenarioAsset(
    id: 'test_gate_scene',
    name: 'Test Gate Scene',
    scope: ScenarioScope.localEventFlow,
    entryNodeId: 'test_start',
    nodes: [
      const ScenarioNode(id: 'test_start', type: ScenarioNodeType.start),
      const ScenarioNode(
        id: 'test_source_gate',
        type: ScenarioNodeType.reference,
        payload: ScenarioNodePayload(actionKind: kScenarioSourceEntityInteract),
        binding: ScenarioNodeBinding(
          mapId: _testMapId,
          entityId: _testLockedGateId,
        ),
      ),
      const ScenarioNode(
        id: 'test_gate_condition',
        type: ScenarioNodeType.condition,
        payload: ScenarioNodePayload(
          condition: ScriptCondition(
            type: ScriptConditionType.flagIsSet,
            params: {ScriptConditionParams.flagName: _testKeyFact},
          ),
        ),
      ),
      const ScenarioNode(
        id: 'test_gate_unlocked_fact',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
        binding: ScenarioNodeBinding(flagName: _testGateUnlockedFact),
      ),
      const ScenarioNode(
        id: 'test_gate_unlocked_step',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(
          actionKind: kScenarioActionCompleteStep,
          params: {'stepId': _testGateUnlockedStep},
        ),
      ),
      const ScenarioNode(
        id: 'test_gate_blocked_message',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(
          actionKind: kScenarioActionShowMessage,
          message: 'test_blocked_dialogue',
        ),
      ),
      const ScenarioNode(id: 'test_gate_end', type: ScenarioNodeType.end),
    ],
    edges: [
      _edge('test_edge_source_condition', 'test_source_gate',
          'test_gate_condition'),
      _edge(
        'test_edge_condition_unlocked',
        'test_gate_condition',
        'test_gate_unlocked_fact',
        kind: ScenarioEdgeKind.trueBranch,
      ),
      _edge(
        'test_edge_condition_blocked',
        'test_gate_condition',
        'test_gate_blocked_message',
        kind: ScenarioEdgeKind.falseBranch,
      ),
      _edge(
        'test_edge_unlocked_fact_step',
        'test_gate_unlocked_fact',
        'test_gate_unlocked_step',
      ),
      _edge(
        'test_edge_unlocked_step_end',
        'test_gate_unlocked_step',
        'test_gate_end',
      ),
    ],
  );
}

ScenarioAsset _keyPickupScenario() {
  return ScenarioAsset(
    id: 'test_key_pickup_scene',
    name: 'Test Key Pickup Scene',
    scope: ScenarioScope.localEventFlow,
    entryNodeId: 'test_start',
    nodes: [
      const ScenarioNode(id: 'test_start', type: ScenarioNodeType.start),
      const ScenarioNode(
        id: 'test_source_key_pickup',
        type: ScenarioNodeType.reference,
        payload: ScenarioNodePayload(actionKind: kScenarioSourceEntityInteract),
        binding: ScenarioNodeBinding(
          mapId: _testMapId,
          entityId: _testKeyPickupId,
        ),
      ),
      const ScenarioNode(
        id: 'test_give_key_item',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(
          actionKind: kScenarioActionGiveItem,
          params: {'itemId': _testItemKeyId, 'quantity': '1'},
        ),
      ),
      const ScenarioNode(
        id: 'test_set_key_fact',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
        binding: ScenarioNodeBinding(flagName: _testKeyFact),
      ),
      const ScenarioNode(id: 'test_key_pickup_end', type: ScenarioNodeType.end),
    ],
    edges: [
      _edge(
        'test_edge_key_source_give',
        'test_source_key_pickup',
        'test_give_key_item',
      ),
      _edge(
          'test_edge_key_give_fact', 'test_give_key_item', 'test_set_key_fact'),
      _edge(
          'test_edge_key_fact_end', 'test_set_key_fact', 'test_key_pickup_end'),
    ],
  );
}

ScenarioEdge _edge(
  String id,
  String from,
  String to, {
  ScenarioEdgeKind kind = ScenarioEdgeKind.next,
}) {
  return ScenarioEdge(id: id, fromNodeId: from, toNodeId: to, kind: kind);
}

MapEntity _closedGateProxy() {
  return const MapEntity(
    id: 'test_closed_gate',
    kind: MapEntityKind.npc,
    pos: GridPos(x: 1, y: 1),
    npc: MapEntityNpcData(
      displayName: 'Test Closed Gate',
      visibilityRule: MapEntityNpcVisibilityRule(
        mode: MapEntityNpcVisibilityMode.hiddenWhen,
        predicate: MapEntityRuntimePredicate(
          kind: MapEntityRuntimePredicateKind.storyFlagSet,
          refId: _testGateUnlockedFact,
        ),
      ),
    ),
  );
}

MapEntity _openGateProxy() {
  return const MapEntity(
    id: 'test_open_gate',
    kind: MapEntityKind.npc,
    pos: GridPos(x: 1, y: 1),
    npc: MapEntityNpcData(
      displayName: 'Test Open Gate',
      visibilityRule: MapEntityNpcVisibilityRule(
        mode: MapEntityNpcVisibilityMode.visibleWhen,
        predicate: MapEntityRuntimePredicate(
          kind: MapEntityRuntimePredicateKind.storyFlagSet,
          refId: _testGateUnlockedFact,
        ),
      ),
    ),
  );
}

MapEntity _stepClosedGateProxy() {
  return const MapEntity(
    id: 'test_step_closed_gate',
    kind: MapEntityKind.npc,
    pos: GridPos(x: 2, y: 1),
    npc: MapEntityNpcData(
      displayName: 'Test Step Closed Gate',
      visibilityRule: MapEntityNpcVisibilityRule(
        mode: MapEntityNpcVisibilityMode.hiddenWhen,
        predicate: MapEntityRuntimePredicate(
          kind: MapEntityRuntimePredicateKind.stepCompleted,
          refId: _testGateUnlockedStep,
        ),
      ),
    ),
  );
}

MapEntity _stepOpenGateProxy() {
  return const MapEntity(
    id: 'test_step_open_gate',
    kind: MapEntityKind.npc,
    pos: GridPos(x: 2, y: 1),
    npc: MapEntityNpcData(
      displayName: 'Test Step Open Gate',
      visibilityRule: MapEntityNpcVisibilityRule(
        mode: MapEntityNpcVisibilityMode.visibleWhen,
        predicate: MapEntityRuntimePredicate(
          kind: MapEntityRuntimePredicateKind.stepCompleted,
          refId: _testGateUnlockedStep,
        ),
      ),
    ),
  );
}

MapEntityRuntimePredicateEvaluator _evaluator(GameState state) {
  return MapEntityRuntimePredicateEvaluator(
    gameState: state,
    chapterIndex: const GlobalStoryChapterStepIndex(chapterIdToStepIds: {}),
  );
}
