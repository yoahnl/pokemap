import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  const mutations = GameStateMutations();
  const shop = ShopDefinition(
    id: 'selbrume-mart',
    label: 'Boutique de Selbrume',
    entries: <ShopEntryDefinition>[
      ShopEntryDefinition(itemId: 'potion', price: 300, stock: 3),
      ShopEntryDefinition(itemId: 'poke-ball', price: 200),
    ],
  );

  GameState state({int money = 1000}) => GameState(
        saveId: 'shop-operations',
        trainerProfile: TrainerProfile(name: 'Karim', money: money),
      );

  group('GameStateMutations.purchaseFromShop', () {
    test('uses authored price and persists finite stock consumption', () {
      final first = mutations.purchaseFromShop(
        state(),
        shop: shop,
        itemId: ' potion ',
        categoryId: 'medicine',
        quantity: 2,
      );
      final reloaded = normalizeLoadedGameState(
        gameStateFromSaveData(saveDataFromGameState(first.state)),
      );
      final second = mutations.purchaseFromShop(
        reloaded,
        shop: shop,
        itemId: 'potion',
        categoryId: 'medicine',
        quantity: 1,
      );

      expect(first.isSuccess, isTrue);
      expect(first.totalCost, 600);
      expect(first.remainingStock, 1);
      expect(first.state.trainerProfile.money, 400);
      expect(first.state.bag.entries.single.quantity, 2);
      expect(second.isSuccess, isTrue);
      expect(second.remainingStock, 0);
      expect(second.state.progression.shopPurchaseCounts.values.single, 3);
    });

    test('rejects depleted stock without a partial debit or grant', () {
      final initial = state(money: 2000).copyWith(
        progression: const PlayerProgression(
          shopPurchaseCounts: <String, int>{'selbrume-mart::potion': 3},
        ),
      );

      final result = mutations.purchaseFromShop(
        initial,
        shop: shop,
        itemId: 'potion',
        categoryId: 'medicine',
        quantity: 1,
      );

      expect(result.failure, ShopPurchaseFailure.outOfStock);
      expect(result.remainingStock, 0);
      expect(result.state, same(initial));
    });

    test('rejects unknown item, invalid quantity and insufficient funds', () {
      final initial = state(money: 299);

      final unknown = mutations.purchaseFromShop(
        initial,
        shop: shop,
        itemId: 'revive',
        categoryId: 'medicine',
        quantity: 1,
      );
      final invalid = mutations.purchaseFromShop(
        initial,
        shop: shop,
        itemId: 'potion',
        categoryId: 'medicine',
        quantity: 0,
      );
      final poor = mutations.purchaseFromShop(
        initial,
        shop: shop,
        itemId: 'potion',
        categoryId: 'medicine',
        quantity: 1,
      );

      expect(unknown.failure, ShopPurchaseFailure.unknownItem);
      expect(invalid.failure, ShopPurchaseFailure.invalidRequest);
      expect(poor.failure, ShopPurchaseFailure.insufficientFunds);
      expect(unknown.state, same(initial));
      expect(invalid.state, same(initial));
      expect(poor.state, same(initial));
    });

    test('does not track stock for an unlimited entry', () {
      final result = mutations.purchaseFromShop(
        state(),
        shop: shop,
        itemId: 'poke-ball',
        categoryId: 'items',
        quantity: 2,
      );

      expect(result.isSuccess, isTrue);
      expect(result.remainingStock, isNull);
      expect(result.state.progression.shopPurchaseCounts, isEmpty);
    });
  });
}
