import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK action queue move families', () {
    test('s_after_you fails after PP when the target already acted', () {
      final result = _runMove(
        playerSpeed: 10,
        opponentSpeed: 100,
        playerMove: _statusMove(
          id: 'after_you',
          battleEngineMethod: 's_after_you',
        ),
        opponentMove: _damageMove(id: 'opponent_tackle'),
      );

      expect(_damageMoveIds(result), equals(<String>['opponent_tackle']));
      expect(_failures(result), hasLength(1));
      expect(_failures(result).single.moveId, 'after_you');
      expect(
        _failures(result).single.reason,
        BattleMoveFailureReason.unusableByUser.jsonName,
      );
      expect(_ppSpent(result, moveId: 'after_you'), hasLength(1));
    });

    test('s_after_you succeeds while the target still has a queued move', () {
      final result = _runMove(
        playerSpeed: 100,
        opponentSpeed: 10,
        playerMove: _statusMove(
          id: 'after_you',
          battleEngineMethod: 's_after_you',
        ),
        opponentMove: _damageMove(id: 'opponent_tackle'),
      );

      expect(_failures(result), isEmpty);
      expect(_damageMoveIds(result), equals(<String>['opponent_tackle']));
      expect(_ppSpent(result, moveId: 'after_you'), hasLength(1));
      expect(_hasPersistentEffect(result, 'after_you'), isFalse);
    });

    test('s_quash fails after PP when the target already acted', () {
      final result = _runMove(
        playerSpeed: 10,
        opponentSpeed: 100,
        playerMove: _statusMove(
          id: 'quash',
          battleEngineMethod: 's_quash',
        ),
        opponentMove: _damageMove(id: 'opponent_tackle'),
      );

      expect(_damageMoveIds(result), equals(<String>['opponent_tackle']));
      expect(_failures(result), hasLength(1));
      expect(_failures(result).single.moveId, 'quash');
      expect(
        _failures(result).single.reason,
        BattleMoveFailureReason.unusableByUser.jsonName,
      );
      expect(_ppSpent(result, moveId: 'quash'), hasLength(1));
    });

    test('s_quash succeeds while the target still has a queued move', () {
      final result = _runMove(
        playerSpeed: 100,
        opponentSpeed: 10,
        playerMove: _statusMove(
          id: 'quash',
          battleEngineMethod: 's_quash',
        ),
        opponentMove: _damageMove(id: 'opponent_tackle'),
      );

      expect(_failures(result), isEmpty);
      expect(_damageMoveIds(result), equals(<String>['opponent_tackle']));
      expect(_ppSpent(result, moveId: 'quash'), hasLength(1));
      expect(_hasPersistentEffect(result, 'quash'), isFalse);
    });
  });
}

PsdkBattleTurnResult _runMove({
  required int playerSpeed,
  required int opponentSpeed,
  required PsdkBattleMoveData playerMove,
  required PsdkBattleMoveData opponentMove,
}) {
  final engine = PsdkBattleEngine(
    setup: PsdkBattleSetup.singles(
      player: _combatant(
        id: 'player',
        speed: playerSpeed,
        move: playerMove,
      ),
      opponent: _combatant(
        id: 'opponent',
        speed: opponentSpeed,
        move: opponentMove,
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
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: 300,
    currentHp: 300,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: speed,
    ),
    moves: <PsdkBattleMoveData>[move],
  );
}

PsdkBattleMoveData _damageMove({required String id}) {
  return _move(
    id: id,
    power: 40,
    category: PsdkBattleMoveCategory.physical,
    battleEngineMethod: 's_basic',
    target: PsdkBattleMoveTarget.adjacentFoe,
  );
}

PsdkBattleMoveData _statusMove({
  required String id,
  required String battleEngineMethod,
}) {
  return _move(
    id: id,
    power: 0,
    category: PsdkBattleMoveCategory.status,
    battleEngineMethod: battleEngineMethod,
    target: PsdkBattleMoveTarget.adjacentFoe,
  );
}

PsdkBattleMoveData _move({
  required String id,
  required int power,
  required PsdkBattleMoveCategory category,
  required String battleEngineMethod,
  required PsdkBattleMoveTarget target,
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: 'normal',
    category: category,
    power: power,
    accuracy: 100,
    pp: 35,
    priority: 0,
    criticalRate: 1,
    battleEngineMethod: battleEngineMethod,
    target: target,
  );
}

List<String> _damageMoveIds(PsdkBattleTurnResult result) {
  return result.timeline.events
      .whereType<PsdkBattleDamageEvent>()
      .map((event) => event.moveId)
      .toList(growable: false);
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

bool _hasPersistentEffect(PsdkBattleTurnResult result, String effectId) {
  return result.state.battlerAt(psdkPlayerSlot).effects.contains(effectId) ||
      result.state.battlerAt(psdkOpponentSlot).effects.contains(effectId);
}
