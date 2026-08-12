import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  const mutations = GameStateMutations();
  final itemCatalog = ItemCatalogSnapshot.fromCatalog(
    const ProjectItemCatalog(
      schemaVersion: 1,
      entries: <ProjectItemDefinition>[
        ProjectItemDefinition(
          id: 'potion',
          displayName: 'Potion',
          pocketId: 'medicine',
        ),
        ProjectItemDefinition(
          id: 'lab-key',
          displayName: 'Lab Key',
          pocketId: 'key-items',
          tags: <String>{'key-item'},
        ),
        ProjectItemDefinition(
          id: 'p5_generic_medicine',
          displayName: 'Generic Medicine',
          pocketId: 'medicine',
        ),
      ],
    ),
  );

  PlayerPokemon pokemon({
    String speciesId = 'p5_starter_species',
    int level = 7,
    int currentHp = 12,
    String statusId = '',
    List<String> knownMoveIds = const ['p5_tackle'],
    Map<String, int>? currentPpByMoveId,
  }) {
    return PlayerPokemon(
      speciesId: speciesId,
      level: level,
      natureId: 'hardy',
      abilityId: 'overgrow',
      knownMoveIds: knownMoveIds,
      currentPpByMoveId: currentPpByMoveId,
      currentHp: currentHp,
      statusId: statusId,
    );
  }

  GameState partyBagState({
    List<PlayerPokemon> members = const [],
    List<BagEntry> bagEntries = const [],
    int money = 0,
  }) {
    var state = GameState(
      saveId: 'p5_party_bag_heal_save',
      currentMapId: 'p5_party_bag_heal_map',
      playerPosition: const GridPos(x: 4, y: 9),
      playerFacing: EntityFacing.west,
      party: PlayerParty(members: members),
      trainerProfile: TrainerProfile(name: 'P5 Tester', money: money),
      bag: Bag(entries: bagEntries),
      metadata: const {'lot': 'p5_04'},
    );
    state = mutations.setFlag(state, 'p5.flag.ready');
    state = mutations.markEventConsumed(state, 'p5.event.consumed');
    return state;
  }

  group('GameStateMutations.consumeItem', () {
    test('decrements an item quantity', () {
      final state = partyBagState(
        members: [pokemon()],
        bagEntries: const [
          BagEntry(itemId: 'potion', quantity: 5),
          BagEntry(itemId: 'poke-ball', quantity: 2),
        ],
      );

      final updated = mutations.consumeItem(
        state,
        itemId: ' potion ',
        quantity: 2,
        itemCatalog: itemCatalog,
        reason: ItemConsumptionReason.scriptedUse,
      );
      final potion =
          updated.bag.entries.singleWhere((entry) => entry.itemId == 'potion');
      final pokeBall = updated.bag.entries
          .singleWhere((entry) => entry.itemId == 'poke-ball');

      expect(potion.quantity, 3);
      expect(pokeBall.quantity, 2);
    });

    test('removes an entry when quantity reaches zero', () {
      final state = partyBagState(
        bagEntries: const [
          BagEntry(itemId: 'potion', quantity: 2),
        ],
      );

      final updated = mutations.consumeItem(
        state,
        itemId: 'potion',
        quantity: 2,
        itemCatalog: itemCatalog,
        reason: ItemConsumptionReason.scriptedUse,
      );

      expect(updated.bag.entries, isEmpty);
    });

    test('preserves party, map, progression and metadata', () {
      final firstPokemon = pokemon(currentHp: 8, statusId: 'poison');
      final state = partyBagState(
        members: [firstPokemon],
        bagEntries: const [
          BagEntry(itemId: 'potion', quantity: 3),
        ],
      );

      final updated = mutations.consumeItem(
        state,
        itemId: 'potion',
        quantity: 1,
        itemCatalog: itemCatalog,
        reason: ItemConsumptionReason.scriptedUse,
      );

      expect(updated.currentMapId, state.currentMapId);
      expect(updated.playerPosition, state.playerPosition);
      expect(updated.playerFacing, state.playerFacing);
      expect(updated.party.members, state.party.members);
      expect(updated.storyFlags, state.storyFlags);
      expect(updated.consumedEventIds, state.consumedEventIds);
      expect(updated.metadata, state.metadata);
    });

    test('handles missing item, blank id and invalid quantity safely', () {
      final state = partyBagState(
        bagEntries: const [
          BagEntry(itemId: 'potion', quantity: 1),
        ],
      );

      GameState consume(String itemId, int quantity) => mutations.consumeItem(
            state,
            itemId: itemId,
            quantity: quantity,
            itemCatalog: itemCatalog,
            reason: ItemConsumptionReason.scriptedUse,
          );

      expect(consume('ether', 1), same(state));
      expect(consume('   ', 1), same(state));
      expect(consume('potion', 0), same(state));
      expect(consume('potion', -1), same(state));
      expect(consume('potion', 2), same(state));
    });

    test('protects key items unless consumption is explicitly authorized', () {
      final state = partyBagState(
        bagEntries: const <BagEntry>[
          BagEntry(itemId: 'lab-key', quantity: 1),
        ],
      );

      final protected = mutations.consumeItem(
        state,
        itemId: 'lab-key',
        quantity: 1,
        itemCatalog: itemCatalog,
        reason: ItemConsumptionReason.scriptedUse,
      );
      final authorized = mutations.consumeItem(
        state,
        itemId: 'lab-key',
        quantity: 1,
        itemCatalog: itemCatalog,
        reason: ItemConsumptionReason.scriptedUse,
        allowKeyItemConsumption: true,
      );

      expect(protected, same(state));
      expect(authorized.bag.entries, isEmpty);
    });

    test('narrative removal is distinct and intentionally removes key items',
        () {
      final state = partyBagState(
        bagEntries: const <BagEntry>[
          BagEntry(itemId: 'lab-key', quantity: 1),
        ],
      );

      final removed = mutations.removeItemForNarrativeConsequence(
        state,
        itemId: 'lab-key',
        quantity: 1,
      );

      expect(removed.bag.entries, isEmpty);
    });
  });

  group('GameStateMutations.applyHpMedicineToPartyMember', () {
    test('heals a party member and consumes the medicine item', () {
      final state = partyBagState(
        members: [pokemon(currentHp: 6)],
        bagEntries: const [
          BagEntry(itemId: 'potion', quantity: 2),
        ],
      );

      final updated = mutations.applyHpMedicineToPartyMember(
        state,
        partyIndex: 0,
        itemId: 'potion',
        healAmount: 8,
        maxHp: 20,
        itemCatalog: itemCatalog,
      );

      expect(updated.party.members.single.currentHp, 14);
      expect(updated.bag.entries.single.quantity, 1);
      expect(updated.party.members.single.statusId, isEmpty);
    });

    test('caps healing at explicit maxHp', () {
      final state = partyBagState(
        members: [pokemon(currentHp: 17)],
        bagEntries: const [
          BagEntry(itemId: 'potion', quantity: 1),
        ],
      );

      final updated = mutations.applyHpMedicineToPartyMember(
        state,
        partyIndex: 0,
        itemId: 'potion',
        healAmount: 20,
        maxHp: 22,
        itemCatalog: itemCatalog,
      );

      expect(updated.party.members.single.currentHp, 22);
      expect(updated.bag.entries, isEmpty);
    });

    test('does not consume item on invalid index, missing item or no healing',
        () {
      final state = partyBagState(
        members: [pokemon(currentHp: 20)],
        bagEntries: const [
          BagEntry(itemId: 'potion', quantity: 1),
        ],
      );

      expect(
        mutations.applyHpMedicineToPartyMember(
          state,
          partyIndex: 3,
          itemId: 'potion',
          healAmount: 5,
          maxHp: 25,
          itemCatalog: itemCatalog,
        ),
        same(state),
      );
      expect(
        mutations.applyHpMedicineToPartyMember(
          state,
          partyIndex: 0,
          itemId: 'ether',
          healAmount: 5,
          maxHp: 25,
          itemCatalog: itemCatalog,
        ),
        same(state),
      );
      expect(
        mutations.applyHpMedicineToPartyMember(
          state,
          partyIndex: 0,
          itemId: 'potion',
          healAmount: 5,
          maxHp: 20,
          itemCatalog: itemCatalog,
        ),
        same(state),
      );
    });
  });

  group('GameStateMutations.recoverParty', () {
    test('restores HP, status and persisted PP together', () {
      final state = partyBagState(
        members: [
          pokemon(
            currentHp: 0,
            statusId: 'poison',
            knownMoveIds: const ['p5_tackle', 'p5_growl'],
            currentPpByMoveId: const {'p5_tackle': 1, 'p5_growl': 0},
          ),
        ],
      );

      final updated = mutations.recoverParty(
        state,
        maxHpByPartyIndex: const {0: 24},
        maxPpByPartyIndex: const {
          0: {'p5_tackle': 35, 'p5_growl': 40},
        },
      );

      expect(updated.party.members.single.currentHp, 24);
      expect(updated.party.members.single.statusId, isEmpty);
      expect(
        updated.party.members.single.currentPpByMoveId,
        const {'p5_tackle': 35, 'p5_growl': 40},
      );
    });

    test('restores multiple party members with explicit max HP caps', () {
      final state = partyBagState(
        members: [
          pokemon(speciesId: 'p5_species_a', currentHp: 3),
          pokemon(speciesId: 'p5_species_b', currentHp: 0, statusId: 'sleep'),
        ],
        bagEntries: const [
          BagEntry(itemId: 'potion', quantity: 1),
        ],
      );

      final updated = mutations.recoverParty(
        state,
        maxHpByPartyIndex: const {0: 18, 1: 21},
      );

      expect(updated.party.members[0].currentHp, 18);
      expect(updated.party.members[1].currentHp, 21);
      expect(updated.party.members[0].statusId, isEmpty);
      expect(updated.party.members[1].statusId, isEmpty);
      expect(updated.bag, state.bag);
      expect(updated.currentMapId, state.currentMapId);
      expect(updated.storyFlags, state.storyFlags);
      expect(updated.consumedEventIds, state.consumedEventIds);
    });

    test('skips party members without a valid explicit cap', () {
      final state = partyBagState(
        members: [
          pokemon(speciesId: 'p5_species_a', currentHp: 5),
          pokemon(speciesId: 'p5_species_b', currentHp: 6, statusId: 'burn'),
        ],
      );

      final updated = mutations.recoverParty(
        state,
        maxHpByPartyIndex: const {0: 12, 1: 0},
      );

      expect(updated.party.members[0].currentHp, 12);
      expect(updated.party.members[0].statusId, isEmpty);
      expect(updated.party.members[1].currentHp, 6);
      expect(updated.party.members[1].statusId, 'burn');
    });

    test('round-trips healed party and updated bag through SaveData', () {
      final state = partyBagState(
        members: [pokemon(currentHp: 4, statusId: 'poison')],
        bagEntries: const [
          BagEntry(itemId: 'potion', quantity: 2),
        ],
      );

      final healed = mutations.applyHpMedicineToPartyMember(
        state,
        partyIndex: 0,
        itemId: 'potion',
        healAmount: 10,
        maxHp: 16,
        itemCatalog: itemCatalog,
      );
      final recovered = mutations.recoverParty(
        healed,
        maxHpByPartyIndex: const {0: 20},
      );
      final saveData = saveDataFromGameState(recovered);
      final reloaded =
          normalizeLoadedGameState(gameStateFromSaveData(saveData));

      expect(reloaded.party.members.single.currentHp, 20);
      expect(reloaded.party.members.single.statusId, isEmpty);
      expect(reloaded.bag.entries.single.itemId, 'potion');
      expect(reloaded.bag.entries.single.quantity, 1);
      expect(reloaded.currentMapId, state.currentMapId);
      expect(reloaded.metadata, state.metadata);
    });

    test('does not hardcode any Selbrume ids', () {
      final state = partyBagState(
        members: [pokemon(speciesId: 'p5_generic_species', currentHp: 1)],
        bagEntries: const [
          BagEntry(
            itemId: 'p5_generic_medicine',
            quantity: 1,
          ),
        ],
      );

      final updated = mutations.applyHpMedicineToPartyMember(
        state,
        partyIndex: 0,
        itemId: 'p5_generic_medicine',
        healAmount: 2,
        maxHp: 5,
        itemCatalog: itemCatalog,
      );

      expect(updated.party.members.single.speciesId, 'p5_generic_species');
      expect(updated.bag.entries, isEmpty);
    });
  });

  group('GameStateMutations.purchaseItem', () {
    test('atomically pays for and grants the requested item quantity', () {
      final state = partyBagState(
        money: 1000,
        bagEntries: const [
          BagEntry(itemId: 'potion', quantity: 1),
        ],
      );

      final result = mutations.purchaseItem(
        state,
        itemId: ' potion ',
        quantity: 2,
        unitPrice: 300,
        itemCatalog: itemCatalog,
      );

      expect(result.isSuccess, isTrue);
      expect(result.failure, isNull);
      expect(result.totalCost, 600);
      expect(result.state.trainerProfile.money, 400);
      expect(result.state.bag.entries.single.quantity, 3);
      expect(result.state.storyFlags, state.storyFlags);
      expect(result.state.currentMapId, state.currentMapId);
    });

    test('fails without mutating state when money is insufficient', () {
      final state = partyBagState(money: 299);

      final result = mutations.purchaseItem(
        state,
        itemId: 'potion',
        quantity: 1,
        unitPrice: 300,
        itemCatalog: itemCatalog,
      );

      expect(result.isSuccess, isFalse);
      expect(result.failure, ShopPurchaseFailure.insufficientFunds);
      expect(result.state, same(state));
      expect(result.totalCost, 300);
    });

    test('rejects blank ids and non-positive quantity or price', () {
      final state = partyBagState(money: 1000);

      for (final result in <ShopPurchaseResult>[
        mutations.purchaseItem(
          state,
          itemId: ' ',
          quantity: 1,
          unitPrice: 100,
          itemCatalog: itemCatalog,
        ),
        mutations.purchaseItem(
          state,
          itemId: 'potion',
          quantity: 0,
          unitPrice: 100,
          itemCatalog: itemCatalog,
        ),
        mutations.purchaseItem(
          state,
          itemId: 'potion',
          quantity: 1,
          unitPrice: 0,
          itemCatalog: itemCatalog,
        ),
      ]) {
        expect(result.failure, ShopPurchaseFailure.invalidRequest);
        expect(result.state, same(state));
      }
    });
  });
}
