import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

const _playerLeft = BattlePositionRef(bank: 0, position: 0);
const _playerRight = BattlePositionRef(bank: 0, position: 1);
const _opponentLeft = BattlePositionRef(bank: 1, position: 0);
const _opponentRight = BattlePositionRef(bank: 1, position: 1);

void main() {
  group('PSDK multi-target resolution', () {
    test('resolves foe spread target families from alive topology', () {
      expect(_resolve(PsdkBattleMoveTarget.allFoes), <BattlePositionRef>[
        _opponentLeft,
        _opponentRight,
      ]);
      expect(
        _resolve(PsdkBattleMoveTarget.allAdjacentFoes),
        <BattlePositionRef>[_opponentLeft, _opponentRight],
      );
    });

    test('resolves adjacent battlers allies and all battlers in slot order',
        () {
      expect(_resolve(PsdkBattleMoveTarget.allAdjacent), <BattlePositionRef>[
        _playerRight,
        _opponentLeft,
        _opponentRight,
      ]);
      expect(_resolve(PsdkBattleMoveTarget.allAllies), <BattlePositionRef>[
        _playerRight,
      ]);
      expect(_resolve(PsdkBattleMoveTarget.allBattlers), <BattlePositionRef>[
        _playerLeft,
        _playerRight,
        _opponentLeft,
        _opponentRight,
      ]);
    });

    test('resolves optional single-target families without inventing misses',
        () {
      expect(
        _resolve(PsdkBattleMoveTarget.adjacentAlly),
        <BattlePositionRef>[_playerRight],
      );
      expect(
        _resolve(
          PsdkBattleMoveTarget.adjacentAlly,
          requestedTarget: _opponentLeft,
        ),
        isEmpty,
      );
      expect(
        _resolve(PsdkBattleMoveTarget.adjacentAllyOrSelf),
        <BattlePositionRef>[_playerLeft],
      );
      expect(
        _resolve(PsdkBattleMoveTarget.anyFoe),
        <BattlePositionRef>[_opponentLeft],
      );
      expect(
        _resolve(PsdkBattleMoveTarget.self, requestedTarget: _opponentLeft),
        <BattlePositionRef>[_playerLeft],
      );
    });

    test('filters fainted combatants from spread targets', () {
      final state = _state(
        faintedSlots: <PsdkBattleSlotRef>{
          const PsdkBattleSlotRef(bank: 1, position: 1),
        },
      );

      expect(
        _resolve(PsdkBattleMoveTarget.allFoes, state: state),
        <BattlePositionRef>[_opponentLeft],
      );
      expect(
        _resolve(PsdkBattleMoveTarget.allBattlers, state: state),
        <BattlePositionRef>[_playerLeft, _playerRight, _opponentLeft],
      );
    });

    test('side and field targets prepare without a battler target', () {
      final execution = _execution(
        state: _state(),
        move: _move(target: PsdkBattleMoveTarget.userSide),
        requestedTarget: null,
      );

      final result = const BattleMoveProcedure().prepare(execution);
      final events = execution.timeline.build().events;

      expect(result.shouldExecuteBehavior, isTrue);
      expect(result.targets, isEmpty);
      expect(execution.actualTargets, isEmpty);
      expect(events.whereType<BattleMoveDeclaredTimelineEvent>(), hasLength(1));
      expect(events.whereType<BattleAnimationCueTimelineEvent>(), hasLength(1));
      expect(events.whereType<BattleMoveFailedTimelineEvent>(), isEmpty);
    });

    test('random foe remains loud until target RNG is threaded through', () {
      expect(
        () => _resolve(PsdkBattleMoveTarget.randomFoe),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });
}

List<BattlePositionRef> _resolve(
  PsdkBattleMoveTarget target, {
  PsdkBattleState? state,
  BattlePositionRef? requestedTarget,
}) {
  return const BattleTargetResolver().resolve(
    _execution(
      state: state ?? _state(),
      move: _move(target: target),
      requestedTarget: requestedTarget,
    ),
  );
}

BattleMoveProcedureExecution _execution({
  required PsdkBattleState state,
  required BattleMoveDefinition move,
  required BattlePositionRef? requestedTarget,
}) {
  return BattleMoveProcedureExecution(
    context: BattleMoveBehaviorContext(
      state: state,
      rng: _rng(),
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

PsdkBattleState _state({
  Set<PsdkBattleSlotRef> faintedSlots = const <PsdkBattleSlotRef>{},
}) {
  final slots = <PsdkBattleSlotRef>[
    const PsdkBattleSlotRef(bank: 0, position: 0),
    const PsdkBattleSlotRef(bank: 0, position: 1),
    const PsdkBattleSlotRef(bank: 1, position: 0),
    const PsdkBattleSlotRef(bank: 1, position: 1),
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

BattleRngStreams _rng() {
  return BattleRngStreams.fromSeeds(
    moveDamageSeed: 1,
    moveCriticalSeed: 2,
    moveAccuracySeed: 3,
    genericSeed: 4,
  );
}
