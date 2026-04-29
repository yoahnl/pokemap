import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK counter/delayed damage move families', () {
    test('s_counter returns double current-turn damage to the attacker', () {
      final result = _runMove(
        playerSpeed: 1,
        opponentSpeed: 100,
        playerMove: _move(
          id: 'counter',
          type: 'fighting',
          power: 0,
          battleEngineMethod: 's_counter',
        ),
        opponentMove: _move(id: 'opponent_tackle', power: 40),
      );

      final incoming = _damage(result, moveId: 'opponent_tackle');
      final counter = _damage(result, moveId: 'counter');
      expect(counter, incoming * 2);
    });

    test('s_mirror_coat returns double current-turn damage to the attacker',
        () {
      final result = _runMove(
        playerSpeed: 1,
        opponentSpeed: 100,
        playerMove: _move(
          id: 'mirror_coat',
          type: 'psychic',
          category: PsdkBattleMoveCategory.special,
          power: 0,
          battleEngineMethod: 's_mirror_coat',
        ),
        opponentMove: _move(
          id: 'opponent_water_gun',
          category: PsdkBattleMoveCategory.special,
          power: 40,
        ),
      );

      final incoming = _damage(result, moveId: 'opponent_water_gun');
      final reflected = _damage(result, moveId: 'mirror_coat');
      expect(reflected, incoming * 2);
    });

    test('s_metal_burst returns 1.5x current-turn damage to the attacker', () {
      final result = _runMove(
        playerSpeed: 1,
        opponentSpeed: 100,
        playerMove: _move(
          id: 'metal_burst',
          type: 'steel',
          power: 0,
          battleEngineMethod: 's_metal_burst',
        ),
        opponentMove: _move(id: 'opponent_tackle', power: 40),
      );

      final incoming = _damage(result, moveId: 'opponent_tackle');
      final burst = _damage(result, moveId: 'metal_burst');
      expect(burst, (incoming * 1.5).floor());
    });

    test('s_bide releases double stored damage from prior entries', () {
      final result = _runMove(
        playerDamageHistory: PsdkBattleDamageHistory(
          entries: const <PsdkBattleDamageHistoryEntry>[
            PsdkBattleDamageHistoryEntry(
              turn: 1,
              source: psdkOpponentSlot,
              moveId: 'hit_one',
              damage: 8,
              remainingHp: 92,
            ),
            PsdkBattleDamageHistoryEntry(
              turn: 2,
              source: psdkOpponentSlot,
              moveId: 'hit_two',
              damage: 10,
              remainingHp: 82,
            ),
          ],
        ),
        playerMove: _move(
          id: 'bide',
          type: 'normal',
          power: 0,
          battleEngineMethod: 's_bide',
        ),
      );

      expect(_damage(result, moveId: 'bide'), 36);
    });
  });
}

PsdkBattleTurnResult _runMove({
  required PsdkBattleMoveData playerMove,
  PsdkBattleMoveData? opponentMove,
  PsdkBattleDamageHistory playerDamageHistory =
      const PsdkBattleDamageHistory.empty(),
  int playerSpeed = 100,
  int opponentSpeed = 1,
}) {
  final engine = PsdkBattleEngine(
    setup: PsdkBattleSetup.singles(
      player: _combatant(
        id: 'player',
        speed: playerSpeed,
        move: playerMove,
        damageHistory: playerDamageHistory,
      ),
      opponent: _combatant(
        id: 'opponent',
        speed: opponentSpeed,
        move: opponentMove ??
            _move(
              id: 'opponent_wait',
              power: 0,
              accuracy: 0,
              category: PsdkBattleMoveCategory.status,
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
  PsdkBattleDamageHistory damageHistory = const PsdkBattleDamageHistory.empty(),
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
    damageHistory: damageHistory,
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

int _damage(PsdkBattleTurnResult result, {required String moveId}) {
  return result.timeline.events
      .whereType<PsdkBattleDamageEvent>()
      .singleWhere((event) => event.moveId == moveId)
      .damage;
}
