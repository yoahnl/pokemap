import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  const mutations = GameStateMutations();
  final catalog = ItemCatalogSnapshot.fromCatalog(
      const ProjectItemCatalog(schemaVersion: 1, entries: [
    ProjectItemDefinition(
        id: 'ball', displayName: 'Ball', pocketId: 'balls', sellPrice: 100),
    ProjectItemDefinition(
        id: 'bonus', displayName: 'Bonus', pocketId: 'balls', sellPrice: 10),
    ProjectItemDefinition(
        id: 'medicine',
        displayName: 'Medicine',
        pocketId: 'medicine',
        sellPrice: 250),
    ProjectItemDefinition(
        id: 'key',
        displayName: 'Key',
        pocketId: 'key-items',
        tags: {'key-item'},
        sellPrice: 1000)
  ]));
  const shop = ShopDefinition(
      id: 'mart',
      label: 'Mart',
      sellPolicy: ShopSellPolicy.catalogPrices,
      entries: [
        ShopEntryDefinition(
            itemId: 'ball',
            price: 200,
            maximumOwnedQuantity: 999,
            purchaseBonus: ShopPurchaseBonus(
                itemId: 'bonus',
                everyQuantity: 10,
                quantity: 1,
                maximumOwnedQuantity: 999))
      ]);
  GameState state({List<BagEntry> bag = const []}) => GameState(
      saveId: 'shop-policy',
      trainerProfile: const TrainerProfile(name: 'Player', money: 1000000),
      bag: Bag(entries: bag));
  ShopPurchaseResult buy(GameState state, int quantity,
          {ShopDefinition definition = shop}) =>
      mutations.purchaseFromResolvedShop(state,
          shop: definition,
          expectedStateId: ShopStateResolver.defaultStateId,
          itemId: 'ball',
          quantity: quantity,
          itemCatalog: catalog);
  int count(GameState state, String item) =>
      const BagOperations().quantityOf(state.bag, item);

  for (final row in [(9, 0), (10, 1), (25, 2)]) {
    test('purchase ${row.$1} applies floor bonus ${row.$2}', () {
      final result = buy(state(), row.$1);
      expect(result.isSuccess, isTrue);
      expect(count(result.state, 'ball'), row.$1);
      expect(count(result.state, 'bonus'), row.$2);
      expect(result.bonusQuantity, row.$2);
      expect(result.state.trainerProfile.money, 1000000 - row.$1 * 200);
    });
  }
  test('principal ownership cap rejects atomically before charging', () {
    final before = state(bag: const [BagEntry(itemId: 'ball', quantity: 995)]);
    final result = buy(before, 10);
    expect(result.failure, ShopPurchaseFailure.ownershipLimit);
    expect(identical(result.state, before), isTrue);
  });
  test('full bonus stack does not roll back a valid purchase', () {
    final result =
        buy(state(bag: const [BagEntry(itemId: 'bonus', quantity: 999)]), 25);
    expect(result.isSuccess, isTrue);
    expect(count(result.state, 'ball'), 25);
    expect(count(result.state, 'bonus'), 999);
    expect(result.bonusQuantity, 0);
    expect(result.state.trainerProfile.money, 995000);
  });
  test('bonus fills remaining capacity without unbounded iteration', () {
    final result =
        buy(state(bag: const [BagEntry(itemId: 'bonus', quantity: 998)]), 25);
    expect(result.isSuccess, isTrue);
    expect(result.bonusQuantity, 1);
    expect(count(result.state, 'bonus'), 999);
  });
  test(
      'ownership cap one permits reacquisition after removal without permanent stock',
      () {
    final limited = shop.copyWith(entries: const [
      ShopEntryDefinition(itemId: 'ball', price: 200, maximumOwnedQuantity: 1)
    ]);
    final bought = buy(state(), 1, definition: limited);
    expect(buy(bought.state, 1, definition: limited).failure,
        ShopPurchaseFailure.ownershipLimit);
    final removed = mutations.removeItemForNarrativeConsequence(bought.state,
        itemId: 'ball', quantity: 1);
    expect(buy(removed, 1, definition: limited).isSuccess, isTrue);
    expect(bought.state.progression.shopPurchaseCounts, isEmpty);
  });
  test('invalid unknown bonus rejects purchase before charging', () {
    final invalid = shop.copyWith(entries: const [
      ShopEntryDefinition(
          itemId: 'ball',
          price: 200,
          purchaseBonus: ShopPurchaseBonus(
              itemId: 'missing', everyQuantity: 10, quantity: 1))
    ]);
    final before = state();
    final result = buy(before, 10, definition: invalid);
    expect(result.isSuccess, isFalse);
    expect(identical(result.state, before), isTrue);
  });
  test('catalog sale policy buys unlisted owned items at canonical prices', () {
    final result = mutations.sellToResolvedShop(
        state(bag: const [BagEntry(itemId: 'medicine', quantity: 2)]),
        shop: shop,
        expectedStateId: ShopStateResolver.defaultStateId,
        itemId: 'medicine',
        quantity: 2,
        itemCatalog: catalog);
    expect(result.isSuccess, isTrue);
    expect(result.totalRevenue, 500);
    expect(count(result.state, 'medicine'), 0);
  });
  test('listed sale policy keeps unlisted items unavailable', () {
    final result = mutations.sellToResolvedShop(
        state(bag: const [BagEntry(itemId: 'medicine', quantity: 2)]),
        shop: shop.copyWith(sellPolicy: ShopSellPolicy.listedEntries),
        expectedStateId: ShopStateResolver.defaultStateId,
        itemId: 'medicine',
        quantity: 1,
        itemCatalog: catalog);
    expect(result.failure, ShopSaleFailure.unknownItem);
  });
  test('catalog sale policy preserves protected key items', () {
    final result = mutations.sellToResolvedShop(
        state(bag: const [BagEntry(itemId: 'key', quantity: 1)]),
        shop: shop,
        expectedStateId: ShopStateResolver.defaultStateId,
        itemId: 'key',
        quantity: 1,
        itemCatalog: catalog);
    expect(result.failure, ShopSaleFailure.keyItem);
  });
}
