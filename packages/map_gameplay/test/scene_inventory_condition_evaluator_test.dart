import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  SceneConditionSource condition({
    String? quantity = '3',
    SceneConditionOperator operator = SceneConditionOperator.isTrue,
  }) => SceneConditionSource(
    sourceKind: SceneConditionSourceKind.inventoryItem,
    sourceId: 'oran_berry',
    operator: operator,
    field: 'minimumQuantity',
    value: quantity,
  );

  GameState state(List<BagEntry> entries) => GameState(
    saveId: 'inventory-scene',
    bag: Bag(entries: entries),
  );

  test('a three-berry choice unlocks at the threshold and tracks the bag', () {
    for (final quantity in [0, 2, 3, 4]) {
      final before = state([BagEntry(itemId: 'oran_berry', quantity: quantity)]);
      expect(
        evaluateSceneInventoryCondition(source: condition(), gameState: before),
        quantity >= 3,
      );
      expect(before.bag.entries.single.quantity, quantity);
    }
  });

  test('quantity checks aggregate matching entries and ignore other items', () {
    final inventory = state(const [
      BagEntry(itemId: 'oran_berry', quantity: 1),
      BagEntry(itemId: 'potion', quantity: 20),
      BagEntry(itemId: 'oran_berry', quantity: 2),
    ]);
    expect(
      evaluateSceneInventoryCondition(source: condition(), gameState: inventory),
      isTrue,
    );
    expect(
      evaluateSceneInventoryCondition(
        source: condition(operator: SceneConditionOperator.isFalse),
        gameState: inventory,
      ),
      isFalse,
    );
  });

  test('an authored condition retains its threshold after serialization', () {
    final restored = SceneConditionSource.fromJson(condition().toJson());
    expect(restored.inventoryQuantityThreshold, 3);
    expect(
      evaluateSceneInventoryCondition(
        source: restored,
        gameState: state(const [BagEntry(itemId: 'oran_berry', quantity: 2)]),
      ),
      isFalse,
    );
    expect(condition(quantity: null).inventoryQuantityThreshold, 1);
  });

  test('invalid thresholds fail explicitly instead of granting a free choice', () {
    for (final quantity in ['0', '-1', '3.5', 'three', '03']) {
      expect(
        () => evaluateSceneInventoryCondition(
          source: condition(quantity: quantity),
          gameState: state(const []),
        ),
        throwsArgumentError,
      );
    }
    expect(condition(operator: SceneConditionOperator.equals).inventoryQuantityThreshold, isNull);
  });
}
