import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PsdkBattleMoveExecutor', () {
    test('executes s_fixed_damage directly by battleEngineMethod', () {
      final result = const PsdkBattleMoveExecutor().execute(
        _request(
          moveId: 'sonic_boom',
          dbSymbol: 'sonic_boom',
          battleEngineMethod: 's_fixed_damage',
          power: 1,
        ),
      );

      final damage = result.events.whereType<PsdkBattleDamageEvent>().single;
      expect(damage.moveId, equals('sonic_boom'));
      expect(damage.damage, equals(20));
      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, equals(80));
    });

    test('executes s_basic directly with standard damage behavior', () {
      final result = const PsdkBattleMoveExecutor().execute(
        _request(
          moveId: 'tackle',
          dbSymbol: 'tackle',
          battleEngineMethod: 's_basic',
          power: 40,
        ),
      );

      final damage = result.events.whereType<PsdkBattleDamageEvent>().single;
      expect(damage.moveId, equals('tackle'));
      expect(damage.damage, greaterThan(0));
      expect(
        result.state.battlerAt(psdkOpponentSlot).currentHp,
        equals(100 - damage.damage),
      );
    });

    test('fails explicitly for an unknown battleEngineMethod', () {
      expect(
        () => const PsdkBattleMoveExecutor().execute(
          _request(
            moveId: 'mystery_move',
            dbSymbol: 'mystery_move',
            battleEngineMethod: 's_missing_from_registry',
            power: 40,
          ),
        ),
        throwsA(
          isA<UnsupportedBattleMoveBehavior>().having(
            (error) => error.battleEngineMethod,
            'battleEngineMethod',
            equals('s_missing_from_registry'),
          ),
        ),
      );
    });
  });
}

PsdkBattleMoveRequest _request({
  required String moveId,
  required String dbSymbol,
  required String battleEngineMethod,
  required int power,
}) {
  return PsdkBattleMoveRequest(
    state: PsdkBattleState.fromSetup(_setup()),
    rng: BattleRngStreams.fromSeeds(
      moveDamageSeed: 1,
      moveCriticalSeed: 2,
      moveAccuracySeed: 3,
      genericSeed: 4,
    ),
    turn: 1,
    user: psdkPlayerSlot,
    target: psdkOpponentSlot,
    moveId: moveId,
    battleEngineMethod: battleEngineMethod,
    studioMove: _move(
      id: moveId,
      dbSymbol: dbSymbol,
      battleEngineMethod: battleEngineMethod,
      power: power,
    ),
  );
}

PsdkBattleSetup _setup() {
  return PsdkBattleSetup.singles(
    player: _combatant(id: 'player'),
    opponent: _combatant(id: 'opponent'),
    rngSeeds: const PsdkBattleRngSeeds(
      moveDamage: 1,
      moveCritical: 2,
      moveAccuracy: 3,
      generic: 4,
    ),
  );
}

PsdkBattleCombatantSetup _combatant({required String id}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 50,
    maxHp: 100,
    currentHp: 100,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: const PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: 50,
    ),
    moves: <PsdkBattleMoveData>[
      _move(
        id: '${id}_move',
        dbSymbol: '${id}_move',
        battleEngineMethod: 's_basic',
        power: 40,
      ),
    ],
  );
}

PsdkBattleMoveData _move({
  required String id,
  required String dbSymbol,
  required String battleEngineMethod,
  required int power,
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: dbSymbol,
    name: id,
    type: 'normal',
    category: PsdkBattleMoveCategory.physical,
    power: power,
    accuracy: 100,
    pp: 35,
    priority: 0,
    battleEngineMethod: battleEngineMethod,
    target: PsdkBattleMoveTarget.adjacentFoe,
  );
}
