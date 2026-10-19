import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

const _capacity = ProjectBagCapacity(
  pockets: {
    'items': BagPocketCapacity(maxDistinctItems: 1, maxQuantityPerItem: 2),
  },
);

final _catalog = ItemCatalogSnapshot.fromCatalog(
  const ProjectItemCatalog(
    schemaVersion: 1,
    entries: [
      ProjectItemDefinition(
        id: 'guard',
        displayName: 'Guard',
        pocketId: 'items',
        heldEffectId: 'prevent_evolution',
      ),
      ProjectItemDefinition(
        id: 'spare',
        displayName: 'Spare',
        pocketId: 'items',
        heldEffectId: 'prevent_evolution',
      ),
    ],
  ),
);

void main() {
  test(
    'shop refuses a full pocket without money, stock or save changes',
    () async {
      var state = const GameState(
        saveId: 'capacity-shop',
        trainerProfile: TrainerProfile(name: 'Player', money: 100),
        bag: Bag(entries: [BagEntry(itemId: 'guard', quantity: 1)]),
      );
      final before = state;
      var saves = 0;
      final controller = PlayerServiceRuntimeController.contextual(
        currentGameState: () => state,
        commitAndSave: (next) async {
          saves++;
          state = next;
        },
        setInputLocked: (_) {},
        loadRecoveryCaps: (_) async =>
            const RuntimePlayerServiceRecoveryCaps(maxHpByPartyIndex: {}),
        itemCatalog: _catalog,
        bagCapacity: _capacity,
      );
      addTearDown(controller.dispose);
      final open = controller.openShop(
        const ShopDefinition(
          id: 'shop',
          label: 'Shop',
          entries: [ShopEntryDefinition(itemId: 'spare', price: 10, stock: 3)],
        ),
        request: const OpenShopService(
          interactionId: 'merchant',
          shopId: 'shop',
        ),
      );
      await Future<void>.delayed(Duration.zero);
      final rejected = await controller.dispatchWorldService(
        RuntimeWorldServiceCommand(
          action: RuntimeWorldServiceAction.confirm,
          snapshotRevision: controller.worldServiceSnapshot!.revision,
          targetId: 'spare',
          quantity: 1,
        ),
      );
      expect(rejected.status, RuntimeWorldServiceCommandStatus.unavailable);
      expect(rejected.safeMessage, contains('sac'));
      expect(state, same(before));
      expect(saves, 0);
      expect(
        (controller.worldServiceSnapshot!.content! as RuntimeShopServiceContent)
            .entries
            .single
            .remainingStock,
        3,
      );
      controller.dispose();
      await open;
      expect(saves, 0);
    },
  );

  for (final quantity in [1, 2]) {
    test(
      'held swap checks final pocket with incoming quantity $quantity',
      () async {
        var state = _heldState(quantity: quantity);
        final before = state;
        var saves = 0;
        final controller = PlayerServiceRuntimeController.contextual(
          currentGameState: () => state,
          commitAndSave: (next) async {
            saves++;
            state = next;
          },
          setInputLocked: (_) {},
          loadRecoveryCaps: (_) async =>
              const RuntimePlayerServiceRecoveryCaps(maxHpByPartyIndex: {}),
          itemCatalog: _catalog,
          bagCapacity: _capacity,
        );
        addTearDown(controller.dispose);
        final result = await controller.useBagItemOutsideBattle(
          const RuntimePlayerPauseCommand.equipHeldItem(
            itemTargetId: 'spare',
            partyTargetId: 'party.0',
          ),
        );
        if (quantity == 1) {
          expect(result.status, RuntimePlayerPauseCommandStatus.accepted);
          expect(saves, 1);
          expect(state.party.members.single.heldItemId, 'spare');
          expect(state.bag.entries.single.itemId, 'guard');
          expect(state.bag.entries.single.quantity, 1);
        } else {
          expect(result.status, RuntimePlayerPauseCommandStatus.unavailable);
          expect(result.safeMessage, contains('sac'));
          expect(saves, 0);
          expect(state, same(before));
        }
      },
    );
  }

  test(
    'held item stays equipped if a full pocket refuses its return',
    () async {
      var state = _heldState(quantity: 1);
      final before = state;
      var saves = 0;
      final controller = PlayerServiceRuntimeController.contextual(
        currentGameState: () => state,
        commitAndSave: (next) async {
          saves++;
          state = next;
        },
        setInputLocked: (_) {},
        loadRecoveryCaps: (_) async =>
            const RuntimePlayerServiceRecoveryCaps(maxHpByPartyIndex: {}),
        itemCatalog: _catalog,
        bagCapacity: _capacity,
      );
      addTearDown(controller.dispose);
      final result = await controller.useBagItemOutsideBattle(
        const RuntimePlayerPauseCommand.unequipHeldItem(
          partyTargetId: 'party.0',
        ),
      );
      expect(result.status, RuntimePlayerPauseCommandStatus.unavailable);
      expect(result.safeMessage, contains('sac'));
      expect(saves, 0);
      expect(state, same(before));
      expect(state.party.members.single.heldItemId, 'guard');
    },
  );
}

GameState _heldState({required int quantity}) => GameState(
  saveId: 'capacity-held',
  bag: Bag(
    entries: [BagEntry(itemId: 'spare', quantity: quantity)],
  ),
  party: const PlayerParty(
    members: [
      PlayerPokemon(
        speciesId: 'partner',
        natureId: 'hardy',
        abilityId: 'steady',
        currentHp: 10,
        heldItemId: 'guard',
      ),
    ],
  ),
);
