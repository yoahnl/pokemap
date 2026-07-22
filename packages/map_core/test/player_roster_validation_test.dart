import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('validatePlayerRoster', () {
    test('reports party capacity, box overflow and missing species paths', () {
      final member = _pokemon('bulbasaur');
      final issues = validatePlayerRoster(
        party: PlayerParty(members: List<PlayerPokemon>.filled(7, member)),
        storage: PokemonStorage(
          boxes: <PokemonBox>[
            PokemonBox(
              id: 'box-01',
              label: 'Box 1',
              capacity: 1,
              pokemon: <PlayerPokemon>[member, _pokemon(' ')],
            ),
          ],
        ),
      );

      expect(
        issues.map((issue) => issue.code),
        containsAll(<PlayerRosterValidationIssueCode>[
          PlayerRosterValidationIssueCode.partyCapacityExceeded,
          PlayerRosterValidationIssueCode.boxCapacityExceeded,
          PlayerRosterValidationIssueCode.missingSpeciesId,
        ]),
      );
      expect(issues.every((issue) => issue.path.isNotEmpty), isTrue);
      expect(issues.every((issue) => issue.message.isNotEmpty), isTrue);
    });

    test('uses optional catalogues to report unknown species and moves', () {
      final issues = validatePlayerRoster(
        party: PlayerParty(
          members: <PlayerPokemon>[
            _pokemon('missing',
                moves: const <String>['tackle', 'missing_move']),
          ],
        ),
        storage: const PokemonStorage(),
        knownSpeciesIds: const <String>{'bulbasaur'},
        knownMoveIds: const <String>{'tackle'},
      );

      expect(
        issues.map((issue) => issue.code),
        <PlayerRosterValidationIssueCode>[
          PlayerRosterValidationIssueCode.unknownSpecies,
          PlayerRosterValidationIssueCode.unknownMove,
        ],
      );
    });

    test('accepts a bounded roster backed by known catalog entries', () {
      final issues = validatePlayerRoster(
        party: PlayerParty(
          members: <PlayerPokemon>[
            _pokemon('bulbasaur', moves: const <String>['tackle']),
          ],
        ),
        storage: const PokemonStorage(),
        knownSpeciesIds: const <String>{'bulbasaur'},
        knownMoveIds: const <String>{'tackle'},
      );

      expect(issues, isEmpty);
    });
  });

  test('PlayerParty normalization rejects more than six members', () {
    final member = _pokemon('bulbasaur');

    expect(
      () => PlayerParty(
        members: List<PlayerPokemon>.filled(7, member),
      ).normalized(),
      throwsStateError,
    );
  });
}

PlayerPokemon _pokemon(String speciesId, {List<String> moves = const []}) {
  return PlayerPokemon(
    speciesId: speciesId,
    natureId: 'docile',
    abilityId: 'ability',
    knownMoveIds: moves,
  );
}
