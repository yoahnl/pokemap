import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/battle_start_request.dart';
import 'package:map_runtime/src/application/runtime_battle_authoring_capability_truth.dart';
import 'package:map_runtime/src/application/runtime_battle_outcome_apply.dart';

void main() {
  test('runtime write-back consumes an authoring simulation outcome', () {
    final simulation = const BattleAuthoringSimulator().simulate(
      BattleAuthoringSimulationRequest(
        setup: const BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'hero',
            level: 5,
            maxHp: 20,
            stats: BattleStatsSnapshot(
              attack: 100,
              defense: 50,
              specialAttack: 50,
              specialDefense: 50,
              speed: 100,
            ),
            moves: <BattleMoveData>[
              BattleMoveData(id: 'finisher', name: 'Finisher', power: 100),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'wild',
            level: 5,
            maxHp: 5,
            stats: BattleStatsSnapshot(
              attack: 10,
              defense: 10,
              specialAttack: 10,
              specialDefense: 10,
              speed: 1,
            ),
            moves: <BattleMoveData>[
              BattleMoveData(id: 'tap', name: 'Tap', power: 1),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
        seed: 42,
      ),
    );
    const initialState = GameState(
      saveId: 'runtime-authoring-proof',
      party: PlayerParty(
        members: <PlayerPokemon>[
          PlayerPokemon(
            speciesId: 'hero',
            natureId: 'hardy',
            abilityId: 'overgrow',
            level: 5,
            knownMoveIds: <String>['finisher'],
            currentPpByMoveId: <String, int>{'finisher': 35},
            currentHp: 20,
          ),
        ],
      ),
    );

    final updated = applyRuntimeBattleOutcomeToGameState(
      gameState: initialState,
      context: RuntimeActiveBattleContext(
        request: _wildRequest(),
        playerPartyIndex: 0,
      ),
      outcome: simulation.outcome,
    );

    expect(
      updated.party.members.single.currentHp,
      simulation.outcome.finalState.player.currentHp,
    );
    expect(
      updated.party.members.single.currentPpByMoveId!['finisher'],
      simulation.outcome.finalState.player.moves.single.currentPp,
    );
    expect(
        initialState.party.members.single.currentPpByMoveId!['finisher'], 35);
  });

  test('runtime capability truth never promotes unsupported effects', () {
    final truth = RuntimeBattleAuthoringCapabilityTruth();

    for (final id in const <String>[
      'writeBack.playerHp',
      'writeBack.movePp',
      'writeBack.majorStatus',
      'writeBack.heldItem',
      'progression.experience',
      'progression.level',
      'progression.moves',
      'progression.evolution',
      'capture.destination',
      'reward.money',
      'reward.items',
      'reward.facts',
      'reward.badges',
    ]) {
      expect(
        truth.require(id).status,
        RuntimeBattleAuthoringSupportStatus.supported,
        reason: id,
      );
    }
    expect(
      truth.require('battle.registeredEffects').status,
      RuntimeBattleAuthoringSupportStatus.partial,
    );
    expect(
      truth.require('battle.unregisteredEffects').status,
      RuntimeBattleAuthoringSupportStatus.unsupported,
    );
  });
}

WildBattleStartRequest _wildRequest() {
  return const WildBattleStartRequest(
    requestId: 'authoring-proof',
    createdAtEpochMs: 1,
    returnContext: OverworldReturnContext(
      mapId: 'field',
      playerPos: GridPos(x: 1, y: 1),
      playerFacing: Direction.south,
    ),
    mapId: 'field',
    zoneId: 'grass',
    tableId: 'grass-table',
    encounterKind: EncounterKind.walk,
    speciesId: 'wild',
    level: 5,
    minLevel: 5,
    maxLevel: 5,
    weight: 1,
    playerPos: GridPos(x: 1, y: 1),
  );
}
