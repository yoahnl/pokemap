import 'package:map_battle/map_battle.dart';
import 'package:map_battle/src/domain/action/battle_shift_action_handler.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK misc battle actions', () {
    test('flee ends an eligible wild battle', () {
      final engine = BattleEngine(
        setup: _setup(
          canFlee: true,
          opponentMoves: <PsdkBattleMoveData>[_move(id: 'wait', power: 0)],
        ),
      );

      final result = engine.submit(const BattleDecision.flee());

      expect(result.outcome?.kind, BattleEngineOutcomeKind.fled);
      expect(result.nextRequest, isNull);
      expect(
        result.timeline.events
            .whereType<BattleFleeAttemptTimelineEvent>()
            .single,
        isA<BattleFleeAttemptTimelineEvent>()
            .having((event) => event.succeeded, 'succeeded', isTrue),
      );
    });

    test('flee fails in a trainer battle without ending the battle', () {
      final engine = BattleEngine(
        setup: _setup(
          canFlee: false,
          opponentMoves: <PsdkBattleMoveData>[_move(id: 'wait', power: 0)],
        ),
      );

      final result = engine.submit(const BattleDecision.flee());

      expect(result.outcome, isNull);
      expect(result.nextRequest, isNotNull);
      expect(
        result.timeline.events
            .whereType<BattleFleeAttemptTimelineEvent>()
            .single,
        isA<BattleFleeAttemptTimelineEvent>()
            .having((event) => event.succeeded, 'succeeded', isFalse),
      );
    });

    test('no action consumes the player action without move effects', () {
      final engine = BattleEngine(
        setup: _setup(
          opponentMoves: <PsdkBattleMoveData>[_move(id: 'wait', power: 0)],
        ),
      );

      final result = engine.submit(const BattleDecision.noAction());

      expect(result.outcome, isNull);
      expect(result.state.battlerAt(psdkPlayerSlot).moves.single.currentPp, 35);
      expect(
        result.timeline.events
            .whereType<BattleMovePpSpentTimelineEvent>()
            .map((event) => event.user),
        <BattlePositionRef>[const BattlePositionRef(bank: 1, position: 0)],
      );
    });

    test('shift swaps adjacent active battlers in the same bank', () {
      final left = _combatant(
        id: 'player-left',
        speciesId: 'leftmon',
        hp: 70,
      );
      final right = _combatant(
        id: 'player-right',
        speciesId: 'rightmon',
        hp: 80,
      );
      final state = PsdkBattleState(
        combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
          const PsdkBattleSlotRef(bank: 0, position: 0):
              PsdkBattleCombatant.fromSetup(left),
          const PsdkBattleSlotRef(bank: 0, position: 1):
              PsdkBattleCombatant.fromSetup(right),
          psdkOpponentSlot: PsdkBattleCombatant.fromSetup(
            _combatant(id: 'opponent', speciesId: 'opponent', hp: 90),
          ),
        },
      );

      final result = const BattleShiftActionHandler().shift(
        context: BattleHandlerContext(
          state: state,
          rng: BattleRngStreams.fromPsdkSeeds(
            const PsdkBattleRngSeeds(
              moveDamage: 1,
              moveCritical: 2,
              moveAccuracy: 3,
              generic: 4,
            ),
          ),
          turn: 1,
          user: const PsdkBattleSlotRef(bank: 0, position: 0),
        ),
        action: const PsdkBattleShiftAction(
          user: PsdkBattleSlotRef(bank: 0, position: 0),
          target: PsdkBattleSlotRef(bank: 0, position: 1),
        ),
      );

      expect(
        result.state
            .battlerAt(const PsdkBattleSlotRef(bank: 0, position: 0))
            .speciesId,
        'rightmon',
      );
      expect(
        result.state
            .battlerAt(const PsdkBattleSlotRef(bank: 0, position: 1))
            .speciesId,
        'leftmon',
      );
      expect(
        result.state
            .battlerAt(const PsdkBattleSlotRef(bank: 0, position: 0))
            .hasJustShifted,
        isTrue,
      );
    });
  });
}

BattleEngineSetup _setup({
  bool canFlee = false,
  List<PsdkBattleMoveData>? opponentMoves,
}) {
  return BattleEngineSetup.singles(
    canFlee: canFlee,
    player: _combatant(
      id: 'player-eevee',
      speciesId: 'eevee',
      hp: 100,
    ),
    opponent: _combatant(
      id: 'opponent-rattata',
      speciesId: 'rattata',
      hp: 70,
      moves: opponentMoves,
    ),
    rngSeeds: const PsdkBattleRngSeeds(
      moveDamage: 1,
      moveCritical: 99999,
      moveAccuracy: 3,
      generic: 4,
    ),
  );
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required String speciesId,
  required int hp,
  List<PsdkBattleMoveData>? moves,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: speciesId,
    displayName: speciesId,
    level: 20,
    maxHp: hp,
    currentHp: hp,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: const PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: 50,
    ),
    moves: moves ?? <PsdkBattleMoveData>[_move(id: 'tackle', power: 40)],
  );
}

PsdkBattleMoveData _move({
  required String id,
  required int power,
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: 'normal',
    category: PsdkBattleMoveCategory.physical,
    power: power,
    accuracy: 100,
    pp: 35,
    priority: 0,
    battleEngineMethod: 's_basic',
    target: PsdkBattleMoveTarget.adjacentFoe,
  );
}
