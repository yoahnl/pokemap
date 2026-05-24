import 'dart:convert';
import 'dart:io';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/global_story_chapter_runtime.dart';
import 'package:map_runtime/src/application/map_entity_runtime_predicate_evaluator.dart';
import 'package:path/path.dart' as p;

const String _testMapId = 'test_map';
const String _testPickupEntityId = 'test_pickup_entity';
const String _testItemId = 'test_item_potion';
const String _testPickupFact = 'test_pickup_done_fact';
const String _testPickupStep = 'test_step_pickup_done';

void main() {
  group('Item Pickup / GiveItem authoring readiness', () {
    const executor = ScenarioRuntimeExecutor();

    test('new game starts with empty bag', () {
      final state = createNewGameState(startMapId: _testMapId);

      expect(state.bag.entries, isEmpty);
    });

    test('giveItem action adds item with quantity', () {
      var state = const GameState(saveId: 'test_save');

      final result = _dispatch(
        executor,
        scenario: _pickupScenario(quantity: '2', setFlag: false),
        state: state,
        onUpdate: (next) => state = next,
      );

      expect(result.success, isTrue);
      expect(state.bag.entries, hasLength(1));
      expect(state.bag.entries.single.itemId, _testItemId);
      expect(state.bag.entries.single.quantity, 2);
    });

    test('giveItem action accumulates quantity when item already exists', () {
      var state = const GameState(
        saveId: 'test_save',
        bag: Bag(
          entries: [
            BagEntry(
              itemId: _testItemId,
              categoryId: 'items',
              quantity: 3,
            ),
          ],
        ),
      );

      final result = _dispatch(
        executor,
        scenario: _pickupScenario(quantity: '2', setFlag: false),
        state: state,
        onUpdate: (next) => state = next,
      );

      expect(result.success, isTrue);
      expect(state.bag.entries, hasLength(1));
      expect(state.bag.entries.single.quantity, 5);
    });

    test('giveItem action blocks when itemId is missing', () {
      var state = const GameState(saveId: 'test_save');

      final result = _dispatch(
        executor,
        scenario: _pickupScenario(itemId: null, setFlag: false),
        state: state,
        onUpdate: (next) => state = next,
      );

      expect(result.status, ScenarioRuntimeExecutionStatus.blocked);
      expect(state.bag.entries, isEmpty);
    });

    test('giveItem action blocks when itemId is blank', () {
      var state = const GameState(saveId: 'test_save');

      final result = _dispatch(
        executor,
        scenario: _pickupScenario(itemId: '   ', setFlag: false),
        state: state,
        onUpdate: (next) => state = next,
      );

      expect(result.status, ScenarioRuntimeExecutionStatus.blocked);
      expect(state.bag.entries, isEmpty);
    });

    test('giveItem action defaults missing or invalid quantity to one', () {
      var missingQuantityState = const GameState(saveId: 'test_missing_qty');
      _dispatch(
        executor,
        scenario: _pickupScenario(quantity: null, setFlag: false),
        state: missingQuantityState,
        onUpdate: (next) => missingQuantityState = next,
      );

      var invalidQuantityState = const GameState(saveId: 'test_invalid_qty');
      _dispatch(
        executor,
        scenario: _pickupScenario(quantity: 'not_an_int', setFlag: false),
        state: invalidQuantityState,
        onUpdate: (next) => invalidQuantityState = next,
      );

      expect(missingQuantityState.bag.entries.single.quantity, 1);
      expect(invalidQuantityState.bag.entries.single.quantity, 1);
    });

    test('giveItem action blocks non-positive quantity', () {
      var state = const GameState(saveId: 'test_save');

      final result = _dispatch(
        executor,
        scenario: _pickupScenario(quantity: '0', setFlag: false),
        state: state,
        onUpdate: (next) => state = next,
      );

      expect(result.status, ScenarioRuntimeExecutionStatus.blocked);
      expect(state.bag.entries, isEmpty);
    });

    test('scenario item pickup gives item and records fact and step', () {
      var state = createNewGameState(startMapId: _testMapId);

      final result = _dispatch(
        executor,
        scenario: _pickupScenario(quantity: '2'),
        state: state,
        onUpdate: (next) => state = next,
      );

      expect(result.success, isTrue);
      expect(state.bag.entries.single.itemId, _testItemId);
      expect(state.bag.entries.single.quantity, 2);
      expect(state.storyFlags.activeFlags, contains(_testPickupFact));
      expect(state.progression.completedStepIds, contains(_testPickupStep));
    });

    test('save/load preserves bag item quantity, pickup fact, and step', () {
      var state = createNewGameState(startMapId: _testMapId);
      _dispatch(
        executor,
        scenario: _pickupScenario(quantity: '2'),
        state: state,
        onUpdate: (next) => state = next,
      );

      final saveData = saveDataFromGameState(state);
      final reloaded =
          normalizeLoadedGameState(gameStateFromSaveData(saveData));

      expect(reloaded.bag.entries.single.itemId, _testItemId);
      expect(reloaded.bag.entries.single.quantity, 2);
      expect(reloaded.storyFlags.activeFlags, contains(_testPickupFact));
      expect(reloaded.progression.completedStepIds, contains(_testPickupStep));
    });

    test('scenario activation condition prevents a second pickup', () {
      var state = createNewGameState(startMapId: _testMapId);
      final scenario = _pickupScenario(
        quantity: '2',
        activationCondition: const ScriptCondition(
          type: ScriptConditionType.flagIsUnset,
          params: {ScriptConditionParams.flagName: _testPickupFact},
        ),
      );

      final first = _dispatch(
        executor,
        scenario: scenario,
        state: state,
        onUpdate: (next) => state = next,
      );
      final second = _dispatch(
        executor,
        scenario: scenario,
        state: state,
        onUpdate: (next) => state = next,
      );

      expect(first.success, isTrue);
      expect(second.status, ScenarioRuntimeExecutionStatus.noMatchingSource);
      expect(state.bag.entries.single.quantity, 2);
    });

    test('world rule pattern hides pickup proxy after pickup fact', () {
      final proxy = _pickupProxyNpc();
      final before = createNewGameState(startMapId: _testMapId);
      final after = before.copyWith(
        storyFlags: const StoryFlags(activeFlags: {_testPickupFact}),
      );

      expect(_evaluator(before).isNpcPresentOnMap(proxy), isTrue);
      expect(_evaluator(after).isNpcPresentOnMap(proxy), isFalse);
    });

    test('playable item entity interaction dispatches pickup scenario',
        () async {
      final root = await Directory.systemTemp.createTemp(
        'item_pickup_runtime_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });

      final projectFilePath = await _writeRuntimeProject(
        root,
        maps: [_runtimePickupMap()],
        scenarios: [_pickupScenario(quantity: '2')],
      );
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: _testMapId,
      );
      final game = _LoadedPlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
      );

      game.onGameResize(Vector2(640, 480));
      await game.onLoad();

      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.primary),
        ),
        isTrue,
      );

      expect(game.gameStateSnapshot.bag.entries.single.itemId, _testItemId);
      expect(game.gameStateSnapshot.bag.entries.single.quantity, 2);
    });

    test('fixtures use only generic test ids', () {
      final ids = <String>[
        _testMapId,
        _testPickupEntityId,
        _testItemId,
        _testPickupFact,
        _testPickupStep,
        _pickupScenario().id,
        for (final node in _pickupScenario().nodes) node.id,
      ];

      expect(ids, everyElement(startsWith('test_')));
    });
  });
}

ScenarioRuntimeExecutionResult _dispatch(
  ScenarioRuntimeExecutor executor, {
  required ScenarioAsset scenario,
  required GameState state,
  required void Function(GameState) onUpdate,
}) {
  return executor.dispatch(
    scenarios: [scenario],
    sourceEvent: ScenarioRuntimeSourceEvent.entityInteract(
      mapId: _testMapId,
      entityId: _testPickupEntityId,
    ),
    context: _context(state: state, onUpdate: onUpdate),
  );
}

ScenarioRuntimeExecutionContext _context({
  required GameState state,
  required void Function(GameState) onUpdate,
}) {
  return ScenarioRuntimeExecutionContext(
    gameState: state,
    onGameStateUpdated: onUpdate,
    openDialogue: (_, {startNode, runtimeSourceId}) => false,
    runScript: (_, {startNode, runtimeSourceId}) => false,
    showMessage: (_) {},
  );
}

ScenarioAsset _pickupScenario({
  String? itemId = _testItemId,
  String? quantity = '2',
  bool setFlag = true,
  ScriptCondition? activationCondition,
}) {
  final nodes = <ScenarioNode>[
    const ScenarioNode(
      id: 'test_start',
      type: ScenarioNodeType.start,
    ),
    const ScenarioNode(
      id: 'test_source_pickup',
      type: ScenarioNodeType.reference,
      payload: ScenarioNodePayload(actionKind: kScenarioSourceEntityInteract),
      binding: ScenarioNodeBinding(
        mapId: _testMapId,
        entityId: _testPickupEntityId,
      ),
    ),
    ScenarioNode(
      id: 'test_give_item',
      type: ScenarioNodeType.action,
      payload: ScenarioNodePayload(
        actionKind: kScenarioActionGiveItem,
        params: {
          if (itemId != null) 'itemId': itemId,
          if (quantity != null) 'quantity': quantity,
        },
      ),
    ),
    if (setFlag)
      const ScenarioNode(
        id: 'test_set_pickup_fact',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
        binding: ScenarioNodeBinding(flagName: _testPickupFact),
      ),
    if (setFlag)
      const ScenarioNode(
        id: 'test_complete_pickup_step',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(
          actionKind: kScenarioActionCompleteStep,
          params: {'stepId': _testPickupStep},
        ),
      ),
    const ScenarioNode(id: 'test_end_pickup', type: ScenarioNodeType.end),
  ];

  return ScenarioAsset(
    id: 'test_pickup_scene',
    name: 'Test Pickup Scene',
    scope: ScenarioScope.localEventFlow,
    activationCondition: activationCondition,
    entryNodeId: 'test_start',
    nodes: nodes,
    edges: [
      _edge('test_edge_source_give', 'test_source_pickup', 'test_give_item'),
      if (setFlag) ...[
        _edge(
          'test_edge_give_flag',
          'test_give_item',
          'test_set_pickup_fact',
        ),
        _edge(
          'test_edge_flag_step',
          'test_set_pickup_fact',
          'test_complete_pickup_step',
        ),
        _edge(
          'test_edge_step_end',
          'test_complete_pickup_step',
          'test_end_pickup',
        ),
      ] else
        _edge('test_edge_give_end', 'test_give_item', 'test_end_pickup'),
    ],
  );
}

ScenarioEdge _edge(String id, String from, String to) {
  return ScenarioEdge(id: id, fromNodeId: from, toNodeId: to);
}

MapEntity _pickupProxyNpc() {
  return const MapEntity(
    id: 'test_pickup_proxy',
    kind: MapEntityKind.npc,
    pos: GridPos(x: 1, y: 1),
    npc: MapEntityNpcData(
      displayName: 'Test Pickup Proxy',
      visibilityRule: MapEntityNpcVisibilityRule(
        mode: MapEntityNpcVisibilityMode.hiddenWhen,
        predicate: MapEntityRuntimePredicate(
          kind: MapEntityRuntimePredicateKind.storyFlagSet,
          refId: _testPickupFact,
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

MapData _runtimePickupMap() {
  return const MapData(
    id: _testMapId,
    name: 'Test Pickup Map',
    size: GridSize(width: 3, height: 3),
    layers: [MapLayer.object(id: 'objects', name: 'Objects')],
    entities: [
      MapEntity(
        id: 'test_spawn',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 0, y: 0),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.east,
        ),
      ),
      MapEntity(
        id: _testPickupEntityId,
        kind: MapEntityKind.item,
        pos: GridPos(x: 1, y: 0),
        item: MapEntityItemData(gameItemId: _testItemId, quantity: 2),
      ),
    ],
    mapMetadata: MapMetadata(defaultSpawnId: 'test_spawn'),
  );
}

Future<String> _writeRuntimeProject(
  Directory root, {
  required List<MapData> maps,
  required List<ScenarioAsset> scenarios,
}) async {
  final manifest = ProjectManifest(
    name: 'Test Item Pickup Project',
    settings: const ProjectSettings(tileWidth: 16, tileHeight: 16),
    maps: maps
        .map(
          (map) => ProjectMapEntry(
            id: map.id,
            name: map.name,
            relativePath: 'maps/${map.id}.json',
          ),
        )
        .toList(growable: false),
    tilesets: const [],
    scenarios: scenarios,
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
  final mapsDir = Directory(p.join(root.path, 'maps'));
  await mapsDir.create(recursive: true);
  for (final map in maps) {
    await File(p.join(mapsDir.path, '${map.id}.json')).writeAsString(
      const JsonEncoder.withIndent('  ').convert(map.toJson()),
    );
  }
  final projectFile = File(p.join(root.path, 'project.json'));
  await projectFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
  );
  return projectFile.path;
}

class _LoadedPlayableMapGame extends PlayableMapGame {
  _LoadedPlayableMapGame({
    required super.bundle,
    required super.projectFilePath,
  });

  @override
  bool get isLoaded => true;
}
