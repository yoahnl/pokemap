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

    test('s_fell_stinger raises user Attack by three after a KO', () {
      final result = _runMove(
        playerMove: _move(
          id: 'fell_stinger',
          type: 'bug',
          battleEngineMethod: 's_fell_stinger',
          power: 200,
        ),
        opponentTypes: const PsdkBattleTypes(primary: 'grass'),
        opponentCurrentHp: 20,
      );

      expect(_damageEvents(result, moveId: 'fell_stinger'), hasLength(1));
      expect(result.state.battlerAt(psdkOpponentSlot).isFainted, isTrue);
      expect(
          result.state.battlerAt(psdkPlayerSlot).statStages.valueOf('attack'),
          3);
      expect(
        result.timeline.events
            .where((event) => event.kind == 'stat_stage_change')
            .map((event) => event.toJson()['stat']),
        contains('attack'),
      );
    });

    test('s_fell_stinger does not raise Attack when the target survives', () {
      final result = _runMove(
        playerMove: _move(
          id: 'fell_stinger',
          type: 'bug',
          battleEngineMethod: 's_fell_stinger',
          power: 20,
        ),
        opponentTypes: const PsdkBattleTypes(primary: 'grass'),
      );

      expect(_damageEvents(result, moveId: 'fell_stinger'), hasLength(1));
      expect(result.state.battlerAt(psdkOpponentSlot).isFainted, isFalse);
      expect(
          result.state.battlerAt(psdkPlayerSlot).statStages.valueOf('attack'),
          0);
      expect(
        result.timeline.events.where(
          (event) => event.kind == 'stat_stage_change',
        ),
        isEmpty,
      );
    });

    test('s_stomp doubles power against a minimized target', () {
      final normal = _runMove(
        playerMove: _move(
          id: 'stomp',
          battleEngineMethod: 's_stomp',
          power: 65,
        ),
      );
      final minimized = _runMove(
        opponentEffects: PsdkBattleEffectStack(
          values: const <String>['minimize'],
        ),
        playerMove: _move(
          id: 'stomp',
          battleEngineMethod: 's_stomp',
          power: 65,
        ),
      );

      expect(
        _damage(minimized, moveId: 'stomp'),
        greaterThan(_damage(normal, moveId: 'stomp')),
      );
    });

    test('s_stomp bypasses accuracy against a minimized target', () {
      final result = _runMove(
        opponentEffects: PsdkBattleEffectStack(
          values: const <String>['minimize'],
        ),
        playerMove: _move(
          id: 'stomp',
          battleEngineMethod: 's_stomp',
          power: 65,
          accuracy: 1,
        ),
      );

      expect(_damageEvents(result, moveId: 'stomp'), hasLength(1));
      expect(
        result.timeline.events.map((event) => event.kind),
        isNot(contains('move_missed')),
      );
    });

    test('s_grav_apple gains power under Gravity and keeps Defense drop', () {
      BattleEngineTurnResult run({PsdkBattleEffectStack? playerEffects}) {
        return _runMove(
          playerEffects: playerEffects,
          playerMove: _move(
            id: 'grav_apple',
            type: 'grass',
            battleEngineMethod: 's_grav_apple',
            power: 80,
            stageMods: const <PsdkBattleMoveStageMod>[
              PsdkBattleMoveStageMod(
                stat: 'defense',
                stages: -1,
                chance: 100,
              ),
            ],
          ),
        );
      }

      final normal = run();
      final gravity = run(
        playerEffects: PsdkBattleEffectStack(
          values: const <String>['gravity'],
        ),
      );

      expect(
        _damage(gravity, moveId: 'grav_apple'),
        greaterThan(_damage(normal, moveId: 'grav_apple')),
      );
      expect(
        gravity.state.battlerAt(psdkOpponentSlot).statStages.valueOf('defense'),
        -1,
      );
    });

    test('s_jump_kick crashes the user for half max HP when it misses', () {
      final result = _runMove(
        playerMove: _move(
          id: 'high_jump_kick',
          type: 'fighting',
          battleEngineMethod: 's_jump_kick',
          power: 130,
          accuracy: 1,
        ),
      );

      final damage = _damageEvents(result, moveId: 'high_jump_kick');
      expect(damage, hasLength(1));
      expect(
        damage.single.target,
        const BattlePositionRef(bank: 0, position: 0),
      );
      expect(damage.single.damage, 50);
      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 50);
    });

    test('s_jump_kick crashes the user for half max HP on target immunity', () {
      final result = _runMove(
        opponentTypes: const PsdkBattleTypes(primary: 'ghost'),
        playerMove: _move(
          id: 'high_jump_kick',
          type: 'fighting',
          battleEngineMethod: 's_jump_kick',
          power: 130,
        ),
      );

      final damage = _damageEvents(result, moveId: 'high_jump_kick');
      expect(damage, hasLength(1));
      expect(
        damage.single.target,
        const BattlePositionRef(bank: 0, position: 0),
      );
      expect(damage.single.damage, 50);
      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 50);
    });

    test('s_poltergeist fails before damage when the target has no held item',
        () {
      final result = _runMove(
        playerMove: _move(
          id: 'poltergeist',
          type: 'ghost',
          battleEngineMethod: 's_poltergeist',
          power: 110,
        ),
      );

      final failures =
          result.timeline.events.whereType<BattleMoveFailedTimelineEvent>();
      expect(failures, hasLength(1));
      expect(failures.single.reason, 'no_held_item');
      expect(_damageEvents(result, moveId: 'poltergeist'), isEmpty);
      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 100);
    });

    test('s_poltergeist damages normally when the target has a held item', () {
      final result = _runMove(
        opponentHeldItemId: 'oran_berry',
        playerMove: _move(
          id: 'poltergeist',
          type: 'ghost',
          battleEngineMethod: 's_poltergeist',
          power: 110,
        ),
      );

      expect(_damageEvents(result, moveId: 'poltergeist'), hasLength(1));
      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, lessThan(100));
    });

    test('s_freezy_frost damages then resets alive battler stat stages', () {
      final result = _runMove(
        playerStatStages: PsdkBattleStatStages(
          values: const <String, int>{
            'attack': 2,
            'speed': -1,
          },
        ),
        opponentStatStages: PsdkBattleStatStages(
          values: const <String, int>{
            'defense': -2,
            'specialAttack': 3,
          },
        ),
        playerMove: _move(
          id: 'freezy_frost',
          type: 'ice',
          battleEngineMethod: 's_freezy_frost',
          power: 100,
        ),
      );

      final player = result.state.battlerAt(psdkPlayerSlot);
      final opponent = result.state.battlerAt(psdkOpponentSlot);

      expect(_damageEvents(result, moveId: 'freezy_frost'), hasLength(1));
      expect(player.statStages.values, isEmpty);
      expect(opponent.statStages.values, isEmpty);
    });

    test('s_freezy_frost does not reset stat stages when it misses', () {
      final result = _runMove(
        playerStatStages: PsdkBattleStatStages(
          values: const <String, int>{'attack': 2},
        ),
        opponentStatStages: PsdkBattleStatStages(
          values: const <String, int>{'defense': -2},
        ),
        playerMove: _move(
          id: 'freezy_frost',
          type: 'ice',
          battleEngineMethod: 's_freezy_frost',
          power: 100,
          accuracy: 1,
        ),
      );

      final player = result.state.battlerAt(psdkPlayerSlot);
      final opponent = result.state.battlerAt(psdkOpponentSlot);

      expect(_damageEvents(result, moveId: 'freezy_frost'), isEmpty);
      expect(player.statStages.valueOf('attack'), 2);
      expect(opponent.statStages.valueOf('defense'), -2);
    });
  });
}

BattleEngineTurnResult _runMove({
  required PsdkBattleMoveData playerMove,
  PsdkBattleEffectStack? playerEffects,
  int opponentCurrentHp = 100,
  PsdkBattleTypes opponentTypes = const PsdkBattleTypes(primary: 'fire'),
  PsdkBattleEffectStack? opponentEffects,
  String? opponentHeldItemId,
  PsdkBattleStatStages? playerStatStages,
  PsdkBattleStatStages? opponentStatStages,
}) {
  final engine = BattleEngine(
    setup: BattleEngineSetup.singles(
      player: _combatant(
        id: 'player',
        currentHp: 100,
        speed: 100,
        move: playerMove,
        effects: playerEffects,
        statStages: playerStatStages,
      ),
      opponent: _combatant(
        id: 'opponent',
        currentHp: opponentCurrentHp,
        speed: 1,
        types: opponentTypes,
        effects: opponentEffects,
        heldItemId: opponentHeldItemId,
        statStages: opponentStatStages,
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
  PsdkBattleEffectStack? effects,
  String? heldItemId,
  PsdkBattleStatStages? statStages,
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
    effects: effects,
    heldItemId: heldItemId,
    statStages: statStages,
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
