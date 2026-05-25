import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  MapData newGameMap({
    String mapId = 'p5_new_game_map',
    String? defaultSpawnId = 'p5_spawn_default',
    List<MapEntity>? entities,
  }) {
    return MapData(
      id: mapId,
      name: 'P5 New Game Test Map',
      size: const GridSize(width: 12, height: 10),
      mapMetadata: MapMetadata(defaultSpawnId: defaultSpawnId),
      entities: entities ??
          const [
            MapEntity(
              id: 'p5_spawn_default',
              name: 'Default Spawn',
              kind: MapEntityKind.spawn,
              pos: GridPos(x: 3, y: 4),
              spawn: MapEntitySpawnData(
                spawnKey: 'p5_spawn_default',
                role: EntitySpawnRole.playerStart,
                facing: EntityFacing.west,
              ),
            ),
          ],
    );
  }

  group('createNewGameState', () {
    test('creates a GameState with the correct start map id', () {
      final state = createNewGameState(startMapId: 'test_start_map');

      expect(state.currentMapId, 'test_start_map');
    });

    test('trims whitespace from startMapId', () {
      final state = createNewGameState(startMapId: '  test_map  ');

      expect(state.currentMapId, 'test_map');
    });

    test('sets the default start position to (0, 0)', () {
      final state = createNewGameState(startMapId: 'test_map');

      expect(state.playerPosition, const GridPos(x: 0, y: 0));
    });

    test('sets a custom start position', () {
      final state = createNewGameState(
        startMapId: 'test_map',
        startPosition: const GridPos(x: 5, y: 10),
      );

      expect(state.playerPosition, const GridPos(x: 5, y: 10));
    });

    test('sets the default facing to south', () {
      final state = createNewGameState(startMapId: 'test_map');

      expect(state.playerFacing, EntityFacing.south);
    });

    test('sets a custom facing', () {
      final state = createNewGameState(
        startMapId: 'test_map',
        startFacing: EntityFacing.east,
      );

      expect(state.playerFacing, EntityFacing.east);
    });

    test('initializes party as empty', () {
      final state = createNewGameState(startMapId: 'test_map');

      expect(state.party.members, isEmpty);
    });

    test('initializes bag as empty', () {
      final state = createNewGameState(startMapId: 'test_map');

      expect(state.bag.entries, isEmpty);
    });

    test('initializes storyFlags as empty', () {
      final state = createNewGameState(startMapId: 'test_map');

      expect(state.storyFlags.activeFlags, isEmpty);
    });

    test('initializes scriptVariables as empty', () {
      final state = createNewGameState(startMapId: 'test_map');

      expect(state.scriptVariables.values, isEmpty);
    });

    test('initializes completedStepIds as empty', () {
      final state = createNewGameState(startMapId: 'test_map');

      expect(state.progression.completedStepIds, isEmpty);
    });

    test('initializes completedCutsceneIds as empty', () {
      final state = createNewGameState(startMapId: 'test_map');

      expect(state.progression.completedCutsceneIds, isEmpty);
    });

    test('initializes consumedEventIds as empty', () {
      final state = createNewGameState(startMapId: 'test_map');

      expect(state.consumedEventIds, isEmpty);
    });

    test('initializes progression seenSpeciesIds as empty', () {
      final state = createNewGameState(startMapId: 'test_map');

      expect(state.progression.seenSpeciesIds, isEmpty);
    });

    test('initializes progression caughtSpeciesIds as empty', () {
      final state = createNewGameState(startMapId: 'test_map');

      expect(state.progression.caughtSpeciesIds, isEmpty);
    });

    test('initializes progression storyFlags as empty', () {
      final state = createNewGameState(startMapId: 'test_map');

      expect(state.progression.storyFlags, isEmpty);
    });

    test('initializes unlockedFieldAbilities as empty', () {
      final state = createNewGameState(startMapId: 'test_map');

      expect(state.progression.unlockedFieldAbilities, isEmpty);
    });

    test('initializes metadata as empty', () {
      final state = createNewGameState(startMapId: 'test_map');

      expect(state.metadata, isEmpty);
    });

    test('sets playerMovementMode to walk', () {
      final state = createNewGameState(startMapId: 'test_map');

      expect(state.playerMovementMode, MovementMode.walk);
    });

    test('does not preload any Pokemon', () {
      final state = createNewGameState(startMapId: 'test_map');

      expect(state.party.members, isEmpty);
      expect(state.progression.seenSpeciesIds, isEmpty);
      expect(state.progression.caughtSpeciesIds, isEmpty);
    });

    test('sets the default saveId to new_game', () {
      final state = createNewGameState(startMapId: 'test_map');

      expect(state.saveId, 'new_game');
    });

    test('accepts a custom saveId', () {
      final state = createNewGameState(
        startMapId: 'test_map',
        saveId: 'custom_save',
      );

      expect(state.saveId, 'custom_save');
    });

    test('falls back to new_game when saveId is blank', () {
      final state = createNewGameState(
        startMapId: 'test_map',
        saveId: '   ',
      );

      expect(state.saveId, 'new_game');
    });

    test('sets the default player name to Player', () {
      final state = createNewGameState(startMapId: 'test_map');

      expect(state.trainerProfile.name, 'Player');
    });

    test('accepts a custom player name', () {
      final state = createNewGameState(
        startMapId: 'test_map',
        playerName: 'Maël',
      );

      expect(state.trainerProfile.name, 'Maël');
    });

    test('falls back to Player when playerName is blank', () {
      final state = createNewGameState(
        startMapId: 'test_map',
        playerName: '   ',
      );

      expect(state.trainerProfile.name, 'Player');
    });

    test('trainerProfile starts with zero money', () {
      final state = createNewGameState(startMapId: 'test_map');

      expect(state.trainerProfile.money, 0);
    });

    test('trainerProfile starts with zero playtime', () {
      final state = createNewGameState(startMapId: 'test_map');

      expect(state.trainerProfile.playtimeSeconds, 0);
    });

    test('trainerProfile starts with no badges', () {
      final state = createNewGameState(startMapId: 'test_map');

      expect(state.trainerProfile.badgeIds, isEmpty);
    });

    // --- Error cases ---

    test('throws ArgumentError when startMapId is empty', () {
      expect(
        () => createNewGameState(startMapId: ''),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError when startMapId is blank', () {
      expect(
        () => createNewGameState(startMapId: '   '),
        throwsArgumentError,
      );
    });

    // --- Save/load round-trip ---

    test('round-trips through SaveData correctly', () {
      final state = createNewGameState(
        startMapId: 'test_start_map',
        startPosition: const GridPos(x: 3, y: 7),
        startFacing: EntityFacing.north,
        playerName: 'TestPlayer',
      );

      final saveData = saveDataFromGameState(state);
      final reloaded =
          normalizeLoadedGameState(gameStateFromSaveData(saveData));

      expect(reloaded.currentMapId, state.currentMapId);
      expect(reloaded.playerPosition, state.playerPosition);
      expect(reloaded.playerFacing, state.playerFacing);
      expect(reloaded.party.members, isEmpty);
      expect(reloaded.bag.entries, isEmpty);
      expect(reloaded.trainerProfile.name, 'TestPlayer');
    });

    // --- No Selbrume ids ---

    test('does not reference any Selbrume-specific ids', () {
      // This test documents the mechanics-first requirement:
      // createNewGameState must never hardcode Selbrume ids.
      final state = createNewGameState(startMapId: 'any_project_map');

      expect(state.currentMapId, isNot(contains('selbrume')));
      expect(state.currentMapId, isNot(contains('bourg')));
      expect(state.currentMapId, isNot(contains('port')));
    });
  });

  group('createNewGameStateFromMap', () {
    test('resolves defaultSpawnId into start position and facing', () {
      final state = createNewGameStateFromMap(
        startMap: newGameMap(),
        saveId: 'p5_new_game_save',
        playerName: 'P5 Player',
      );

      expect(state.saveId, 'p5_new_game_save');
      expect(state.currentMapId, 'p5_new_game_map');
      expect(state.playerPosition, const GridPos(x: 3, y: 4));
      expect(state.playerFacing, EntityFacing.west);
      expect(state.trainerProfile.name, 'P5 Player');
      expect(state.party.members, isEmpty);
      expect(state.bag.entries, isEmpty);
      expect(state.trainerProfile.money, 0);
      expect(state.progression.completedStepIds, isEmpty);
      expect(state.storyFlags.activeFlags, isEmpty);
      expect(state.consumedEventIds, isEmpty);
      expect(state.metadata, isEmpty);
    });

    test(
        'falls back to the first playerStart spawn when defaultSpawnId is absent',
        () {
      final state = createNewGameStateFromMap(
        startMap: newGameMap(
          defaultSpawnId: null,
          entities: const [
            MapEntity(
              id: 'z_spawn',
              kind: MapEntityKind.spawn,
              pos: GridPos(x: 7, y: 8),
              spawn: MapEntitySpawnData(
                spawnKey: 'z_spawn',
                role: EntitySpawnRole.playerStart,
                facing: EntityFacing.north,
              ),
            ),
            MapEntity(
              id: 'a_spawn',
              kind: MapEntityKind.spawn,
              pos: GridPos(x: 1, y: 2),
              spawn: MapEntitySpawnData(
                spawnKey: 'a_spawn',
                role: EntitySpawnRole.playerStart,
                facing: EntityFacing.east,
              ),
            ),
          ],
        ),
      );

      expect(state.currentMapId, 'p5_new_game_map');
      expect(state.playerPosition, const GridPos(x: 1, y: 2));
      expect(state.playerFacing, EntityFacing.east);
    });

    test('throws when the map id is blank', () {
      expect(
        () => createNewGameStateFromMap(
          startMap: newGameMap(mapId: '   '),
        ),
        throwsArgumentError,
      );
    });

    test('throws when no player spawn can be resolved', () {
      expect(
        () => createNewGameStateFromMap(
          startMap: newGameMap(
            defaultSpawnId: null,
            entities: const [],
          ),
        ),
        throwsA(isA<GameplaySpawnResolutionException>()),
      );
    });

    test('round-trips the spawn-derived state through SaveData', () {
      final state = createNewGameStateFromMap(
        startMap: newGameMap(),
        saveId: 'p5_roundtrip_save',
      );

      final saveData = saveDataFromGameState(state);
      final reloaded =
          normalizeLoadedGameState(gameStateFromSaveData(saveData));

      expect(reloaded.saveId, 'p5_roundtrip_save');
      expect(reloaded.currentMapId, 'p5_new_game_map');
      expect(reloaded.playerPosition, const GridPos(x: 3, y: 4));
      expect(reloaded.playerFacing, EntityFacing.west);
      expect(reloaded.party.members, isEmpty);
      expect(reloaded.bag.entries, isEmpty);
      expect(reloaded.trainerProfile.money, 0);
      expect(reloaded.progression.completedStepIds, isEmpty);
    });

    test('does not hardcode Selbrume ids when resolving a map spawn', () {
      final state = createNewGameStateFromMap(startMap: newGameMap());

      expect(state.currentMapId.toLowerCase(), isNot(contains('selbrume')));
      expect(state.currentMapId.toLowerCase(), isNot(contains('lysa')));
      expect(state.currentMapId.toLowerCase(), isNot(contains('mael')));
      expect(state.currentMapId.toLowerCase(), isNot(contains('brume')));
    });
  });
}
