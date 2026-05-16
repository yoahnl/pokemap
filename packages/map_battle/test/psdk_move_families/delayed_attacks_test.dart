import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK delayed attack move families', () {
    test('Future Sight damages the targeted position after its countdown', () {
      final engine = PsdkBattleEngine(
        setup: PsdkBattleSetup.singles(
          player: _combatant(
            id: 'player',
            speed: 100,
            moves: <PsdkBattleMoveData>[
              _move(
                id: 'future_sight',
                type: 'psychic',
                category: PsdkBattleMoveCategory.special,
                power: 120,
                accuracy: 100,
                battleEngineMethod: 's_future_sight',
              ),
              _move(id: 'wait'),
            ],
          ),
          opponent: _combatant(
            id: 'opponent',
            speed: 1,
            moves: <PsdkBattleMoveData>[
              _move(id: 'opponent_wait'),
            ],
          ),
          rngSeeds: const PsdkBattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 1,
            generic: 1,
          ),
        ),
      );

      final first = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      expect(_damageEvents(first, moveId: 'future_sight'), isEmpty);
      expect(
        first.state.battlerAt(psdkOpponentSlot).effects.contains(
              'future_sight',
            ),
        isTrue,
      );

      final second = engine.submit(const PsdkBattleDecision.fight(moveSlot: 1));
      expect(_damageEvents(second, moveId: 'future_sight'), isEmpty);
      expect(
        second.state.battlerAt(psdkOpponentSlot).effects.contains(
              'future_sight',
            ),
        isTrue,
      );

      final third = engine.submit(const PsdkBattleDecision.fight(moveSlot: 1));
      final delayedDamage = _damageEvents(third, moveId: 'future_sight');

      expect(delayedDamage, hasLength(1));
      expect(delayedDamage.single.target, psdkOpponentSlot);
      expect(delayedDamage.single.damage, greaterThan(0));
      expect(
        third.state.battlerAt(psdkOpponentSlot).effects.contains(
              'future_sight',
            ),
        isFalse,
      );
    });

    test('Future Sight fails while the targeted position already has one', () {
      final engine = PsdkBattleEngine(
        setup: PsdkBattleSetup.singles(
          player: _combatant(
            id: 'player',
            speed: 100,
            moves: <PsdkBattleMoveData>[
              _move(
                id: 'future_sight',
                type: 'psychic',
                category: PsdkBattleMoveCategory.special,
                power: 120,
                accuracy: 100,
                battleEngineMethod: 's_future_sight',
              ),
            ],
          ),
          opponent: _combatant(
            id: 'opponent',
            speed: 1,
            moves: <PsdkBattleMoveData>[
              _move(id: 'opponent_wait'),
            ],
          ),
          rngSeeds: const PsdkBattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 1,
            generic: 1,
          ),
        ),
      );

      engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final blocked =
          engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));

      final failures = blocked.timeline.events
          .whereType<PsdkBattleMoveFailedEvent>()
          .where((event) => event.moveId == 'future_sight')
          .toList();
      expect(failures, hasLength(1));
      expect(failures.single.reason, 'future_sight_already_active');
    });
  });
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required int speed,
  required List<PsdkBattleMoveData> moves,
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
    moves: moves,
  );
}

PsdkBattleMoveData _move({
  required String id,
  String type = 'normal',
  PsdkBattleMoveCategory category = PsdkBattleMoveCategory.status,
  int power = 0,
  int accuracy = 0,
  String battleEngineMethod = 's_splash',
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: type,
    category: category,
    power: power,
    accuracy: accuracy,
    pp: 10,
    priority: 0,
    criticalRate: 1,
    battleEngineMethod: battleEngineMethod,
    target: category == PsdkBattleMoveCategory.status
        ? PsdkBattleMoveTarget.user
        : PsdkBattleMoveTarget.adjacentFoe,
  );
}

List<PsdkBattleDamageEvent> _damageEvents(
  PsdkBattleTurnResult result, {
  required String moveId,
}) {
  return result.timeline.events
      .whereType<PsdkBattleDamageEvent>()
      .where((event) => event.moveId == moveId)
      .toList();
}
