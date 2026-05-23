import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
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
      final reloaded = normalizeLoadedGameState(gameStateFromSaveData(saveData));

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
}
