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

    test('overflows a full party into the first available box', () {
      // BETA-PTY-004. Avant le service unique d'acquisition, un cadeau reçu à
      // party pleine glissait un SEPTIÈME membre dans l'état — et la sauvegarde
      // plantait ensuite, saveDataFromGameState normalisant la party au moment
      // d'écrire. Le joueur perdait sa capacité à sauvegarder sur un cadeau
      // scénarisé.
      var state = emptyState();
      for (var index = 0; index < 6; index++) {
        state = mutations.givePokemon(
          state,
          pokemon: testPokemon(speciesId: 'member_$index'),
        );
      }

      final gifted = mutations.givePokemon(
        state,
        pokemon: testPokemon(speciesId: 'overflow_gift'),
      );

      expect(gifted.party.members, hasLength(6));
      expect(
        gifted.pokemonStorage.boxes.first.pokemon.single.speciesId,
        'overflow_gift',
        reason: 'the gift lands in the first box, like a capture would',
      );
      // Et la sauvegarde passe — c'était le crash d'avant.
      final reloaded = gameStateFromSaveData(saveDataFromGameState(gifted));
      expect(
        reloaded.pokemonStorage.boxes.first.pokemon.single.speciesId,
        'overflow_gift',
      );
    });

    test('a gift with storage full leaves the state untouched', () {
      var state = emptyState();
      for (var index = 0; index < 6; index++) {
        state = mutations.givePokemon(
          state,
          pokemon: testPokemon(speciesId: 'member_$index'),
        );
      }
      state = state.copyWith(
        pokemonStorage: PokemonStorage(
          boxes: <PokemonBox>[
            PokemonBox(
              id: 'tiny',
              label: 'Tiny',
              capacity: 1,
              pokemon: <PlayerPokemon>[
                testPokemon(
                  individualId: 'pkm_occupant',
                  speciesId: 'occupant',
                ),
              ],
            ),
          ],
        ),
      );

      final unchanged = mutations.givePokemon(
        state,
        pokemon: testPokemon(speciesId: 'lost_gift'),
      );

      expect(unchanged, same(state));
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

    test('a failed grant does not consume its operation id', () {
      // Le critère « duplicate retry », et il protège d'une PERTE DÉFINITIVE :
      // avant ce ticket, givePokemonOnce marquait l'opération appliquée même
      // quand rien ne s'était passé. Un cadeau tombé sur un stockage plein
      // était perdu à jamais, même après libération de place.
      var state = emptyState();
      for (var index = 0; index < 6; index++) {
        state = mutations.givePokemon(
          state,
          pokemon: testPokemon(speciesId: 'member_$index'),
        );
      }
      state = state.copyWith(
        pokemonStorage: PokemonStorage(
          boxes: <PokemonBox>[
            PokemonBox(
              id: 'tiny',
              label: 'Tiny',
              capacity: 1,
              pokemon: <PlayerPokemon>[
                testPokemon(
                  individualId: 'pkm_occupant',
                  speciesId: 'occupant',
                ),
              ],
            ),
          ],
        ),
      );

      final failed = mutations.givePokemonOnce(
        state,
        grantOperationId: 'gift.retryable',
        pokemon: testPokemon(speciesId: 'retryable_gift'),
      );

      expect(failed, same(state));
      expect(
        failed.appliedPokemonGrantOperationIds,
        isNot(contains('gift.retryable')),
        reason: 'a failed acquisition must stay retryable',
      );

      // De la place se libère : LE MÊME identifiant d'opération réussit.
      final withRoom = failed.copyWith(
        pokemonStorage: PokemonStorage(
          boxes: <PokemonBox>[
            PokemonBox(
              id: 'tiny',
              label: 'Tiny',
              capacity: 2,
              pokemon: failed.pokemonStorage.boxes.single.pokemon,
            ),
          ],
        ),
      );
      final retried = mutations.givePokemonOnce(
        withRoom,
        grantOperationId: 'gift.retryable',
        pokemon: testPokemon(speciesId: 'retryable_gift'),
      );

      expect(
        retried.pokemonStorage.boxes.single.pokemon.last.speciesId,
        'retryable_gift',
      );
      expect(
        retried.appliedPokemonGrantOperationIds,
        contains('gift.retryable'),
      );
    });

    test('an intentional duplicate no-op still consumes the operation id', () {
      // Le pendant : un doublon VOULU comme no-op est une opération FAITE.
      // Un scénario rejoué ne doit pas retenter le cadeau à chaque passage.
      var state = emptyState();
      state = mutations.givePokemon(
        state,
        pokemon: testPokemon(speciesId: 'already_owned'),
      );

      final applied = mutations.givePokemonOnce(
        state,
        grantOperationId: 'gift.duplicate',
        pokemon: testPokemon(speciesId: 'already_owned'),
        preventDuplicateSpecies: true,
      );

      expect(applied.party.members, hasLength(1));
      expect(
        applied.appliedPokemonGrantOperationIds,
        contains('gift.duplicate'),
      );
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
