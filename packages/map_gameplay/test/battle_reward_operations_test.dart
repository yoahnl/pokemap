import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  const mutations = GameStateMutations();

  PlayerPokemon pokemon({
    String speciesId = 'p5_reward_species',
    int level = 8,
    int currentHp = 16,
  }) {
    return PlayerPokemon(
      speciesId: speciesId,
      natureId: 'hardy',
      abilityId: 'p5_reward_ability',
      level: level,
      knownMoveIds: const ['p5_reward_tackle'],
      currentHp: currentHp,
    );
  }

  GameState rewardState({
    int money = 100,
    List<PlayerPokemon> members = const [],
    Set<String> storyFlags = const {},
  }) {
    var state = GameState(
      saveId: 'p5_battle_reward_save',
      currentMapId: 'p5_battle_reward_map',
      playerPosition: const GridPos(x: 6, y: 3),
      playerFacing: EntityFacing.east,
      trainerProfile: TrainerProfile(name: 'P5 Player', money: money),
      party: PlayerParty(members: members),
      bag: const Bag(
        entries: [
          BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 2),
        ],
      ),
      storyFlags: StoryFlags(activeFlags: storyFlags),
      metadata: const {'lot': 'p5_05'},
    );
    state = mutations.markEventConsumed(state, 'p5.event.before_reward');
    return state;
  }

  group('GameStateMutations.addMoney', () {
    test('increases trainerProfile money', () {
      final state = rewardState(money: 120);

      final updated = mutations.addMoney(state, 35);

      expect(updated.trainerProfile.money, 155);
      expect(updated.currentMapId, state.currentMapId);
      expect(updated.playerPosition, state.playerPosition);
      expect(updated.bag, state.bag);
    });

    test('is a no-op for non-positive amounts', () {
      final state = rewardState(money: 120);

      expect(mutations.addMoney(state, 0), same(state));
      expect(mutations.addMoney(state, -10), same(state));
    });
  });

  group('GameStateMutations.applyBattleRewards', () {
    test('applies money reward and preserves world state', () {
      final state = rewardState(
        money: 50,
        members: [pokemon()],
        storyFlags: const {'trainer_defeated:p5_existing_trainer'},
      );

      final updated = mutations.applyBattleRewards(
        state,
        moneyReward: 200,
      );

      expect(updated.trainerProfile.money, 250);
      expect(updated.currentMapId, state.currentMapId);
      expect(updated.playerPosition, state.playerPosition);
      expect(updated.playerFacing, state.playerFacing);
      expect(updated.bag, state.bag);
      expect(updated.party, state.party);
      expect(updated.storyFlags, state.storyFlags);
      expect(updated.consumedEventIds, state.consumedEventIds);
      expect(updated.metadata, state.metadata);
    });

    test('applies direct minimal level-up when XP is not persisted', () {
      final state = rewardState(
        members: [
          pokemon(speciesId: 'p5_reward_a', level: 8),
          pokemon(speciesId: 'p5_reward_b', level: 12),
        ],
      );

      final updated = mutations.applyBattleRewards(
        state,
        levelUpsByPartyIndex: const {0: 2, 1: 1},
      );

      expect(updated.party.members[0].level, 10);
      expect(updated.party.members[1].level, 13);
      expect(updated.party.members[0].knownMoveIds, ['p5_reward_tackle']);
      expect(updated.party.members[1].currentHp, 16);
    });

    test('caps direct level-up at PlayerPokemon max level', () {
      final state = rewardState(
        members: [pokemon(level: 99)],
      );

      final updated = mutations.applyBattleRewards(
        state,
        levelUpsByPartyIndex: const {0: 5},
      );

      expect(updated.party.members.single.level, 100);
    });

    test('ignores invalid party indexes and non-positive level increments', () {
      final state = rewardState(
        members: [pokemon(level: 9)],
      );

      final updated = mutations.applyBattleRewards(
        state,
        levelUpsByPartyIndex: const {
          -1: 5,
          0: 0,
          1: 3,
        },
      );

      expect(updated, same(state));
    });

    test('applies money even when party is empty', () {
      final state = rewardState(money: 5);

      final updated = mutations.applyBattleRewards(
        state,
        moneyReward: 15,
        levelUpsByPartyIndex: const {0: 1},
      );

      expect(updated.trainerProfile.money, 20);
      expect(updated.party.members, isEmpty);
    });

    test('does not create or duplicate trainer defeated policy', () {
      final state = rewardState(
        members: [pokemon()],
        storyFlags: const {'trainer_defeated:p5_existing_trainer'},
      );

      final updated = mutations.applyBattleRewards(
        state,
        moneyReward: 10,
        levelUpsByPartyIndex: const {0: 1},
      );

      expect(
        updated.storyFlags.activeFlags
            .where((flag) => flag.startsWith('trainer_defeated:')),
        ['trainer_defeated:p5_existing_trainer'],
      );
    });

    test('round-trips money and direct level-up through SaveData', () {
      final state = rewardState(
        money: 25,
        members: [pokemon(speciesId: 'p5_roundtrip_species', level: 14)],
      );

      final rewarded = mutations.applyBattleRewards(
        state,
        moneyReward: 75,
        levelUpsByPartyIndex: const {0: 3},
      );
      final saveData = saveDataFromGameState(rewarded);
      final reloaded =
          normalizeLoadedGameState(gameStateFromSaveData(saveData));

      expect(reloaded.trainerProfile.money, 100);
      expect(reloaded.party.members.single.speciesId, 'p5_roundtrip_species');
      expect(reloaded.party.members.single.level, 17);
      expect(reloaded.bag.entries.single.itemId, 'potion');
      expect(reloaded.metadata, state.metadata);
    });

    test('does not hardcode any Selbrume ids', () {
      final state = rewardState(
        members: [pokemon(speciesId: 'p5_generic_reward_species')],
      );

      final updated = mutations.applyBattleRewards(
        state,
        moneyReward: 1,
        levelUpsByPartyIndex: const {0: 1},
      );

      final joined = [
        updated.currentMapId,
        updated.party.members.single.speciesId,
        ...updated.party.members.single.knownMoveIds,
      ].join('|').toLowerCase();

      expect(joined, isNot(contains('selbrume')));
      expect(joined, isNot(contains('lysa')));
      expect(joined, isNot(contains('mael')));
      expect(joined, isNot(contains('brume')));
    });
  });
}
