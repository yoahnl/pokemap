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

  ShopDefinition dynamicShop() => ShopDefinition(
        id: 'selbrume-mart',
        label: 'Boutique de Selbrume',
        entries: const <ShopEntryDefinition>[
          ShopEntryDefinition(itemId: 'potion', price: 300, stock: 3),
          ShopEntryDefinition(itemId: 'poke-ball', price: 200),
        ],
        states: <ShopStateDefinition>[
          ShopStateDefinition(
            id: 'after-lysa',
            label: 'Après Lysa',
            priority: 10,
            activation: ScriptConditionFactory.flagIsSet('lysa_defeated'),
            entries: const <ShopEntryDefinition>[
              ShopEntryDefinition(itemId: 'potion', price: 250, stock: 2),
              ShopEntryDefinition(itemId: 'antidote', price: 100),
            ],
          ),
          ShopStateDefinition(
            id: 'story-finished',
            label: 'Histoire terminée',
            priority: 30,
            activation: ScriptConditionFactory.flagIsSet('story_finished'),
            entries: const <ShopEntryDefinition>[
              ShopEntryDefinition(itemId: 'potion', price: 200, stock: 1),
            ],
          ),
          ShopStateDefinition(
            id: 'lighthouse-alert',
            label: 'Alerte au phare',
            priority: 40,
            activation: ScriptConditionFactory.flagIsSet('lighthouse_danger'),
            isOpen: false,
            closedMessage: 'Le comptoir est fermé pendant l’alerte.',
          ),
        ],
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

  group('GameStateMutations.purchaseFromResolvedShop', () {
    test('rejects an item outside the resolved state', () {
      final initial = mutations.setFlag(state(), 'lysa_defeated');

      final result = mutations.purchaseFromResolvedShop(
        initial,
        shop: dynamicShop(),
        expectedStateId: 'after-lysa',
        itemId: 'poke-ball',
        categoryId: 'items',
        quantity: 1,
      );

      expect(result.failure, ShopPurchaseFailure.unknownItem);
      expect(result.state, same(initial));
    });

    test('rejects a closed state', () {
      final initial = mutations.setFlag(state(), 'lighthouse_danger');

      final result = mutations.purchaseFromResolvedShop(
        initial,
        shop: dynamicShop(),
        expectedStateId: 'lighthouse-alert',
        itemId: 'potion',
        categoryId: 'medicine',
        quantity: 1,
      );

      expect(result.failure, ShopPurchaseFailure.shopClosed);
      expect(result.state, same(initial));
    });

    test('rejects a state changed since rendering', () {
      final initial = mutations.setFlag(state(), 'lysa_defeated');

      final result = mutations.purchaseFromResolvedShop(
        initial,
        shop: dynamicShop(),
        expectedStateId: ShopStateResolver.defaultStateId,
        itemId: 'potion',
        categoryId: 'medicine',
        quantity: 1,
      );

      expect(result.failure, ShopPurchaseFailure.shopStateChanged);
      expect(result.state, same(initial));
    });

    test('uses a state-scoped stock key for a conditional state', () {
      final initial = mutations.setFlag(state(), 'lysa_defeated');

      final result = mutations.purchaseFromResolvedShop(
        initial,
        shop: dynamicShop(),
        expectedStateId: 'after-lysa',
        itemId: 'potion',
        categoryId: 'medicine',
        quantity: 1,
      );

      expect(result.isSuccess, isTrue);
      expect(result.totalCost, 250);
      expect(result.remainingStock, 1);
      expect(
        result.state.progression.shopPurchaseCounts,
        <String, int>{'selbrume-mart::after-lysa::potion': 1},
      );
    });

    test('keeps the legacy stock key for the default state', () {
      final result = mutations.purchaseFromResolvedShop(
        state(),
        shop: dynamicShop(),
        expectedStateId: ShopStateResolver.defaultStateId,
        itemId: 'potion',
        categoryId: 'medicine',
        quantity: 1,
      );

      expect(result.isSuccess, isTrue);
      expect(
        result.state.progression.shopPurchaseCounts,
        <String, int>{'selbrume-mart::potion': 1},
      );
    });

    test('preserves consumed stock when returning to a prior state', () {
      final afterLysa = mutations.setFlag(state(money: 2000), 'lysa_defeated');
      final first = mutations.purchaseFromResolvedShop(
        afterLysa,
        shop: dynamicShop(),
        expectedStateId: 'after-lysa',
        itemId: 'potion',
        categoryId: 'medicine',
        quantity: 1,
      );
      final ending = mutations.setFlag(first.state, 'story_finished');
      final atEnding = mutations.purchaseFromResolvedShop(
        ending,
        shop: dynamicShop(),
        expectedStateId: 'story-finished',
        itemId: 'potion',
        categoryId: 'medicine',
        quantity: 1,
      );
      final returned = mutations.clearFlag(
        atEnding.state,
        'story_finished',
      );
      final second = mutations.purchaseFromResolvedShop(
        returned,
        shop: dynamicShop(),
        expectedStateId: 'after-lysa',
        itemId: 'potion',
        categoryId: 'medicine',
        quantity: 1,
      );

      expect(first.isSuccess, isTrue);
      expect(atEnding.isSuccess, isTrue);
      expect(second.isSuccess, isTrue);
      expect(second.remainingStock, 0);
      expect(
        second.state.progression.shopPurchaseCounts,
        <String, int>{
          'selbrume-mart::after-lysa::potion': 2,
          'selbrume-mart::story-finished::potion': 1,
        },
      );
    });
  });
}
