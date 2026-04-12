import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  group('evaluateSurfAttempt', () {
    test('returns NotWater when target cell is not water', () {
      final result = evaluateSurfAttempt(
        gameState: _fullSurfGameState(),
        isTargetWater: false,
      );
      expect(result, isA<NotWater>());
    });

    test('returns AlreadySurfing when player is already in surf mode', () {
      final result = evaluateSurfAttempt(
        gameState: _fullSurfGameState().copyWith(
          playerMovementMode: MovementMode.surf,
        ),
        isTargetWater: true,
      );
      expect(result, isA<AlreadySurfing>());
    });

    test('returns MissingSurfCapablePokemon when no party member knows surf',
        () {
      const gameState = GameState(
        saveId: 'test',
        party: PlayerParty(members: [
          PlayerPokemon(
            speciesId: 'pikachu',
            natureId: 'timid',
            abilityId: 'static',
            knownMoveIds: ['thunderbolt'],
          ),
        ]),
        progression: PlayerProgression(
          unlockedFieldAbilities: [FieldAbility.surf],
        ),
      );
      final result = evaluateSurfAttempt(
        gameState: gameState,
        isTargetWater: true,
      );
      expect(result, isA<MissingSurfCapablePokemon>());
    });

    test('returns MissingSurfCapablePokemon when surf pokemon is fainted', () {
      const gameState = GameState(
        saveId: 'test',
        party: PlayerParty(members: [
          PlayerPokemon(
            speciesId: 'lapras',
            natureId: 'modest',
            abilityId: 'water-absorb',
            knownMoveIds: ['surf'],
            currentHp: 0,
          ),
        ]),
        progression: PlayerProgression(
          unlockedFieldAbilities: [FieldAbility.surf],
        ),
      );
      final result = evaluateSurfAttempt(
        gameState: gameState,
        isTargetWater: true,
      );
      expect(result, isA<MissingSurfCapablePokemon>());
    });

    test('returns MissingSurfCapablePokemon when party is empty', () {
      const gameState = GameState(
        saveId: 'test',
        progression: PlayerProgression(
          unlockedFieldAbilities: [FieldAbility.surf],
        ),
      );
      final result = evaluateSurfAttempt(
        gameState: gameState,
        isTargetWater: true,
      );
      expect(result, isA<MissingSurfCapablePokemon>());
    });

    test(
        'returns SurfNotUnlocked when pokemon knows surf but ability is locked',
        () {
      const gameState = GameState(
        saveId: 'test',
        party: PlayerParty(members: [
          PlayerPokemon(
            speciesId: 'lapras',
            natureId: 'modest',
            abilityId: 'water-absorb',
            knownMoveIds: ['surf'],
          ),
        ]),
        progression: PlayerProgression(
          unlockedFieldAbilities: [], // surf not unlocked
        ),
      );
      final result = evaluateSurfAttempt(
        gameState: gameState,
        isTargetWater: true,
      );
      expect(result, isA<SurfNotUnlocked>());
    });

    test('returns CanPromptSurf when all conditions are met', () {
      final result = evaluateSurfAttempt(
        gameState: _fullSurfGameState(),
        isTargetWater: true,
      );
      expect(result, isA<CanPromptSurf>());
    });

    test(
        'returns CanPromptSurf with multiple party members (one capable, one not)',
        () {
      const gameState = GameState(
        saveId: 'test',
        party: PlayerParty(members: [
          PlayerPokemon(
            speciesId: 'pikachu',
            natureId: 'timid',
            abilityId: 'static',
            knownMoveIds: ['thunderbolt'],
          ),
          PlayerPokemon(
            speciesId: 'lapras',
            natureId: 'modest',
            abilityId: 'water-absorb',
            knownMoveIds: ['surf', 'ice_beam'],
          ),
        ]),
        progression: PlayerProgression(
          unlockedFieldAbilities: [FieldAbility.surf],
        ),
      );
      final result = evaluateSurfAttempt(
        gameState: gameState,
        isTargetWater: true,
      );
      expect(result, isA<CanPromptSurf>());
    });
  });

  group('partyHasUsableFieldMove', () {
    test('returns true when a non-fainted member knows the move', () {
      const party = PlayerParty(members: [
        PlayerPokemon(
          speciesId: 'lapras',
          natureId: 'modest',
          abilityId: 'water-absorb',
          knownMoveIds: ['surf'],
        ),
      ]);
      expect(partyHasUsableFieldMove(party, FieldAbility.surf), isTrue);
    });

    test('returns false when the member knowing the move is fainted', () {
      const party = PlayerParty(members: [
        PlayerPokemon(
          speciesId: 'lapras',
          natureId: 'modest',
          abilityId: 'water-absorb',
          knownMoveIds: ['surf'],
          currentHp: 0,
        ),
      ]);
      expect(partyHasUsableFieldMove(party, FieldAbility.surf), isFalse);
    });

    test('returns false when no member knows the move', () {
      const party = PlayerParty(members: [
        PlayerPokemon(
          speciesId: 'pikachu',
          natureId: 'timid',
          abilityId: 'static',
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

GameState _fullSurfGameState() {
  return const GameState(
    saveId: 'test',
    party: PlayerParty(members: [
      PlayerPokemon(
        speciesId: 'lapras',
        natureId: 'modest',
        abilityId: 'water-absorb',
        level: 30,
        knownMoveIds: ['surf', 'ice_beam'],
      ),
    ]),
    progression: PlayerProgression(
      unlockedFieldAbilities: [FieldAbility.surf],
    ),
  );
}
