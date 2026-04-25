import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK item/stat power move families', () {
    test('s_acrobatics doubles power when the user has no held item', () {
      final holdingItem = _runMove(
        playerHeldItemId: 'oran_berry',
        playerMove: _move(
          id: 'acrobatics',
          battleEngineMethod: 's_acrobatics',
          power: 55,
          type: 'flying',
        ),
      );
      final noItem = _runMove(
        playerMove: _move(
          id: 'acrobatics',
          battleEngineMethod: 's_acrobatics',
          power: 55,
          type: 'flying',
        ),
      );

      expect(
        _damage(noItem, moveId: 'acrobatics'),
        greaterThan(_damage(holdingItem, moveId: 'acrobatics')),
      );
    });

    test('s_stored_power adds 20 power for each positive user stat stage', () {
      final neutral = _runMove(
        playerMove: _move(
          id: 'stored_power',
          battleEngineMethod: 's_stored_power',
          power: 20,
          type: 'psychic',
          category: PsdkBattleMoveCategory.special,
        ),
      );
      final boosted = _runMove(
        playerStatStages: PsdkBattleStatStages(
          values: const <String, int>{
            'attack': 2,
            'defense': 1,
            'speed': 3,
            'specialAttack': -1,
          },
        ),
        playerMove: _move(
          id: 'stored_power',
          battleEngineMethod: 's_stored_power',
          power: 20,
          type: 'psychic',
          category: PsdkBattleMoveCategory.special,
        ),
      );

      expect(
        _damage(boosted, moveId: 'stored_power'),
        greaterThan(_damage(neutral, moveId: 'stored_power') * 4),
      );
    });
  });

  group('PSDK drain and heal move families', () {
    test('s_absorb heals the user from half the damage dealt', () {
      final result = _runMove(
        playerCurrentHp: 60,
        playerMove: _move(
          id: 'absorb',
          battleEngineMethod: 's_absorb',
          power: 80,
          type: 'grass',
          category: PsdkBattleMoveCategory.special,
        ),
      );
      final damage = _damage(result, moveId: 'absorb');
      final heal = _healJson(result, moveId: 'absorb');

      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 100 - damage);
      expect(
          result.state.battlerAt(psdkPlayerSlot).currentHp, 60 + (damage ~/ 2));
      expect(heal['amount'], damage ~/ 2);
      expect(heal['target'], psdkPlayerSlot.toJson());
    });

    test('s_dream_eater only drains targets that are asleep', () {
      final awake = _runMove(
        playerCurrentHp: 60,
        playerMove: _move(
          id: 'dream_eater',
          battleEngineMethod: 's_dream_eater',
          power: 100,
          type: 'psychic',
          category: PsdkBattleMoveCategory.special,
        ),
      );
      final asleep = _runMove(
        playerCurrentHp: 60,
        opponentMajorStatus: PsdkBattleMajorStatus.sleep,
        playerMove: _move(
          id: 'dream_eater',
          battleEngineMethod: 's_dream_eater',
          power: 100,
          type: 'psychic',
          category: PsdkBattleMoveCategory.special,
        ),
      );

      expect(_damageEvents(awake, moveId: 'dream_eater'), isEmpty);
      expect(
        awake.timeline.events.map((event) => event.kind),
        contains('move_immune'),
      );
      expect(_damage(asleep, moveId: 'dream_eater'), greaterThan(0));
      expect(_healJson(asleep, moveId: 'dream_eater')['amount'],
          _damage(asleep, moveId: 'dream_eater') ~/ 2);
    });

    test('s_heal restores half of the target max HP', () {
      final result = _runMove(
        playerCurrentHp: 35,
        playerMove: _move(
          id: 'recover',
          battleEngineMethod: 's_heal',
          power: 0,
          category: PsdkBattleMoveCategory.status,
          target: PsdkBattleMoveTarget.user,
        ),
      );
      final heal = _healJson(result, moveId: 'recover');

      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 85);
      expect(heal['amount'], 50);
      expect(heal['remainingHp'], 85);
    });
  });
}

PsdkBattleTurnResult _runMove({
  required PsdkBattleMoveData playerMove,
  int playerCurrentHp = 100,
  String? playerHeldItemId,
  bool playerItemConsumed = false,
  PsdkBattleStatStages? playerStatStages,
  int opponentCurrentHp = 100,
  PsdkBattleMajorStatus? opponentMajorStatus,
  String? opponentAbilityId,
}) {
  final engine = PsdkBattleEngine(
    setup: PsdkBattleSetup.singles(
      player: _combatant(
        id: 'player',
        currentHp: playerCurrentHp,
        move: playerMove,
        heldItemId: playerHeldItemId,
        itemConsumed: playerItemConsumed,
        statStages: playerStatStages,
      ),
      opponent: _combatant(
        id: 'opponent',
        currentHp: opponentCurrentHp,
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
  required PsdkBattleMoveData move,
  String? heldItemId,
  bool itemConsumed = false,
  PsdkBattleStatStages? statStages,
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
    types: const PsdkBattleTypes(primary: 'fire'),
    stats: const PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: 100,
    ),
    moves: <PsdkBattleMoveData>[move],
    heldItemId: heldItemId,
    itemConsumed: itemConsumed,
    statStages: statStages,
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
    pp: 35,
    priority: 0,
    criticalRate: criticalRate,
    battleEngineMethod: battleEngineMethod,
    target: target,
  );
}

int _damage(
  PsdkBattleTurnResult result, {
  required String moveId,
}) {
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

Map<String, Object?> _healJson(
  PsdkBattleTurnResult result, {
  required String moveId,
}) {
  return result.timeline.events
      .where((event) => event.kind == 'heal')
      .map((event) => event.toJson())
      .singleWhere((json) => json['moveId'] == moveId);
}
