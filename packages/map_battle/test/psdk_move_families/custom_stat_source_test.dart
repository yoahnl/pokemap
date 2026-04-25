import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK custom stat-source move families', () {
    test('s_body_press uses the user Defense as the offensive stat', () {
      final highDefense = _runMove(
        playerMove: _move(
          id: 'body_press',
          battleEngineMethod: 's_body_press',
          power: 80,
        ),
        playerStats: _stats(
          attack: 10,
          defense: 100,
        ),
      );
      final lowDefense = _runMove(
        playerMove: _move(
          id: 'body_press',
          battleEngineMethod: 's_body_press',
          power: 80,
        ),
        playerStats: _stats(
          attack: 100,
          defense: 20,
        ),
      );

      expect(_damage(highDefense, moveId: 'body_press'), 29);
      expect(_damage(lowDefense, moveId: 'body_press'), 6);
    });

    test('s_body_press uses Defense stages and ignores Attack stages', () {
      final neutral = _runMove(
        playerMove: _move(
          id: 'body_press',
          battleEngineMethod: 's_body_press',
          power: 80,
        ),
      );
      final defenseBoost = _runMove(
        playerMove: _move(
          id: 'body_press',
          battleEngineMethod: 's_body_press',
          power: 80,
        ),
        playerStages: PsdkBattleStatStages(values: const <String, int>{
          'dfe': 2,
        }),
      );
      final attackBoost = _runMove(
        playerMove: _move(
          id: 'body_press',
          battleEngineMethod: 's_body_press',
          power: 80,
        ),
        playerStages: PsdkBattleStatStages(values: const <String, int>{
          'atk': 2,
        }),
      );

      expect(_damage(neutral, moveId: 'body_press'), 15);
      expect(_damage(defenseBoost, moveId: 'body_press'), 29);
      expect(_damage(attackBoost, moveId: 'body_press'), 15);
    });

    test('s_foul_play uses the target Attack as the offensive stat', () {
      final strongTarget = _runMove(
        playerMove: _move(
          id: 'foul_play',
          battleEngineMethod: 's_foul_play',
          power: 95,
        ),
        playerStats: _stats(attack: 10),
        opponentStats: _stats(attack: 100),
      );
      final weakTarget = _runMove(
        playerMove: _move(
          id: 'foul_play',
          battleEngineMethod: 's_foul_play',
          power: 95,
        ),
        playerStats: _stats(attack: 200),
        opponentStats: _stats(attack: 20),
      );

      expect(_damage(strongTarget, moveId: 'foul_play'), 34);
      expect(_damage(weakTarget, moveId: 'foul_play'), 7);
    });

    test('s_foul_play uses target Attack stages, not user Attack stages', () {
      final targetBoost = _runMove(
        playerMove: _move(
          id: 'foul_play',
          battleEngineMethod: 's_foul_play',
          power: 95,
        ),
        opponentStages: PsdkBattleStatStages(values: const <String, int>{
          'attack': 2,
        }),
      );
      final userBoost = _runMove(
        playerMove: _move(
          id: 'foul_play',
          battleEngineMethod: 's_foul_play',
          power: 95,
        ),
        playerStages: PsdkBattleStatStages(values: const <String, int>{
          'attack': 2,
        }),
      );

      expect(_damage(targetBoost, moveId: 'foul_play'), 34);
      expect(_damage(userBoost, moveId: 'foul_play'), 18);
    });

    test('s_psyshock uses user Special Attack against target Defense', () {
      final highSpecialDefenseTarget = _runMove(
        playerMove: _move(
          id: 'psyshock',
          battleEngineMethod: 's_psyshock',
          power: 80,
          category: PsdkBattleMoveCategory.special,
        ),
        playerStats: _stats(specialAttack: 100),
        opponentStats: _stats(
          defense: 50,
          specialDefense: 200,
        ),
      );
      final highDefenseTarget = _runMove(
        playerMove: _move(
          id: 'psyshock',
          battleEngineMethod: 's_psyshock',
          power: 80,
          category: PsdkBattleMoveCategory.special,
        ),
        playerStats: _stats(specialAttack: 100),
        opponentStats: _stats(
          defense: 100,
          specialDefense: 50,
        ),
      );

      expect(_damage(highSpecialDefenseTarget, moveId: 'psyshock'), 29);
      expect(_damage(highDefenseTarget, moveId: 'psyshock'), 15);
    });

    test('custom stat-source moves keep PSDK critical stage rules', () {
      final bodyPressCrit = _runMove(
        playerMove: _move(
          id: 'body_press',
          battleEngineMethod: 's_body_press',
          power: 80,
          criticalRate: 4,
        ),
        playerStages: PsdkBattleStatStages(values: const <String, int>{
          'defense': -2,
        }),
      );
      final foulPlayCrit = _runMove(
        playerMove: _move(
          id: 'foul_play',
          battleEngineMethod: 's_foul_play',
          power: 95,
          criticalRate: 4,
        ),
        opponentStages: PsdkBattleStatStages(values: const <String, int>{
          'attack': 2,
        }),
      );
      final psyshockCritWithDrop = _runMove(
        playerMove: _move(
          id: 'psyshock',
          battleEngineMethod: 's_psyshock',
          power: 80,
          category: PsdkBattleMoveCategory.special,
          criticalRate: 4,
        ),
        playerStages: PsdkBattleStatStages(values: const <String, int>{
          'specialAttack': -2,
        }),
      );
      final psyshockCritWithBoost = _runMove(
        playerMove: _move(
          id: 'psyshock',
          battleEngineMethod: 's_psyshock',
          power: 80,
          category: PsdkBattleMoveCategory.special,
          criticalRate: 4,
        ),
        playerStages: PsdkBattleStatStages(values: const <String, int>{
          'specialAttack': 2,
        }),
      );
      final targetDefenseBoostCrit = _runMove(
        playerMove: _move(
          id: 'body_press',
          battleEngineMethod: 's_body_press',
          power: 80,
          criticalRate: 4,
        ),
        opponentStages: PsdkBattleStatStages(values: const <String, int>{
          'defense': 2,
        }),
      );
      final targetDefenseDropCrit = _runMove(
        playerMove: _move(
          id: 'body_press',
          battleEngineMethod: 's_body_press',
          power: 80,
          criticalRate: 4,
        ),
        opponentStages: PsdkBattleStatStages(values: const <String, int>{
          'defense': -2,
        }),
      );

      expect(_damage(bodyPressCrit, moveId: 'body_press'), 23);
      expect(_damage(foulPlayCrit, moveId: 'foul_play'), 26);
      expect(_damage(psyshockCritWithDrop, moveId: 'psyshock'), 23);
      expect(_damage(psyshockCritWithBoost, moveId: 'psyshock'), 44);
      expect(_damage(targetDefenseBoostCrit, moveId: 'body_press'), 23);
      expect(_damage(targetDefenseDropCrit, moveId: 'body_press'), 44);
    });

    test('s_custom_stats_based supports PSDK psyshock and secret_sword aliases',
        () {
      final psyshock = _runMove(
        playerMove: _move(
          id: 'psyshock',
          dbSymbol: 'psyshock',
          battleEngineMethod: 's_custom_stats_based',
          power: 80,
          category: PsdkBattleMoveCategory.special,
        ),
        playerStats: _stats(specialAttack: 100),
      );
      final secretSword = _runMove(
        playerMove: _move(
          id: 'secret_sword',
          dbSymbol: 'secret_sword',
          battleEngineMethod: 's_custom_stats_based',
          power: 80,
          category: PsdkBattleMoveCategory.special,
        ),
        playerStats: _stats(specialAttack: 100),
      );

      expect(_damage(psyshock, moveId: 'psyshock'), 29);
      expect(_damage(secretSword, moveId: 'secret_sword'), 29);
      expect(
        () => _runMove(
          playerMove: _move(
            id: 'unknown_custom',
            dbSymbol: 'unknown_custom',
            battleEngineMethod: 's_custom_stats_based',
            power: 80,
          ),
        ),
        throwsUnsupportedError,
      );
    });

    test('custom stat-source moves keep the post-damage secondary chain', () {
      final result = _runMove(
        playerMove: _move(
          id: 'body_press',
          battleEngineMethod: 's_body_press',
          power: 80,
          stageMods: const <PsdkBattleMoveStageMod>[
            PsdkBattleMoveStageMod(
              stat: 'speed',
              stages: -1,
              chance: 100,
            ),
          ],
        ),
      );

      final events = result.timeline.events.map((event) => event.kind).toList();
      expect(
          events,
          containsAllInOrder(<String>[
            'damage',
            'stat_stage_change',
          ]));
      expect(
        result.state.battlerAt(psdkOpponentSlot).statStages.valueOf('speed'),
        -1,
      );
    });
  });
}

PsdkBattleTurnResult _runMove({
  required PsdkBattleMoveData playerMove,
  PsdkBattleStats? playerStats,
  PsdkBattleStats? opponentStats,
  PsdkBattleStatStages? playerStages,
  PsdkBattleStatStages? opponentStages,
}) {
  final engine = PsdkBattleEngine(
    setup: PsdkBattleSetup.singles(
      player: _combatant(
        id: 'player',
        stats: playerStats ?? _stats(),
        statStages: playerStages,
        move: playerMove,
      ),
      opponent: _combatant(
        id: 'opponent',
        stats: opponentStats ?? _stats(),
        statStages: opponentStages,
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
  required PsdkBattleStats stats,
  required PsdkBattleMoveData move,
  PsdkBattleStatStages? statStages,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: 100,
    currentHp: 100,
    // Keep fixtures away from move types so formula assertions do not measure
    // STAB or type effectiveness by accident.
    types: const PsdkBattleTypes(primary: 'fire'),
    stats: stats,
    statStages: statStages,
    moves: <PsdkBattleMoveData>[move],
  );
}

PsdkBattleStats _stats({
  int attack = 50,
  int defense = 50,
  int specialAttack = 50,
  int specialDefense = 50,
  int speed = 50,
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
  String? dbSymbol,
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
    dbSymbol: dbSymbol ?? id,
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
