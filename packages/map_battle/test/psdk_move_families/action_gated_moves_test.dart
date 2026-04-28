import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK action-gated move families', () {
    test('s_snore fails before PP unless the user is asleep', () {
      final awake = _runMove(
        playerMove: _move(
          id: 'snore',
          type: 'normal',
          category: PsdkBattleMoveCategory.special,
          power: 50,
          battleEngineMethod: 's_snore',
        ),
      );
      final asleep = _runMove(
        playerMajorStatus: PsdkBattleMajorStatus.sleep,
        playerMove: _move(
          id: 'snore',
          type: 'normal',
          category: PsdkBattleMoveCategory.special,
          power: 50,
          battleEngineMethod: 's_snore',
        ),
      );

      expect(_failures(awake), hasLength(1));
      expect(_failures(awake).single.moveId, 'snore');
      expect(
        _failures(awake).single.reason,
        BattleMoveFailureReason.unusableByUser.jsonName,
      );
      expect(_ppSpent(awake, moveId: 'snore'), isEmpty);
      expect(_damageEvents(awake, moveId: 'snore'), isEmpty);
      expect(_failures(asleep), isEmpty);
      expect(_damageEvents(asleep, moveId: 'snore'), hasLength(1));
    });

    test('s_snore can be used by a Comatose user without sleep status', () {
      final result = _runMove(
        playerAbilityId: 'comatose',
        playerMove: _move(
          id: 'snore',
          type: 'normal',
          category: PsdkBattleMoveCategory.special,
          power: 50,
          battleEngineMethod: 's_snore',
        ),
      );

      expect(_failures(result), isEmpty);
      expect(_damageEvents(result, moveId: 'snore'), hasLength(1));
    });

    test('s_sucker_punch hits a target with a pending damaging move', () {
      final result = _runMove(
        playerSpeed: 100,
        opponentSpeed: 1,
        playerMove: _move(
          id: 'sucker_punch',
          type: 'dark',
          power: 70,
          battleEngineMethod: 's_sucker_punch',
        ),
        opponentMove: _move(id: 'opponent_tackle', power: 40),
      );

      expect(_failures(result), isEmpty);
      expect(_damageEvents(result, moveId: 'sucker_punch'), hasLength(1));
    });

    test('s_sucker_punch fails against a pending status move', () {
      final result = _runMove(
        playerSpeed: 100,
        opponentSpeed: 1,
        playerMove: _move(
          id: 'sucker_punch',
          type: 'dark',
          power: 70,
          battleEngineMethod: 's_sucker_punch',
        ),
        opponentMove: _move(
          id: 'opponent_splash',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          battleEngineMethod: 's_splash',
        ),
      );

      expect(_failures(result), hasLength(1));
      expect(_failures(result).single.moveId, 'sucker_punch');
      expect(
        _failures(result).single.reason,
        BattleMoveFailureReason.unusableByUser.jsonName,
      );
      expect(_ppSpent(result, moveId: 'sucker_punch'), isEmpty);
      expect(_damageEvents(result, moveId: 'sucker_punch'), isEmpty);
    });

    test('s_sucker_punch fails after the target already moved this turn', () {
      final result = _runMove(
        playerSpeed: 1,
        opponentSpeed: 100,
        playerMove: _move(
          id: 'sucker_punch',
          type: 'dark',
          power: 70,
          battleEngineMethod: 's_sucker_punch',
        ),
        opponentMove: _move(id: 'opponent_tackle', power: 40),
      );

      expect(_failures(result), hasLength(1));
      expect(_failures(result).single.moveId, 'sucker_punch');
      expect(
        _failures(result).single.reason,
        BattleMoveFailureReason.unusableByUser.jsonName,
      );
      expect(_damageEvents(result, moveId: 'sucker_punch'), isEmpty);
    });

    test('s_fake_out fails before PP after the user first active turn', () {
      final result = _runMove(
        playerBattleTurnCount: 2,
        playerMove: _move(
          id: 'fake_out',
          power: 40,
          battleEngineMethod: 's_fake_out',
        ),
      );

      expect(_failures(result), hasLength(1));
      expect(_failures(result).single.moveId, 'fake_out');
      expect(
        _failures(result).single.reason,
        BattleMoveFailureReason.unusableByUser.jsonName,
      );
      expect(_ppSpent(result, moveId: 'fake_out'), isEmpty);
      expect(_damageEvents(result, moveId: 'fake_out'), isEmpty);
    });

    test('s_fake_out flinches a slower target on the user first active turn',
        () {
      final result = _runMove(
        playerBattleTurnCount: 1,
        playerSpeed: 100,
        opponentSpeed: 1,
        playerMove: _move(
          id: 'fake_out',
          power: 40,
          battleEngineMethod: 's_fake_out',
        ),
        opponentMove: _move(id: 'opponent_tackle', power: 40),
      );

      expect(_failures(result), hasLength(1));
      expect(_failures(result).single.moveId, 'opponent_tackle');
      expect(
        _failures(result).single.reason,
        BattleMoveFailureReason.unusableByUser.jsonName,
      );
      expect(_damageEvents(result, moveId: 'fake_out'), hasLength(1));
      expect(_damageEvents(result, moveId: 'opponent_tackle'), isEmpty);
    });
  });
}

PsdkBattleTurnResult _runMove({
  required PsdkBattleMoveData playerMove,
  PsdkBattleMoveData? opponentMove,
  PsdkBattleMajorStatus? playerMajorStatus,
  String? playerAbilityId,
  int playerSpeed = 100,
  int opponentSpeed = 1,
  int playerBattleTurnCount = 0,
}) {
  final engine = PsdkBattleEngine(
    setup: PsdkBattleSetup.singles(
      player: _combatant(
        id: 'player',
        speed: playerSpeed,
        move: playerMove,
        majorStatus: playerMajorStatus,
        abilityId: playerAbilityId,
        battleTurnCount: playerBattleTurnCount,
      ),
      opponent: _combatant(
        id: 'opponent',
        speed: opponentSpeed,
        move: opponentMove ??
            _move(
              id: 'opponent_wait',
              category: PsdkBattleMoveCategory.status,
              power: 0,
              battleEngineMethod: 's_splash',
            ),
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
  required int speed,
  required PsdkBattleMoveData move,
  PsdkBattleMajorStatus? majorStatus,
  String? abilityId,
  int battleTurnCount = 0,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: 100,
    currentHp: 100,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: speed,
    ),
    majorStatus: majorStatus,
    abilityId: abilityId,
    battleTurnCount: battleTurnCount,
    moves: <PsdkBattleMoveData>[move],
  );
}

PsdkBattleMoveData _move({
  required String id,
  String type = 'normal',
  PsdkBattleMoveCategory category = PsdkBattleMoveCategory.physical,
  required int power,
  int accuracy = 100,
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
    criticalRate: 1,
    battleEngineMethod: battleEngineMethod,
    target: PsdkBattleMoveTarget.adjacentFoe,
  );
}

List<PsdkBattleMoveFailedEvent> _failures(PsdkBattleTurnResult result) {
  return result.timeline.events
      .whereType<PsdkBattleMoveFailedEvent>()
      .toList(growable: false);
}

List<PsdkBattleMovePpSpentEvent> _ppSpent(
  PsdkBattleTurnResult result, {
  required String moveId,
}) {
  return result.timeline.events
      .whereType<PsdkBattleMovePpSpentEvent>()
      .where((event) => event.moveId == moveId)
      .toList(growable: false);
}

List<PsdkBattleDamageEvent> _damageEvents(
  PsdkBattleTurnResult result, {
  required String moveId,
}) {
  return result.timeline.events
      .whereType<PsdkBattleDamageEvent>()
      .where((event) => event.moveId == moveId)
      .toList(growable: false);
}
