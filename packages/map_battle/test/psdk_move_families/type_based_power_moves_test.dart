import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK type-based damage move families', () {
    test('s_revelation_dance uses the user primary type', () {
      final normal = _runMove(
        playerTypes: const PsdkBattleTypes(primary: 'normal'),
        opponentTypes: const PsdkBattleTypes(primary: 'grass'),
        playerMove: _move(
          id: 'revelation_dance',
          type: 'normal',
          power: 90,
          battleEngineMethod: 's_revelation_dance',
        ),
      );
      final fireTyped = _runMove(
        playerTypes: const PsdkBattleTypes(primary: 'fire'),
        opponentTypes: const PsdkBattleTypes(primary: 'grass'),
        playerMove: _move(
          id: 'revelation_dance',
          type: 'normal',
          power: 90,
          battleEngineMethod: 's_revelation_dance',
        ),
      );

      expect(
        _damage(fireTyped, moveId: 'revelation_dance'),
        greaterThan(_damage(normal, moveId: 'revelation_dance')),
      );
    });

    test('s_judgment uses the held plate type', () {
      final normal = _runMove(
        opponentTypes: const PsdkBattleTypes(primary: 'grass'),
        playerMove: _move(
          id: 'judgment',
          type: 'normal',
          power: 100,
          battleEngineMethod: 's_judgment',
        ),
      );
      final plated = _runMove(
        playerHeldItemId: 'flame_plate',
        opponentTypes: const PsdkBattleTypes(primary: 'grass'),
        playerMove: _move(
          id: 'judgment',
          type: 'normal',
          power: 100,
          battleEngineMethod: 's_judgment',
        ),
      );

      expect(
        _damage(plated, moveId: 'judgment'),
        greaterThan(_damage(normal, moveId: 'judgment')),
      );
    });

    test('s_multi_attack uses the held memory type', () {
      final normal = _runMove(
        opponentTypes: const PsdkBattleTypes(primary: 'grass'),
        playerMove: _move(
          id: 'multi_attack',
          type: 'normal',
          power: 120,
          battleEngineMethod: 's_multi_attack',
        ),
      );
      final memorized = _runMove(
        playerHeldItemId: 'fire_memory',
        opponentTypes: const PsdkBattleTypes(primary: 'grass'),
        playerMove: _move(
          id: 'multi_attack',
          type: 'normal',
          power: 120,
          battleEngineMethod: 's_multi_attack',
        ),
      );

      expect(
        _damage(memorized, moveId: 'multi_attack'),
        greaterThan(_damage(normal, moveId: 'multi_attack')),
      );
    });

    test('s_ivy_cudgel uses the held mask type', () {
      final grass = _runMove(
        opponentTypes: const PsdkBattleTypes(primary: 'grass'),
        playerMove: _move(
          id: 'ivy_cudgel',
          type: 'grass',
          power: 100,
          battleEngineMethod: 's_ivy_cudgel',
        ),
      );
      final masked = _runMove(
        playerHeldItemId: 'hearthflame_mask',
        opponentTypes: const PsdkBattleTypes(primary: 'grass'),
        playerMove: _move(
          id: 'ivy_cudgel',
          type: 'grass',
          power: 100,
          battleEngineMethod: 's_ivy_cudgel',
        ),
      );

      expect(
        _damage(masked, moveId: 'ivy_cudgel'),
        greaterThan(_damage(grass, moveId: 'ivy_cudgel')),
      );
    });
  });
}

PsdkBattleTurnResult _runMove({
  required PsdkBattleMoveData playerMove,
  PsdkBattleTypes playerTypes = const PsdkBattleTypes(primary: 'normal'),
  PsdkBattleTypes opponentTypes = const PsdkBattleTypes(primary: 'normal'),
  String? playerHeldItemId,
}) {
  final engine = PsdkBattleEngine(
    setup: PsdkBattleSetup.singles(
      player: _combatant(
        id: 'player',
        types: playerTypes,
        move: playerMove,
        heldItemId: playerHeldItemId,
      ),
      opponent: _combatant(
        id: 'opponent',
        speed: 1,
        types: opponentTypes,
        move: _move(
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
  required PsdkBattleTypes types,
  required PsdkBattleMoveData move,
  int speed = 100,
  String? heldItemId,
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
    heldItemId: heldItemId,
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

int _damage(
  PsdkBattleTurnResult result, {
  required String moveId,
}) {
  return result.timeline.events
      .whereType<PsdkBattleDamageEvent>()
      .singleWhere((event) => event.moveId == moveId)
      .damage;
}
