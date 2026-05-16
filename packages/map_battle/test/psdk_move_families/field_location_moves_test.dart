import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK field/location move families', () {
    test('s_camouflage changes the user type from active terrain', () {
      final electric = _runMove(
        field: const PsdkBattleFieldState(
          terrain: PsdkBattleTerrainState(
            id: PsdkBattleTerrainId.electricTerrain,
            remainingTurns: 5,
          ),
        ),
        playerMove: _move(
          id: 'camouflage',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          battleEngineMethod: 's_camouflage',
          target: PsdkBattleMoveTarget.user,
        ),
      );
      final neutral = _runMove(
        playerMove: _move(
          id: 'camouflage',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          battleEngineMethod: 's_camouflage',
          target: PsdkBattleMoveTarget.user,
        ),
        playerTypes: const PsdkBattleTypes(primary: 'fire'),
      );

      expect(
          electric.state.battlerAt(psdkPlayerSlot).types.primary, 'electric');
      expect(electric.state.battlerAt(psdkPlayerSlot).type3, isNull);
      expect(electric.state.battlerAt(psdkPlayerSlot).temporaryTypes, isEmpty);
      expect(neutral.state.battlerAt(psdkPlayerSlot).types.primary, 'normal');
    });

    test('s_nature_power becomes a terrain-specific damaging move', () {
      final neutral = _runMove(
        opponentTypes: const PsdkBattleTypes(primary: 'water'),
        playerMove: _move(
          id: 'nature_power',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          battleEngineMethod: 's_nature_power',
        ),
      );
      final electric = _runMove(
        field: const PsdkBattleFieldState(
          terrain: PsdkBattleTerrainState(
            id: PsdkBattleTerrainId.electricTerrain,
            remainingTurns: 5,
          ),
        ),
        opponentTypes: const PsdkBattleTypes(primary: 'water'),
        playerMove: _move(
          id: 'nature_power',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          battleEngineMethod: 's_nature_power',
        ),
      );

      expect(_damage(neutral, moveId: 'nature_power'), greaterThan(0));
      expect(
        _damage(electric, moveId: 'nature_power'),
        greaterThan(_damage(neutral, moveId: 'nature_power')),
      );
    });

    test('s_nature_power records the converted special damage category', () {
      final result = _runMove(
        field: const PsdkBattleFieldState(
          terrain: PsdkBattleTerrainState(
            id: PsdkBattleTerrainId.electricTerrain,
            remainingTurns: 5,
          ),
        ),
        opponentTypes: const PsdkBattleTypes(primary: 'water'),
        playerMove: _move(
          id: 'nature_power',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          battleEngineMethod: 's_nature_power',
        ),
        opponentMove: _move(
          id: 'mirror_coat',
          type: 'psychic',
          category: PsdkBattleMoveCategory.special,
          power: 0,
          battleEngineMethod: 's_mirror_coat',
        ),
      );

      final incoming = _damage(result, moveId: 'nature_power');
      final reflected = _damage(result, moveId: 'mirror_coat');
      expect(reflected, incoming * 2);
    });

    test('s_secret_power records its physical damage category', () {
      final result = _runMove(
        playerMove: _move(
          id: 'secret_power',
          power: 70,
          battleEngineMethod: 's_secret_power',
        ),
        opponentMove: _move(
          id: 'counter',
          type: 'fighting',
          power: 0,
          battleEngineMethod: 's_counter',
        ),
      );

      final incoming = _damage(result, moveId: 'secret_power');
      final counter = _damage(result, moveId: 'counter');
      expect(counter, incoming * 2);
    });

    test('s_secret_power applies its terrain secondary effect on proc', () {
      final result = _runMove(
        field: const PsdkBattleFieldState(
          terrain: PsdkBattleTerrainState(
            id: PsdkBattleTerrainId.electricTerrain,
            remainingTurns: 5,
          ),
        ),
        playerMove: _move(
          id: 'secret_power',
          power: 70,
          battleEngineMethod: 's_secret_power',
        ),
      );

      expect(_damage(result, moveId: 'secret_power'), greaterThan(0));
      expect(
        result.state.battlerAt(psdkOpponentSlot).majorStatus,
        PsdkBattleMajorStatus.paralysis,
      );
    });

    test('s_synchronoise fails unless the target shares a user type', () {
      final blocked = _runMove(
        playerTypes: const PsdkBattleTypes(primary: 'psychic'),
        opponentTypes: const PsdkBattleTypes(primary: 'water'),
        playerMove: _move(
          id: 'synchronoise',
          type: 'psychic',
          category: PsdkBattleMoveCategory.special,
          power: 120,
          battleEngineMethod: 's_synchronoise',
        ),
      );
      final shared = _runMove(
        playerTypes: const PsdkBattleTypes(primary: 'psychic'),
        opponentTypes: const PsdkBattleTypes(primary: 'psychic'),
        playerMove: _move(
          id: 'synchronoise',
          type: 'psychic',
          category: PsdkBattleMoveCategory.special,
          power: 120,
          battleEngineMethod: 's_synchronoise',
        ),
      );

      expect(_failed(blocked, moveId: 'synchronoise'), isTrue);
      expect(_damageEvents(blocked, moveId: 'synchronoise'), isEmpty);
      expect(_damage(shared, moveId: 'synchronoise'), greaterThan(0));
    });

    test('s_pledge remains a dedicated basic-damage local singles slice', () {
      final result = _runMove(
        playerMove: _move(
          id: 'water_pledge',
          type: 'water',
          category: PsdkBattleMoveCategory.special,
          power: 80,
          battleEngineMethod: 's_pledge',
        ),
      );

      expect(_damage(result, moveId: 'water_pledge'), greaterThan(0));
    });
  });
}

PsdkBattleTurnResult _runMove({
  required PsdkBattleMoveData playerMove,
  PsdkBattleFieldState field = const PsdkBattleFieldState(),
  PsdkBattleTypes playerTypes = const PsdkBattleTypes(primary: 'normal'),
  PsdkBattleTypes opponentTypes = const PsdkBattleTypes(primary: 'normal'),
  PsdkBattleMoveData? opponentMove,
}) {
  final engine = PsdkBattleEngine(
    setup: PsdkBattleSetup.singles(
      field: field,
      player: _combatant(
        id: 'player',
        speed: 100,
        types: playerTypes,
        move: playerMove,
      ),
      opponent: _combatant(
        id: 'opponent',
        speed: 1,
        types: opponentTypes,
        move: opponentMove ??
            _move(
              id: 'opponent_wait',
              category: PsdkBattleMoveCategory.status,
              power: 0,
              accuracy: 0,
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
  required PsdkBattleTypes types,
  required PsdkBattleMoveData move,
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
  PsdkBattleMoveTarget target = PsdkBattleMoveTarget.adjacentFoe,
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: type,
    category: category,
    power: power,
    accuracy: accuracy,
    pp: 20,
    priority: 0,
    criticalRate: 1,
    battleEngineMethod: battleEngineMethod,
    target: target,
  );
}

int _damage(PsdkBattleTurnResult result, {required String moveId}) {
  return _damageEvents(result, moveId: moveId).single.damage;
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

bool _failed(PsdkBattleTurnResult result, {required String moveId}) {
  return result.timeline.events
      .whereType<PsdkBattleMoveFailedEvent>()
      .any((event) => event.moveId == moveId);
}
