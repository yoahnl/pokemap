import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('PlayerPokemon identity', () {
    test(
      'round-trips individualId and formId through the strict save wire',
      () {
        const state = GameState(
          saveId: 'identity-round-trip',
          party: PlayerParty(
            members: <PlayerPokemon>[
              PlayerPokemon(
                individualId: 'pkm_round_trip',
                speciesId: 'rotom',
                formId: 'wash',
                natureId: 'modest',
                abilityId: 'levitate',
              ),
            ],
          ),
        );

        final restored = gameStateFromStrictSaveJson(
          strictGameStateSaveJson(state),
        );

        expect(restored.party.members.single.individualId, 'pkm_round_trip');
        expect(restored.party.members.single.formId, 'wash');
      },
    );

    test(
      'migrates legacy party and boxes deterministically in stable order',
      () {
        const legacy = GameState(
          saveId: 'legacy-identity',
          party: PlayerParty(
            members: <PlayerPokemon>[
              PlayerPokemon(
                speciesId: 'bulbasaur',
                natureId: 'bold',
                abilityId: 'overgrow',
              ),
            ],
          ),
          pokemonStorage: PokemonStorage(
            boxes: <PokemonBox>[
              PokemonBox(
                id: 'box-a',
                label: 'A',
                pokemon: <PlayerPokemon>[
                  PlayerPokemon(
                    speciesId: 'charmander',
                    natureId: 'timid',
                    abilityId: 'blaze',
                  ),
                ],
              ),
            ],
          ),
        );

        final first = normalizeLoadedGameState(legacy);
        final second = normalizeLoadedGameState(legacy);
        final normalizedSave = SaveData(
          saveId: legacy.saveId,
          party: legacy.party,
          pokemonStorage: legacy.pokemonStorage,
        ).normalized();
        final ids = <String>[
          first.party.members.single.individualId,
          first.pokemonStorage.boxes.single.pokemon.single.individualId,
        ];

        expect(ids.every((id) => id.startsWith('pkm_')), isTrue);
        expect(ids.toSet(), hasLength(2));
        expect(second.party.members.single.individualId, ids.first);
        expect(
          second.pokemonStorage.boxes.single.pokemon.single.individualId,
          ids.last,
        );
        expect(normalizedSave.party.members.single.individualId, ids.first);
        expect(
          normalizedSave
              .pokemonStorage
              .boxes
              .single
              .pokemon
              .single
              .individualId,
          ids.last,
        );
      },
    );

    test('rejects duplicate ids across party and PC storage', () {
      const duplicate = PlayerPokemon(
        individualId: 'pkm_duplicate',
        speciesId: 'eevee',
        natureId: 'hardy',
        abilityId: 'run-away',
      );
      const state = GameState(
        saveId: 'duplicate-identity',
        party: PlayerParty(members: <PlayerPokemon>[duplicate]),
        pokemonStorage: PokemonStorage(
          boxes: <PokemonBox>[
            PokemonBox(
              id: 'box-a',
              label: 'A',
              pokemon: <PlayerPokemon>[duplicate],
            ),
          ],
        ),
      );

      expect(() => normalizeLoadedGameState(state), throwsStateError);
    });

    test('allocates the next deterministic id after a collision', () {
      const pokemon = PlayerPokemon(
        speciesId: 'eevee',
        natureId: 'hardy',
        abilityId: 'run-away',
      );
      final first = deterministicPlayerPokemonIndividualId(
        saveId: 'identity-allocation',
        location: 'gift|eevee',
        pokemon: pokemon,
      );

      final second = nextPlayerPokemonIndividualId(
        saveId: 'identity-allocation',
        location: 'gift|eevee',
        pokemon: pokemon,
        occupiedIndividualIds: <String>[first],
      );

      expect(second, isNot(first));
      expect(
        second,
        deterministicPlayerPokemonIndividualId(
          saveId: 'identity-allocation',
          location: 'gift|eevee',
          pokemon: pokemon,
          collision: 1,
        ),
      );
    });
  });
}
