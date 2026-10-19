import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

const _capacity = ProjectBagCapacity(
  pockets: {'supplies': BagPocketCapacity(maxQuantityPerItem: 2)},
);
final _catalog = ItemCatalogSnapshot.fromCatalog(
  const ProjectItemCatalog(
    schemaVersion: 1,
    entries: [
      ProjectItemDefinition(
        id: 'supply',
        displayName: 'Supply',
        pocketId: 'supplies',
      ),
    ],
  ),
);

void main() {
  test('script gift refusal never commits or reports completion', () {
    const before = GameState(
      saveId: 'script-capacity',
      bag: Bag(entries: [BagEntry(itemId: 'supply', quantity: 2)]),
    );
    var commits = 0;
    final context = ScriptExecutionContext(
      gameState: before,
      onGameStateUpdated: (_) => commits++,
      bagCapacity: _capacity,
      itemCatalog: _catalog,
    );
    final result = ScriptCommandExecutor(context: context).execute(
      const ScriptCommand(
        type: ScriptCommandType.giveItem,
        params: {'itemId': 'supply', 'quantity': '1'},
      ),
      before,
    );
    expect(result, isA<ScriptCommandResultError>());
    expect((result as ScriptCommandResultError).message, contains('sac'));
    expect(commits, 0);
    expect(context.gameState, same(before));
  });

  test(
    'scenario gift stops before its receipt and retries after making space',
    () {
      var state = const GameState(
        saveId: 'scenario-capacity',
        bag: Bag(entries: [BagEntry(itemId: 'supply', quantity: 2)]),
      );
      final before = state;
      var commits = 0;
      ScenarioRuntimeExecutionResult play() {
        return const ScenarioRuntimeExecutor().dispatch(
          scenarios: [_scenario],
          sourceEvent: ScenarioRuntimeSourceEvent.entityInteract(
            mapId: 'map',
            entityId: 'gift',
          ),
          context: ScenarioRuntimeExecutionContext(
            gameState: state,
            onGameStateUpdated: (next) {
              commits++;
              state = next;
            },
            bagCapacity: _capacity,
            itemCatalog: _catalog,
            openDialogue: (_, {startNode, runtimeSourceId}) => false,
            runScript: (_, {startNode, runtimeSourceId}) => false,
            showMessage: (_) {},
          ),
        );
      }

      final rejected = play();
      expect(rejected.status, ScenarioRuntimeExecutionStatus.blocked);
      expect(rejected.message, contains('sac'));
      expect(commits, 0);
      expect(state, same(before));
      expect(state.storyFlags.activeFlags, isEmpty);
      final space = const BagOperations().take(
        BagTakeRequest(bag: state.bag, itemId: 'supply', quantity: 1),
      );
      state = state.copyWith(bag: space.bag);
      final received = play();
      expect(received.success, isTrue);
      expect(state.bag.entries.single.quantity, 2);
      expect(state.storyFlags.activeFlags, contains('received'));
    },
  );
}

const _scenario = ScenarioAsset(
  id: 'gift',
  name: 'Gift',
  entryNodeId: 'source',
  nodes: [
    ScenarioNode(
      id: 'source',
      type: ScenarioNodeType.reference,
      payload: ScenarioNodePayload(actionKind: kScenarioSourceEntityInteract),
      binding: ScenarioNodeBinding(mapId: 'map', entityId: 'gift'),
    ),
    ScenarioNode(
      id: 'grant',
      type: ScenarioNodeType.action,
      payload: ScenarioNodePayload(
        actionKind: kScenarioActionGiveItem,
        params: {'itemId': 'supply', 'quantity': '1'},
      ),
    ),
    ScenarioNode(
      id: 'receipt',
      type: ScenarioNodeType.action,
      payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
      binding: ScenarioNodeBinding(flagName: 'received'),
    ),
    ScenarioNode(id: 'end', type: ScenarioNodeType.end),
  ],
  edges: [
    ScenarioEdge(id: 'source-grant', fromNodeId: 'source', toNodeId: 'grant'),
    ScenarioEdge(id: 'grant-receipt', fromNodeId: 'grant', toNodeId: 'receipt'),
    ScenarioEdge(id: 'receipt-end', fromNodeId: 'receipt', toNodeId: 'end'),
  ],
);
