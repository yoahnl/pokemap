import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK Substitute and Focus Punch families', () {
    test('Substitute absorbs opposing damage before the user HP is touched',
        () {
      final engine = PsdkBattleEngine(
        setup: PsdkBattleSetup.singles(
          player: _combatant(
            id: 'player',
            speed: 100,
            moves: <PsdkBattleMoveData>[
              _move(
                id: 'substitute',
                battleEngineMethod: 's_substitute',
                target: PsdkBattleMoveTarget.user,
                category: PsdkBattleMoveCategory.status,
                power: 0,
                accuracy: 0,
              ),
              _move(
                id: 'splash',
                battleEngineMethod: 's_splash',
                target: PsdkBattleMoveTarget.none,
                category: PsdkBattleMoveCategory.status,
                power: 0,
                accuracy: 0,
              ),
            ],
          ),
          opponent: _combatant(
            id: 'opponent',
            speed: 1,
            moves: <PsdkBattleMoveData>[
              _move(
                id: 'heavy_slam',
                battleEngineMethod: 's_basic',
                target: PsdkBattleMoveTarget.adjacentFoe,
                category: PsdkBattleMoveCategory.physical,
                power: 200,
                accuracy: 100,
              ),
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

      final afterSubstitute = engine.submit(
        const PsdkBattleDecision.fight(moveSlot: 0),
      );
      final player = afterSubstitute.state.battlerAt(psdkPlayerSlot);

      expect(player.currentHp, 75);
      expect(player.effects.contains('substitute'), isFalse);
      expect(
        _damage(afterSubstitute, moveId: 'heavy_slam'),
        greaterThanOrEqualTo(25),
      );
    });

    test('Substitute fails when the user max HP is below the PSDK cost floor',
        () {
      final engine = PsdkBattleEngine(
        setup: PsdkBattleSetup.singles(
          player: _combatant(
            id: 'player',
            speed: 100,
            maxHp: 3,
            currentHp: 3,
            moves: <PsdkBattleMoveData>[
              _move(
                id: 'substitute',
                battleEngineMethod: 's_substitute',
                target: PsdkBattleMoveTarget.user,
                category: PsdkBattleMoveCategory.status,
                power: 0,
                accuracy: 0,
              ),
            ],
          ),
          opponent: _combatant(
            id: 'opponent',
            speed: 1,
            moves: <PsdkBattleMoveData>[
              _move(
                id: 'splash',
                battleEngineMethod: 's_splash',
                target: PsdkBattleMoveTarget.none,
                category: PsdkBattleMoveCategory.status,
                power: 0,
                accuracy: 0,
              ),
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

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final player = result.state.battlerAt(psdkPlayerSlot);

      expect(player.currentHp, 3);
      expect(player.effects.contains('substitute'), isFalse);
      expect(_failed(result, moveId: 'substitute'), isTrue);
    });
  });
}

int _damage(PsdkBattleTurnResult result, {required String moveId}) {
  return result.timeline.events
      .whereType<PsdkBattleDamageEvent>()
      .singleWhere((event) => event.moveId == moveId)
      .damage;
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required int speed,
  required List<PsdkBattleMoveData> moves,
  int maxHp = 100,
  int currentHp = 100,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: maxHp,
    currentHp: currentHp,
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

bool _failed(PsdkBattleTurnResult result, {required String moveId}) {
  return result.timeline.events
      .whereType<PsdkBattleMoveFailedEvent>()
      .any((event) => event.moveId == moveId);
}

PsdkBattleMoveData _move({
  required String id,
  required String battleEngineMethod,
  required PsdkBattleMoveTarget target,
  required PsdkBattleMoveCategory category,
  required int power,
  required int accuracy,
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: 'normal',
    category: category,
    power: power,
    accuracy: accuracy,
    pp: 35,
    priority: 0,
    criticalRate: 1,
    battleEngineMethod: battleEngineMethod,
    target: target,
  );
}
