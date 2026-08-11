import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  const mutations = GameStateMutations();
  const evaluator = ScriptConditionEvaluator();
  final itemCatalog = ItemCatalogSnapshot.fromCatalog(
    const ProjectItemCatalog(
      schemaVersion: 1,
      entries: <ProjectItemDefinition>[
        ProjectItemDefinition(
          id: 'observatory-key',
          displayName: 'Observatory Key',
          pocketId: 'quest-tools',
          tags: <String>{'key-item', 'passive'},
        ),
      ],
    ),
  );

  GameState state({int quantity = 0}) => GameState(
        saveId: 'key-item-gate',
        bag: quantity == 0
            ? const Bag()
            : Bag(
                entries: <BagEntry>[
                  BagEntry(itemId: 'observatory-key', quantity: quantity),
                ],
              ),
      );

  test('bag capability reports presence, absence and exact quantity', () {
    expect(mutations.itemQuantity(state(), 'observatory-key'), 0);
    expect(mutations.itemQuantity(state(quantity: 2), 'observatory-key'), 2);
    expect(mutations.itemQuantity(state(quantity: 2), ' observatory-key '), 2);
  });

  test('script gate checks the bag without consuming the key item', () {
    final initial = state(quantity: 2);
    final oneRequired =
        ScriptConditionFactory.itemQuantityAtLeast('observatory-key', 1);
    final threeRequired =
        ScriptConditionFactory.itemQuantityAtLeast('observatory-key', 3);

    expect(evaluator.evaluate(oneRequired, initial), isTrue);
    expect(evaluator.evaluate(threeRequired, initial), isFalse);
    expect(initial.bag.entries.single.quantity, 2);
  });

  test('key item remains unsellable even with an authored sale price', () {
    final initial = state(quantity: 1);

    final result = mutations.sellItem(
      initial,
      itemId: 'observatory-key',
      quantity: 1,
      unitPrice: 500,
      itemCatalog: itemCatalog,
    );

    expect(result.failure, ShopSaleFailure.keyItem);
    expect(result.state, same(initial));
    expect(result.remainingQuantity, 1);
  });

  test('save roundtrip preserves the key item gate and its quantity', () {
    final initial = state(quantity: 2);
    final reloaded = normalizeLoadedGameState(
      gameStateFromSaveData(saveDataFromGameState(initial)),
    );
    final condition =
        ScriptConditionFactory.itemQuantityAtLeast('observatory-key', 2);

    expect(evaluator.evaluate(condition, reloaded), isTrue);
    expect(reloaded.bag.entries.single.quantity, 2);
  });
}
