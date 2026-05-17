import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK variable-power move families', () {
    test('s_brine doubles base power only when the target is at half HP', () {
      final aboveHalf = _runMove(
        playerMove: _move(
          id: 'brine',
          battleEngineMethod: 's_brine',
          power: 65,
          category: PsdkBattleMoveCategory.special,
        ),
        opponentCurrentHp: 51,
      );
      final atHalf = _runMove(
        playerMove: _move(
          id: 'brine',
          battleEngineMethod: 's_brine',
          power: 65,
          category: PsdkBattleMoveCategory.special,
        ),
        opponentCurrentHp: 50,
      );

      expect(
        _damage(atHalf, moveId: 'brine'),
        greaterThan(_damage(aboveHalf, moveId: 'brine')),
      );
      expect(
        atHalf.state.battlerAt(psdkOpponentSlot).currentHp,
        50 - _damage(atHalf, moveId: 'brine'),
      );
    });

    test('s_eruption scales from the user HP rate with a one-power floor', () {
      final fullHp = _runMove(
        playerMove: _move(
          id: 'eruption',
          battleEngineMethod: 's_eruption',
          power: 150,
          category: PsdkBattleMoveCategory.special,
        ),
        playerCurrentHp: 100,
      );
      final lowHp = _runMove(
        playerMove: _move(
          id: 'eruption',
          battleEngineMethod: 's_eruption',
          power: 150,
          category: PsdkBattleMoveCategory.special,
        ),
        playerCurrentHp: 1,
      );

      expect(
        _damage(fullHp, moveId: 'eruption'),
        greaterThan(_damage(lowHp, moveId: 'eruption')),
      );
      expect(_damage(lowHp, moveId: 'eruption'), greaterThan(0));
    });

    test('s_flail uses the PSDK HP threshold table', () {
      final highHp = _runMove(
        playerMove: _move(
          id: 'flail',
          battleEngineMethod: 's_flail',
          power: 1,
        ),
        playerCurrentHp: 100,
      );
      final criticalHp = _runMove(
        playerMove: _move(
          id: 'flail',
          battleEngineMethod: 's_flail',
          power: 1,
        ),
        playerCurrentHp: 3,
      );

      expect(
        _damage(criticalHp, moveId: 'flail'),
        greaterThan(_damage(highHp, moveId: 'flail') * 5),
      );
    });

    test('s_wring_out and s_hard_press scale from target remaining HP', () {
      final wringOutFullTarget = _runMove(
        playerMove: _move(
          id: 'wring_out',
          battleEngineMethod: 's_wring_out',
          power: 1,
          category: PsdkBattleMoveCategory.special,
        ),
        opponentCurrentHp: 100,
      );
      final wringOutLowTarget = _runMove(
        playerMove: _move(
          id: 'wring_out',
          battleEngineMethod: 's_wring_out',
          power: 1,
          category: PsdkBattleMoveCategory.special,
        ),
        opponentCurrentHp: 25,
      );
      final hardPressFullTarget = _runMove(
        playerMove: _move(
          id: 'hard_press',
          type: 'steel',
          battleEngineMethod: 's_hard_press',
          power: 1,
        ),
        opponentCurrentHp: 100,
      );
      final hardPressLowTarget = _runMove(
        playerMove: _move(
          id: 'hard_press',
          type: 'steel',
          battleEngineMethod: 's_hard_press',
          power: 1,
        ),
        opponentCurrentHp: 25,
      );

      expect(
        _damage(wringOutFullTarget, moveId: 'wring_out'),
        greaterThan(_damage(wringOutLowTarget, moveId: 'wring_out')),
      );
      expect(
        _damage(hardPressFullTarget, moveId: 'hard_press'),
        greaterThan(_damage(hardPressLowTarget, moveId: 'hard_press')),
      );
    });

    test('s_electro_ball and s_gyro_ball resolve power from speed ratio', () {
      final electroFastUser = _runMove(
        playerMove: _move(
          id: 'electro_ball',
          type: 'electric',
          battleEngineMethod: 's_electro_ball',
          power: 1,
          category: PsdkBattleMoveCategory.special,
        ),
        playerSpeed: 200,
        opponentSpeed: 40,
      );
      final electroSlowUser = _runMove(
        playerMove: _move(
          id: 'electro_ball',
          type: 'electric',
          battleEngineMethod: 's_electro_ball',
          power: 1,
          category: PsdkBattleMoveCategory.special,
        ),
        playerSpeed: 50,
        opponentSpeed: 100,
      );
      final gyroSlowUser = _runMove(
        playerMove: _move(
          id: 'gyro_ball',
          type: 'steel',
          battleEngineMethod: 's_gyro_ball',
          power: 1,
        ),
        playerSpeed: 25,
        opponentSpeed: 200,
      );
      final gyroFastUser = _runMove(
        playerMove: _move(
          id: 'gyro_ball',
          type: 'steel',
          battleEngineMethod: 's_gyro_ball',
          power: 1,
        ),
        playerSpeed: 200,
        opponentSpeed: 25,
      );

      expect(
        _damage(electroFastUser, moveId: 'electro_ball'),
        greaterThan(_damage(electroSlowUser, moveId: 'electro_ball')),
      );
      expect(
        _damage(gyroSlowUser, moveId: 'gyro_ball'),
        greaterThan(_damage(gyroFastUser, moveId: 'gyro_ball')),
      );
    });

    test('s_electro_ball keeps PSDK strict threshold boundaries', () {
      PsdkBattleTurnResult runElectroBallAtRatio({
        required int targetSpeed,
      }) {
        return _runMove(
          playerMove: _move(
            id: 'electro_ball',
            type: 'electric',
            battleEngineMethod: 's_electro_ball',
            power: 1,
            category: PsdkBattleMoveCategory.special,
          ),
          playerSpeed: 100,
          opponentSpeed: targetSpeed,
        );
      }

      // PSDK's Ruby table uses `first > ratio`, so exact thresholds fall into
      // the next lower bucket: 25/100 => 120 power, 33/100 => 80 power,
      // 50/100 => 60 power, 100/100 => 40 power.
      expect(
          _damage(runElectroBallAtRatio(targetSpeed: 24),
              moveId: 'electro_ball'),
          27);
      expect(
          _damage(runElectroBallAtRatio(targetSpeed: 25),
              moveId: 'electro_ball'),
          22);
      expect(
          _damage(runElectroBallAtRatio(targetSpeed: 32),
              moveId: 'electro_ball'),
          22);
      expect(
          _damage(runElectroBallAtRatio(targetSpeed: 33),
              moveId: 'electro_ball'),
          15);
      expect(
          _damage(runElectroBallAtRatio(targetSpeed: 49),
              moveId: 'electro_ball'),
          15);
      expect(
          _damage(runElectroBallAtRatio(targetSpeed: 50),
              moveId: 'electro_ball'),
          12);
      expect(
          _damage(runElectroBallAtRatio(targetSpeed: 99),
              moveId: 'electro_ball'),
          12);
      expect(
          _damage(runElectroBallAtRatio(targetSpeed: 100),
              moveId: 'electro_ball'),
          8);
    });

    test('s_flail keeps exact PSDK HP threshold boundaries', () {
      PsdkBattleTurnResult runFlailAtHp(int hp) {
        return _runMove(
          playerMove: _move(
            id: 'flail',
            battleEngineMethod: 's_flail',
            power: 1,
          ),
          playerCurrentHp: hp,
        );
      }

      // PSDK uses strict `>` thresholds: HP rate 70%, 35%, 20%, 10% and 4%
      // already belong to the stronger lower-HP bucket.
      expect(_damage(runFlailAtHp(71), moveId: 'flail'), 5);
      expect(_damage(runFlailAtHp(70), moveId: 'flail'), 8);
      expect(_damage(runFlailAtHp(36), moveId: 'flail'), 8);
      expect(_damage(runFlailAtHp(35), moveId: 'flail'), 15);
      expect(_damage(runFlailAtHp(21), moveId: 'flail'), 15);
      expect(_damage(runFlailAtHp(20), moveId: 'flail'), 19);
      expect(_damage(runFlailAtHp(11), moveId: 'flail'), 19);
      expect(_damage(runFlailAtHp(10), moveId: 'flail'), 27);
      expect(_damage(runFlailAtHp(5), moveId: 'flail'), 27);
      expect(_damage(runFlailAtHp(4), moveId: 'flail'), 36);
    });

    test('status-boosted power moves check the correct battler status', () {
      final healthyFacade = _runMove(
        playerMove: _move(
          id: 'facade',
          battleEngineMethod: 's_facade',
          power: 70,
        ),
      );
      final burnedFacade = _runMove(
        playerMove: _move(
          id: 'facade',
          battleEngineMethod: 's_facade',
          power: 70,
        ),
        playerMajorStatus: PsdkBattleMajorStatus.burn,
      );
      final healthyParade = _runMove(
        playerMove: _move(
          id: 'infernal_parade',
          type: 'ghost',
          battleEngineMethod: 's_infernal_parade',
          power: 60,
          category: PsdkBattleMoveCategory.special,
        ),
      );
      final targetStatusParade = _runMove(
        playerMove: _move(
          id: 'infernal_parade',
          type: 'ghost',
          battleEngineMethod: 's_infernal_parade',
          power: 60,
          category: PsdkBattleMoveCategory.special,
        ),
        opponentMajorStatus: PsdkBattleMajorStatus.sleep,
      );
      final targetStatusBitterMalice = _runMove(
        playerMove: _move(
          id: 'bitter_malice',
          type: 'ghost',
          battleEngineMethod: 's_bitter_malice',
          power: 60,
          category: PsdkBattleMoveCategory.special,
        ),
        opponentMajorStatus: PsdkBattleMajorStatus.paralysis,
      );

      expect(
        _damage(burnedFacade, moveId: 'facade'),
        greaterThan(_damage(healthyFacade, moveId: 'facade')),
      );
      expect(
        _damage(targetStatusParade, moveId: 'infernal_parade'),
        greaterThan(_damage(healthyParade, moveId: 'infernal_parade')),
      );
      expect(
        _damage(targetStatusBitterMalice, moveId: 'bitter_malice'),
        _damage(targetStatusParade, moveId: 'infernal_parade'),
      );
    });

    test('s_hex and s_venoshock double final damage for PSDK status rules', () {
      final normalHex = _runMove(
        playerMove: _move(
          id: 'hex',
          type: 'ghost',
          battleEngineMethod: 's_hex',
          power: 65,
          category: PsdkBattleMoveCategory.special,
        ),
      );
      final burnedHex = _runMove(
        playerMove: _move(
          id: 'hex',
          type: 'ghost',
          battleEngineMethod: 's_hex',
          power: 65,
          category: PsdkBattleMoveCategory.special,
        ),
        opponentMajorStatus: PsdkBattleMajorStatus.burn,
      );
      final comatoseHex = _runMove(
        playerMove: _move(
          id: 'hex',
          type: 'ghost',
          battleEngineMethod: 's_hex',
          power: 65,
          category: PsdkBattleMoveCategory.special,
        ),
        opponentAbilityId: 'comatose',
      );
      final burnedVenoshock = _runMove(
        playerMove: _move(
          id: 'venoshock',
          type: 'poison',
          battleEngineMethod: 's_venoshock',
          power: 65,
          category: PsdkBattleMoveCategory.special,
        ),
        opponentMajorStatus: PsdkBattleMajorStatus.burn,
      );
      final poisonedVenoshock = _runMove(
        playerMove: _move(
          id: 'venoshock',
          type: 'poison',
          battleEngineMethod: 's_venoshock',
          power: 65,
          category: PsdkBattleMoveCategory.special,
        ),
        opponentMajorStatus: PsdkBattleMajorStatus.poison,
      );

      expect(_damage(burnedHex, moveId: 'hex'),
          _damage(normalHex, moveId: 'hex') * 2);
      expect(_damage(comatoseHex, moveId: 'hex'),
          _damage(normalHex, moveId: 'hex') * 2);
      expect(
        _damage(poisonedVenoshock, moveId: 'venoshock'),
        _damage(burnedVenoshock, moveId: 'venoshock') * 2,
      );
    });
  });
}

PsdkBattleTurnResult _runMove({
  required PsdkBattleMoveData playerMove,
  int playerCurrentHp = 100,
  int opponentCurrentHp = 100,
  int playerSpeed = 100,
  int opponentSpeed = 50,
  PsdkBattleMajorStatus? playerMajorStatus,
  PsdkBattleMajorStatus? opponentMajorStatus,
  String? opponentAbilityId,
}) {
  final engine = PsdkBattleEngine(
    setup: PsdkBattleSetup.singles(
      player: _combatant(
        id: 'player',
        currentHp: playerCurrentHp,
        speed: playerSpeed,
        move: playerMove,
        majorStatus: playerMajorStatus,
      ),
      opponent: _combatant(
        id: 'opponent',
        currentHp: opponentCurrentHp,
        speed: opponentSpeed,
        move: _move(
          id: 'opponent_wait',
          power: 0,
          accuracy: 1,
        ),
        majorStatus: opponentMajorStatus,
        abilityId: opponentAbilityId,
      ),
      rngSeeds: const PsdkBattleRngSeeds(
        moveDamage: 1,
        moveCritical: 99999,
        moveAccuracy: 3,
        generic: 4,
      ),
    ),
  );
  return engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required int currentHp,
  required int speed,
  required PsdkBattleMoveData move,
  PsdkBattleMajorStatus? majorStatus,
  String? abilityId,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: 100,
    currentHp: currentHp,
    // Keep fixture types away from the move types so the assertions isolate the
    // PSDK formulas instead of accidentally measuring STAB.
    types: const PsdkBattleTypes(primary: 'fire'),
    stats: PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: speed,
    ),
    moves: <PsdkBattleMoveData>[move],
    majorStatus: majorStatus,
    abilityId: abilityId,
  );
}

PsdkBattleMoveData _move({
  required String id,
  String type = 'normal',
  PsdkBattleMoveCategory category = PsdkBattleMoveCategory.physical,
  required int power,
  int accuracy = 100,
  int criticalRate = 0,
  String battleEngineMethod = 's_basic',
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: type,
    category: category,
    power: power,
    accuracy: accuracy,
    pp: 35,
    priority: 0,
    criticalRate: criticalRate,
    battleEngineMethod: battleEngineMethod,
    target: PsdkBattleMoveTarget.adjacentFoe,
  );
}

int _damage(
  PsdkBattleTurnResult result, {
  required String moveId,
}) {
  return result.timeline.events
      .whereType<PsdkBattleDamageEvent>()
      .singleWhere((event) => event.moveId == moveId)
      .damage;
}
