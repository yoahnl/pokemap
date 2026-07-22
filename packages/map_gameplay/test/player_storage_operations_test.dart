import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  const operations = PlayerStorageOperations();

  group('PlayerStorageOperations', () {
    test('finds the first available stable box slot', () {
      final slot = operations.findFirstAvailableSlot(
        PokemonStorage(
          boxes: <PokemonBox>[
            PokemonBox(
              id: 'full',
              label: 'Full',
              capacity: 1,
              pokemon: <PlayerPokemon>[_pokemon('one')],
            ),
            const PokemonBox(id: 'open', label: 'Open', capacity: 2),
          ],
        ),
      );

      expect(slot?.boxId, 'open');
      expect(slot?.boxIndex, 0);
    });

    test('deposits into first available box atomically', () {
      final state = _state(
        party: <PlayerPokemon>[_pokemon('lead'), _pokemon('reserve')],
      );

      final result = operations.deposit(state: state, partyIndex: 1);

      expect(result.isSuccess, isTrue);
      expect(result.state.party.members.single.speciesId, 'lead');
      expect(result.storageSlot?.boxId, 'box-01');
      expect(result.state.pokemonStorage.boxes.first.pokemon.single.speciesId,
          'reserve');
    });

    test('rejects depositing the last usable Pokemon without mutation', () {
      final state = _state(
        party: <PlayerPokemon>[
          _pokemon('fainted', hp: 0),
          _pokemon('usable'),
        ],
      );

      final result = operations.deposit(state: state, partyIndex: 1);

      expect(result.failure, PlayerStorageFailure.lastUsablePokemon);
      expect(result.state, same(state));
    });

    test('withdraws, swaps and reorders party while preserving validity', () {
      final state = _state(
        party: <PlayerPokemon>[_pokemon('lead'), _pokemon('reserve')],
        boxes: <PokemonBox>[
          PokemonBox(
            id: 'box-a',
            label: 'A',
            pokemon: <PlayerPokemon>[_pokemon('stored')],
          ),
        ],
      );

      final withdrawn = operations.withdraw(
        state: state,
        boxId: 'box-a',
        boxIndex: 0,
      );
      final swapped = operations.swapPartyWithBox(
        state: state,
        partyIndex: 1,
        boxId: 'box-a',
        boxIndex: 0,
      );
      final reordered = operations.setLead(state: state, partyIndex: 1);

      expect(withdrawn.state.party.members.last.speciesId, 'stored');
      expect(withdrawn.state.pokemonStorage.boxes.single.pokemon, isEmpty);
      expect(swapped.state.party.members[1].speciesId, 'stored');
      expect(swapped.state.pokemonStorage.boxes.single.pokemon.single.speciesId,
          'reserve');
      expect(reordered.state.party.members.first.speciesId, 'reserve');
      expect(reordered.state.party.members.last.speciesId, 'lead');
    });

    test('moves within one box and between boxes in deterministic order', () {
      final state = _state(
        party: <PlayerPokemon>[_pokemon('lead')],
        boxes: <PokemonBox>[
          PokemonBox(
            id: 'a',
            label: 'A',
            pokemon: <PlayerPokemon>[
              _pokemon('one'),
              _pokemon('two'),
              _pokemon('three'),
            ],
          ),
          const PokemonBox(id: 'b', label: 'B'),
        ],
      );

      final movedWithin = operations.moveWithinBox(
        state: state,
        boxId: 'a',
        fromIndex: 0,
        toIndex: 2,
      );
      final movedBetween = operations.moveBetweenBoxes(
        state: movedWithin.state,
        sourceBoxId: 'a',
        sourceIndex: 0,
        targetBoxId: 'b',
      );

      expect(
        movedWithin.state.pokemonStorage.boxes.first.pokemon
            .map((pokemon) => pokemon.speciesId),
        <String>['two', 'three', 'one'],
      );
      expect(
        movedBetween.state.pokemonStorage.boxes.first.pokemon
            .map((pokemon) => pokemon.speciesId),
        <String>['three', 'one'],
      );
      expect(
        movedBetween.state.pokemonStorage.boxes.last.pokemon.single.speciesId,
        'two',
      );
    });

    test('returns typed capacity and index failures without partial mutation',
        () {
      final fullParty = _state(
        party: List<PlayerPokemon>.generate(
          maxPlayerPartySize,
          (index) => _pokemon('party-$index'),
        ),
        boxes: <PokemonBox>[
          PokemonBox(
            id: 'full',
            label: 'Full',
            capacity: 1,
            pokemon: <PlayerPokemon>[_pokemon('stored')],
          ),
        ],
      );

      final partyFull = operations.withdraw(
        state: fullParty,
        boxId: 'full',
        boxIndex: 0,
      );
      final boxFull = operations.deposit(
        state: fullParty,
        partyIndex: 1,
        boxId: 'full',
        requireUsablePartyMember: false,
      );
      final invalidIndex = operations.moveWithinBox(
        state: fullParty,
        boxId: 'full',
        fromIndex: 7,
        toIndex: 0,
      );

      expect(partyFull.failure, PlayerStorageFailure.partyFull);
      expect(boxFull.failure, PlayerStorageFailure.boxFull);
      expect(invalidIndex.failure, PlayerStorageFailure.invalidBoxIndex);
      expect(partyFull.state, same(fullParty));
      expect(boxFull.state, same(fullParty));
      expect(invalidIndex.state, same(fullParty));
    });
  });
}

GameState _state({
  required List<PlayerPokemon> party,
  List<PokemonBox>? boxes,
}) {
  return GameState(
    saveId: 'storage-test',
    party: PlayerParty(members: party),
    pokemonStorage:
        PokemonStorage(boxes: boxes ?? const <PokemonBox>[]).normalized(),
  );
}

PlayerPokemon _pokemon(String speciesId, {int hp = 10}) => PlayerPokemon(
      speciesId: speciesId,
      natureId: 'docile',
      abilityId: 'ability',
      currentHp: hp,
    );
