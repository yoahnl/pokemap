import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

const _playerLeft = BattlePositionRef(bank: 0, position: 0);
const _playerMid = BattlePositionRef(bank: 0, position: 1);
const _opponentLeft = BattlePositionRef(bank: 1, position: 0);
const _opponentMid = BattlePositionRef(bank: 1, position: 1);
const _opponentRight = BattlePositionRef(bank: 1, position: 2);

void main() {
  group('PSDK target resolver double and multi-slot topology', () {
    test('keeps singles adjacent foe resolution unchanged', () {
      expect(
        _resolve(
          PsdkBattleMoveTarget.adjacentFoe,
          state: _singlesState(),
          requestedTarget: _opponentLeft,
        ),
        <BattlePositionRef>[_opponentLeft],
      );
    });

    test('filters non-adjacent slots from adjacent spread targets', () {
      expect(_resolve(PsdkBattleMoveTarget.allAdjacent), <BattlePositionRef>[
        _playerMid,
        _opponentLeft,
        _opponentMid,
      ]);
      expect(
        _resolve(PsdkBattleMoveTarget.allAdjacentFoes),
        <BattlePositionRef>[_opponentLeft, _opponentMid],
      );
    });

    test('distinguishes adjacent foe from any foe target families', () {
      expect(
        _resolve(
          PsdkBattleMoveTarget.adjacentFoe,
          requestedTarget: _opponentRight,
        ),
        isEmpty,
      );
      expect(
        _resolve(PsdkBattleMoveTarget.anyFoe, requestedTarget: _opponentRight),
        <BattlePositionRef>[_opponentRight],
      );
    });

    test('random foe selects from alive foes using generic RNG seed', () {
      expect(
        _resolve(PsdkBattleMoveTarget.randomFoe, genericSeed: 2),
        <BattlePositionRef>[_opponentRight],
      );

      final faintedRight = _state(
        faintedSlots: <PsdkBattleSlotRef>{
          const PsdkBattleSlotRef(bank: 1, position: 2),
        },
      );
      expect(
        _resolve(
          PsdkBattleMoveTarget.randomFoe,
          state: faintedRight,
          genericSeed: 2,
        ),
        <BattlePositionRef>[_opponentLeft],
      );
    });
  });
}

List<BattlePositionRef> _resolve(
  PsdkBattleMoveTarget target, {
  PsdkBattleState? state,
  BattlePositionRef? requestedTarget,
  int genericSeed = 4,
}) {
  return const BattleTargetResolver().resolve(
    _execution(
      state: state ?? _state(),
      move: _move(target: target),
      requestedTarget: requestedTarget,
      genericSeed: genericSeed,
    ),
  );
}

BattleMoveProcedureExecution _execution({
  required PsdkBattleState state,
  required BattleMoveDefinition move,
  required BattlePositionRef? requestedTarget,
  required int genericSeed,
}) {
  return BattleMoveProcedureExecution(
    context: BattleMoveBehaviorContext(
      state: state,
      rng: _rng(genericSeed: genericSeed),
      turn: 1,
      user: const PsdkBattleSlotRef(bank: 0, position: 0),
      target: const PsdkBattleSlotRef(bank: 1, position: 0),
      move: move,
    ),
    timeline: BattleTimelineBuilder(),
    user: _playerLeft,
    move: move,
    requestedTarget: requestedTarget,
  );
}

PsdkBattleState _singlesState() {
  return PsdkBattleState(
    combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
      const PsdkBattleSlotRef(bank: 0, position: 0):
          PsdkBattleCombatant.fromSetup(_combatant(id: 'player')),
      const PsdkBattleSlotRef(bank: 1, position: 0):
          PsdkBattleCombatant.fromSetup(_combatant(id: 'opponent')),
    },
  );
}

PsdkBattleState _state({
  Set<PsdkBattleSlotRef> faintedSlots = const <PsdkBattleSlotRef>{},
}) {
  final slots = <PsdkBattleSlotRef>[
    const PsdkBattleSlotRef(bank: 0, position: 0),
    const PsdkBattleSlotRef(bank: 0, position: 1),
    const PsdkBattleSlotRef(bank: 0, position: 2),
    const PsdkBattleSlotRef(bank: 1, position: 0),
    const PsdkBattleSlotRef(bank: 1, position: 1),
    const PsdkBattleSlotRef(bank: 1, position: 2),
  ];
  return PsdkBattleState(
    combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
      for (final slot in slots)
        slot: PsdkBattleCombatant.fromSetup(
          _combatant(
            id: 'b${slot.bank}p${slot.position}',
            currentHp: faintedSlots.contains(slot) ? 0 : 40,
          ),
        ),
    },
  );
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  int currentHp = 40,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 10,
    maxHp: 40,
    currentHp: currentHp,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: const PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: 50,
    ),
    moves: <PsdkBattleMoveData>[_move().psdkMove],
  );
}

BattleMoveDefinition _move({
  PsdkBattleMoveTarget target = PsdkBattleMoveTarget.adjacentFoe,
}) {
  return BattleMoveDefinition(
    id: 'swift',
    dbSymbol: 'swift',
    name: 'Swift',
    type: 'normal',
    category: PsdkBattleMoveCategory.special,
    power: 60,
    accuracy: 100,
    pp: 20,
    priority: 0,
    battleEngineMethod: 's_basic',
    target: target,
  );
}

BattleRngStreams _rng({required int genericSeed}) {
  return BattleRngStreams.fromSeeds(
    moveDamageSeed: 1,
    moveCriticalSeed: 2,
    moveAccuracySeed: 3,
    genericSeed: genericSeed,
  );
}
