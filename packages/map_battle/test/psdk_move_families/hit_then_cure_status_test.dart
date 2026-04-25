import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK hit-then-cure status move families', () {
    test('s_smelling_salt doubles power against paralysis then cures it', () {
      final neutral = _runMove(
        playerMove: _move(
          id: 'smelling_salt',
          battleEngineMethod: 's_smelling_salt',
          power: 70,
        ),
      );
      final paralyzed = _runMove(
        opponentMajorStatus: PsdkBattleMajorStatus.paralysis,
        playerMove: _move(
          id: 'smelling_salt',
          battleEngineMethod: 's_smelling_salt',
          power: 70,
        ),
      );

      expect(
        _damage(paralyzed, moveId: 'smelling_salt'),
        greaterThan(_damage(neutral, moveId: 'smelling_salt')),
      );
      expect(paralyzed.state.battlerAt(psdkOpponentSlot).majorStatus, isNull);
      expect(
        _moveKinds(paralyzed, moveId: 'smelling_salt'),
        containsAllInOrder(<String>['damage', 'status_cure']),
      );
    });

    test('s_wakeup_slap doubles power against sleep then cures it', () {
      final awake = _runMove(
        playerMove: _move(
          id: 'wake_up_slap',
          battleEngineMethod: 's_wakeup_slap',
          power: 70,
        ),
      );
      final asleep = _runMove(
        opponentMajorStatus: PsdkBattleMajorStatus.sleep,
        playerMove: _move(
          id: 'wake_up_slap',
          battleEngineMethod: 's_wakeup_slap',
          power: 70,
        ),
      );

      expect(
        _damage(asleep, moveId: 'wake_up_slap'),
        greaterThan(_damage(awake, moveId: 'wake_up_slap')),
      );
      expect(asleep.state.battlerAt(psdkOpponentSlot).majorStatus, isNull);
      expect(
        _cureJson(asleep, moveId: 'wake_up_slap')['status'],
        PsdkBattleMajorStatus.sleep.name,
      );
    });

    test('s_wakeup_slap doubles power against Comatose without fake cure', () {
      final awake = _runMove(
        playerMove: _move(
          id: 'wake_up_slap',
          battleEngineMethod: 's_wakeup_slap',
          power: 70,
        ),
      );
      final comatose = _runMove(
        opponentAbilityId: 'comatose',
        playerMove: _move(
          id: 'wake_up_slap',
          battleEngineMethod: 's_wakeup_slap',
          power: 70,
        ),
      );

      expect(
        _damage(comatose, moveId: 'wake_up_slap'),
        greaterThan(_damage(awake, moveId: 'wake_up_slap')),
      );
      expect(comatose.state.battlerAt(psdkOpponentSlot).majorStatus, isNull);
      expect(
        _moveKinds(comatose, moveId: 'wake_up_slap'),
        isNot(contains('status_cure')),
      );
    });

    test('s_sparkling_aria cures burn after damage without boosting power', () {
      final neutral = _runMove(
        playerMove: _move(
          id: 'sparkling_aria',
          battleEngineMethod: 's_sparkling_aria',
          type: 'water',
          category: PsdkBattleMoveCategory.special,
          power: 90,
        ),
      );
      final burned = _runMove(
        opponentMajorStatus: PsdkBattleMajorStatus.burn,
        playerMove: _move(
          id: 'sparkling_aria',
          battleEngineMethod: 's_sparkling_aria',
          type: 'water',
          category: PsdkBattleMoveCategory.special,
          power: 90,
        ),
      );

      expect(
        _damage(burned, moveId: 'sparkling_aria'),
        _damage(neutral, moveId: 'sparkling_aria'),
      );
      expect(burned.state.battlerAt(psdkOpponentSlot).majorStatus, isNull);
      expect(
        _moveKinds(burned, moveId: 'sparkling_aria'),
        containsAllInOrder(<String>['damage', 'status_cure']),
      );
    });
  });
}

PsdkBattleTurnResult _runMove({
  required PsdkBattleMoveData playerMove,
  PsdkBattleMajorStatus? opponentMajorStatus,
  String? opponentAbilityId,
}) {
  final engine = PsdkBattleEngine(
    setup: PsdkBattleSetup.singles(
      player: _combatant(
        id: 'player',
        speed: 100,
        move: playerMove,
      ),
      opponent: _combatant(
        id: 'opponent',
        speed: 1,
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
    currentHp: 100,
    types: const PsdkBattleTypes(primary: 'normal'),
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

List<String> _moveKinds(
  PsdkBattleTurnResult result, {
  required String moveId,
}) {
  return result.timeline.events
      .where((event) => event.toJson()['moveId'] == moveId)
      .map((event) => event.kind)
      .toList(growable: false);
}

Map<String, Object?> _cureJson(
  PsdkBattleTurnResult result, {
  required String moveId,
}) {
  return result.timeline.events
      .where((event) => event.kind == 'status_cure')
      .map((event) => event.toJson())
      .singleWhere((json) => json['moveId'] == moveId);
}
