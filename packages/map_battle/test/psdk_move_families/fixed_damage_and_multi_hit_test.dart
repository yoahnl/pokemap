import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK fixed-damage move families', () {
    test('s_fixed_damage applies the PSDK dbSymbol amount without damage RNG',
        () {
      const seeds = BattleRngSeeds(
        moveDamage: 11,
        moveCritical: 22,
        moveAccuracy: 33,
        generic: 44,
      );
      final engine = BattleEngine(
        setup: _setup(
          playerMove: _move(
            id: 'sonic_boom',
            dbSymbol: 'sonic_boom',
            battleEngineMethod: 's_fixed_damage',
            power: 1,
          ),
          opponentHp: 20,
          rngSeeds: seeds,
        ),
      );

      final result = engine.submit(const BattleDecision.fight(moveSlot: 0));
      final damage = _damageEvents(result, moveId: 'sonic_boom');

      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 0);
      expect(damage, hasLength(1));
      expect(damage.single.damage, 20);
      expect(result.state.rngSeeds.moveDamage, seeds.moveDamage);
      expect(result.state.rngSeeds.moveCritical, seeds.moveCritical);
    });

    test('s_fixed_damage respects the common miss pipeline', () {
      final engine = BattleEngine(
        setup: _setup(
          playerMove: _move(
            id: 'dragon_rage',
            dbSymbol: 'dragon_rage',
            battleEngineMethod: 's_fixed_damage',
            power: 1,
            accuracy: 1,
          ),
          opponentHp: 80,
          rngSeeds: const BattleRngSeeds(
            moveDamage: 1,
            moveCritical: 2,
            moveAccuracy: 99,
            generic: 4,
          ),
        ),
      );

      final result = engine.submit(const BattleDecision.fight(moveSlot: 0));

      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 80);
      expect(_damageEvents(result, moveId: 'dragon_rage'), isEmpty);
      expect(
        result.timeline.events
            .whereType<BattleMoveMissedTimelineEvent>()
            .where((event) => event.moveId == 'dragon_rage'),
        hasLength(1),
      );
    });

    test('s_hp_eq_level deals the user level as damage', () {
      final result = _runPsdkMove(
        playerLevel: 23,
        playerMove: _move(
          id: 'night_shade',
          dbSymbol: 'night_shade',
          battleEngineMethod: 's_hp_eq_level',
          power: 1,
        ),
        opponentHp: 100,
      );

      final damage = _psdkDamageEvents(result, moveId: 'night_shade');
      expect(damage, hasLength(1));
      expect(damage.single.damage, 23);
      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 77);
    });

    test('s_psywave uses PSDK move-damage RNG for 0.5x to 1.5x level damage',
        () {
      final engine = BattleEngine(
        setup: _setup(
          playerLevel: 20,
          playerMove: _move(
            id: 'psywave',
            dbSymbol: 'psywave',
            battleEngineMethod: 's_psywave',
            power: 1,
          ),
          opponentHp: 100,
          rngSeeds: const BattleRngSeeds(
            moveDamage: 99,
            moveCritical: 99999,
            moveAccuracy: 3,
            generic: 4,
          ),
        ),
      );

      final result = engine.submit(const BattleDecision.fight(moveSlot: 0));
      final damage = _damageEvents(result, moveId: 'psywave');

      expect(damage, hasLength(1));
      expect(damage.single.damage, 30);
      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 70);
      expect(result.state.rngSeeds.moveDamage, isNot(99));
      expect(result.state.rngSeeds.moveCritical, 99999);
    });

    test('s_super_fang halves the current target HP with a one HP minimum', () {
      final result = _runPsdkMove(
        playerMove: _move(
          id: 'super_fang',
          dbSymbol: 'super_fang',
          battleEngineMethod: 's_super_fang',
          power: 1,
        ),
        opponentHp: 100,
        opponentCurrentHp: 75,
      );

      final damage = _psdkDamageEvents(result, moveId: 'super_fang');
      expect(damage, hasLength(1));
      expect(damage.single.damage, 37);
      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 38);
    });

    test('fixed-damage moves keep the PSDK post-damage secondary chain', () {
      final result = _runPsdkMove(
        playerMove: _move(
          id: 'dragon_rage',
          dbSymbol: 'dragon_rage',
          battleEngineMethod: 's_fixed_damage',
          power: 1,
          statuses: <PsdkBattleMoveStatus>[
            PsdkBattleMoveStatus(
              status: PsdkBattleMajorStatus.burn,
              chance: 100,
            ),
          ],
          stageMods: const <PsdkBattleMoveStageMod>[
            PsdkBattleMoveStageMod(
              stat: 'defense',
              stages: -1,
              chance: 100,
            ),
          ],
        ),
        opponentHp: 100,
      );

      final events = result.timeline.events
          .map((event) => event.kind)
          .toList(growable: false);

      expect(
        events,
        containsAllInOrder(<String>[
          'damage',
          'status',
          'stat_stage_change',
        ]),
      );
      expect(
        result.state.battlerAt(psdkOpponentSlot).majorStatus,
        PsdkBattleMajorStatus.burn,
      );
      expect(
        result.state.battlerAt(psdkOpponentSlot).statStages.valueOf('defense'),
        -1,
      );
    });
  });

  group('PSDK multi-hit move families', () {
    test('s_2hits and s_3hits emit one damage event per successful hit', () {
      final twoHits = _runPsdkMove(
        playerMove: _move(
          id: 'double_kick',
          dbSymbol: 'double_kick',
          battleEngineMethod: 's_2hits',
          power: 30,
        ),
        opponentHp: 120,
      );
      final threeHits = _runPsdkMove(
        playerMove: _move(
          id: 'triple_hit',
          dbSymbol: 'triple_hit',
          battleEngineMethod: 's_3hits',
          power: 30,
        ),
        opponentHp: 120,
      );

      expect(_psdkDamageEvents(twoHits, moveId: 'double_kick'), hasLength(2));
      expect(_psdkDamageEvents(threeHits, moveId: 'triple_hit'), hasLength(3));
    });

    test('s_multi_hit uses the PSDK 2-5 hit distribution on generic RNG', () {
      final result = _runPsdkMove(
        playerMove: _move(
          id: 'double_slap',
          dbSymbol: 'double_slap',
          battleEngineMethod: 's_multi_hit',
          power: 25,
        ),
        opponentHp: 200,
        rngSeeds: const BattleRngSeeds(
          moveDamage: 1,
          moveCritical: 99999,
          moveAccuracy: 3,
          generic: 5,
        ),
      );

      expect(_psdkDamageEvents(result, moveId: 'double_slap'), hasLength(5));
    });

    test('multi-hit stops before scheduling extra hits once the target faints',
        () {
      final result = _runPsdkMove(
        playerMove: _move(
          id: 'double_kick',
          dbSymbol: 'double_kick',
          battleEngineMethod: 's_2hits',
          power: 200,
        ),
        opponentHp: 12,
      );

      final damage = _psdkDamageEvents(result, moveId: 'double_kick');
      expect(damage, hasLength(1));
      expect(result.outcome?.kind, PsdkBattleOutcomeKind.victory);
    });

    test('multi-hit moves keep the PSDK post-damage secondary chain once', () {
      final result = _runPsdkMove(
        playerMove: _move(
          id: 'double_slap',
          dbSymbol: 'double_slap',
          battleEngineMethod: 's_2hits',
          power: 25,
          statuses: <PsdkBattleMoveStatus>[
            PsdkBattleMoveStatus(
              status: PsdkBattleMajorStatus.paralysis,
              chance: 100,
            ),
          ],
          stageMods: const <PsdkBattleMoveStageMod>[
            PsdkBattleMoveStageMod(
              stat: 'speed',
              stages: -1,
              chance: 100,
            ),
          ],
        ),
        opponentHp: 200,
      );

      final damage = _psdkDamageEvents(result, moveId: 'double_slap');
      final status = result.timeline.events
          .whereType<PsdkBattleStatusEvent>()
          .where((event) => event.moveId == 'double_slap')
          .toList(growable: false);
      final statStages = result.timeline.events
          .whereType<PsdkBattleStatStageEvent>()
          .where((event) => event.stat == 'speed')
          .toList(growable: false);

      expect(damage, hasLength(2));
      expect(status, hasLength(1));
      expect(statStages, hasLength(1));
      expect(
        result.state.battlerAt(psdkOpponentSlot).majorStatus,
        PsdkBattleMajorStatus.paralysis,
      );
      expect(
        result.state.battlerAt(psdkOpponentSlot).statStages.valueOf('speed'),
        -1,
      );
    });

    test('s_triple_kick ramps power on each successful hit', () {
      final result = _runPsdkMove(
        playerMove: _move(
          id: 'triple_kick',
          dbSymbol: 'triple_kick',
          type: 'fire',
          battleEngineMethod: 's_triple_kick',
          power: 10,
        ),
        opponentHp: 100,
      );

      final damage = _psdkDamageEvents(result, moveId: 'triple_kick');
      expect(damage.map((event) => event.damage), <int>[3, 5, 7]);
      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 85);
    });

    test('s_triple_kick stops when a subsequent hit misses', () {
      final result = _runPsdkMove(
        playerMove: _move(
          id: 'triple_kick',
          dbSymbol: 'triple_kick',
          type: 'fire',
          battleEngineMethod: 's_triple_kick',
          power: 10,
          accuracy: 90,
        ),
        opponentHp: 100,
        rngSeeds: const BattleRngSeeds(
          moveDamage: 1,
          moveCritical: 99999,
          moveAccuracy: 3,
          generic: 4,
        ),
      );

      final damage = _psdkDamageEvents(result, moveId: 'triple_kick');
      final misses = result.timeline.events
          .whereType<PsdkBattleMissEvent>()
          .where((event) => event.moveId == 'triple_kick')
          .toList(growable: false);

      expect(damage.map((event) => event.damage), <int>[3]);
      expect(misses, hasLength(1));
      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 97);
    });

    test('s_triple_kick keeps damage from hits before a third-hit miss', () {
      final result = _runPsdkMove(
        playerMove: _move(
          id: 'triple_kick',
          dbSymbol: 'triple_kick',
          type: 'fire',
          battleEngineMethod: 's_triple_kick',
          power: 10,
          accuracy: 90,
        ),
        opponentHp: 100,
        rngSeeds: const BattleRngSeeds(
          moveDamage: 1,
          moveCritical: 99999,
          moveAccuracy: 100,
          generic: 4,
        ),
      );

      final damage = _psdkDamageEvents(result, moveId: 'triple_kick');
      final misses = result.timeline.events
          .whereType<PsdkBattleMissEvent>()
          .where((event) => event.moveId == 'triple_kick')
          .toList(growable: false);

      expect(damage.map((event) => event.damage), <int>[3, 5]);
      expect(misses, hasLength(1));
      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 92);
    });

    test('s_population_bomb can hit ten times with fixed power', () {
      final result = _runPsdkMove(
        playerMove: _move(
          id: 'population_bomb',
          dbSymbol: 'population_bomb',
          type: 'fire',
          battleEngineMethod: 's_population_bomb',
          power: 20,
        ),
        opponentHp: 200,
      );

      final damage = _psdkDamageEvents(result, moveId: 'population_bomb');
      expect(damage, hasLength(10));
      expect(damage.map((event) => event.damage).toSet(), <int>{5});
      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 150);
    });

    test('s_population_bomb stops when a subsequent hit misses', () {
      final result = _runPsdkMove(
        playerMove: _move(
          id: 'population_bomb',
          dbSymbol: 'population_bomb',
          type: 'fire',
          battleEngineMethod: 's_population_bomb',
          power: 20,
          accuracy: 90,
        ),
        opponentHp: 200,
        rngSeeds: const BattleRngSeeds(
          moveDamage: 1,
          moveCritical: 99999,
          moveAccuracy: 3,
          generic: 4,
        ),
      );

      final damage = _psdkDamageEvents(result, moveId: 'population_bomb');
      final misses = result.timeline.events
          .whereType<PsdkBattleMissEvent>()
          .where((event) => event.moveId == 'population_bomb')
          .toList(growable: false);

      expect(damage.map((event) => event.damage), <int>[5]);
      expect(misses, hasLength(1));
      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 195);
    });

    test('s_water_shuriken uses the base PSDK multi-hit distribution for now',
        () {
      final result = _runPsdkMove(
        playerMove: _move(
          id: 'water_shuriken',
          dbSymbol: 'water_shuriken',
          battleEngineMethod: 's_water_shuriken',
          power: 25,
        ),
        opponentHp: 200,
        rngSeeds: const BattleRngSeeds(
          moveDamage: 1,
          moveCritical: 99999,
          moveAccuracy: 3,
          generic: 5,
        ),
      );

      expect(_psdkDamageEvents(result, moveId: 'water_shuriken'), hasLength(5));
    });
  });
}

PsdkBattleTurnResult _runPsdkMove({
  required PsdkBattleMoveData playerMove,
  int playerLevel = 20,
  int opponentHp = 100,
  int? opponentCurrentHp,
  BattleRngSeeds rngSeeds = const BattleRngSeeds(
    moveDamage: 1,
    moveCritical: 99999,
    moveAccuracy: 3,
    generic: 4,
  ),
}) {
  final engine = PsdkBattleEngine(
    setup: _setup(
      playerMove: playerMove,
      playerLevel: playerLevel,
      opponentHp: opponentHp,
      opponentCurrentHp: opponentCurrentHp,
      rngSeeds: rngSeeds,
    ).psdkSetup,
  );
  return engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
}

BattleEngineSetup _setup({
  required PsdkBattleMoveData playerMove,
  int playerLevel = 20,
  int opponentHp = 100,
  int? opponentCurrentHp,
  BattleRngSeeds rngSeeds = const BattleRngSeeds(
    moveDamage: 1,
    moveCritical: 99999,
    moveAccuracy: 3,
    generic: 4,
  ),
}) {
  return BattleEngineSetup.singles(
    player: _combatant(
      id: 'player',
      level: playerLevel,
      maxHp: 100,
      currentHp: 100,
      speed: 100,
      move: playerMove,
    ),
    opponent: _combatant(
      id: 'opponent',
      level: 20,
      maxHp: opponentHp,
      currentHp: opponentCurrentHp ?? opponentHp,
      speed: 1,
      move: _move(
        id: 'opponent_wait',
        dbSymbol: 'opponent_wait',
        power: 0,
      ),
    ),
    rngSeeds: rngSeeds.psdkSeeds,
  );
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required int level,
  required int maxHp,
  required int currentHp,
  required int speed,
  required PsdkBattleMoveData move,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: level,
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
    moves: <PsdkBattleMoveData>[move],
  );
}

PsdkBattleMoveData _move({
  required String id,
  required String dbSymbol,
  String type = 'normal',
  PsdkBattleMoveCategory category = PsdkBattleMoveCategory.physical,
  required int power,
  int accuracy = 100,
  int criticalRate = 0,
  String battleEngineMethod = 's_basic',
  List<PsdkBattleMoveStatus> statuses = const <PsdkBattleMoveStatus>[],
  List<PsdkBattleMoveStageMod> stageMods = const <PsdkBattleMoveStageMod>[],
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: dbSymbol,
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
    statuses: statuses,
    stageMods: stageMods,
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

List<PsdkBattleDamageEvent> _psdkDamageEvents(
  PsdkBattleTurnResult result, {
  required String moveId,
}) {
  return result.timeline.events
      .whereType<PsdkBattleDamageEvent>()
      .where((event) => event.moveId == moveId)
      .toList(growable: false);
}
