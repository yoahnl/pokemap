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

    test('s_absorb applies Big Root to the drained heal amount', () {
      final result = _runMove(
        playerCurrentHp: 10,
        playerHeldItemId: 'big_root',
        playerMove: _move(
          id: 'absorb',
          battleEngineMethod: 's_absorb',
          power: 80,
          type: 'grass',
          category: PsdkBattleMoveCategory.special,
        ),
      );
      final damage = _damage(result, moveId: 'absorb');
      final expectedHeal = (damage * 1.3 / 2).floor();

      expect(
          result.state.battlerAt(psdkPlayerSlot).currentHp, 10 + expectedHeal);
      expect(_healJson(result, moveId: 'absorb')['amount'], expectedHeal);
    });

    test('s_absorb turns healing into user damage against Liquid Ooze', () {
      final result = _runMove(
        playerCurrentHp: 60,
        opponentAbilityId: 'liquid_ooze',
        playerMove: _move(
          id: 'absorb',
          battleEngineMethod: 's_absorb',
          power: 80,
          type: 'grass',
          category: PsdkBattleMoveCategory.special,
        ),
      );
      final damageEvents = _damageEvents(result, moveId: 'absorb');
      expect(damageEvents, hasLength(2));

      final targetDamage = damageEvents[0].damage;
      final liquidOozeDamage = targetDamage ~/ 2;

      expect(_healEvents(result, moveId: 'absorb'), isEmpty);
      expect(damageEvents[0].target, psdkOpponentSlot);
      expect(damageEvents[1].target, psdkPlayerSlot);
      expect(damageEvents[1].damage, liquidOozeDamage);
      expect(
        result.state.battlerAt(psdkPlayerSlot).currentHp,
        60 - liquidOozeDamage,
      );
    });

    test('s_absorb damages but does not heal a Heal Blocked user', () {
      final result = _runMove(
        playerCurrentHp: 60,
        playerEffects: PsdkBattleEffectStack(
          values: const <String>['heal_block'],
        ),
        playerMove: _move(
          id: 'absorb',
          battleEngineMethod: 's_absorb',
          power: 80,
          type: 'grass',
          category: PsdkBattleMoveCategory.special,
        ),
      );

      expect(_damageEvents(result, moveId: 'absorb'), hasLength(1));
      expect(_healEvents(result, moveId: 'absorb'), isEmpty);
      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 60);
    });

    test('s_absorb drains from each spread target independently', () {
      final result = const PsdkBattleMoveExecutor().execute(
        PsdkBattleMoveRequest(
          state: _doublesState(userCurrentHp: 1),
          rng: BattleRngStreams.fromSeeds(
            moveDamageSeed: 1,
            moveCriticalSeed: 99999,
            moveAccuracySeed: 3,
            genericSeed: 4,
          ),
          turn: 1,
          user: psdkPlayerSlot,
          target: psdkOpponentSlot,
          moveId: 'parabolic_charge',
          battleEngineMethod: 's_absorb',
          studioMove: _move(
            id: 'parabolic_charge',
            type: 'electric',
            category: PsdkBattleMoveCategory.special,
            power: 65,
            battleEngineMethod: 's_absorb',
            target: PsdkBattleMoveTarget.allAdjacent,
          ),
        ),
      );

      final damageEvents = _resolutionDamageEvents(
        result,
        moveId: 'parabolic_charge',
      );
      final healEvents = _resolutionHealEvents(
        result,
        moveId: 'parabolic_charge',
      );

      expect(damageEvents.map((event) => event.target), <PsdkBattleSlotRef>[
        _psdkPlayerRightSlot,
        psdkOpponentSlot,
        _psdkOpponentRightSlot,
      ]);
      expect(healEvents, hasLength(damageEvents.length));
      for (var i = 0; i < damageEvents.length; i += 1) {
        expect(healEvents[i].amount, damageEvents[i].damage ~/ 2);
        expect(healEvents[i].target, psdkPlayerSlot);
      }
      final totalHeal = healEvents.fold<int>(
        0,
        (sum, event) => sum + event.amount,
      );
      expect(
        result.state.battlerAt(psdkPlayerSlot).currentHp,
        1 + totalHeal,
      );
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

      final awakeKinds = awake.timeline.events
          .where((event) => event.toJson()['moveId'] == 'dream_eater')
          .map((event) => event.kind)
          .toList(growable: false);
      expect(_damageEvents(awake, moveId: 'dream_eater'), isEmpty);
      expect(awakeKinds, contains('move_immune'));
      expect(awakeKinds, isNot(contains('animation_cue')));
      expect(awakeKinds, isNot(contains('damage')));
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

    test('s_heal Heal Pulse heals an adjacent target', () {
      final result = _runMove(
        opponentCurrentHp: 10,
        playerMove: _move(
          id: 'heal_pulse',
          battleEngineMethod: 's_heal',
          power: 0,
          category: PsdkBattleMoveCategory.status,
          target: PsdkBattleMoveTarget.anyFoe,
          pulse: true,
        ),
      );
      final heal = _healJson(result, moveId: 'heal_pulse');

      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 60);
      expect(heal['amount'], 50);
      expect(heal['target'], psdkOpponentSlot.toJson());
    });

    test('s_heal Heal Pulse gets Mega Launcher healing boost', () {
      final result = _runMove(
        playerAbilityId: 'mega_launcher',
        opponentCurrentHp: 1,
        playerMove: _move(
          id: 'heal_pulse',
          battleEngineMethod: 's_heal',
          power: 0,
          category: PsdkBattleMoveCategory.status,
          target: PsdkBattleMoveTarget.anyFoe,
          pulse: true,
        ),
      );
      final heal = _healJson(result, moveId: 'heal_pulse');

      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 76);
      expect(heal['amount'], 75);
    });

    test('s_heal Heal Pulse is blocked by target Substitute', () {
      final result = _runMove(
        opponentCurrentHp: 10,
        opponentEffects: PsdkBattleEffectStack(
          values: const <String>['substitute'],
        ),
        playerMove: _move(
          id: 'heal_pulse',
          battleEngineMethod: 's_heal',
          power: 0,
          category: PsdkBattleMoveCategory.status,
          target: PsdkBattleMoveTarget.anyFoe,
          pulse: true,
        ),
      );

      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 10);
      expect(_healEvents(result, moveId: 'heal_pulse'), isEmpty);
      expect(
        _moveJsonEvents(result, moveId: 'heal_pulse')
            .map((event) => event['kind']),
        contains('move_immune'),
      );
    });

    test('s_heal fails before PP spending when the target is already full HP',
        () {
      final result = _runMove(
        playerMove: _move(
          id: 'recover',
          battleEngineMethod: 's_heal',
          power: 0,
          category: PsdkBattleMoveCategory.status,
          target: PsdkBattleMoveTarget.user,
        ),
      );
      final player = result.state.battlerAt(psdkPlayerSlot);
      final recoverEvents = _moveJsonEvents(result, moveId: 'recover');

      expect(player.currentHp, 100);
      expect(player.moves.single.currentPp, 35);
      expect(_healEvents(result, moveId: 'recover'), isEmpty);
      expect(recoverEvents.map((event) => event['kind']), <String>[
        'move_failed',
      ]);
      expect(recoverEvents.single['reason'], 'unusable_by_user');
    });

    test('s_heal_weather changes the heal ratio from active weather', () {
      PsdkBattleTurnResult run(PsdkBattleFieldState field) {
        return _runMove(
          field: field,
          playerCurrentHp: 10,
          playerMove: _move(
            id: 'moonlight',
            battleEngineMethod: 's_heal_weather',
            power: 0,
            category: PsdkBattleMoveCategory.status,
            target: PsdkBattleMoveTarget.user,
          ),
        );
      }

      final noWeather = run(const PsdkBattleFieldState());
      final sunny = run(
        const PsdkBattleFieldState(
          weather: PsdkBattleWeatherState(
            id: PsdkBattleWeatherId.sunny,
            remainingTurns: 5,
          ),
        ),
      );
      final rain = run(
        const PsdkBattleFieldState(
          weather: PsdkBattleWeatherState(
            id: PsdkBattleWeatherId.rain,
            remainingTurns: 5,
          ),
        ),
      );
      final strongWinds = run(
        const PsdkBattleFieldState(
          weather: PsdkBattleWeatherState(
            id: PsdkBattleWeatherId.strongWinds,
            remainingTurns: 5,
          ),
        ),
      );

      expect(_healJson(noWeather, moveId: 'moonlight')['amount'], 50);
      expect(_healJson(sunny, moveId: 'moonlight')['amount'], 66);
      expect(_healJson(rain, moveId: 'moonlight')['amount'], 25);
      expect(_healJson(strongWinds, moveId: 'moonlight')['amount'], 50);
    });

    test('s_floral_healing heals more on Grassy Terrain', () {
      final noTerrain = _runMove(
        playerCurrentHp: 10,
        playerMove: _move(
          id: 'floral_healing',
          battleEngineMethod: 's_floral_healing',
          power: 0,
          category: PsdkBattleMoveCategory.status,
          target: PsdkBattleMoveTarget.user,
        ),
      );
      final grassyTerrain = _runMove(
        field: const PsdkBattleFieldState(
          terrain: PsdkBattleTerrainState(
            id: PsdkBattleTerrainId.grassyTerrain,
            remainingTurns: 5,
          ),
        ),
        playerCurrentHp: 10,
        playerMove: _move(
          id: 'floral_healing',
          battleEngineMethod: 's_floral_healing',
          power: 0,
          category: PsdkBattleMoveCategory.status,
          target: PsdkBattleMoveTarget.user,
        ),
      );

      expect(_healJson(noTerrain, moveId: 'floral_healing')['amount'], 50);
      expect(_healJson(grassyTerrain, moveId: 'floral_healing')['amount'], 66);
    });

    test('s_roost heals half max HP while the Roost effect is pending', () {
      final result = _runMove(
        playerCurrentHp: 10,
        playerMove: _move(
          id: 'roost',
          battleEngineMethod: 's_roost',
          power: 0,
          category: PsdkBattleMoveCategory.status,
          target: PsdkBattleMoveTarget.user,
        ),
      );

      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 60);
      expect(_healJson(result, moveId: 'roost')['amount'], 50);
    });

    test('s_shore_up heals more in a sandstorm', () {
      final noWeather = _runMove(
        playerCurrentHp: 10,
        playerMove: _move(
          id: 'shore_up',
          battleEngineMethod: 's_shore_up',
          power: 0,
          category: PsdkBattleMoveCategory.status,
          target: PsdkBattleMoveTarget.user,
        ),
      );
      final sandstorm = _runMove(
        field: const PsdkBattleFieldState(
          weather: PsdkBattleWeatherState(
            id: PsdkBattleWeatherId.sandstorm,
            remainingTurns: 5,
          ),
        ),
        playerCurrentHp: 10,
        playerMove: _move(
          id: 'shore_up',
          battleEngineMethod: 's_shore_up',
          power: 0,
          category: PsdkBattleMoveCategory.status,
          target: PsdkBattleMoveTarget.user,
        ),
      );

      expect(_healJson(noWeather, moveId: 'shore_up')['amount'], 50);
      expect(_healJson(sandstorm, moveId: 'shore_up')['amount'], 66);
    });

    test('s_life_dew and s_jungle_healing heal one quarter max HP', () {
      final lifeDew = _runMove(
        playerCurrentHp: 10,
        playerMove: _move(
          id: 'life_dew',
          battleEngineMethod: 's_life_dew',
          power: 0,
          category: PsdkBattleMoveCategory.status,
          target: PsdkBattleMoveTarget.user,
        ),
      );
      final jungleHealing = _runMove(
        playerCurrentHp: 10,
        playerMove: _move(
          id: 'jungle_healing',
          battleEngineMethod: 's_jungle_healing',
          power: 0,
          category: PsdkBattleMoveCategory.status,
          target: PsdkBattleMoveTarget.user,
        ),
      );

      expect(_healJson(lifeDew, moveId: 'life_dew')['amount'], 25);
      expect(
        _healJson(jungleHealing, moveId: 'jungle_healing')['amount'],
        25,
      );
    });

    test('s_jungle_healing cures the healed target major status', () {
      final result = _runMove(
        playerCurrentHp: 10,
        playerMajorStatus: PsdkBattleMajorStatus.burn,
        playerMove: _move(
          id: 'jungle_healing',
          battleEngineMethod: 's_jungle_healing',
          power: 0,
          category: PsdkBattleMoveCategory.status,
          target: PsdkBattleMoveTarget.user,
        ),
      );

      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 35);
      expect(result.state.battlerAt(psdkPlayerSlot).majorStatus, isNull);
      expect(
        result.timeline.events.map((event) => event.kind),
        containsAllInOrder(<String>[
          'heal',
          'status_cure',
        ]),
      );
    });
  });
}

PsdkBattleTurnResult _runMove({
  required PsdkBattleMoveData playerMove,
  PsdkBattleFieldState field = const PsdkBattleFieldState(),
  int playerCurrentHp = 100,
  String? playerHeldItemId,
  String? playerAbilityId,
  bool playerItemConsumed = false,
  PsdkBattleStatStages? playerStatStages,
  PsdkBattleEffectStack? playerEffects,
  PsdkBattleMajorStatus? playerMajorStatus,
  int opponentCurrentHp = 100,
  PsdkBattleMajorStatus? opponentMajorStatus,
  PsdkBattleEffectStack? opponentEffects,
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
        effects: playerEffects,
        majorStatus: playerMajorStatus,
        abilityId: playerAbilityId,
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
        effects: opponentEffects,
        abilityId: opponentAbilityId,
      ),
      rngSeeds: const PsdkBattleRngSeeds(
        moveDamage: 1,
        moveCritical: 99999,
        moveAccuracy: 3,
        generic: 4,
      ),
      field: field,
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
  PsdkBattleEffectStack? effects,
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
    effects: effects,
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
  bool pulse = false,
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
    pulse: pulse,
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
  return _healEvents(result, moveId: moveId)
      .map((event) => event.toJson())
      .single;
}

List<PsdkBattleHealEvent> _healEvents(
  PsdkBattleTurnResult result, {
  required String moveId,
}) {
  return result.timeline.events
      .where((event) => event.kind == 'heal')
      .whereType<PsdkBattleHealEvent>()
      .where((event) => event.moveId == moveId)
      .toList(growable: false);
}

List<PsdkBattleDamageEvent> _resolutionDamageEvents(
  BattleMoveBehaviorResolution result, {
  required String moveId,
}) {
  return result.events
      .whereType<PsdkBattleDamageEvent>()
      .where((event) => event.moveId == moveId)
      .toList(growable: false);
}

List<PsdkBattleHealEvent> _resolutionHealEvents(
  BattleMoveBehaviorResolution result, {
  required String moveId,
}) {
  return result.events
      .whereType<PsdkBattleHealEvent>()
      .where((event) => event.moveId == moveId)
      .toList(growable: false);
}

List<Map<String, Object?>> _moveJsonEvents(
  PsdkBattleTurnResult result, {
  required String moveId,
}) {
  return result.timeline.events
      .map((event) => event.toJson())
      .where((event) => event['moveId'] == moveId)
      .toList(growable: false);
}

const _psdkPlayerRightSlot = PsdkBattleSlotRef(bank: 0, position: 1);
const _psdkOpponentRightSlot = PsdkBattleSlotRef(bank: 1, position: 1);

PsdkBattleState _doublesState({
  required int userCurrentHp,
}) {
  return PsdkBattleState(
    combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
      psdkPlayerSlot: PsdkBattleCombatant.fromSetup(
        _combatant(
          id: 'player',
          currentHp: userCurrentHp,
          move: _move(
            id: 'parabolic_charge',
            battleEngineMethod: 's_absorb',
            power: 65,
            type: 'electric',
            category: PsdkBattleMoveCategory.special,
            target: PsdkBattleMoveTarget.allAdjacent,
          ),
        ),
      ),
      _psdkPlayerRightSlot: PsdkBattleCombatant.fromSetup(
        _combatant(
          id: 'player_ally',
          currentHp: 100,
          move: _move(id: 'player_ally_wait', power: 0, accuracy: 1),
        ),
      ),
      psdkOpponentSlot: PsdkBattleCombatant.fromSetup(
        _combatant(
          id: 'opponent',
          currentHp: 100,
          move: _move(id: 'opponent_wait', power: 0, accuracy: 1),
        ),
      ),
      _psdkOpponentRightSlot: PsdkBattleCombatant.fromSetup(
        _combatant(
          id: 'opponent_ally',
          currentHp: 100,
          move: _move(id: 'opponent_ally_wait', power: 0, accuracy: 1),
        ),
      ),
    },
  );
}
