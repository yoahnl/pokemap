import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  const mutations = GameStateMutations();

  PlayerPokemon pokemon({
    String speciesId = 'p5_starter_species',
    int level = 7,
    int currentHp = 12,
    String statusId = '',
    List<String> knownMoveIds = const ['p5_tackle'],
  }) {
    return PlayerPokemon(
      speciesId: speciesId,
      level: level,
      natureId: 'hardy',
      abilityId: 'overgrow',
      knownMoveIds: knownMoveIds,
      currentHp: currentHp,
      statusId: statusId,
    );
  }

  GameState partyBagState({
    List<PlayerPokemon> members = const [],
    List<BagEntry> bagEntries = const [],
  }) {
    var state = GameState(
      saveId: 'p5_party_bag_heal_save',
      currentMapId: 'p5_party_bag_heal_map',
      playerPosition: const GridPos(x: 4, y: 9),
      playerFacing: EntityFacing.west,
      party: PlayerParty(members: members),
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
          BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 5),
          BagEntry(itemId: 'poke-ball', categoryId: 'items', quantity: 2),
        ],
      );

      final updated = mutations.consumeItem(state, ' potion ', 2);
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
          BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 2),
        ],
      );

      final updated = mutations.consumeItem(state, 'potion', 2);

      expect(updated.bag.entries, isEmpty);
    });

    test('preserves party, map, progression and metadata', () {
      final firstPokemon = pokemon(currentHp: 8, statusId: 'poison');
      final state = partyBagState(
        members: [firstPokemon],
        bagEntries: const [
          BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 3),
        ],
      );

      final updated = mutations.consumeItem(state, 'potion', 1);

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
          BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 1),
        ],
      );

      expect(mutations.consumeItem(state, 'ether', 1), same(state));
      expect(mutations.consumeItem(state, '   ', 1), same(state));
      expect(mutations.consumeItem(state, 'potion', 0), same(state));
      expect(mutations.consumeItem(state, 'potion', -1), same(state));
      expect(mutations.consumeItem(state, 'potion', 2), same(state));
    });
  });

  group('GameStateMutations.applyHpMedicineToPartyMember', () {
    test('heals a party member and consumes the medicine item', () {
      final state = partyBagState(
        members: [pokemon(currentHp: 6)],
        bagEntries: const [
          BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 2),
        ],
      );

      final updated = mutations.applyHpMedicineToPartyMember(
        state,
        partyIndex: 0,
        itemId: 'potion',
        healAmount: 8,
        maxHp: 20,
      );

      expect(updated.party.members.single.currentHp, 14);
      expect(updated.bag.entries.single.quantity, 1);
      expect(updated.party.members.single.statusId, isEmpty);
    });

    test('caps healing at explicit maxHp', () {
      final state = partyBagState(
        members: [pokemon(currentHp: 17)],
        bagEntries: const [
          BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 1),
        ],
      );

      final updated = mutations.applyHpMedicineToPartyMember(
        state,
        partyIndex: 0,
        itemId: 'potion',
        healAmount: 20,
        maxHp: 22,
      );

      expect(updated.party.members.single.currentHp, 22);
      expect(updated.bag.entries, isEmpty);
    });

    test('does not consume item on invalid index, missing item or no healing',
        () {
      final state = partyBagState(
        members: [pokemon(currentHp: 20)],
        bagEntries: const [
          BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 1),
        ],
      );

      expect(
        mutations.applyHpMedicineToPartyMember(
          state,
          partyIndex: 3,
          itemId: 'potion',
          healAmount: 5,
          maxHp: 25,
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
        ),
        same(state),
      );
    });
  });

  group('GameStateMutations.recoverParty', () {
    test('restores multiple party members with explicit max HP caps', () {
      final state = partyBagState(
        members: [
          pokemon(speciesId: 'p5_species_a', currentHp: 3),
          pokemon(speciesId: 'p5_species_b', currentHp: 0, statusId: 'sleep'),
        ],
        bagEntries: const [
          BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 1),
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
          BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 2),
        ],
      );

      final healed = mutations.applyHpMedicineToPartyMember(
        state,
        partyIndex: 0,
        itemId: 'potion',
        healAmount: 10,
        maxHp: 16,
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
            categoryId: 'medicine',
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
      );

      expect(updated.party.members.single.speciesId, 'p5_generic_species');
      expect(updated.bag.entries, isEmpty);
    });
  });
}
