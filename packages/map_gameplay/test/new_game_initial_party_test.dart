import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  const mutations = GameStateMutations();

  MapData startMap() {
    return const MapData(
      id: 'p5_initial_party_map',
      name: 'P5 Initial Party Field',
      size: GridSize(width: 10, height: 8),
      mapMetadata: MapMetadata(defaultSpawnId: 'p5_initial_party_spawn'),
      entities: [
        MapEntity(
          id: 'p5_initial_party_spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 4, y: 5),
          spawn: MapEntitySpawnData(
            spawnKey: 'p5_initial_party_spawn',
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.north,
          ),
        ),
      ],
    );
  }

  GameState initialState() {
    return createNewGameStateFromMap(
      startMap: startMap(),
      saveId: 'p5_initial_party_save',
      playerName: 'P5 Player',
    );
  }

  PlayerPokemon starterPokemon({
    String speciesId = 'p5_starter_species',
    int level = 5,
    List<String> knownMoveIds = const [
      'p5_starter_tackle',
      'p5_starter_guard',
    ],
  }) {
    return PlayerPokemon(
      speciesId: speciesId,
      natureId: 'hardy',
      abilityId: 'p5_starter_ability',
      level: level,
      knownMoveIds: knownMoveIds,
      currentHp: 18,
    );
  }

  group('P5-03 initial party flow', () {
    test('creates a starter party from a P5-02 New Game state', () {
      final state = initialState();
      final result = mutations.givePokemon(
        state,
        pokemon: starterPokemon(),
      );

      expect(state.party.members, isEmpty);
      expect(result.party.members, hasLength(1));

      final starter = result.party.members.single;
      expect(starter.speciesId, 'p5_starter_species');
      expect(starter.level, 5);
      expect(
        starter.knownMoveIds,
        ['p5_starter_tackle', 'p5_starter_guard'],
      );
      expect(starter.currentHp, 18);
      expect(starter.statusId, isEmpty);
      expect(starter.heldItemId, isEmpty);
    });

    test('trims starter speciesId through givePokemon', () {
      final result = mutations.givePokemon(
        initialState(),
        pokemon: starterPokemon(speciesId: '  p5_starter_species  '),
      );

      expect(result.party.members.single.speciesId, 'p5_starter_species');
    });

    test('keeps blank starter speciesId as a safe no-op', () {
      final state = initialState();
      final result = mutations.givePokemon(
        state,
        pokemon: starterPokemon(speciesId: '   '),
      );

      expect(identical(result, state), isTrue);
      expect(result.party.members, isEmpty);
    });

    test('preserves New Game map, spawn, bag, money, and progression', () {
      final state = initialState();
      final result = mutations.givePokemon(
        state,
        pokemon: starterPokemon(),
      );

      expect(result.currentMapId, 'p5_initial_party_map');
      expect(result.playerPosition, const GridPos(x: 4, y: 5));
      expect(result.playerFacing, EntityFacing.north);
      expect(result.bag.entries, isEmpty);
      expect(result.trainerProfile.money, 0);
      expect(result.progression.completedStepIds, isEmpty);
      expect(result.progression.completedCutsceneIds, isEmpty);
      expect(result.progression.unlockedFieldAbilities, isEmpty);
      expect(result.storyFlags.activeFlags, isEmpty);
      expect(result.consumedEventIds, isEmpty);
      expect(result.metadata, isEmpty);
    });

    test('round-trips the initial party through SaveData', () {
      final stateWithStarter = mutations.givePokemon(
        initialState(),
        pokemon: starterPokemon(level: 7),
      );

      final saveData = saveDataFromGameState(stateWithStarter);
      final reloaded =
          normalizeLoadedGameState(gameStateFromSaveData(saveData));

      expect(reloaded.saveId, 'p5_initial_party_save');
      expect(reloaded.currentMapId, 'p5_initial_party_map');
      expect(reloaded.playerPosition, const GridPos(x: 4, y: 5));
      expect(reloaded.playerFacing, EntityFacing.north);
      expect(reloaded.party.members, hasLength(1));

      final starter = reloaded.party.members.single;
      expect(starter.speciesId, 'p5_starter_species');
      expect(starter.level, 7);
      expect(
        starter.knownMoveIds,
        ['p5_starter_tackle', 'p5_starter_guard'],
      );
      expect(reloaded.bag.entries, isEmpty);
      expect(reloaded.trainerProfile.money, 0);
    });

    test('prevents duplicate starter species when requested', () {
      var state = initialState();
      state = mutations.givePokemon(
        state,
        pokemon: starterPokemon(level: 5),
      );
      final result = mutations.givePokemon(
        state,
        pokemon: starterPokemon(level: 10),
        preventDuplicateSpecies: true,
      );

      expect(result.party.members, hasLength(1));
      expect(result.party.members.single.level, 5);
    });

    test('persistence validation rejects invalid starter level', () {
      final stateWithInvalidStarter = mutations.givePokemon(
        initialState(),
        pokemon: starterPokemon(level: 0),
      );

      expect(
        () => saveDataFromGameState(stateWithInvalidStarter),
        throwsStateError,
      );
    });

    test('persistence validation rejects blank starter move ids', () {
      final stateWithInvalidStarter = mutations.givePokemon(
        initialState(),
        pokemon: starterPokemon(knownMoveIds: const ['p5_valid_move', '  ']),
      );

      expect(
        () => saveDataFromGameState(stateWithInvalidStarter),
        throwsStateError,
      );
    });

    test('does not hardcode Selbrume-specific ids', () {
      final result = mutations.givePokemon(
        initialState(),
        pokemon: starterPokemon(),
      );

      final joined = [
        result.currentMapId,
        result.party.members.single.speciesId,
        ...result.party.members.single.knownMoveIds,
      ].join('|').toLowerCase();

      expect(joined, isNot(contains('selbrume')));
      expect(joined, isNot(contains('lysa')));
      expect(joined, isNot(contains('mael')));
      expect(joined, isNot(contains('brume')));
    });
  });
}
