import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  const mutations = GameStateMutations();

  PlayerPokemon pokemon(String speciesId, {int level = 5}) {
    return PlayerPokemon(
      speciesId: speciesId,
      natureId: 'hardy',
      abilityId: 'p5_capture_ability',
      level: level,
      knownMoveIds: const ['p5_capture_move'],
      currentHp: 12,
    );
  }

  GameState captureState({
    required List<PlayerPokemon> party,
    List<PlayerPokemon> storage = const [],
    Set<String> storyFlags = const {'p5.capture.flag'},
  }) {
    var state = GameState(
      saveId: 'p5_capture_save',
      currentMapId: 'p5_capture_map',
      playerPosition: const GridPos(x: 4, y: 7),
      playerFacing: EntityFacing.west,
      trainerProfile: const TrainerProfile(name: 'P5 Player', money: 325),
      party: PlayerParty(members: party),
      pokemonStorage: PokemonStorage(storedPokemon: storage),
      bag: const Bag(
        entries: [
          BagEntry(itemId: 'poke-ball', categoryId: 'items', quantity: 2),
        ],
      ),
      progression: const PlayerProgression(
        seenSpeciesIds: ['p5_seen_before'],
        caughtSpeciesIds: ['p5_caught_before'],
      ),
      storyFlags: StoryFlags(activeFlags: storyFlags),
      metadata: const {'lot': 'p5_06'},
    );
    state = mutations.markEventConsumed(state, 'p5.capture.before');
    return state;
  }

  group('GameStateMutations.applyCapturedPokemon', () {
    test('adds the captured pokemon to party when there is room', () {
      final state = captureState(
        party: [
          pokemon('p5_party_0'),
          pokemon('p5_party_1'),
          pokemon('p5_party_2'),
          pokemon('p5_party_3'),
          pokemon('p5_party_4'),
        ],
      );

      final result = mutations.applyCapturedPokemon(
        state,
        pokemon: pokemon(' p5_captured_party ', level: 9),
      );

      expect(result.destination, CaptureDestinationKind.party);
      expect(result.partyIndex, 5);
      expect(result.storageIndex, isNull);
      expect(result.state.party.members, hasLength(6));
      expect(result.state.party.members.last.speciesId, 'p5_captured_party');
      expect(result.state.pokemonStorage.storedPokemon, isEmpty);
    });

    test('sends the captured pokemon to storage when party is full', () {
      final state = captureState(
        party: List<PlayerPokemon>.generate(
          6,
          (index) => pokemon('p5_party_$index'),
        ),
      );

      final result = mutations.applyCapturedPokemon(
        state,
        pokemon: pokemon('p5_captured_storage', level: 11),
      );

      expect(result.destination, CaptureDestinationKind.storage);
      expect(result.partyIndex, isNull);
      expect(result.storageIndex, 0);
      expect(result.state.party.members, hasLength(6));
      expect(result.state.party.members.map((member) => member.speciesId), [
        'p5_party_0',
        'p5_party_1',
        'p5_party_2',
        'p5_party_3',
        'p5_party_4',
        'p5_party_5',
      ]);
      expect(result.state.pokemonStorage.storedPokemon, hasLength(1));
      expect(
        result.state.pokemonStorage.storedPokemon.single.speciesId,
        'p5_captured_storage',
      );
    });

    test('appends to existing storage and reports the storage index', () {
      final state = captureState(
        party: List<PlayerPokemon>.generate(
          6,
          (index) => pokemon('p5_party_$index'),
        ),
        storage: [
          pokemon('p5_stored_existing_a'),
          pokemon('p5_stored_existing_b'),
        ],
      );

      final result = mutations.applyCapturedPokemon(
        state,
        pokemon: pokemon('p5_captured_storage_c'),
      );

      expect(result.destination, CaptureDestinationKind.storage);
      expect(result.storageIndex, 2);
      expect(result.state.party.members, hasLength(6));
      expect(result.state.pokemonStorage.storedPokemon, hasLength(3));
      expect(
        result.state.pokemonStorage.storedPokemon
            .map((member) => member.speciesId),
        [
          'p5_stored_existing_a',
          'p5_stored_existing_b',
          'p5_captured_storage_c'
        ],
      );
    });

    test('blank speciesId is a safe no-op', () {
      final state = captureState(
        party: [pokemon('p5_party_0')],
      );

      final result = mutations.applyCapturedPokemon(
        state,
        pokemon: pokemon('   '),
      );

      expect(result.destination, CaptureDestinationKind.none);
      expect(result.state, same(state));
      expect(result.partyIndex, isNull);
      expect(result.storageIndex, isNull);
    });

    test('preserves map, position, bag, money, flags and metadata', () {
      final state = captureState(
        party: List<PlayerPokemon>.generate(
          6,
          (index) => pokemon('p5_party_$index'),
        ),
      );

      final result = mutations.applyCapturedPokemon(
        state,
        pokemon: pokemon('p5_captured_preserve'),
      );

      expect(result.state.currentMapId, state.currentMapId);
      expect(result.state.playerPosition, state.playerPosition);
      expect(result.state.playerFacing, state.playerFacing);
      expect(result.state.bag, state.bag);
      expect(result.state.trainerProfile, state.trainerProfile);
      expect(result.state.storyFlags, state.storyFlags);
      expect(result.state.consumedEventIds, state.consumedEventIds);
      expect(result.state.metadata, state.metadata);
    });

    test('updates caught and seen for party and storage destinations', () {
      final partyResult = mutations.applyCapturedPokemon(
        captureState(party: [pokemon('p5_party_0')]),
        pokemon: pokemon('p5_captured_seen_party'),
      );
      final storageResult = mutations.applyCapturedPokemon(
        captureState(
          party: List<PlayerPokemon>.generate(
            6,
            (index) => pokemon('p5_party_$index'),
          ),
        ),
        pokemon: pokemon('p5_captured_seen_storage'),
      );

      expect(
        partyResult.state.progression.caughtSpeciesIds,
        contains('p5_captured_seen_party'),
      );
      expect(
        partyResult.state.progression.seenSpeciesIds,
        contains('p5_captured_seen_party'),
      );
      expect(
        storageResult.state.progression.caughtSpeciesIds,
        contains('p5_captured_seen_storage'),
      );
      expect(
        storageResult.state.progression.seenSpeciesIds,
        contains('p5_captured_seen_storage'),
      );
    });

    test('round-trips party and storage captures through SaveData', () {
      final partyResult = mutations.applyCapturedPokemon(
        captureState(
          party: [
            pokemon('p5_party_0'),
            pokemon('p5_party_1'),
            pokemon('p5_party_2'),
            pokemon('p5_party_3'),
            pokemon('p5_party_4'),
          ],
        ),
        pokemon: pokemon('p5_roundtrip_party'),
      );
      final storageResult = mutations.applyCapturedPokemon(
        partyResult.state,
        pokemon: pokemon('p5_roundtrip_storage'),
      );

      final saveData = saveDataFromGameState(storageResult.state);
      final reloaded =
          normalizeLoadedGameState(gameStateFromSaveData(saveData));

      expect(reloaded.party.members, hasLength(6));
      expect(reloaded.party.members.last.speciesId, 'p5_roundtrip_party');
      expect(reloaded.pokemonStorage.storedPokemon, hasLength(1));
      expect(
        reloaded.pokemonStorage.storedPokemon.single.speciesId,
        'p5_roundtrip_storage',
      );
      expect(
        reloaded.progression.caughtSpeciesIds,
        containsAll(['p5_roundtrip_party', 'p5_roundtrip_storage']),
      );
      expect(reloaded.metadata, storageResult.state.metadata);
    });

    test('does not hardcode any Selbrume ids', () {
      final result = mutations.applyCapturedPokemon(
        captureState(party: [pokemon('p5_party_generic')]),
        pokemon: pokemon('p5_capture_generic'),
      );

      final joined = [
        result.state.currentMapId,
        ...result.state.party.members.map((member) => member.speciesId),
        ...result.state.pokemonStorage.storedPokemon
            .map((member) => member.speciesId),
      ].join('|').toLowerCase();

      expect(joined, isNot(contains('selbrume')));
      expect(joined, isNot(contains('lysa')));
      expect(joined, isNot(contains('mael')));
      expect(joined, isNot(contains('brume')));
    });
  });
}
