import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/battle_start_request.dart';
import 'package:map_runtime/src/application/runtime_battle_outcome_apply.dart';

void main() {
  group('applyRuntimeBattleOutcomeToGameState', () {
    test('writes back the exact party slot used for the battle handoff', () {
      const initialState = GameState(
        saveId: 'save-slot',
        party: PlayerParty(
          members: <PlayerPokemon>[
            PlayerPokemon(
              speciesId: 'slot_zero',
              natureId: 'hardy',
              abilityId: 'pressure',
              level: 40,
              knownMoveIds: <String>['a'],
              currentHp: 91,
            ),
            PlayerPokemon(
              speciesId: 'slot_one_active',
              natureId: 'bold',
              abilityId: 'overgrow',
              level: 20,
              knownMoveIds: <String>['b'],
              currentHp: 35,
            ),
            PlayerPokemon(
              speciesId: 'slot_two_stays_alive',
              natureId: 'calm',
              abilityId: 'torrent',
              level: 22,
              knownMoveIds: <String>['c'],
              currentHp: 18,
            ),
          ],
        ),
      );

      final updatedState = applyRuntimeBattleOutcomeToGameState(
        gameState: initialState,
        context: RuntimeActiveBattleContext(
          request: _wildRequest(),
          playerPartyIndex: 1,
        ),
        outcome: _finishedOutcome(
          type: BattleOutcomeType.defeat,
          playerCurrentHp: 0,
        ),
      );

      expect(updatedState.party.members[0].currentHp, equals(91));
      expect(updatedState.party.members[1].currentHp, equals(0));
      expect(updatedState.party.members[2].currentHp, equals(18));
    });

    test('trainer victory writes player hp and marks trainer as defeated', () {
      final updatedState = applyRuntimeBattleOutcomeToGameState(
        gameState: _baseState(),
        context: RuntimeActiveBattleContext(
          request: _trainerRequest(trainerId: 'ace_jules'),
          playerPartyIndex: 0,
        ),
        outcome: _finishedOutcome(
          type: BattleOutcomeType.victory,
          playerCurrentHp: 14,
        ),
      );

      expect(updatedState.party.members[0].currentHp, equals(14));
      expect(
        updatedState.storyFlags.activeFlags,
        contains('trainer_defeated:ace_jules'),
      );
    });

    test('trainer defeat writes player hp without marking trainer defeated',
        () {
      final updatedState = applyRuntimeBattleOutcomeToGameState(
        gameState: _baseState(),
        context: RuntimeActiveBattleContext(
          request: _trainerRequest(trainerId: 'ace_jules'),
          playerPartyIndex: 0,
        ),
        outcome: _finishedOutcome(
          type: BattleOutcomeType.defeat,
          playerCurrentHp: 0,
        ),
      );

      expect(updatedState.party.members[0].currentHp, equals(0));
      expect(
        updatedState.storyFlags.activeFlags,
        isNot(contains('trainer_defeated:ace_jules')),
      );
    });

    test('runaway writes player hp without marking trainer defeated', () {
      final updatedState = applyRuntimeBattleOutcomeToGameState(
        gameState: _baseState(),
        context: RuntimeActiveBattleContext(
          request: _trainerRequest(trainerId: 'ace_jules'),
          playerPartyIndex: 0,
        ),
        outcome: _finishedOutcome(
          type: BattleOutcomeType.runaway,
          playerCurrentHp: 11,
        ),
      );

      expect(updatedState.party.members[0].currentHp, equals(11));
      expect(
        updatedState.storyFlags.activeFlags,
        isNot(contains('trainer_defeated:ace_jules')),
      );
    });

    test('captured wild battle appends the pokemon and syncs caught/seen', () {
      final updatedState = applyRuntimeBattleOutcomeToGameState(
        gameState: _baseState(),
        context: RuntimeActiveBattleContext(
          request: _wildRequest(),
          playerPartyIndex: 0,
        ),
        outcome: _finishedOutcome(
          type: BattleOutcomeType.captured,
          playerCurrentHp: 19,
          enemySpeciesId: 'wildmon',
          enemyLevel: 12,
          enemyCurrentHp: 7,
          enemyAbilityId: 'intimidate',
          enemyMoveIds: const <String>['scratch', 'leer'],
        ),
      );

      expect(updatedState.party.members[0].currentHp, equals(19));
      expect(updatedState.party.members, hasLength(3));

      final captured = updatedState.party.members.last;
      expect(captured.speciesId, equals('wildmon'));
      expect(captured.level, equals(12));
      expect(captured.abilityId, equals('intimidate'));
      expect(captured.natureId, equals('hardy'));
      expect(captured.knownMoveIds, equals(<String>['scratch', 'leer']));
      expect(captured.currentHp, equals(7));
      expect(updatedState.progression.caughtSpeciesIds, contains('wildmon'));
      expect(updatedState.progression.seenSpeciesIds, contains('wildmon'));
    });

    test('captured outcome is rejected for trainer battles', () {
      expect(
        () => applyRuntimeBattleOutcomeToGameState(
          gameState: _baseState(),
          context: RuntimeActiveBattleContext(
            request: _trainerRequest(trainerId: 'ace_jules'),
            playerPartyIndex: 0,
          ),
          outcome: _finishedOutcome(
            type: BattleOutcomeType.captured,
            playerCurrentHp: 19,
            enemySpeciesId: 'wildmon',
            enemyLevel: 12,
            enemyCurrentHp: 7,
            enemyAbilityId: 'intimidate',
            enemyMoveIds: const <String>['scratch'],
          ),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('captured outcome is rejected when the party is already full', () {
      final fullPartyState = _baseState().copyWith(
        party: PlayerParty(
          members: <PlayerPokemon>[
            ..._baseState().party.members,
            const PlayerPokemon(
              speciesId: 'party_2',
              natureId: 'hardy',
              abilityId: 'pressure',
              level: 10,
              knownMoveIds: <String>['growl'],
              currentHp: 10,
            ),
            const PlayerPokemon(
              speciesId: 'party_3',
              natureId: 'hardy',
              abilityId: 'pressure',
              level: 10,
              knownMoveIds: <String>['growl'],
              currentHp: 10,
            ),
            const PlayerPokemon(
              speciesId: 'party_4',
              natureId: 'hardy',
              abilityId: 'pressure',
              level: 10,
              knownMoveIds: <String>['growl'],
              currentHp: 10,
            ),
            const PlayerPokemon(
              speciesId: 'party_5',
              natureId: 'hardy',
              abilityId: 'pressure',
              level: 10,
              knownMoveIds: <String>['growl'],
              currentHp: 10,
            ),
          ],
        ),
      );

      expect(
        () => applyRuntimeBattleOutcomeToGameState(
          gameState: fullPartyState,
          context: RuntimeActiveBattleContext(
            request: _wildRequest(),
            playerPartyIndex: 0,
          ),
          outcome: _finishedOutcome(
            type: BattleOutcomeType.captured,
            playerCurrentHp: 19,
            enemySpeciesId: 'wildmon',
            enemyLevel: 12,
            enemyCurrentHp: 7,
            enemyAbilityId: 'intimidate',
            enemyMoveIds: const <String>['scratch'],
          ),
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}

GameState _baseState() {
  return const GameState(
    saveId: 'save-1',
    party: PlayerParty(
      members: <PlayerPokemon>[
        PlayerPokemon(
          speciesId: 'sproutle',
          natureId: 'bold',
          abilityId: 'overgrow',
          level: 12,
          knownMoveIds: <String>['growl', 'vine_whip'],
          currentHp: 23,
        ),
        PlayerPokemon(
          speciesId: 'benchmon',
          natureId: 'hardy',
          abilityId: 'pressure',
          level: 18,
          knownMoveIds: <String>['leer'],
          currentHp: 17,
        ),
      ],
    ),
  );
}

BattleOutcome _finishedOutcome({
  required BattleOutcomeType type,
  required int playerCurrentHp,
  String enemySpeciesId = 'aquafi',
  int enemyLevel = 18,
  int enemyCurrentHp = 0,
  String enemyAbilityId = 'torrent',
  List<String> enemyMoveIds = const <String>['water_gun'],
}) {
  final finalState = BattleState(
    phase: BattlePhase.finished,
    player: BattleCombatant(
      speciesId: 'sproutle',
      level: 12,
      currentHp: playerCurrentHp,
      maxHp: 32,
      moves: const <BattleMove>[
        BattleMove(id: 'growl', name: 'Growl', power: 0),
      ],
    ),
    enemy: BattleCombatant(
      speciesId: enemySpeciesId,
      level: enemyLevel,
      currentHp: enemyCurrentHp,
      maxHp: 35,
      abilityId: enemyAbilityId,
      moves: enemyMoveIds
          .map(
            (moveId) => BattleMove(
              id: moveId,
              name: moveId,
              power: 10,
            ),
          )
          .toList(growable: false),
    ),
    currentTurn: null,
    outcome: null,
  );

  return BattleOutcome(
    type: type,
    finalState: finalState,
  );
}

WildBattleStartRequest _wildRequest() {
  return const WildBattleStartRequest(
    requestId: 'wild-request',
    createdAtEpochMs: 1,
    returnContext: OverworldReturnContext(
      mapId: 'field_map',
      playerPos: GridPos(x: 1, y: 1),
      playerFacing: Direction.south,
    ),
    mapId: 'field_map',
    zoneId: 'grass',
    tableId: 'field_grass',
    encounterKind: EncounterKind.walk,
    speciesId: 'wildmon',
    level: 12,
    minLevel: 12,
    maxLevel: 12,
    weight: 30,
    playerPos: GridPos(x: 1, y: 1),
  );
}

TrainerBattleStartRequest _trainerRequest({required String trainerId}) {
  return TrainerBattleStartRequest(
    requestId: 'trainer-request',
    createdAtEpochMs: 1,
    returnContext: const OverworldReturnContext(
      mapId: 'field_map',
      playerPos: GridPos(x: 1, y: 1),
      playerFacing: Direction.south,
    ),
    trainerId: trainerId,
    npcEntityId: 'npc_ace',
    mapId: 'field_map',
    playerPos: const GridPos(x: 1, y: 1),
  );
}
