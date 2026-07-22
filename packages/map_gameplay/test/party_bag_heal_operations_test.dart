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

  group('PlayerItemOperations', () {
    const operations = PlayerItemOperations();

    test('registry exposes heal, cure, revive, PP and inert metadata', () {
      const registry = PlayerItemEffectRegistry.mvp();

      expect(registry.effectFor('potion')?.kind, PlayerItemEffectKind.healHp);
      expect(
        registry.effectFor('antidote')?.kind,
        PlayerItemEffectKind.cureStatus,
      );
      expect(registry.effectFor('revive')?.kind, PlayerItemEffectKind.revive);
      expect(registry.effectFor('ether')?.kind, PlayerItemEffectKind.restorePp);
      expect(
        registry.effectFor('poke-ball')?.kind,
        PlayerItemEffectKind.ballMetadata,
      );
      expect(
          registry.effectFor('key-item')?.kind, PlayerItemEffectKind.keyItem);
    });

    test('heals a valid target and consumes exactly one Potion', () {
      final state = partyBagState(
        members: [pokemon(currentHp: 5)],
        bagEntries: const [
          BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 2),
        ],
      );

      final result = operations.useOnPartyMember(
        state,
        itemId: 'potion',
        partyIndex: 0,
        maxHp: 30,
      );

      expect(result.isSuccess, isTrue);
      expect(result.state.party.members.single.currentHp, 25);
      expect(result.state.bag.entries.single.quantity, 1);
    });

    test('does not consume Potion on a full-HP or fainted target', () {
      final full = partyBagState(
        members: [pokemon(currentHp: 20)],
        bagEntries: const [
          BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 1),
        ],
      );
      final fainted = full.copyWith(
        party: PlayerParty(members: [pokemon(currentHp: 0)]),
      );

      final fullResult = operations.useOnPartyMember(
        full,
        itemId: 'potion',
        partyIndex: 0,
        maxHp: 20,
      );
      final faintedResult = operations.useOnPartyMember(
        fainted,
        itemId: 'potion',
        partyIndex: 0,
        maxHp: 20,
      );

      expect(fullResult.failure, PlayerItemUseFailure.noEffect);
      expect(faintedResult.failure, PlayerItemUseFailure.wrongTarget);
      expect(fullResult.state, same(full));
      expect(faintedResult.state, same(fainted));
    });

    test('Antidote cures only poison and Revive targets only a KO', () {
      final poisoned = partyBagState(
        members: [pokemon(currentHp: 5, statusId: 'poison')],
        bagEntries: const [
          BagEntry(itemId: 'antidote', categoryId: 'medicine', quantity: 1),
          BagEntry(itemId: 'revive', categoryId: 'medicine', quantity: 1),
        ],
      );
      final cured = operations.useOnPartyMember(
        poisoned,
        itemId: 'antidote',
        partyIndex: 0,
        maxHp: 20,
      );
      final awake = poisoned.copyWith(
        party: PlayerParty(
          members: [pokemon(currentHp: 5, statusId: 'sleep')],
        ),
      );
      final wrongStatus = operations.useOnPartyMember(
        awake,
        itemId: 'antidote',
        partyIndex: 0,
        maxHp: 20,
      );
      final knockedOut = poisoned.copyWith(
        party: PlayerParty(members: [pokemon(currentHp: 0)]),
      );
      final revived = operations.useOnPartyMember(
        knockedOut,
        itemId: 'revive',
        partyIndex: 0,
        maxHp: 21,
      );

      expect(cured.state.party.members.single.statusId, isEmpty);
      expect(wrongStatus.failure, PlayerItemUseFailure.wrongTarget);
      expect(wrongStatus.state, same(awake));
      expect(revived.state.party.members.single.currentHp, 11);
    });

    test('status medicines cure their authored status and Full Heal cures any',
        () {
      const cases = <(String, String)>[
        ('antidote', 'badly-poisoned'),
        ('awakening', 'sleep'),
        ('paralyze-heal', 'paralysis'),
        ('burn-heal', 'burn'),
        ('ice-heal', 'freeze'),
        ('full-heal', 'confusion'),
      ];

      for (final (itemId, statusId) in cases) {
        final state = partyBagState(
          members: [pokemon(currentHp: 5, statusId: statusId)],
          bagEntries: [
            BagEntry(itemId: itemId, categoryId: 'medicine', quantity: 1),
          ],
        );

        final result = operations.useOnPartyMember(
          state,
          itemId: itemId,
          partyIndex: 0,
          maxHp: 20,
        );

        expect(result.isSuccess, isTrue,
            reason: '$itemId should cure $statusId');
        expect(result.state.party.members.single.statusId, isEmpty);
        expect(result.state.bag.entries, isEmpty);
      }
    });

    test('Ether restores one persisted move PP and rejects no-effect use', () {
      final state = partyBagState(
        members: [
          pokemon(
            knownMoveIds: const ['p5_tackle'],
            currentPpByMoveId: const {'p5_tackle': 2},
          ),
        ],
        bagEntries: const [
          BagEntry(itemId: 'ether', categoryId: 'medicine', quantity: 2),
        ],
      );

      final restored = operations.useOnPartyMember(
        state,
        itemId: 'ether',
        partyIndex: 0,
        maxHp: 20,
        moveId: 'p5_tackle',
        maxPpByMoveId: const {'p5_tackle': 35},
      );
      final noEffect = operations.useOnPartyMember(
        restored.state,
        itemId: 'ether',
        partyIndex: 0,
        maxHp: 20,
        moveId: 'p5_tackle',
        maxPpByMoveId: const {'p5_tackle': 12},
      );

      expect(
        restored.state.party.members.single.currentPpByMoveId,
        const {'p5_tackle': 12},
      );
      expect(restored.state.bag.entries.single.quantity, 1);
      expect(noEffect.failure, PlayerItemUseFailure.noEffect);
      expect(noEffect.state, same(restored.state));
    });

    test('returns typed failures for unknown item, bad target and no stock',
        () {
      final state = partyBagState(members: [pokemon()]);

      expect(
        operations
            .useOnPartyMember(
              state,
              itemId: 'missing',
              partyIndex: 0,
              maxHp: 20,
            )
            .failure,
        PlayerItemUseFailure.unknownItem,
      );
      expect(
        operations
            .useOnPartyMember(
              state,
              itemId: 'potion',
              partyIndex: 9,
              maxHp: 20,
            )
            .failure,
        PlayerItemUseFailure.invalidTarget,
      );
      expect(
        operations
            .useOnPartyMember(
              state,
              itemId: 'potion',
              partyIndex: 0,
              maxHp: 20,
            )
            .failure,
        PlayerItemUseFailure.insufficientQuantity,
      );
    });
  });

  group('GameStateMutations.purchaseItem', () {
    test('atomically pays for and grants the requested item quantity', () {
      final state = partyBagState(
        money: 1000,
        bagEntries: const [
          BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 1),
        ],
      );

      final result = mutations.purchaseItem(
        state,
        itemId: ' potion ',
        categoryId: 'medicine',
        quantity: 2,
        unitPrice: 300,
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
        categoryId: 'medicine',
        quantity: 1,
        unitPrice: 300,
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
          categoryId: 'medicine',
          quantity: 1,
          unitPrice: 100,
        ),
        mutations.purchaseItem(
          state,
          itemId: 'potion',
          categoryId: ' ',
          quantity: 1,
          unitPrice: 100,
        ),
        mutations.purchaseItem(
          state,
          itemId: 'potion',
          categoryId: 'medicine',
          quantity: 0,
          unitPrice: 100,
        ),
        mutations.purchaseItem(
          state,
          itemId: 'potion',
          categoryId: 'medicine',
          quantity: 1,
          unitPrice: 0,
        ),
      ]) {
        expect(result.failure, ShopPurchaseFailure.invalidRequest);
        expect(result.state, same(state));
      }
    });
  });
}
