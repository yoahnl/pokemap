import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

const _player = BattlePositionRef(bank: 0, position: 0);
const _opponent = BattlePositionRef(bank: 1, position: 0);

void main() {
  group('PSDK move procedure parity seams', () {
    test('traces the PSDK pre-hit stage order for a successful move', () {
      final execution = _execution();

      final result = const BattleMoveProcedure(traceStages: true).prepare(
        execution,
      );
      final timeline = execution.timeline.build();

      expect(result.shouldExecuteBehavior, isTrue);
      expect(
        _traceStages(timeline),
        <BattleMoveProcedureStage>[
          BattleMoveProcedureStage.userAlive,
          BattleMoveProcedureStage.resolveTargets,
          BattleMoveProcedureStage.usableByUser,
          BattleMoveProcedureStage.usage,
          BattleMoveProcedureStage.preAccuracy,
          BattleMoveProcedureStage.noTarget,
          BattleMoveProcedureStage.accuracy,
          BattleMoveProcedureStage.remap,
          BattleMoveProcedureStage.immunity,
          BattleMoveProcedureStage.postAccuracy,
          BattleMoveProcedureStage.postAccuracyMove,
          BattleMoveProcedureStage.animation,
        ],
      );
      expect(timeline.psdkTimeline.events.map((event) => event.kind), <String>[
        'move_declared',
        'animation_cue',
      ]);
    });

    test('no-target failures stop before accuracy and keep PSDK events clean',
        () {
      final execution = _execution(
        state: PsdkBattleState(
          combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
            psdkPlayerSlot: PsdkBattleCombatant.fromSetup(
              _combatant(id: 'player'),
            ),
          },
        ),
      );

      final result = const BattleMoveProcedure(traceStages: true).prepare(
        execution,
      );
      final timeline = execution.timeline.build();

      expect(result.reason, BattleMoveFailureReason.noTarget);
      expect(
        _traceStages(timeline),
        <BattleMoveProcedureStage>[
          BattleMoveProcedureStage.userAlive,
          BattleMoveProcedureStage.resolveTargets,
          BattleMoveProcedureStage.usableByUser,
          BattleMoveProcedureStage.usage,
          BattleMoveProcedureStage.preAccuracy,
          BattleMoveProcedureStage.noTarget,
        ],
      );
      expect(timeline.psdkTimeline.events.map((event) => event.kind), <String>[
        'move_failed',
      ]);
    });

    test('miss failures stop before remap and immunity', () {
      final execution = _execution(accuracy: 1, moveAccuracySeed: 99);

      final result = const BattleMoveProcedure(traceStages: true).prepare(
        execution,
      );
      final timeline = execution.timeline.build();

      expect(result.reason, BattleMoveFailureReason.accuracy);
      expect(
        _traceStages(timeline),
        <BattleMoveProcedureStage>[
          BattleMoveProcedureStage.userAlive,
          BattleMoveProcedureStage.resolveTargets,
          BattleMoveProcedureStage.usableByUser,
          BattleMoveProcedureStage.usage,
          BattleMoveProcedureStage.preAccuracy,
          BattleMoveProcedureStage.noTarget,
          BattleMoveProcedureStage.accuracy,
        ],
      );
      expect(timeline.psdkTimeline.events.map((event) => event.kind), <String>[
        'move_declared',
        'miss',
      ]);
    });

    test('remapper can change actual targets after accuracy', () {
      final execution = _execution();

      final result = const BattleMoveProcedure(
        remapper: _SelfTargetRemapper(),
        traceStages: true,
      ).prepare(execution);

      expect(result.targets, <BattlePositionRef>[_player]);
      expect(execution.actualTargets, <BattlePositionRef>[_player]);
      expect(
        execution.timeline
            .build()
            .events
            .whereType<BattleAnimationCueTimelineEvent>()
            .single
            .targets,
        <BattlePositionRef>[_player],
      );
    });

    test('default immunity resolver removes type-immune targets', () {
      final execution = _execution(
        state: PsdkBattleState.fromSetup(
          _setup(
            _move().psdkMove,
            opponentTypes: const PsdkBattleTypes(primary: 'ghost'),
          ),
        ),
      );

      final result = BattleMoveProcedure(
        targetPrecheck: BattleMoveImmunityResolver().precheck,
        traceStages: true,
      ).prepare(execution);
      final timeline = execution.timeline.build();

      expect(result.reason, BattleMoveFailureReason.immunity);
      expect(
          timeline.events.map((event) => event.kind), contains('move_immune'));
      expect(
        timeline.events.map((event) => event.kind),
        isNot(contains('animation_cue')),
      );
      expect(
        _traceStages(timeline),
        containsAllInOrder(<BattleMoveProcedureStage>[
          BattleMoveProcedureStage.remap,
          BattleMoveProcedureStage.immunity,
        ]),
      );
    });

    test('history recorder centralizes attempt and success mutations', () {
      final state = PsdkBattleState.fromSetup(_setup(_move().psdkMove));
      const recorder = BattleMoveHistoryRecorder();

      final attempted = recorder.recordAttempt(
        state: state,
        user: psdkPlayerSlot,
        moveId: 'tackle',
        turn: 7,
        targets: const <PsdkBattleSlotRef>[psdkOpponentSlot],
      );
      final succeeded = recorder.recordSuccess(
        state: attempted,
        user: psdkPlayerSlot,
        moveId: 'tackle',
        turn: 7,
        targets: const <PsdkBattleSlotRef>[psdkOpponentSlot],
      );
      final history = succeeded.battlerAt(psdkPlayerSlot).moveHistory;

      expect(history.lastMoveId, 'tackle');
      expect(history.lastSuccessfulMoveId, 'tackle');
      expect(history.attempts.single.turn, 7);
      expect(history.successes.single.targets, const <PsdkBattleSlotRef>[
        psdkOpponentSlot,
      ]);
    });
  });
}

List<BattleMoveProcedureStage> _traceStages(BattleTimeline timeline) {
  return timeline.events
      .whereType<BattleMoveProcedureTraceEvent>()
      .map((event) => event.stage)
      .toList(growable: false);
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

PsdkBattleSetup _setup(
  PsdkBattleMoveData move, {
  PsdkBattleTypes opponentTypes = const PsdkBattleTypes(primary: 'normal'),
}) {
  return PsdkBattleSetup.singles(
    player: _combatant(id: 'player', moves: <PsdkBattleMoveData>[move]),
    opponent: _combatant(id: 'opponent', types: opponentTypes),
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
  PsdkBattleTypes types = const PsdkBattleTypes(primary: 'normal'),
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 10,
    maxHp: 40,
    currentHp: 40,
    types: types,
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

final class _SelfTargetRemapper implements BattleMoveRemapper {
  const _SelfTargetRemapper();

  @override
  BattleMoveRemapResult remap(BattleMoveRemapContext context) {
    return BattleMoveRemapResult(
      state: context.state,
      user: context.user,
      targets: <BattlePositionRef>[context.user],
    );
  }
}
