import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

const _allySlot = PsdkBattleSlotRef(bank: 0, position: 1);

void main() {
  for (final helpingUser in [psdkPlayerSlot, psdkOpponentSlot]) {
    test(
        'singles Helping Hand from bank ${helpingUser.bank} fails without breaking turns',
        () {
      final engine = PsdkBattleEngine(
          setup: PsdkBattleSetup.singlesPokeMapBetaV1ForTest(
              player: _combatant('player',
                  move: helpingUser == psdkPlayerSlot
                      ? _helpingHand()
                      : _tackle()),
              opponent: _combatant('opponent',
                  move: helpingUser == psdkOpponentSlot
                      ? _helpingHand()
                      : _tackle()),
              rngSeeds: const PsdkBattleRngSeeds(
                  moveDamage: 1,
                  moveCritical: 2,
                  moveAccuracy: 3,
                  generic: 4)));
      for (var turn = 1; turn <= 2; turn++) {
        final result =
            engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
        final failures = result.timeline.events
            .whereType<PsdkBattleMoveFailedEvent>()
            .where((event) => event.moveId == 'helping_hand');
        expect(failures, hasLength(1));
        expect(failures.single.reason, 'no_target');
        expect(
            result.timeline.events
                .whereType<PsdkBattleMovePpSpentEvent>()
                .where((event) => event.moveId == 'helping_hand')
                .single
                .remainingPp,
            20 - turn);
        expect(result.state.battlerAt(helpingUser).moves.single.currentPp,
            20 - turn);
        expect(result.state.battlerAt(helpingUser).moves.single.id,
            'helping_hand');
        expect(result.state.battlerAt(helpingUser).moves.single.target,
            PsdkBattleMoveTarget.adjacentAlly);
        expect(
            result.timeline.events
                .whereType<PsdkBattleTurnStartedEvent>()
                .single
                .turn,
            turn);
        expect(
            result.timeline.events
                .whereType<PsdkBattleDamageEvent>()
                .where((event) => event.moveId == 'tackle'),
            hasLength(1));
        expect(
            result.timeline.events
                .whereType<PsdkBattleAnimationCueEvent>()
                .where((event) => event.moveId == 'helping_hand'),
            isEmpty);
        for (final battler in result.state.combatants.values) {
          expect(battler.effects.contains('helping_hand_mark'), isFalse);
        }
        expect(result.outcome, isNull);
      }
    });
  }

  test('unrequested adjacent ally action resolves a real living ally', () {
    final state = _state(allyHp: 100);
    final action = _action(state);
    expect(action.target, _allySlot);
    expect(_targets(state, action),
        [const BattlePositionRef(bank: 0, position: 1)]);
  });

  test('a fainted ally never becomes an effective Helping Hand target', () {
    final state = _state(allyHp: 0);
    expect(_targets(state, _action(state)), isEmpty);
  });

  test('an explicit foe target cannot be silently replaced with an ally', () {
    final state = _state(allyHp: 100);
    final action = _action(state, target: psdkOpponentSlot);
    expect(action.target, psdkOpponentSlot);
    expect(_targets(state, action), isEmpty);
  });

  test('ally or self retains its legal default self target', () {
    final state = _state(target: PsdkBattleMoveTarget.adjacentAllyOrSelf);
    final action = _action(state);
    expect(action.target, psdkPlayerSlot);
    expect(_targets(state, action),
        [const BattlePositionRef(bank: 0, position: 0)]);
  });
}

PsdkBattleFightAction _action(PsdkBattleState state,
        {PsdkBattleSlotRef? target}) =>
    const PsdkBattleActionDecisionMapper().map(
            state: state,
            user: psdkPlayerSlot,
            decision: BattleDecision.fight(moveSlot: 0, target: target))
        as PsdkBattleFightAction;

List<BattlePositionRef> _targets(
        PsdkBattleState state, PsdkBattleFightAction action) =>
    const BattleTargetResolver().resolve(BattleMoveProcedureExecution(
        context: BattleMoveBehaviorContext(
            state: state,
            rng: BattleRngStreams.fromSeeds(
                moveDamageSeed: 1,
                moveCriticalSeed: 2,
                moveAccuracySeed: 3,
                genericSeed: 4),
            turn: 1,
            user: action.user,
            target: action.target,
            move: BattleMoveDefinition.fromPsdk(action.move)),
        timeline: BattleTimelineBuilder(),
        user: BattlePositionRef(
            bank: action.user.bank, position: action.user.position),
        move: BattleMoveDefinition.fromPsdk(action.move),
        requestedTarget: BattlePositionRef(
            bank: action.target.bank, position: action.target.position)));

PsdkBattleState _state(
        {int? allyHp,
        PsdkBattleMoveTarget target = PsdkBattleMoveTarget.adjacentAlly}) =>
    PsdkBattleState.pokeMapBetaV1ForTest(combatants: {
      psdkPlayerSlot: PsdkBattleCombatant.fromSetup(
          _combatant('player', move: _helpingHand(target: target))),
      psdkOpponentSlot: PsdkBattleCombatant.fromSetup(
          _combatant('opponent', move: _tackle())),
      if (allyHp != null)
        _allySlot: PsdkBattleCombatant.fromSetup(
            _combatant('ally', move: _tackle(), currentHp: allyHp)),
    });

PsdkBattleCombatantSetup _combatant(String id,
        {required PsdkBattleMoveData move, int currentHp = 100}) =>
    PsdkBattleCombatantSetup(
        id: id,
        speciesId: id,
        displayName: id,
        level: 20,
        maxHp: 100,
        currentHp: currentHp,
        types: const PsdkBattleTypes(primary: 'normal'),
        stats: const PsdkBattleStats(
            attack: 30,
            defense: 50,
            specialAttack: 30,
            specialDefense: 50,
            speed: 30),
        moves: [move]);

PsdkBattleMoveData _helpingHand({
  PsdkBattleMoveTarget target = PsdkBattleMoveTarget.adjacentAlly,
}) =>
    PsdkBattleMoveData(
        id: 'helping_hand',
        dbSymbol: 'helping_hand',
        name: 'Helping Hand',
        type: 'normal',
        category: PsdkBattleMoveCategory.status,
        power: 0,
        accuracy: 0,
        pp: 20,
        priority: 5,
        battleEngineMethod: 's_helping_hand',
        target: target);

PsdkBattleMoveData _tackle() => PsdkBattleMoveData(
    id: 'tackle',
    dbSymbol: 'tackle',
    name: 'Tackle',
    type: 'normal',
    category: PsdkBattleMoveCategory.physical,
    power: 20,
    accuracy: 100,
    pp: 35,
    priority: 0,
    battleEngineMethod: 's_basic',
    target: PsdkBattleMoveTarget.adjacentFoe);
