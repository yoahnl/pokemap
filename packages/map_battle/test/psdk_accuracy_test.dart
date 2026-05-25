import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

const _player = BattlePositionRef(bank: 0, position: 0);
const _opponent = BattlePositionRef(bank: 1, position: 0);

void main() {
  group('PSDK clean accuracy', () {
    test('bypass accuracy keeps the accuracy stream untouched', () {
      final execution = _execution(
        accuracy: 0,
        moveAccuracySeed: 99,
      );

      final result = const BattleAccuracyResolver().resolve(
        execution: execution,
        targets: const <BattlePositionRef>[_opponent],
      );

      expect(result.bypassed, isTrue);
      expect(result.hitTargets, <BattlePositionRef>[_opponent]);
      expect(result.rng.seeds.moveAccuracy, 99);
    });

    test('miss consumes accuracy without moving damage or generic streams', () {
      final execution = _execution(
        accuracy: 1,
        moveAccuracySeed: 99,
      );

      final result = const BattleAccuracyResolver().resolve(
        execution: execution,
        targets: const <BattlePositionRef>[_opponent],
      );

      expect(result.hitTargets, isEmpty);
      expect(result.missedTargets, <BattlePositionRef>[_opponent]);
      expect(result.rng.seeds.moveAccuracy, isNot(99));
      expect(result.rng.seeds.moveDamage, 1);
      expect(result.rng.seeds.generic, 4);
    });

    test('hit consumes accuracy and returns the target as accurate', () {
      final execution = _execution(
        accuracy: 50,
        moveAccuracySeed: 0,
      );

      final result = const BattleAccuracyResolver().resolve(
        execution: execution,
        targets: const <BattlePositionRef>[_opponent],
      );

      expect(result.hitTargets, <BattlePositionRef>[_opponent]);
      expect(result.missedTargets, isEmpty);
      expect(result.rng.seeds.moveAccuracy, isNot(0));
    });

    test('a 100 accuracy move still consumes the accuracy stream', () {
      final execution = _execution(
        accuracy: 100,
        moveAccuracySeed: 99,
      );

      final result = const BattleAccuracyResolver().resolve(
        execution: execution,
        targets: const <BattlePositionRef>[_opponent],
      );

      expect(result.bypassed, isFalse);
      expect(result.hitTargets, <BattlePositionRef>[_opponent]);
      expect(result.missedTargets, isEmpty);
      expect(result.rng.seeds.moveAccuracy, isNot(99));
    });

    test('accuracy and evasion stages modify chance of hit like PSDK', () {
      final neutral = const BattleAccuracyResolver().resolve(
        execution: _execution(
          accuracy: 100,
          moveAccuracySeed: 90,
        ),
        targets: const <BattlePositionRef>[_opponent],
      );
      final loweredAccuracy = const BattleAccuracyResolver().resolve(
        execution: _execution(
          accuracy: 100,
          moveAccuracySeed: 90,
          playerStatStages: PsdkBattleStatStages(
            values: <String, int>{'accuracy': -1},
          ),
        ),
        targets: const <BattlePositionRef>[_opponent],
      );
      final raisedEvasion = const BattleAccuracyResolver().resolve(
        execution: _execution(
          accuracy: 100,
          moveAccuracySeed: 90,
          opponentStatStages: PsdkBattleStatStages(
            values: <String, int>{'evasion': 1},
          ),
        ),
        targets: const <BattlePositionRef>[_opponent],
      );

      expect(neutral.hitTargets, <BattlePositionRef>[_opponent]);
      expect(loweredAccuracy.missedTargets, <BattlePositionRef>[_opponent]);
      expect(raisedEvasion.missedTargets, <BattlePositionRef>[_opponent]);
    });

    test('held accuracy items modify chance of hit like PSDK item hooks', () {
      final wideLens = const BattleAccuracyResolver().resolve(
        execution: _execution(
          accuracy: 91,
          moveAccuracySeed: 99,
          playerHeldItemId: 'wide_lens',
        ),
        targets: const <BattlePositionRef>[_opponent],
      );
      final wideLensBaseline = const BattleAccuracyResolver().resolve(
        execution: _execution(
          accuracy: 91,
          moveAccuracySeed: 99,
        ),
        targets: const <BattlePositionRef>[_opponent],
      );
      final laxIncense = const BattleAccuracyResolver().resolve(
        execution: _execution(
          accuracy: 100,
          moveAccuracySeed: 98,
          opponentHeldItemId: 'lax_incense',
        ),
        targets: const <BattlePositionRef>[_opponent],
      );
      final brightPowder = const BattleAccuracyResolver().resolve(
        execution: _execution(
          accuracy: 100,
          moveAccuracySeed: 98,
          opponentHeldItemId: 'bright_powder',
        ),
        targets: const <BattlePositionRef>[_opponent],
      );

      expect(wideLens.hitTargets, <BattlePositionRef>[_opponent]);
      expect(wideLensBaseline.missedTargets, <BattlePositionRef>[_opponent]);
      expect(laxIncense.missedTargets, <BattlePositionRef>[_opponent]);
      expect(brightPowder.missedTargets, <BattlePositionRef>[_opponent]);
    });

    test('Zoom Lens improves accuracy only after the target acted', () {
      final afterTarget = const BattleAccuracyResolver().resolve(
        execution: _execution(
          accuracy: 84,
          moveAccuracySeed: 90,
          playerHeldItemId: 'zoom_lens',
          opponentMoveHistory: PsdkBattleMoveHistory(
            attempts: <PsdkBattleMoveHistoryEntry>[
              PsdkBattleMoveHistoryEntry(
                moveId: 'quick_attack',
                turn: 1,
                targets: <PsdkBattleSlotRef>[psdkPlayerSlot],
                attackOrder: 0,
              ),
            ],
          ),
        ),
        targets: const <BattlePositionRef>[_opponent],
      );
      final beforeTarget = const BattleAccuracyResolver().resolve(
        execution: _execution(
          accuracy: 84,
          moveAccuracySeed: 90,
          playerHeldItemId: 'zoom_lens',
        ),
        targets: const <BattlePositionRef>[_opponent],
      );
      final previousTurn = const BattleAccuracyResolver().resolve(
        execution: _execution(
          accuracy: 84,
          moveAccuracySeed: 90,
          playerHeldItemId: 'zoom_lens',
          opponentMoveHistory: PsdkBattleMoveHistory(
            attempts: <PsdkBattleMoveHistoryEntry>[
              PsdkBattleMoveHistoryEntry(
                moveId: 'quick_attack',
                turn: 0,
                targets: <PsdkBattleSlotRef>[psdkPlayerSlot],
                attackOrder: 0,
              ),
            ],
          ),
        ),
        targets: const <BattlePositionRef>[_opponent],
      );

      expect(afterTarget.hitTargets, <BattlePositionRef>[_opponent]);
      expect(beforeTarget.missedTargets, <BattlePositionRef>[_opponent]);
      expect(previousTurn.missedTargets, <BattlePositionRef>[_opponent]);
    });

    test('Tangled Feet halves chance of hit while the target is confused', () {
      final confusedTarget = const BattleAccuracyResolver().resolve(
        execution: _execution(
          accuracy: 100,
          moveAccuracySeed: 60,
          opponentAbilityId: 'tangled_feet',
          opponentEffects: PsdkBattleEffectStack(values: <String>[
            PsdkBattleEffectIds.confusion,
          ]),
        ),
        targets: const <BattlePositionRef>[_opponent],
      );
      final clearTarget = const BattleAccuracyResolver().resolve(
        execution: _execution(
          accuracy: 100,
          moveAccuracySeed: 60,
          opponentAbilityId: 'tangled_feet',
        ),
        targets: const <BattlePositionRef>[_opponent],
      );

      expect(confusedTarget.missedTargets, <BattlePositionRef>[_opponent]);
      expect(clearTarget.hitTargets, <BattlePositionRef>[_opponent]);
    });
  });
}

BattleMoveProcedureExecution _execution({
  required int accuracy,
  required int moveAccuracySeed,
  String? playerHeldItemId,
  String? opponentHeldItemId,
  String? opponentAbilityId,
  PsdkBattleEffectStack? opponentEffects,
  PsdkBattleMoveHistory? opponentMoveHistory,
  PsdkBattleStatStages? playerStatStages,
  PsdkBattleStatStages? opponentStatStages,
}) {
  final move = BattleMoveDefinition(
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
  return BattleMoveProcedureExecution(
    context: BattleMoveBehaviorContext(
      state: PsdkBattleState.fromSetup(
        _setup(
          move.psdkMove,
          playerHeldItemId: playerHeldItemId,
          opponentHeldItemId: opponentHeldItemId,
          opponentAbilityId: opponentAbilityId,
          opponentEffects: opponentEffects,
          opponentMoveHistory: opponentMoveHistory,
          playerStatStages: playerStatStages,
          opponentStatStages: opponentStatStages,
        ),
      ),
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
  String? playerHeldItemId,
  String? opponentHeldItemId,
  String? opponentAbilityId,
  PsdkBattleEffectStack? opponentEffects,
  PsdkBattleMoveHistory? opponentMoveHistory,
  PsdkBattleStatStages? playerStatStages,
  PsdkBattleStatStages? opponentStatStages,
}) {
  return PsdkBattleSetup.singles(
    player: _combatant(
      id: 'player',
      heldItemId: playerHeldItemId,
      statStages: playerStatStages,
      moves: <PsdkBattleMoveData>[move],
    ),
    opponent: _combatant(
      id: 'opponent',
      abilityId: opponentAbilityId,
      heldItemId: opponentHeldItemId,
      effects: opponentEffects,
      moveHistory: opponentMoveHistory,
      statStages: opponentStatStages,
    ),
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
  String? abilityId,
  String? heldItemId,
  PsdkBattleEffectStack? effects,
  PsdkBattleMoveHistory? moveHistory,
  PsdkBattleStatStages? statStages,
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
    abilityId: abilityId,
    heldItemId: heldItemId,
    effects: effects,
    moveHistory: moveHistory,
    statStages: statStages,
    moves: moves ?? <PsdkBattleMoveData>[moveStub()],
  );
}

PsdkBattleMoveData moveStub() {
  return BattleMoveDefinition(
    id: 'stub',
    dbSymbol: 'stub',
    name: 'Stub',
    type: 'normal',
    category: PsdkBattleMoveCategory.physical,
    power: 1,
    accuracy: 100,
    pp: 35,
    priority: 0,
    battleEngineMethod: 's_basic',
    target: PsdkBattleMoveTarget.adjacentFoe,
  ).psdkMove;
}
