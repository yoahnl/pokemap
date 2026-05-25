import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK damage formula parity', () {
    test('burn is a Mod1 multiplier before the +2 damage floor', () {
      final damage = _calculate(
        user: _combatant(
          id: 'burned_attacker',
          type: 'fighting',
          attack: 11,
          status: PsdkBattleMajorStatus.burn,
        ),
        target: _combatant(id: 'defender', type: 'water', defense: 12),
        move: _move(
          id: 'scratch',
          type: 'normal',
          category: PsdkBattleMoveCategory.physical,
          power: 10,
        ),
      );

      expect(damage.damage, 4);
    });

    test('weather is a PSDK Mod1 multiplier before the +2 damage floor', () {
      final rainWater = _calculate(
        user: _combatant(id: 'attacker', type: 'normal', specialAttack: 10),
        target: _combatant(id: 'defender', type: 'normal', specialDefense: 12),
        move: _move(
          id: 'water_gun',
          type: 'water',
          category: PsdkBattleMoveCategory.special,
          power: 10,
        ),
        field: const PsdkBattleFieldState(
          weather: PsdkBattleWeatherState(
            id: PsdkBattleWeatherId.rain,
            remainingTurns: 5,
          ),
        ),
      );
      final rainFire = _calculate(
        user: _combatant(id: 'attacker', type: 'normal', specialAttack: 11),
        target: _combatant(id: 'defender', type: 'normal', specialDefense: 12),
        move: _move(
          id: 'ember',
          type: 'fire',
          category: PsdkBattleMoveCategory.special,
          power: 10,
        ),
        field: const PsdkBattleFieldState(
          weather: PsdkBattleWeatherState(
            id: PsdkBattleWeatherId.rain,
            remainingTurns: 5,
          ),
        ),
      );

      expect(rainWater.damage, 6);
      expect(rainFire.damage, 4);
    });

    test('terrain power changes are PSDK Mod1 multipliers', () {
      final electricTerrain = _calculate(
        user: _combatant(id: 'attacker', type: 'normal', specialAttack: 10),
        target: _combatant(id: 'defender', type: 'normal', specialDefense: 12),
        move: _move(
          id: 'thunder_shock',
          type: 'electric',
          category: PsdkBattleMoveCategory.special,
          power: 10,
        ),
        field: const PsdkBattleFieldState(
          terrain: PsdkBattleTerrainState(
            id: PsdkBattleTerrainId.electricTerrain,
            remainingTurns: 5,
          ),
        ),
      );
      final mistyTerrain = _calculate(
        user: _combatant(id: 'attacker', type: 'normal', specialAttack: 11),
        target: _combatant(id: 'defender', type: 'normal', specialDefense: 12),
        move: _move(
          id: 'dragon_pulse',
          type: 'dragon',
          category: PsdkBattleMoveCategory.special,
          power: 10,
        ),
        field: const PsdkBattleFieldState(
          terrain: PsdkBattleTerrainState(
            id: PsdkBattleTerrainId.mistyTerrain,
            remainingTurns: 5,
          ),
        ),
      );

      expect(electricTerrain.damage, 6);
      expect(mistyTerrain.damage, 4);
    });
  });
}

BattleMoveDamageResult _calculate({
  required PsdkBattleCombatant user,
  required PsdkBattleCombatant target,
  required BattleMoveDefinition move,
  PsdkBattleFieldState field = const PsdkBattleFieldState(),
}) {
  return const BattleMoveDamageCalculator().calculate(
    BattleMoveDamageContext(
      user: user,
      target: target,
      move: move,
      field: field,
      rng: BattleRngStreams.fromSeeds(
        moveDamageSeed: 14,
        moveCriticalSeed: 99999,
        moveAccuracySeed: 1,
        genericSeed: 1,
      ),
    ),
  );
}

PsdkBattleCombatant _combatant({
  required String id,
  required String type,
  int attack = 10,
  int defense = 10,
  int specialAttack = 10,
  int specialDefense = 10,
  PsdkBattleMajorStatus? status,
}) {
  return PsdkBattleCombatant(
    id: id,
    speciesId: id,
    displayName: id,
    level: 50,
    maxHp: 100,
    currentHp: 100,
    types: PsdkBattleTypes(primary: type),
    stats: PsdkBattleStats(
      attack: attack,
      defense: defense,
      specialAttack: specialAttack,
      specialDefense: specialDefense,
      speed: 10,
    ),
    moves: const <PsdkBattleMoveData>[],
    majorStatus: status,
  );
}

BattleMoveDefinition _move({
  required String id,
  required String type,
  required PsdkBattleMoveCategory category,
  required int power,
}) {
  return BattleMoveDefinition(
    id: id,
    dbSymbol: id,
    name: id,
    type: type,
    category: category,
    power: power,
    accuracy: 100,
    pp: 10,
    priority: 0,
    criticalRate: 0,
    battleEngineMethod: 's_basic',
    target: PsdkBattleMoveTarget.adjacentFoe,
  );
}
