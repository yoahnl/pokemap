import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('strict s_basic damage parity', () {
    test('uses imported physical and special damage categories', () {
      final physical = _execute(
        _move(
          id: 'slash',
          category: PsdkBattleMoveCategory.physical,
          power: 70,
        ),
        userStats: _stats(attack: 100, specialAttack: 20),
        targetStats: _stats(defense: 40, specialDefense: 120),
      );
      final special = _execute(
        _move(
          id: 'swift',
          category: PsdkBattleMoveCategory.special,
          power: 70,
        ),
        userStats: _stats(attack: 100, specialAttack: 20),
        targetStats: _stats(defense: 40, specialDefense: 120),
      );

      expect(_damage(physical), greaterThan(_damage(special)));
    });

    test('uses imported type for STAB and type effectiveness', () {
      final fire = _execute(
        _move(id: 'ember', type: 'fire', power: 40),
        userTypes: const PsdkBattleTypes(primary: 'fire'),
        targetTypes: const PsdkBattleTypes(primary: 'grass'),
      );
      final normal = _execute(
        _move(id: 'tackle', type: 'normal', power: 40),
        userTypes: const PsdkBattleTypes(primary: 'fire'),
        targetTypes: const PsdkBattleTypes(primary: 'grass'),
      );

      expect(_damage(fire), greaterThan(_damage(normal)));
    });

    test('uses imported priority in turn ordering', () {
      final engine = BattleEngine.fromPsdk(
        setup: _setup(
          playerMove: _move(id: 'ice_shard', power: 40, priority: 1),
          opponentMove: _move(id: 'heavy_hit', power: 120),
          playerStats: _stats(speed: 10),
          opponentStats: _stats(speed: 200),
          opponentHp: 10,
        ),
      );

      final result = engine.submit(const BattleDecision.fight(moveSlot: 0));

      expect(result.state.battlerAt(psdkOpponentSlot).isFainted, isTrue);
      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, equals(100));
      expect(
        result.timeline.events
            .whereType<BattleDamageTimelineEvent>()
            .single
            .moveId,
        equals('ice_shard'),
      );
    });

    test('uses imported critical rate', () {
      final normal = _execute(
        _move(id: 'cut', power: 70, criticalRate: 0),
      );
      final highCrit = _execute(
        _move(id: 'slash', power: 70, criticalRate: 100),
      );

      expect(_damage(highCrit), greaterThan(_damage(normal)));
    });

    test('uses imported always-hit and non-100 accuracy', () {
      final alwaysHit = _execute(
        _move(id: 'aerial_ace', accuracy: 0),
        rngSeeds: const BattleRngSeeds(
          moveDamage: 1,
          moveCritical: 2,
          moveAccuracy: 99,
          generic: 4,
        ),
      );
      final miss = _execute(
        _move(id: 'mega_punch', accuracy: 1),
        rngSeeds: const BattleRngSeeds(
          moveDamage: 1,
          moveCritical: 2,
          moveAccuracy: 99,
          generic: 4,
        ),
      );

      expect(_damageEvents(alwaysHit), hasLength(1));
      expect(alwaysHit.rng.seeds.moveAccuracy, equals(99));
      expect(_damageEvents(miss), isEmpty);
      expect(miss.rng.seeds.moveAccuracy, isNot(99));
    });
  });
}

BattleMoveBehaviorResolution _execute(
  PsdkBattleMoveData move, {
  PsdkBattleTypes userTypes = const PsdkBattleTypes(primary: 'normal'),
  PsdkBattleTypes targetTypes = const PsdkBattleTypes(primary: 'normal'),
  PsdkBattleStats? userStats,
  PsdkBattleStats? targetStats,
  BattleRngSeeds rngSeeds = const BattleRngSeeds(
    moveDamage: 1,
    moveCritical: 2,
    moveAccuracy: 3,
    generic: 4,
  ),
}) {
  return const PsdkBattleMoveExecutor().execute(
    PsdkBattleMoveRequest(
      state: PsdkBattleState.fromSetup(
        _setup(
          playerMove: move,
          playerTypes: userTypes,
          opponentTypes: targetTypes,
          playerStats: userStats,
          opponentStats: targetStats,
          rngSeeds: rngSeeds,
        ),
      ),
      rng: BattleRngStreams.fromSeeds(
        moveDamageSeed: rngSeeds.moveDamage,
        moveCriticalSeed: rngSeeds.moveCritical,
        moveAccuracySeed: rngSeeds.moveAccuracy,
        genericSeed: rngSeeds.generic,
      ),
      turn: 1,
      user: psdkPlayerSlot,
      target: psdkOpponentSlot,
      moveId: move.id,
      battleEngineMethod: move.battleEngineMethod,
      studioMove: move,
    ),
  );
}

int _damage(BattleMoveBehaviorResolution resolution) {
  return _damageEvents(resolution).single.damage;
}

Iterable<PsdkBattleDamageEvent> _damageEvents(
  BattleMoveBehaviorResolution resolution,
) {
  return resolution.events.whereType<PsdkBattleDamageEvent>();
}

PsdkBattleSetup _setup({
  required PsdkBattleMoveData playerMove,
  PsdkBattleMoveData? opponentMove,
  PsdkBattleTypes playerTypes = const PsdkBattleTypes(primary: 'normal'),
  PsdkBattleTypes opponentTypes = const PsdkBattleTypes(primary: 'normal'),
  PsdkBattleStats? playerStats,
  PsdkBattleStats? opponentStats,
  int playerHp = 100,
  int opponentHp = 100,
  BattleRngSeeds rngSeeds = const BattleRngSeeds(
    moveDamage: 1,
    moveCritical: 2,
    moveAccuracy: 3,
    generic: 4,
  ),
}) {
  return PsdkBattleSetup.singles(
    player: _combatant(
      id: 'player',
      hp: playerHp,
      types: playerTypes,
      stats: playerStats ?? _stats(),
      moves: <PsdkBattleMoveData>[playerMove],
    ),
    opponent: _combatant(
      id: 'opponent',
      hp: opponentHp,
      types: opponentTypes,
      stats: opponentStats ?? _stats(),
      moves: <PsdkBattleMoveData>[
        opponentMove ?? _move(id: 'opponent_wait', power: 1),
      ],
    ),
    rngSeeds: PsdkBattleRngSeeds(
      moveDamage: rngSeeds.moveDamage,
      moveCritical: rngSeeds.moveCritical,
      moveAccuracy: rngSeeds.moveAccuracy,
      generic: rngSeeds.generic,
    ),
  );
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required int hp,
  required PsdkBattleTypes types,
  required PsdkBattleStats stats,
  required List<PsdkBattleMoveData> moves,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 50,
    maxHp: hp,
    currentHp: hp,
    types: types,
    stats: stats,
    moves: moves,
  );
}

PsdkBattleStats _stats({
  int attack = 70,
  int defense = 70,
  int specialAttack = 70,
  int specialDefense = 70,
  int speed = 70,
}) {
  return PsdkBattleStats(
    attack: attack,
    defense: defense,
    specialAttack: specialAttack,
    specialDefense: specialDefense,
    speed: speed,
  );
}

PsdkBattleMoveData _move({
  required String id,
  String type = 'normal',
  PsdkBattleMoveCategory category = PsdkBattleMoveCategory.physical,
  int power = 40,
  int accuracy = 100,
  int pp = 35,
  int priority = 0,
  int criticalRate = 1,
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: type,
    category: category,
    power: power,
    accuracy: accuracy,
    pp: pp,
    priority: priority,
    criticalRate: criticalRate,
    battleEngineMethod: 's_basic',
    target: PsdkBattleMoveTarget.adjacentFoe,
  );
}
