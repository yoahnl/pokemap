import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  test('contextual shop keeps pricing and purchase authority in the runtime',
      () async {
    var state = const GameState(
      saveId: 'shop-service',
      trainerProfile: TrainerProfile(name: 'Leaf', money: 100),
    );
    final locks = <bool>[];
    final commits = <GameState>[];
    final controller = PlayerServiceRuntimeController.contextual(
      currentGameState: () => state,
      commitAndSave: (next) async {
        state = next;
        commits.add(next);
      },
      setInputLocked: locks.add,
      loadRecoveryCaps: (_) async => const RuntimePlayerServiceRecoveryCaps(
        maxHpByPartyIndex: <int, int>{},
      ),
    );
    addTearDown(controller.dispose);

    final open = controller.openShop(
      const ShopDefinition(
        id: 'mart',
        label: 'Boutique du Port',
        entries: <ShopEntryDefinition>[
          ShopEntryDefinition(itemId: 'potion', price: 60, stock: 3),
        ],
      ),
      request: const OpenShopService(
        interactionId: 'npc.merchant',
        shopId: 'mart',
      ),
    );
    await Future<void>.delayed(Duration.zero);

    final initialSnapshot = controller.worldServiceSnapshot!;
    final initialContent =
        initialSnapshot.content! as RuntimeShopServiceContent;
    expect(initialContent.money, 100);
    expect(initialContent.entries.single.unitPrice, 60);
    expect(initialContent.entries.single.remainingStock, 3);
    expect(locks, <bool>[true]);

    final insufficient = await controller.dispatchWorldService(
      RuntimeWorldServiceCommand(
        action: RuntimeWorldServiceAction.confirm,
        snapshotRevision: initialSnapshot.revision,
        targetId: 'potion',
        quantity: 2,
      ),
    );
    expect(insufficient.status, RuntimeWorldServiceCommandStatus.unavailable);
    expect(controller.worldServiceSnapshot?.safeMessage, 'Fonds insuffisants.');
    expect(commits, isEmpty);

    final afterFailure = controller.worldServiceSnapshot!;
    final purchased = await controller.dispatchWorldService(
      RuntimeWorldServiceCommand(
        action: RuntimeWorldServiceAction.confirm,
        snapshotRevision: afterFailure.revision,
        targetId: 'potion',
        quantity: 1,
      ),
    );
    expect(purchased.status, RuntimeWorldServiceCommandStatus.accepted);
    expect(
      (controller.worldServiceSnapshot!.content! as RuntimeShopServiceContent)
          .money,
      40,
    );

    final beforeClose = controller.worldServiceSnapshot!;
    await controller.dispatchWorldService(
      RuntimeWorldServiceCommand(
        action: RuntimeWorldServiceAction.close,
        snapshotRevision: beforeClose.revision,
      ),
    );
    final result = await open;

    expect(result.status, PlayerServiceRuntimeStatus.completed);
    expect(commits, hasLength(1));
    expect(state.trainerProfile.money, 40);
    expect(state.bag.entries.single.itemId, 'potion');
    expect(state.bag.entries.single.quantity, 1);
    expect(locks, <bool>[true, false]);
    expect(controller.worldServiceSnapshot, isNull);
  });

  test('stale shop commands are refused without mutation', () async {
    const state = GameState(
      saveId: 'shop-stale',
      trainerProfile: TrainerProfile(name: 'Leaf', money: 500),
    );
    final controller = PlayerServiceRuntimeController.contextual(
      currentGameState: () => state,
      commitAndSave: (_) async {},
      setInputLocked: (_) {},
      loadRecoveryCaps: (_) async => const RuntimePlayerServiceRecoveryCaps(
        maxHpByPartyIndex: <int, int>{},
      ),
    );
    addTearDown(controller.dispose);

    unawaited(
      controller.openShop(
        const ShopDefinition(
          id: 'mart',
          label: 'Boutique',
          entries: <ShopEntryDefinition>[
            ShopEntryDefinition(itemId: 'potion', price: 60),
          ],
        ),
      ),
    );
    await Future<void>.delayed(Duration.zero);

    final result = await controller.dispatchWorldService(
      const RuntimeWorldServiceCommand(
        action: RuntimeWorldServiceAction.confirm,
        snapshotRevision: 99,
        targetId: 'potion',
        quantity: 1,
      ),
    );

    expect(result.status, RuntimeWorldServiceCommandStatus.stale);
    expect(controller.worldServiceSnapshot?.revision, 0);
  });

  test('contextual shop sells guided quantities and protects key items',
      () async {
    var state = const GameState(
      saveId: 'shop-sale',
      trainerProfile: TrainerProfile(name: 'Leaf', money: 100),
      bag: Bag(
        entries: <BagEntry>[
          BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 3),
          BagEntry(itemId: 'bike-pass', categoryId: 'key-items', quantity: 1),
          BagEntry(itemId: 'nugget', categoryId: 'items', quantity: 1),
        ],
      ),
    );
    final commits = <GameState>[];
    final controller = PlayerServiceRuntimeController.contextual(
      currentGameState: () => state,
      commitAndSave: (next) async {
        state = next;
        commits.add(next);
      },
      setInputLocked: (_) {},
      loadRecoveryCaps: (_) async => const RuntimePlayerServiceRecoveryCaps(
        maxHpByPartyIndex: <int, int>{},
      ),
    );
    addTearDown(controller.dispose);

    final open = controller.openShop(
      const ShopDefinition(
        id: 'mart',
        label: 'Boutique',
        entries: <ShopEntryDefinition>[
          ShopEntryDefinition(itemId: 'potion', price: 60, sellPrice: 30),
          ShopEntryDefinition(
            itemId: 'bike-pass',
            price: 1000,
            sellPrice: 500,
          ),
        ],
      ),
    );
    await Future<void>.delayed(Duration.zero);

    var snapshot = controller.worldServiceSnapshot!;
    await controller.dispatchWorldService(
      RuntimeWorldServiceCommand(
        action: RuntimeWorldServiceAction.showSales,
        snapshotRevision: snapshot.revision,
      ),
    );
    snapshot = controller.worldServiceSnapshot!;
    var content = snapshot.content! as RuntimeShopServiceContent;
    expect(content.mode, RuntimeShopMode.sell);
    expect(content.entries, hasLength(3));
    expect(
      content.entries.singleWhere((entry) => entry.itemId == 'potion'),
      isA<RuntimeShopEntrySnapshot>()
          .having((entry) => entry.unitPrice, 'unitPrice', 30)
          .having((entry) => entry.ownedQuantity, 'ownedQuantity', 3)
          .having((entry) => entry.canTransact, 'canTransact', isTrue),
    );
    expect(
      content.entries.singleWhere((entry) => entry.itemId == 'bike-pass'),
      isA<RuntimeShopEntrySnapshot>()
          .having((entry) => entry.canTransact, 'canTransact', isFalse)
          .having(
            (entry) => entry.unavailableReason,
            'unavailableReason',
            'Les objets importants sont invendables.',
          ),
    );

    await controller.dispatchWorldService(
      RuntimeWorldServiceCommand(
        action: RuntimeWorldServiceAction.select,
        snapshotRevision: snapshot.revision,
        targetId: 'potion',
      ),
    );
    snapshot = controller.worldServiceSnapshot!;
    final sold = await controller.dispatchWorldService(
      RuntimeWorldServiceCommand(
        action: RuntimeWorldServiceAction.confirm,
        snapshotRevision: snapshot.revision,
        targetId: 'potion',
        quantity: 2,
      ),
    );
    expect(sold.status, RuntimeWorldServiceCommandStatus.accepted);
    content =
        controller.worldServiceSnapshot!.content! as RuntimeShopServiceContent;
    expect(content.money, 160);
    expect(
      content.entries
          .singleWhere((entry) => entry.itemId == 'potion')
          .ownedQuantity,
      1,
    );

    snapshot = controller.worldServiceSnapshot!;
    await controller.dispatchWorldService(
      RuntimeWorldServiceCommand(
        action: RuntimeWorldServiceAction.close,
        snapshotRevision: snapshot.revision,
      ),
    );
    expect((await open).status, PlayerServiceRuntimeStatus.completed);
    expect(commits, hasLength(1));
    expect(state.trainerProfile.money, 160);
    expect(
      state.bag.entries
          .singleWhere((entry) => entry.itemId == 'potion')
          .quantity,
      1,
    );
  });
}
