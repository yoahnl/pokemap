import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK basic damage specializations', () {
    test('s_false_swipe leaves the target at one HP', () {
      final result = _runMove(
        playerMove: _move(
          id: 'false_swipe',
          battleEngineMethod: 's_false_swipe',
          power: 200,
        ),
        opponentCurrentHp: 30,
      );

      final damage = _damageEvents(result, moveId: 'false_swipe');
      expect(damage, hasLength(1));
      expect(damage.single.damage, 29);
      expect(damage.single.remainingHp, 1);
      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 1);
      expect(result.state.outcome, isNull);
    });

    test(
        's_false_swipe emits no zero-damage event when the target is at one HP',
        () {
      final result = _runMove(
        playerMove: _move(
          id: 'false_swipe',
          battleEngineMethod: 's_false_swipe',
          power: 200,
        ),
        opponentCurrentHp: 1,
      );

      expect(_damageEvents(result, moveId: 'false_swipe'), isEmpty);
      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 1);
    });

    test('s_false_swipe keeps normal damage below the anti-KO threshold', () {
      final result = _runMove(
        playerMove: _move(
          id: 'false_swipe',
          battleEngineMethod: 's_false_swipe',
          power: 40,
        ),
      );

      final damage = _damageEvents(result, moveId: 'false_swipe');
      expect(damage, hasLength(1));
      expect(damage.single.damage, 8);
      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 92);
    });

    test('s_false_swipe keeps the common immunity precheck', () {
      final result = _runMove(
        playerMove: _move(
          id: 'false_swipe',
          battleEngineMethod: 's_false_swipe',
          power: 200,
        ),
        opponentTypes: const PsdkBattleTypes(primary: 'ghost'),
      );

      final kinds = result.timeline.events.map((event) => event.kind);
      expect(kinds, contains('move_immune'));
      expect(_damageEvents(result, moveId: 'false_swipe'), isEmpty);
      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 100);
    });

    test('s_full_crit forces critical damage through the PSDK method', () {
      final baseline = _runMove(
        playerMove: _move(
          id: 'baseline_slash',
          battleEngineMethod: 's_basic',
          power: 80,
        ),
      );
      final fullCrit = _runMove(
        playerMove: _move(
          id: 'full_crit_slash',
          battleEngineMethod: 's_full_crit',
          power: 80,
        ),
      );

      expect(_damage(fullCrit, moveId: 'full_crit_slash'), 23);
      expect(
        _damage(fullCrit, moveId: 'full_crit_slash'),
        greaterThan(_damage(baseline, moveId: 'baseline_slash')),
      );
      expect(fullCrit.state.rngSeeds.moveCritical, 99999);
    });
  });
}

BattleEngineTurnResult _runMove({
  required PsdkBattleMoveData playerMove,
  int opponentCurrentHp = 100,
  PsdkBattleTypes opponentTypes = const PsdkBattleTypes(primary: 'fire'),
}) {
  final engine = BattleEngine(
    setup: BattleEngineSetup.singles(
      player: _combatant(
        id: 'player',
        currentHp: 100,
        speed: 100,
        move: playerMove,
      ),
      opponent: _combatant(
        id: 'opponent',
        currentHp: opponentCurrentHp,
        speed: 1,
        types: opponentTypes,
        move: _move(
          id: 'opponent_wait',
          power: 0,
          accuracy: 1,
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
  return engine.submit(const BattleDecision.fight(moveSlot: 0));
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required int currentHp,
  required int speed,
  required PsdkBattleMoveData move,
  PsdkBattleTypes types = const PsdkBattleTypes(primary: 'fire'),
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: 100,
    currentHp: currentHp,
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

List<BattleDamageTimelineEvent> _damageEvents(
  BattleEngineTurnResult result, {
  required String moveId,
}) {
  return result.timeline.events
      .whereType<BattleDamageTimelineEvent>()
      .where((event) => event.moveId == moveId)
      .toList(growable: false);
}

int _damage(
  BattleEngineTurnResult result, {
  required String moveId,
}) {
  return _damageEvents(result, moveId: moveId).single.damage;
}
