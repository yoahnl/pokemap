import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK weight-power move families', () {
    test('s_low_kick keeps PSDK strict target-weight thresholds', () {
      PsdkBattleTurnResult runLowKickAtWeight(double targetWeight) {
        return _runMove(
          playerMove: _move(
            id: 'low_kick',
            battleEngineMethod: 's_low_kick',
            power: 1,
          ),
          opponentWeight: targetWeight,
        );
      }

      // PSDK uses strict `<` limits: exact thresholds already belong to the
      // next stronger bucket.
      expect(_damage(runLowKickAtWeight(9), moveId: 'low_kick'), 5);
      expect(_damage(runLowKickAtWeight(10), moveId: 'low_kick'), 8);
      expect(_damage(runLowKickAtWeight(25), moveId: 'low_kick'), 12);
      expect(_damage(runLowKickAtWeight(50), moveId: 'low_kick'), 15);
      expect(_damage(runLowKickAtWeight(100), moveId: 'low_kick'), 19);
      expect(_damage(runLowKickAtWeight(200), moveId: 'low_kick'), 22);
    });

    test('s_heavy_slam keeps PSDK strict weight-ratio thresholds', () {
      PsdkBattleTurnResult runHeavySlamAtTargetWeight(double targetWeight) {
        return _runMove(
          playerMove: _move(
            id: 'heavy_slam',
            battleEngineMethod: 's_heavy_slam',
            power: 1,
          ),
          playerWeight: 100,
          opponentWeight: targetWeight,
        );
      }

      // PSDK uses strict `>` ratio limits. With user weight 100:
      // 51% => 40 power, 50% => 60, 33% => 80, 25% => 100, 20% => 120.
      expect(_damage(runHeavySlamAtTargetWeight(51), moveId: 'heavy_slam'), 8);
      expect(_damage(runHeavySlamAtTargetWeight(50), moveId: 'heavy_slam'), 12);
      expect(_damage(runHeavySlamAtTargetWeight(33), moveId: 'heavy_slam'), 15);
      expect(_damage(runHeavySlamAtTargetWeight(25), moveId: 'heavy_slam'), 19);
      expect(_damage(runHeavySlamAtTargetWeight(20), moveId: 'heavy_slam'), 22);
    });

    test('weight-power moves keep the post-damage secondary chain', () {
      final result = _runMove(
        playerMove: _move(
          id: 'low_kick',
          battleEngineMethod: 's_low_kick',
          power: 1,
          stageMods: const <PsdkBattleMoveStageMod>[
            PsdkBattleMoveStageMod(
              stat: 'speed',
              stages: -1,
              chance: 100,
            ),
          ],
        ),
        opponentWeight: 100,
      );

      final events = result.timeline.events.map((event) => event.kind).toList();
      expect(
        events,
        containsAllInOrder(<String>[
          'damage',
          'stat_stage_change',
        ]),
      );
      expect(
        result.state.battlerAt(psdkOpponentSlot).statStages.valueOf('speed'),
        -1,
      );
    });

    test('rejects non-positive battler weights before damage math', () {
      expect(
        () => _combatant(
          id: 'invalid',
          weight: 0,
          move: _move(id: 'low_kick', power: 1),
        ),
        throwsArgumentError,
      );
    });
  });
}

PsdkBattleTurnResult _runMove({
  required PsdkBattleMoveData playerMove,
  double playerWeight = 100,
  double opponentWeight = 100,
}) {
  final engine = PsdkBattleEngine(
    setup: PsdkBattleSetup.singles(
      player: _combatant(
        id: 'player',
        weight: playerWeight,
        move: playerMove,
      ),
      opponent: _combatant(
        id: 'opponent',
        weight: opponentWeight,
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
  return engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required double weight,
  required PsdkBattleMoveData move,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: 100,
    currentHp: 100,
    // Keep fixture types away from move types so formula assertions do not
    // measure STAB or type effectiveness by accident.
    types: const PsdkBattleTypes(primary: 'fire'),
    stats: const PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: 50,
    ),
    baseWeightKg: weight,
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
  List<PsdkBattleMoveStageMod> stageMods = const <PsdkBattleMoveStageMod>[],
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
    stageMods: stageMods,
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
