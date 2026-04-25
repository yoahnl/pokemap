import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

const _player = BattlePositionRef(bank: 0, position: 0);
const _opponent = BattlePositionRef(bank: 1, position: 0);

void main() {
  group('PSDK clean targeting', () {
    test('resolves adjacent foe and user targets from the requested slot', () {
      final adjacentExecution = _execution(
        move: _move(target: PsdkBattleMoveTarget.adjacentFoe),
        requestedTarget: _opponent,
      );
      final userExecution = _execution(
        move: _move(target: PsdkBattleMoveTarget.user),
        requestedTarget: _opponent,
      );
      const resolver = BattleTargetResolver();

      expect(resolver.resolve(adjacentExecution), <BattlePositionRef>[
        _opponent,
      ]);
      expect(resolver.resolve(userExecution), <BattlePositionRef>[_player]);
    });

    test('filters missing or fainted targets without inventing a fallback', () {
      final missingExecution = _execution(
        state: PsdkBattleState(
          combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
            psdkPlayerSlot: PsdkBattleCombatant.fromSetup(
              _combatant(id: 'player'),
            ),
          },
        ),
        requestedTarget: _opponent,
      );
      final faintedExecution = _execution(
        state: PsdkBattleState(
          combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
            psdkPlayerSlot: PsdkBattleCombatant.fromSetup(
              _combatant(id: 'player'),
            ),
            psdkOpponentSlot: PsdkBattleCombatant.fromSetup(
              _combatant(id: 'opponent', currentHp: 0),
            ),
          },
        ),
        requestedTarget: _opponent,
      );
      const resolver = BattleTargetResolver();

      expect(resolver.resolve(missingExecution), isEmpty);
      expect(resolver.resolve(faintedExecution), isEmpty);
    });
  });
}

BattleMoveProcedureExecution _execution({
  PsdkBattleState? state,
  BattleMoveDefinition? move,
  BattlePositionRef? requestedTarget,
}) {
  final definition = move ?? _move(target: PsdkBattleMoveTarget.adjacentFoe);
  return BattleMoveProcedureExecution(
    context: BattleMoveBehaviorContext(
      state: state ?? PsdkBattleState.fromSetup(_setup(definition.psdkMove)),
      rng: _rng(),
      turn: 1,
      user: psdkPlayerSlot,
      target: psdkOpponentSlot,
      move: definition,
    ),
    timeline: BattleTimelineBuilder(),
    user: _player,
    move: definition,
    requestedTarget: requestedTarget,
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
  int currentHp = 40,
  List<PsdkBattleMoveData>? moves,
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
    moves: moves ?? <PsdkBattleMoveData>[_move().psdkMove],
  );
}

BattleMoveDefinition _move({
  PsdkBattleMoveTarget target = PsdkBattleMoveTarget.adjacentFoe,
}) {
  return BattleMoveDefinition(
    id: 'tackle',
    dbSymbol: 'tackle',
    name: 'Tackle',
    type: 'normal',
    category: PsdkBattleMoveCategory.physical,
    power: 40,
    accuracy: 100,
    pp: 35,
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
