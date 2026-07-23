import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import 'support/selbrume_player_service_test_host.dart';

void main() {
  test('physical shop host buys from the resolved conditional profile',
      () async {
    const initial = GameState(
      saveId: 'selbrume-player-services',
      trainerProfile: TrainerProfile(name: 'Leaf', money: 1000),
      storyFlags: StoryFlags(activeFlags: <String>{'lysa_defeated'}),
    );
    final shop = ShopDefinition(
      id: 'shop_port_supplies',
      label: 'Comptoir des Brisants',
      entries: const <ShopEntryDefinition>[
        ShopEntryDefinition(itemId: 'potion', price: 300, stock: 3),
      ],
      states: <ShopStateDefinition>[
        ShopStateDefinition(
          id: 'after-lysa',
          label: 'Après Lysa',
          priority: 10,
          activation: ScriptConditionFactory.flagIsSet('lysa_defeated'),
          entries: const <ShopEntryDefinition>[
            ShopEntryDefinition(itemId: 'potion', price: 250, stock: 2),
          ],
        ),
      ],
    );
    final host = SelbrumePlayerServiceTestHost()..queueShopPurchase('potion');
    GameState? committed;
    final controller = PlayerServiceRuntimeController(
      currentGameState: () => initial,
      host: host,
      commitAndSave: (state) async => committed = state,
      setInputLocked: (_) {},
      loadRecoveryCaps: (_) async => const RuntimePlayerServiceRecoveryCaps(
        maxHpByPartyIndex: <int, int>{},
      ),
    );

    final result = await controller.openShop(shop);

    expect(result.status, PlayerServiceRuntimeStatus.completed);
    expect(committed?.trainerProfile.money, 750);
    expect(committed?.bag.entries.single.itemId, 'potion');
    expect(
      committed?.progression.shopPurchaseCounts,
      <String, int>{'shop_port_supplies::after-lysa::potion': 1},
    );
    expect(host.openedServices, <String>['shop:shop_port_supplies']);
    expect(host.purchasedItemIds, <String>['potion']);
  });
}
