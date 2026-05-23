import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  const mutations = GameStateMutations();

  GameState emptyState() {
    return createNewGameState(startMapId: 'test_map_start');
  }

  group('GameStateMutations.completeStep', () {
    test('adds a step id to empty completedStepIds', () {
      final state = emptyState();
      final result = mutations.completeStep(state, 'test_step_intro');

      expect(
        result.progression.completedStepIds,
        ['test_step_intro'],
      );
    });

    test('trims whitespace', () {
      final state = emptyState();
      final result = mutations.completeStep(state, '  test_step_intro  ');

      expect(
        result.progression.completedStepIds,
        ['test_step_intro'],
      );
    });

    test('is no-op for empty stepId', () {
      final state = emptyState();
      final result = mutations.completeStep(state, '');

      expect(result.progression.completedStepIds, isEmpty);
    });

    test('is no-op for blank stepId', () {
      final state = emptyState();
      final result = mutations.completeStep(state, '   ');

      expect(result.progression.completedStepIds, isEmpty);
    });

    test('is idempotent', () {
      var state = emptyState();
      state = mutations.completeStep(state, 'test_step_intro');
      final result = mutations.completeStep(state, 'test_step_intro');

      expect(result.progression.completedStepIds, hasLength(1));
      expect(result.progression.completedStepIds, ['test_step_intro']);
    });

    test('preserves existing completed steps', () {
      var state = emptyState();
      state = mutations.completeStep(state, 'test_step_intro');
      final result = mutations.completeStep(state, 'test_step_done');

      expect(result.progression.completedStepIds, hasLength(2));
      expect(
        result.progression.completedStepIds,
        ['test_step_intro', 'test_step_done'],
      );
    });

    test('preserves party', () {
      var state = emptyState();
      state = mutations.givePokemon(
        state,
        pokemon: PlayerPokemon(
          speciesId: 'test_species',
          level: 5,
          natureId: 'hardy',
          abilityId: 'unknown',
          currentHp: 5,
        ),
      );
      final result = mutations.completeStep(state, 'test_step');

      expect(result.party.members, hasLength(1));
      expect(result.party.members.first.speciesId, 'test_species');
    });

    test('preserves bag', () {
      var state = emptyState();
      state = mutations.giveItem(state, 'test_item', 3);
      final result = mutations.completeStep(state, 'test_step');

      expect(result.bag.entries, hasLength(1));
      expect(result.bag.entries.first.itemId, 'test_item');
    });

    test('preserves storyFlags', () {
      var state = emptyState();
      state = mutations.setFlag(state, 'test_flag');
      final result = mutations.completeStep(state, 'test_step');

      expect(result.storyFlags.activeFlags, contains('test_flag'));
    });

    test('preserves currentMapId and playerPosition', () {
      final state = createNewGameState(
        startMapId: 'test_map',
        startPosition: const GridPos(x: 5, y: 10),
      );
      final result = mutations.completeStep(state, 'test_step');

      expect(result.currentMapId, 'test_map');
      expect(result.playerPosition, const GridPos(x: 5, y: 10));
    });

    test('preserves consumedEventIds', () {
      var state = emptyState();
      state = mutations.markEventConsumed(state, 'test_event');
      final result = mutations.completeStep(state, 'test_step');

      expect(result.consumedEventIds, contains('test_event'));
    });

    test('does not hardcode any Selbrume ids', () {
      // Mechanics-first: the mutation accepts any stepId.
      final state = emptyState();
      final result = mutations.completeStep(state, 'any_generic_step');

      expect(
        result.progression.completedStepIds,
        ['any_generic_step'],
      );
    });

    test('round-trips through save/load', () {
      var state = emptyState();
      state = mutations.completeStep(state, 'roundtrip_step');

      final saveData = saveDataFromGameState(state);
      final reloaded =
          normalizeLoadedGameState(gameStateFromSaveData(saveData));

      expect(
        reloaded.progression.completedStepIds,
        contains('roundtrip_step'),
      );
    });

    test('full flow: createNewGameState → completeStep → save/load', () {
      var state = createNewGameState(
        startMapId: 'test_start_map',
        startPosition: const GridPos(x: 2, y: 3),
      );
      expect(state.progression.completedStepIds, isEmpty);

      state = mutations.completeStep(state, 'test_step_intro');
      state = mutations.completeStep(state, 'test_step_done');
      expect(state.progression.completedStepIds, hasLength(2));

      final saveData = saveDataFromGameState(state);
      final reloaded =
          normalizeLoadedGameState(gameStateFromSaveData(saveData));

      expect(reloaded.currentMapId, 'test_start_map');
      expect(reloaded.playerPosition, const GridPos(x: 2, y: 3));
      expect(reloaded.progression.completedStepIds, hasLength(2));
      expect(
        reloaded.progression.completedStepIds,
        containsAll(['test_step_intro', 'test_step_done']),
      );
      expect(reloaded.party.members, isEmpty);
    });
  });
}
