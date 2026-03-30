import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  group('evaluateSurfAttempt', () {
    test('returns NotWater when target cell is not water', () {
      final result = evaluateSurfAttempt(
        saveData: _fullSurfSave(),
        isTargetWater: false,
        currentMovementMode: MovementMode.walk,
      );
      expect(result, isA<NotWater>());
    });

    test('returns AlreadySurfing when player is already in surf mode', () {
      final result = evaluateSurfAttempt(
        saveData: _fullSurfSave(),
        isTargetWater: true,
        currentMovementMode: MovementMode.surf,
      );
      expect(result, isA<AlreadySurfing>());
    });

    test('returns MissingSurfCapablePokemon when no party member knows surf',
        () {
      const save = SaveData(
        saveId: 'test',
        party: PlayerParty(members: [
          PlayerPokemon(
            id: 'p1',
            speciesId: 'pikachu',
            knownMoveIds: ['thunderbolt'],
          ),
        ]),
        progression: PlayerProgression(
          unlockedFieldAbilities: [FieldAbility.surf],
        ),
      );
      final result = evaluateSurfAttempt(
        saveData: save,
        isTargetWater: true,
        currentMovementMode: MovementMode.walk,
      );
      expect(result, isA<MissingSurfCapablePokemon>());
    });

    test('returns MissingSurfCapablePokemon when surf pokemon is fainted', () {
      const save = SaveData(
        saveId: 'test',
        party: PlayerParty(members: [
          PlayerPokemon(
            id: 'p1',
            speciesId: 'lapras',
            knownMoveIds: ['surf'],
            isFainted: true,
          ),
        ]),
        progression: PlayerProgression(
          unlockedFieldAbilities: [FieldAbility.surf],
        ),
      );
      final result = evaluateSurfAttempt(
        saveData: save,
        isTargetWater: true,
        currentMovementMode: MovementMode.walk,
      );
      expect(result, isA<MissingSurfCapablePokemon>());
    });

    test('returns MissingSurfCapablePokemon when party is empty', () {
      const save = SaveData(
        saveId: 'test',
        progression: PlayerProgression(
          unlockedFieldAbilities: [FieldAbility.surf],
        ),
      );
      final result = evaluateSurfAttempt(
        saveData: save,
        isTargetWater: true,
        currentMovementMode: MovementMode.walk,
      );
      expect(result, isA<MissingSurfCapablePokemon>());
    });

    test(
        'returns SurfNotUnlocked when pokemon knows surf but ability is locked',
        () {
      const save = SaveData(
        saveId: 'test',
        party: PlayerParty(members: [
          PlayerPokemon(
            id: 'p1',
            speciesId: 'lapras',
            knownMoveIds: ['surf'],
          ),
        ]),
        progression: PlayerProgression(
          unlockedFieldAbilities: [], // surf not unlocked
        ),
      );
      final result = evaluateSurfAttempt(
        saveData: save,
        isTargetWater: true,
        currentMovementMode: MovementMode.walk,
      );
      expect(result, isA<SurfNotUnlocked>());
    });

    test('returns CanPromptSurf when all conditions are met', () {
      final result = evaluateSurfAttempt(
        saveData: _fullSurfSave(),
        isTargetWater: true,
        currentMovementMode: MovementMode.walk,
      );
      expect(result, isA<CanPromptSurf>());
    });

    test(
        'returns CanPromptSurf with multiple party members (one capable, one not)',
        () {
      const save = SaveData(
        saveId: 'test',
        party: PlayerParty(members: [
          PlayerPokemon(
            id: 'p1',
            speciesId: 'pikachu',
            knownMoveIds: ['thunderbolt'],
          ),
          PlayerPokemon(
            id: 'p2',
            speciesId: 'lapras',
            knownMoveIds: ['surf', 'ice_beam'],
          ),
        ]),
        progression: PlayerProgression(
          unlockedFieldAbilities: [FieldAbility.surf],
        ),
      );
      final result = evaluateSurfAttempt(
        saveData: save,
        isTargetWater: true,
        currentMovementMode: MovementMode.walk,
      );
      expect(result, isA<CanPromptSurf>());
    });
  });

  group('partyHasUsableFieldMove', () {
    test('returns true when a non-fainted member knows the move', () {
      const party = PlayerParty(members: [
        PlayerPokemon(
          id: 'p1',
          speciesId: 'lapras',
          knownMoveIds: ['surf'],
        ),
      ]);
      expect(partyHasUsableFieldMove(party, FieldAbility.surf), isTrue);
    });

    test('returns false when the member knowing the move is fainted', () {
      const party = PlayerParty(members: [
        PlayerPokemon(
          id: 'p1',
          speciesId: 'lapras',
          knownMoveIds: ['surf'],
          isFainted: true,
        ),
      ]);
      expect(partyHasUsableFieldMove(party, FieldAbility.surf), isFalse);
    });

    test('returns false when no member knows the move', () {
      const party = PlayerParty(members: [
        PlayerPokemon(
          id: 'p1',
          speciesId: 'pikachu',
          knownMoveIds: ['thunderbolt'],
        ),
      ]);
      expect(partyHasUsableFieldMove(party, FieldAbility.surf), isFalse);
    });

    test('returns false for empty party', () {
      const party = PlayerParty();
      expect(partyHasUsableFieldMove(party, FieldAbility.surf), isFalse);
    });
  });
}

SaveData _fullSurfSave() {
  return const SaveData(
    saveId: 'test',
    party: PlayerParty(members: [
      PlayerPokemon(
        id: 'p1',
        speciesId: 'lapras',
        level: 30,
        knownMoveIds: ['surf', 'ice_beam'],
      ),
    ]),
    progression: PlayerProgression(
      unlockedFieldAbilities: [FieldAbility.surf],
    ),
  );
}
