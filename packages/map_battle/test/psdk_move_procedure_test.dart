import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

const _player = BattlePositionRef(bank: 0, position: 0);
const _opponent = BattlePositionRef(bank: 1, position: 0);

void main() {
  group('PSDK clean move procedure', () {
    test('declares the move then emits an animation cue for accurate targets',
        () {
      final execution = _execution(accuracy: 100);

      final result = const BattleMoveProcedure().prepare(execution);
      final timeline = execution.timeline.build();

      expect(result.shouldExecuteBehavior, isTrue);
      expect(execution.actualTargets, <BattlePositionRef>[_opponent]);
      expect(timeline.events.map((event) => event.kind), <String>[
        'move_declared',
        'animation_cue',
      ]);
    });

    test('miss emits no animation cue and carries the advanced RNG', () {
      final execution = _execution(
        accuracy: 1,
        moveAccuracySeed: 99,
      );

      final result = const BattleMoveProcedure().prepare(execution);
      final timeline = execution.timeline.build();

      expect(result.shouldExecuteBehavior, isFalse);
      expect(result.reason, BattleMoveFailureReason.accuracy);
      expect(result.rng.seeds.moveAccuracy, isNot(99));
      expect(timeline.events.map((event) => event.kind), <String>[
        'move_declared',
        'miss',
      ]);
    });

    test('no target emits a clean failure event and PSDK failure event', () {
      final execution = _execution(
        state: PsdkBattleState(
          combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
            psdkPlayerSlot: PsdkBattleCombatant.fromSetup(
              _combatant(id: 'player'),
            ),
          },
        ),
      );

      final result = const BattleMoveProcedure().prepare(execution);
      final timeline = execution.timeline.build();

      expect(result.shouldExecuteBehavior, isFalse);
      expect(result.reason, BattleMoveFailureReason.noTarget);
      expect(timeline.events.map((event) => event.kind), <String>[
        'move_declared',
        'move_failed',
      ]);
      expect(timeline.psdkTimeline.events.map((event) => event.kind), <String>[
        'move_failed',
      ]);
      expect(
        timeline.psdkTimeline.events.last.toJson(),
        containsPair('reason', 'no_target'),
      );
    });
  });
}

BattleMoveProcedureExecution _execution({
  int accuracy = 100,
  int moveAccuracySeed = 3,
  PsdkBattleState? state,
}) {
  final move = _move(accuracy: accuracy);
  return BattleMoveProcedureExecution(
    context: BattleMoveBehaviorContext(
      state: state ?? PsdkBattleState.fromSetup(_setup(move.psdkMove)),
      rng: BattleRngStreams.fromSeeds(
        moveDamageSeed: 1,
        moveCriticalSeed: 2,
        moveAccuracySeed: moveAccuracySeed,
        genericSeed: 4,
      ),
      turn: 1,
      user: psdkPlayerSlot,
      target: psdkOpponentSlot,
      move: move,
    ),
    timeline: BattleTimelineBuilder(),
    user: _player,
    move: move,
    requestedTarget: _opponent,
  );
}

PsdkBattleSetup _setup(PsdkBattleMoveData move) {
  return PsdkBattleSetup.singles(
    player: _combatant(id: 'player', moves: <PsdkBattleMoveData>[move]),
    opponent: _combatant(id: 'opponent'),
    rngSeeds: const PsdkBattleRngSeeds(
      moveDamage: 1,
      moveCritical: 2,
      moveAccuracy: 3,
      generic: 4,
    ),
  );
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  List<PsdkBattleMoveData>? moves,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 10,
    maxHp: 40,
    currentHp: 40,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: const PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: 50,
    ),
    moves: moves ?? <PsdkBattleMoveData>[_move().psdkMove],
  );
}

BattleMoveDefinition _move({int accuracy = 100}) {
  return BattleMoveDefinition(
    id: 'tackle',
    dbSymbol: 'tackle',
    name: 'Tackle',
    type: 'normal',
    category: PsdkBattleMoveCategory.physical,
    power: 40,
    accuracy: accuracy,
    pp: 35,
    priority: 0,
    battleEngineMethod: 's_basic',
    target: PsdkBattleMoveTarget.adjacentFoe,
  );
}
