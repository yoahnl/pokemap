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
  });
}

BattleMoveProcedureExecution _execution({
  required int accuracy,
  required int moveAccuracySeed,
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
      state: PsdkBattleState.fromSetup(_setup(move.psdkMove)),
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
