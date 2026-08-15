import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  const mutations = GameStateMutations();

  PlayerPokemon testPokemon({
    String individualId = '',
    String speciesId = 'test_species',
    String formId = '',
    int level = 5,
  }) {
    return PlayerPokemon(
      individualId: individualId,
      speciesId: speciesId,
      formId: formId,
      level: level,
      natureId: 'hardy',
      abilityId: 'unknown',
      currentHp: 1,
    );
  }

  GameState emptyState() {
    return createNewGameState(startMapId: 'test_map_start');
  }

  group('GameStateMutations.givePokemon', () {
    test('adds a Pokemon to an empty party', () {
      final state = emptyState();
      final result = mutations.givePokemon(
        state,
        pokemon: testPokemon(),
      );

      expect(result.party.members, hasLength(1));
      expect(result.party.members.first.speciesId, 'test_species');
      expect(result.party.members.first.level, 5);
    });

    test('appends to an existing party', () {
      var state = emptyState();
      state = mutations.givePokemon(
        state,
        pokemon: testPokemon(speciesId: 'first_species'),
      );
      final result = mutations.givePokemon(
        state,
        pokemon: testPokemon(speciesId: 'second_species'),
      );

      expect(result.party.members, hasLength(2));
      expect(result.party.members[0].speciesId, 'first_species');
      expect(result.party.members[1].speciesId, 'second_species');
    });

    test('preserves existing party members', () {
      var state = emptyState();
      state = mutations.givePokemon(
        state,
        pokemon: testPokemon(speciesId: 'existing_species', level: 10),
      );
      final result = mutations.givePokemon(
        state,
        pokemon: testPokemon(speciesId: 'new_species', level: 3),
      );

      expect(result.party.members, hasLength(2));
      expect(result.party.members[0].speciesId, 'existing_species');
      expect(result.party.members[0].level, 10);
      expect(result.party.members[1].speciesId, 'new_species');
      expect(result.party.members[1].level, 3);
    });

    test('preserves bag', () {
      var state = emptyState();
      state = mutations.giveItem(state, 'test_item', 3);
      final result = mutations.givePokemon(
        state,
        pokemon: testPokemon(),
      );

      expect(result.bag.entries, hasLength(1));
      expect(result.bag.entries.first.itemId, 'test_item');
    });

    test('preserves storyFlags', () {
      var state = emptyState();
      state = mutations.setFlag(state, 'test_flag');
      final result = mutations.givePokemon(
        state,
        pokemon: testPokemon(),
      );

      expect(result.storyFlags.activeFlags, contains('test_flag'));
    });

    test('preserves currentMapId and playerPosition', () {
      final state = createNewGameState(
        startMapId: 'test_map',
        startPosition: const GridPos(x: 5, y: 10),
      );
      final result = mutations.givePokemon(
        state,
        pokemon: testPokemon(),
      );

      expect(result.currentMapId, 'test_map');
      expect(result.playerPosition, const GridPos(x: 5, y: 10));
    });

    test('preserves progression', () {
      var state = emptyState();
      state = mutations.markEventConsumed(state, 'test_event');
      final result = mutations.givePokemon(
        state,
        pokemon: testPokemon(),
      );

      expect(result.consumedEventIds, contains('test_event'));
    });

    test('is a no-op when speciesId is empty', () {
      final state = emptyState();
      final result = mutations.givePokemon(
        state,
        pokemon: testPokemon(speciesId: ''),
      );

      expect(result.party.members, isEmpty);
    });

    test('is a no-op when speciesId is blank', () {
      final state = emptyState();
      final result = mutations.givePokemon(
        state,
        pokemon: testPokemon(speciesId: '   '),
      );

      expect(result.party.members, isEmpty);
    });

    test('trims speciesId whitespace', () {
      final state = emptyState();
      final result = mutations.givePokemon(
        state,
        pokemon: testPokemon(
          speciesId: '  test_species  ',
          formId: '  seasonal  ',
        ),
      );

      expect(result.party.members, hasLength(1));
      expect(result.party.members.first.speciesId, 'test_species');
      expect(result.party.members.first.formId, 'seasonal');
    });

    test('allocates one stable identity when individualId is empty', () {
      final result = mutations.givePokemon(
        emptyState(),
        pokemon: testPokemon(),
      );
      final individualId = result.party.members.single.individualId;

      expect(individualId, startsWith('pkm_'));
      final reloaded = normalizeLoadedGameState(
        gameStateFromSaveData(saveDataFromGameState(result)),
      );
      expect(reloaded.party.members.single.individualId, individualId);
    });

    test('allocates distinct identities for two gifts of the same template',
        () {
      final template = testPokemon(speciesId: 'repeatable_gift');
      final first = mutations.givePokemon(
        emptyState(),
        pokemon: template,
      );
      final second = mutations.givePokemon(
        first,
        pokemon: template,
      );

      expect(second.party.members, hasLength(2));
      expect(
        second.party.members.map((pokemon) => pokemon.individualId).toSet(),
        hasLength(2),
      );
    });

    test('preserves an explicit unique identity', () {
      final result = mutations.givePokemon(
        emptyState(),
        pokemon: testPokemon(individualId: 'pkm_authored_gift'),
      );

      expect(result.party.members.single.individualId, 'pkm_authored_gift');
    });

    test('rejects an explicit identity already present in party', () {
      final state = mutations.givePokemon(
        emptyState(),
        pokemon: testPokemon(individualId: 'pkm_collision'),
      );

      expect(
        () => mutations.givePokemon(
          state,
          pokemon: testPokemon(
            individualId: 'pkm_collision',
            speciesId: 'other_species',
          ),
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'PlayerPokemon individualId values must be unique across party and storage',
          ),
        ),
      );
      expect(state.party.members, hasLength(1));
    });

    test('rejects an explicit identity already present in storage', () {
      final state = emptyState().copyWith(
        pokemonStorage: PokemonStorage(
          boxes: <PokemonBox>[
            PokemonBox(
              id: 'box-identity',
              label: 'Identity',
              pokemon: <PlayerPokemon>[
                testPokemon(individualId: 'pkm_stored_collision'),
              ],
            ),
          ],
        ),
      );

      expect(
        () => mutations.givePokemon(
          state,
          pokemon: testPokemon(
            individualId: 'pkm_stored_collision',
            speciesId: 'other_species',
          ),
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'PlayerPokemon individualId values must be unique across party and storage',
          ),
        ),
      );
      expect(state.party.members, isEmpty);
    });

    test('rejects an identity collision before duplicate-species policy', () {
      final state = mutations.givePokemon(
        emptyState(),
        pokemon: testPokemon(individualId: 'pkm_collision'),
      );

      expect(
        () => mutations.givePokemon(
          state,
          pokemon: testPokemon(individualId: 'pkm_collision'),
          preventDuplicateSpecies: true,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('prevents duplicate species when requested', () {
      var state = emptyState();
      state = mutations.givePokemon(
        state,
        pokemon: testPokemon(speciesId: 'test_species'),
      );
      final result = mutations.givePokemon(
        state,
        pokemon: testPokemon(speciesId: 'test_species', level: 99),
        preventDuplicateSpecies: true,
      );

      expect(result.party.members, hasLength(1));
      expect(result.party.members.first.level, 5);
    });

    test('allows duplicate species when preventDuplicateSpecies is false', () {
      var state = emptyState();
      state = mutations.givePokemon(
        state,
        pokemon: testPokemon(speciesId: 'test_species'),
      );
      final result = mutations.givePokemon(
        state,
        pokemon: testPokemon(speciesId: 'test_species', level: 99),
        preventDuplicateSpecies: false,
      );

      expect(result.party.members, hasLength(2));
    });

    test('allows duplicate species by default', () {
      var state = emptyState();
      state = mutations.givePokemon(
        state,
        pokemon: testPokemon(speciesId: 'test_species'),
      );
      final result = mutations.givePokemon(
        state,
        pokemon: testPokemon(speciesId: 'test_species'),
      );

      expect(result.party.members, hasLength(2));
    });

    test('does not hardcode any Selbrume ids', () {
      // Mechanics-first: the mutation accepts any speciesId, never injects one.
      final state = emptyState();
      final result = mutations.givePokemon(
        state,
        pokemon: testPokemon(speciesId: 'any_generic_species'),
      );

      expect(result.party.members.first.speciesId, 'any_generic_species');
    });

    test('round-trips through save/load', () {
      var state = emptyState();
      state = mutations.givePokemon(
        state,
        pokemon: testPokemon(speciesId: 'roundtrip_species', level: 12),
      );

      final saveData = saveDataFromGameState(state);
      final reloaded =
          normalizeLoadedGameState(gameStateFromSaveData(saveData));

      expect(reloaded.party.members, hasLength(1));
      expect(reloaded.party.members.first.speciesId, 'roundtrip_species');
      expect(reloaded.party.members.first.level, 12);
    });

    test('full flow: createNewGameState then givePokemon then save/load', () {
      var state = createNewGameState(
        startMapId: 'test_start_map',
        startPosition: const GridPos(x: 2, y: 3),
      );
      expect(state.party.members, isEmpty);

      state = mutations.givePokemon(
        state,
        pokemon: testPokemon(speciesId: 'starter_test', level: 5),
      );
      expect(state.party.members, hasLength(1));

      final saveData = saveDataFromGameState(state);
      final reloaded =
          normalizeLoadedGameState(gameStateFromSaveData(saveData));

      expect(reloaded.currentMapId, 'test_start_map');
      expect(reloaded.playerPosition, const GridPos(x: 2, y: 3));
      expect(reloaded.party.members, hasLength(1));
      expect(reloaded.party.members.first.speciesId, 'starter_test');
      expect(reloaded.bag.entries, isEmpty);
    });
  });

  group('GameStateMutations.givePokemonOnce', () {
    test('records one grant and makes an identical retry a no-op', () {
      final first = mutations.givePokemonOnce(
        emptyState(),
        grantOperationId: 'scenario:gift-run:node-gift',
        pokemon: testPokemon(),
      );
      final replay = mutations.givePokemonOnce(
        first,
        grantOperationId: 'scenario:gift-run:node-gift',
        pokemon: testPokemon(),
      );

      expect(first.party.members, hasLength(1));
      expect(replay, first);
      expect(
        replay.appliedPokemonGrantOperationIds,
        <String>{'scenario:gift-run:node-gift'},
      );
    });

    test('allows two intentional occurrences of the same template', () {
      final first = mutations.givePokemonOnce(
        emptyState(),
        grantOperationId: 'scene:first:gift-node',
        pokemon: testPokemon(),
      );
      final second = mutations.givePokemonOnce(
        first,
        grantOperationId: 'scene:second:gift-node',
        pokemon: testPokemon(),
      );

      expect(second.party.members, hasLength(2));
      expect(
        second.party.members.map((pokemon) => pokemon.individualId).toSet(),
        hasLength(2),
      );
      expect(second.appliedPokemonGrantOperationIds, hasLength(2));
    });

    test('rejects an empty operation id before changing state', () {
      final state = emptyState();

      expect(
        () => mutations.givePokemonOnce(
          state,
          grantOperationId: '   ',
          pokemon: testPokemon(),
        ),
        throwsArgumentError,
      );
      expect(state.party.members, isEmpty);
      expect(state.appliedPokemonGrantOperationIds, isEmpty);
    });
  });
}
