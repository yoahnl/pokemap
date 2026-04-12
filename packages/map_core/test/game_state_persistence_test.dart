import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('gameStateFromSaveData', () {
    test('migrates legacy save fields to GameState', () {
      const save = SaveData(
        saveId: 'legacy_1',
        currentMapId: 'vova_center',
        playerPosition: GridPos(x: 7, y: 9),
        playerFacing: EntityFacing.west,
        party: PlayerParty(
          members: [
            PlayerPokemon(
              speciesId: 'lapras',
              natureId: 'modest',
              abilityId: 'water-absorb',
              knownMoveIds: ['surf'],
            ),
          ],
        ),
        trainerProfile: TrainerProfile(
          name: 'Red',
          badgeIds: ['boulder'],
          money: 1200,
          playtimeSeconds: 42,
        ),
        bag: Bag(
          entries: [
            BagEntry(itemId: 'poke-ball', categoryId: 'items', quantity: 3),
          ],
        ),
        progression: PlayerProgression(
          unlockedFieldAbilities: [FieldAbility.surf],
          storyFlags: ['met_professor', 'starter_received'],
          completedStepIds: ['step_a'],
        ),
        properties: {'legacy': 'ok'},
      );

      final state = gameStateFromSaveData(save);

      expect(state.saveId, equals('legacy_1'));
      expect(state.currentMapId, equals('vova_center'));
      expect(state.playerPosition, equals(const GridPos(x: 7, y: 9)));
      expect(state.playerFacing, equals(EntityFacing.west));
      expect(state.party.members.length, equals(1));
      expect(state.trainerProfile.name, equals('Red'));
      expect(state.bag.entries.single.itemId, equals('poke-ball'));
      expect(state.progression.unlockedFieldAbilities,
          contains(FieldAbility.surf));
      expect(state.storyFlags.activeFlags,
          containsAll(['met_professor', 'starter_received']));
      expect(state.progression.completedStepIds, ['step_a']);
      expect(state.metadata['legacy'], equals('ok'));
    });
  });

  group('saveDataFromGameState', () {
    test('keeps core fields and merges story flags in legacy slot', () {
      final state = GameState(
        saveId: 'save_2',
        currentMapId: 'route_1',
        playerPosition: const GridPos(x: 3, y: 4),
        playerFacing: EntityFacing.north,
        trainerProfile: const TrainerProfile(
          name: 'Leaf',
          badgeIds: ['cascade', 'boulder'],
          money: 500,
          playtimeSeconds: 99,
        ),
        bag: const Bag(
          entries: [
            BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 2),
            BagEntry(itemId: 'poke-ball', categoryId: 'items', quantity: 5),
          ],
        ),
        progression: const PlayerProgression(
          storyFlags: ['from_progression'],
          completedStepIds: ['step_done'],
        ),
        storyFlags: const StoryFlags(activeFlags: {'from_story_flags'}),
      );

      final save = saveDataFromGameState(state);

      expect(save.saveId, equals('save_2'));
      expect(save.currentMapId, equals('route_1'));
      expect(save.playerPosition, equals(const GridPos(x: 3, y: 4)));
      expect(save.playerFacing, equals(EntityFacing.north));
      expect(save.trainerProfile.name, equals('Leaf'));
      expect(save.trainerProfile.badgeIds, equals(['boulder', 'cascade']));
      expect(save.bag.entries.length, equals(2));
      expect(
        save.progression.storyFlags.toSet(),
        containsAll(<String>{'from_progression', 'from_story_flags'}),
      );
      expect(save.progression.completedStepIds, ['step_done']);
    });
  });

  group('normalizeLoadedGameState', () {
    test('hydrates storyFlags from progression when storyFlags are empty', () {
      final state = GameState(
        saveId: 'save_3',
        progression: const PlayerProgression(
          storyFlags: ['trainer_defeated:gym_leader_1', 'badge_cascade'],
        ),
        storyFlags: const StoryFlags(activeFlags: <String>{}),
      );

      final normalized = normalizeLoadedGameState(state);

      expect(
        normalized.storyFlags.activeFlags,
        containsAll(['trainer_defeated:gym_leader_1', 'badge_cascade']),
      );
    });

    test('keeps explicit storyFlags as source of truth when already set', () {
      final state = GameState(
        saveId: 'save_4',
        progression: const PlayerProgression(storyFlags: ['legacy_flag']),
        storyFlags: const StoryFlags(activeFlags: {'runtime_flag'}),
      );

      final normalized = normalizeLoadedGameState(state);

      expect(normalized.storyFlags.activeFlags, equals({'runtime_flag'}));
    });
  });
}
