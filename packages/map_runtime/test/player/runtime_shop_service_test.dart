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
}
