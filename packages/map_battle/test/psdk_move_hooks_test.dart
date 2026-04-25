import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

const _player = BattlePositionRef(bank: 0, position: 0);
const _opponent = BattlePositionRef(bank: 1, position: 0);

void main() {
  group('PSDK clean move procedure hooks', () {
    test('user prevention blocks before PP, declaration and RNG', () {
      const seeds = BattleRngSeeds(
        moveDamage: 1,
        moveCritical: 99999,
        moveAccuracy: 3,
        generic: 4,
      );
      final failures = <BattleMoveFailureContext>[];
      final engine = BattleEngine(
        setup: _setup(
          playerMove: _move(
            id: 'blocked_tackle',
            type: 'normal',
            pp: 1,
          ),
          rngSeeds: seeds.psdkSeeds,
        ),
        moveProcedureHooks: BattleMoveProcedureHooks(
          userPreventionHooks: <BattleMoveUserPreventionHook>[
            (context) {
              if (context.move.id != 'blocked_tackle') {
                return null;
              }
              return const BattleMoveUserPreventionResult(
                reason: BattleMoveFailureReason.unusableByUser,
              );
            },
          ],
          failureHooks: <BattleMoveFailureHook>[failures.add],
        ),
      );

      final result = engine.submit(const BattleDecision.fight(moveSlot: 0));
      final player = result.state.battlerAt(psdkPlayerSlot);
      final playerEvents = result.timeline.events
          .where((event) => event.toJson()['moveId'] == 'blocked_tackle')
          .toList(growable: false);

      expect(player.moves.single.currentPp, 1);
      expect(player.moveHistory.lastMoveId, 'blocked_tackle');
      expect(player.moveHistory.lastSuccessfulMoveId, isNull);
      expect(result.state.rngSeeds.moveAccuracy, seeds.moveAccuracy);
      expect(playerEvents.map((event) => event.kind), <String>['move_failed']);
      expect(playerEvents.single.toJson()['reason'], 'unusable_by_user');
      expect(
        failures
            .where((failure) => failure.move.id == 'blocked_tackle')
            .map((failure) => failure.reason),
        <BattleMoveFailureReason>[BattleMoveFailureReason.unusableByUser],
      );
    });

    test('procedure hooks wrap a successful accuracy and animation cue', () {
      final calls = <String>[];
      final hooks = BattleMoveProcedureHooks(
        preAccuracyHooks: <BattleMoveAccuracyHook>[
          (context) => calls.add('pre:${context.targets.single}'),
        ],
        postAccuracyHooks: <BattleMoveAccuracyHook>[
          (context) => calls.add('post:${context.targets.single}'),
        ],
        postAccuracyMoveHooks: <BattleMoveAccuracyHook>[
          (context) => calls.add('post_move:${context.targets.single}'),
        ],
      );
      final execution = _execution();

      final result = BattleMoveProcedure(hooks: hooks).prepare(execution);

      expect(result.shouldExecuteBehavior, isTrue);
      expect(calls, <String>[
        'pre:$_opponent',
        'post:$_opponent',
        'post_move:$_opponent',
      ]);
    });

    test('pre accuracy hook runs before a no-target failure', () {
      final calls = <String>[];
      final execution = _execution(
        state: PsdkBattleState(
          combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
            psdkPlayerSlot: PsdkBattleCombatant.fromSetup(
              _combatant(
                id: 'player',
                speed: 100,
                types: const PsdkBattleTypes(primary: 'normal'),
                moves: <PsdkBattleMoveData>[
                  _move(id: 'tackle', type: 'normal'),
                ],
              ),
            ),
          },
        ),
      );

      final result = BattleMoveProcedure(
        hooks: BattleMoveProcedureHooks(
          preAccuracyHooks: <BattleMoveAccuracyHook>[
            (context) => calls.add('pre:${context.targets.length}'),
          ],
          failureHooks: <BattleMoveFailureHook>[
            (context) => calls.add('failure:${context.reason.jsonName}'),
          ],
        ),
      ).prepare(execution);

      expect(result.reason, BattleMoveFailureReason.noTarget);
      expect(calls, <String>['pre:0', 'failure:no_target']);
    });

    test('post accuracy hooks are skipped when precheck removes all targets',
        () {
      final calls = <String>[];
      final execution = _execution();

      final result = BattleMoveProcedure(
        hooks: BattleMoveProcedureHooks(
          postAccuracyHooks: <BattleMoveAccuracyHook>[
            (_) => calls.add('post'),
          ],
          postAccuracyMoveHooks: <BattleMoveAccuracyHook>[
            (_) => calls.add('post_move'),
          ],
          failureHooks: <BattleMoveFailureHook>[
            (context) => calls.add('failure:${context.reason.jsonName}'),
          ],
        ),
        targetPrecheck: (_, __) => BattleMoveTargetPrecheckResult(
          targets: const <BattlePositionRef>[],
          reason: BattleMoveFailureReason.immunity,
        ),
      ).prepare(execution);

      expect(result.reason, BattleMoveFailureReason.immunity);
      expect(calls, <String>['failure:immunity']);
    });

    test('failure hook observes PP and accuracy failures', () {
      final failures = <BattleMoveFailureContext>[];
      final engine = BattleEngine(
        setup: _setup(
          playerMove: _move(
            id: 'empty_ember',
            type: 'fire',
            currentPp: 0,
          ),
        ),
        moveProcedureHooks: BattleMoveProcedureHooks(
          failureHooks: <BattleMoveFailureHook>[failures.add],
        ),
      );

      engine.submit(const BattleDecision.fight(moveSlot: 0));
      final missedExecution = _execution(accuracy: 1, moveAccuracySeed: 99);
      BattleMoveProcedure(
        hooks: BattleMoveProcedureHooks(
          failureHooks: <BattleMoveFailureHook>[failures.add],
        ),
      ).prepare(missedExecution);

      expect(
        failures.map((failure) => failure.reason),
        containsAll(<BattleMoveFailureReason>[
          BattleMoveFailureReason.pp,
          BattleMoveFailureReason.accuracy,
        ]),
      );
    });
  });
}

BattleEngineSetup _setup({
  required PsdkBattleMoveData playerMove,
  PsdkBattleRngSeeds rngSeeds = const PsdkBattleRngSeeds(
    moveDamage: 1,
    moveCritical: 99999,
    moveAccuracy: 3,
    generic: 4,
  ),
}) {
  return BattleEngineSetup.singles(
    player: _combatant(
      id: 'player',
      speed: 100,
      types: const PsdkBattleTypes(primary: 'fire'),
      moves: <PsdkBattleMoveData>[playerMove],
    ),
    opponent: _combatant(
      id: 'opponent',
      speed: 1,
      types: const PsdkBattleTypes(primary: 'grass'),
      moves: <PsdkBattleMoveData>[
        _move(
          id: 'opponent_wait',
          type: 'normal',
          power: 0,
          accuracy: 0,
        ),
      ],
    ),
    rngSeeds: rngSeeds,
  );
}

BattleMoveProcedureExecution _execution({
  int accuracy = 100,
  int moveAccuracySeed = 3,
  PsdkBattleState? state,
}) {
  final move = BattleMoveDefinition.fromPsdk(
    _move(id: 'tackle', type: 'normal', accuracy: accuracy),
  );
  return BattleMoveProcedureExecution(
    context: BattleMoveBehaviorContext(
      state: state ??
          PsdkBattleState.fromSetup(
              _setup(playerMove: move.psdkMove).psdkSetup),
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

PsdkBattleCombatantSetup _combatant({
  required String id,
  required int speed,
  required PsdkBattleTypes types,
  required List<PsdkBattleMoveData> moves,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: 100,
    currentHp: 100,
    types: types,
    stats: PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: speed,
    ),
    moves: moves,
  );
}

PsdkBattleMoveData _move({
  required String id,
  required String type,
  int power = 40,
  int accuracy = 100,
  int pp = 35,
  int? currentPp,
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: type,
    category: power == 0
        ? PsdkBattleMoveCategory.status
        : PsdkBattleMoveCategory.special,
    power: power,
    accuracy: accuracy,
    pp: pp,
    currentPp: currentPp,
    priority: 0,
    battleEngineMethod: power == 0 ? 's_status' : 's_basic',
    target: PsdkBattleMoveTarget.adjacentFoe,
  );
}
