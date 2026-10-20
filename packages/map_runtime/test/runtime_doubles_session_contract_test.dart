import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/battle_start_request.dart';
import 'package:map_runtime/src/application/runtime_battle_outcome_apply.dart';
import 'package:map_runtime/src/application/runtime_battle_progression_context_mapper.dart';
import 'package:map_runtime/src/application/runtime_psdk_battle_session_adapter.dart';

const _playerLeft = PsdkBattleSlotRef(bank: 0, position: 0);
const _playerRight = PsdkBattleSlotRef(bank: 0, position: 1);
const _opponentLeft = PsdkBattleSlotRef(bank: 1, position: 0);
const _opponentRight = PsdkBattleSlotRef(bank: 1, position: 1);
const _playerRightProjection = BattleSlotRef(
  side: BattleSideId.player,
  slotIndex: 1,
);
const _opponentRightProjection = BattleSlotRef(
  side: BattleSideId.enemy,
  slotIndex: 1,
);

void main() {
  test(
    'the real doubles adapter projects four distinct active slots and requests',
    () {
      final adapter = _adapter();
      final presentation = adapter.presentation;

      expect(adapter.isDoubles, isTrue);
      expect(presentation.isDoubles, isTrue);
      expect(presentation.activeCombatants, hasLength(4));
      expect(presentation.combatantsBySlot.keys.toSet(), {
        const BattleSlotRef.active(BattleSideId.player),
        _playerRightProjection,
        const BattleSlotRef.active(BattleSideId.enemy),
        _opponentRightProjection,
      });
      expect(
        presentation.activeCombatants.map((active) => active.combatantId),
        ['player_0', 'player_1', 'opponent_0', 'opponent_1'],
      );
      expect(presentation.combatantAt(_playerRightProjection)!.lineupIndex, 1);
      expect(
        presentation.combatantAt(_opponentRightProjection)!.lineupIndex,
        1,
      );
      expect(presentation.playerParty, hasLength(4));
      expect(identical(presentation.request, adapter.decisionRequest), isTrue);
      expect(
        () => presentation.activeCombatants.clear(),
        throwsUnsupportedError,
      );
      expect(
        () => presentation.combatantsBySlot.clear(),
        throwsUnsupportedError,
      );
    },
  );

  test(
    'two public choices preserve actor and target slot one through translation',
    () {
      final adapter = _adapter();
      final first = adapter.decisionRequest;
      final before = adapter.state;
      final pending = adapter.submitPlayerChoice(
        const PlayerBattleChoiceFight(0),
        request: first,
        target: _opponentLeft,
      );

      expect(pending.timeline.events, isEmpty);
      expect(adapter.state.turnNumber, 0);
      expect(adapter.state.rngSeeds.generic, before.rngSeeds.generic);
      expect(adapter.state.battlerAt(_playerLeft).moves.single.currentPp, 8);
      expect(adapter.state.battlerAt(_playerRight).moves.single.currentPp, 7);
      final second = adapter.presentation.request;
      expect(second.actor, _playerRight);
      expect(second.actorCombatantId, 'player_1');
      expect(second.requestRevision, greaterThan(first.requestRevision));
      expect(
        () => adapter.submitPlayerChoice(
          const PlayerBattleChoiceFight(0),
          request: first,
          target: _opponentRight,
        ),
        throwsA(isA<BattleDecisionRejectedError>()),
      );
      expect(identical(adapter.decisionRequest, second), isTrue);

      final resolved = adapter.submitPlayerChoice(
        const PlayerBattleChoiceFight(0),
        request: second,
        target: _opponentRight,
      );
      final actorTwo = resolved.timeline.events
          .whereType<BattleMoveDeclaredTimelineEvent>()
          .singleWhere(
            (event) =>
                event.user == const BattlePositionRef(bank: 0, position: 1),
          );
      expect(actorTwo.moveId, 'contract-hit-1');
      expect(actorTwo.targets, const [BattlePositionRef(bank: 1, position: 1)]);
      final translated = adapter
          .createLegacyDisplaySession(isTrainerBattle: true)
          .state
          .currentTurn!
          .executions
          .singleWhere(
            (execution) => execution.attackerSlot == _playerRightProjection,
          );
      expect(translated.targetSlot, _opponentRightProjection);
      expect(translated.move.id, 'contract-hit-1');
      expect(adapter.state.battlerAt(_playerLeft).moves.single.currentPp, 7);
      expect(adapter.state.battlerAt(_playerRight).moves.single.currentPp, 6);
    },
  );

  test('switching both slots writes HP PP and status by individual identity after reorder', () {
    final adapter = _adapter(withStatuses: true);
    adapter.submitDecision(
      const BattleDecision.switchPokemon(partyIndex: 2),
      request: adapter.decisionRequest,
    );
    adapter.submitDecision(
      const BattleDecision.switchPokemon(partyIndex: 3),
      request: adapter.decisionRequest,
    );
    final projected = adapter.presentation;
    expect(
      projected
          .combatantAt(const BattleSlotRef.active(BattleSideId.player))!
          .combatantId,
      'player_2',
    );
    expect(
      projected.combatantAt(_playerRightProjection)!.combatantId,
      'player_3',
    );
    expect(projected.combatantAt(_playerRightProjection)!.lineupIndex, 3);
    final reordered = _savedState(order: const [3, 1, 0, 2]);
    final written = writePlayerBattleLineupBackToPartySlots(
      gameState: reordered,
      context: _context(),
      battleState: adapter.createLegacyWriteBackState(),
    );

    expect(
      written.party.members.map((member) => member.individualId),
      reordered.party.members.map((member) => member.individualId),
    );
    _expectIdentityWriteback(adapter, written);
    for (final original in reordered.party.members) {
      final member = written.party.members.singleWhere(
        (member) => member.individualId == original.individualId,
      );
      expect(member.experience, original.experience);
      expect(member.nickname, original.nickname);
    }
    expect(
      written.party.members
          .singleWhere((m) => m.individualId == 'individual-0')
          .statusId,
      'brn',
    );
    expect(
      written.party.members
          .singleWhere((m) => m.individualId == 'individual-1')
          .statusId,
      'psn',
    );
    expect(
      written.party.members
          .singleWhere((m) => m.individualId == 'individual-2')
          .statusId,
      'slp',
    );
    expect(
      written.party.members
          .singleWhere((m) => m.individualId == 'individual-3')
          .statusId,
      'par',
    );
  });

  test('a real doubles victory maps both participants to identity based writeback and XP', () {
    final adapter = _adapter(finishingMove: true);
    adapter.submitPlayerChoice(
      const PlayerBattleChoiceFight(0),
      request: adapter.decisionRequest,
      target: _opponentLeft,
    );
    adapter.submitPlayerChoice(
      const PlayerBattleChoiceFight(0),
      request: adapter.decisionRequest,
      target: _opponentRight,
    );
    expect(adapter.state.outcome?.kind, BattleEngineOutcomeKind.victory);
    final outcome = adapter.createLegacyOutcome(
      isTrainerBattle: true,
      trainerId: _trainerRequest.trainerId,
    );
    expect(outcome.playerParticipantLineupIndexes, {0, 1});
    final original = _savedState(order: const [3, 1, 0, 2]);
    final written = applyRuntimeBattleOutcomeToGameState(
      gameState: original,
      context: _context(),
      outcome: outcome,
    );
    _expectIdentityWriteback(adapter, written);
    final progression = const RuntimeBattleProgressionContextMapper()
        .fromLegacyOutcome(
          runtimeContext: _context(),
          outcome: outcome,
          gameState: written,
          partyLength: written.party.members.length,
          defeatedOpponents: const [
            BattleProgressionDefeatedOpponent(level: 20, baseExperience: 14),
            BattleProgressionDefeatedOpponent(level: 20, baseExperience: 14),
          ],
          partySlotMetadata: [
            for (var index = 0; index < written.party.members.length; index++)
              BattleProgressionPartySlotMetadata(
                partySlot: index,
                growthRateId: 'medium_fast',
                oldMaxHp: 100,
                baseStats: const PokemonBaseStats(
                  hp: 50,
                  attack: 50,
                  defense: 50,
                  specialAttack: 50,
                  specialDefense: 50,
                  speed: 50,
                ),
              ),
          ],
          ruleset: PokemonRulesetProfile.standardV1,
        );
    expect(progression.playerParticipantPartySlots, {1, 2});
    final awarded = const BattleProgressionService().apply(
      state: written,
      context: progression,
      reward: BattleReward(
        sourceKind: BattleRewardSourceKind.trainer,
        trainerId: _trainerRequest.trainerId,
      ),
      applyAuthoredRewards: false,
    );
    for (var index = 0; index < 4; index++) {
      final member = awarded.state.party.members.singleWhere(
        (member) => member.individualId == 'individual-$index',
      );
      expect(member.experience, 8000 + index * 100 + (index < 2 ? 60 : 0));
    }
  });
}

RuntimePsdkBattleSessionAdapter _adapter({
  bool withStatuses = false,
  bool finishingMove = false,
}) {
  const statuses = [
    PsdkBattleMajorStatus.burn,
    PsdkBattleMajorStatus.poison,
    PsdkBattleMajorStatus.sleep,
    PsdkBattleMajorStatus.paralysis,
  ];
  PsdkBattleCombatantSetup player(int index) => _combatant(
    id: 'player_$index',
    hp: 90 - index * 10,
    speed: 100 - index,
    status: withStatuses ? statuses[index] : null,
    move: _move(
      index: index,
      power: finishingMove && index == 0 ? 10000 : 10,
      target: finishingMove && index == 0
          ? PsdkBattleMoveTarget.allAdjacentFoes
          : PsdkBattleMoveTarget.adjacentFoe,
    ),
  );
  return RuntimePsdkBattleSessionAdapter.fromSetup(
    PsdkBattleSetup.doubles(
      ruleset: PokemonRulesetProfile.standardV1,
      player: [player(0), player(1)],
      playerReserves: [player(2), player(3)],
      opponent: [
        for (var index = 0; index < 2; index++)
          _combatant(
            id: 'opponent_$index',
            hp: 100,
            speed: 10 + index,
            move: _move(index: 9, power: 0, target: PsdkBattleMoveTarget.self),
          ),
      ],
      rngSeeds: const PsdkBattleRngSeeds(
        moveDamage: 14,
        moveCritical: 99999,
        moveAccuracy: 1,
        generic: 1,
      ),
    ),
  );
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required int hp,
  required int speed,
  required PsdkBattleMoveData move,
  PsdkBattleMajorStatus? status,
}) => PsdkBattleCombatantSetup(
  id: id,
  speciesId: 'same-species',
  displayName: id,
  level: 20,
  maxHp: 100,
  currentHp: hp,
  majorStatus: status,
  sleepTurns: status == PsdkBattleMajorStatus.sleep ? 2 : 0,
  types: const PsdkBattleTypes(primary: 'normal'),
  stats: PsdkBattleStats(
    attack: 50,
    defense: 50,
    specialAttack: 50,
    specialDefense: 50,
    speed: speed,
  ),
  moves: [move],
);

PsdkBattleMoveData _move({
  required int index,
  required int power,
  required PsdkBattleMoveTarget target,
}) => PsdkBattleMoveData(
  id: 'contract-hit-$index',
  dbSymbol: 'contract_hit_$index',
  name: 'Contract hit $index',
  type: 'normal',
  category: power == 0
      ? PsdkBattleMoveCategory.status
      : PsdkBattleMoveCategory.physical,
  power: power,
  accuracy: 100,
  pp: 10,
  currentPp: index < 4 ? 8 - index : 10,
  priority: 0,
  battleEngineMethod: 's_basic',
  target: target,
);

GameState _savedState({required List<int> order}) => GameState(
  saveId: 'doubles-session-contract',
  party: PlayerParty(
    members: [
      for (final index in order)
        PlayerPokemon(
          individualId: 'individual-$index',
          speciesId: 'same-species',
          nickname: 'Member $index',
          natureId: 'hardy',
          abilityId: 'unknown',
          level: 20,
          currentHp: 100,
          knownMoveIds: ['contract-hit-$index'],
          currentPpByMoveId: {'contract-hit-$index': 8 - index},
          experience: 8000 + index * 100,
        ),
    ],
  ),
);

const _trainerRequest = TrainerBattleStartRequest(
  requestId: 'doubles-session-contract',
  createdAtEpochMs: 1,
  returnContext: OverworldReturnContext(
    mapId: 'field',
    playerPos: GridPos(x: 1, y: 1),
    playerFacing: Direction.south,
  ),
  trainerId: 'contract-trainer',
  npcEntityId: 'contract-npc',
  mapId: 'field',
  playerPos: GridPos(x: 1, y: 1),
);

RuntimeActiveBattleContext _context() =>
    RuntimeActiveBattleContext.withLineupMapping(
      request: _trainerRequest,
      playerPartyIndex: 0,
      playerIndividualId: 'individual-0',
      playerPartySlotIndicesByLineupIndex: const [0, 1, 2, 3],
      playerIndividualIdsByLineupIndex: const [
        'individual-0',
        'individual-1',
        'individual-2',
        'individual-3',
      ],
    );

void _expectIdentityWriteback(
  RuntimePsdkBattleSessionAdapter adapter,
  GameState written,
) {
  final party = adapter.state.partyForBank(0);
  for (var index = 0; index < party.length; index++) {
    final engine = party[index];
    final saved = written.party.members.singleWhere(
      (member) => member.individualId == 'individual-$index',
    );
    expect(saved.speciesId, 'same-species');
    expect(saved.currentHp, engine.currentHp);
    expect(saved.currentPpByMoveId, {
      'contract-hit-$index': engine.moves.single.currentPp,
    });
  }
}
