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
  });
}

PsdkBattleTurnResult _runMove({
  required PsdkBattleMoveData playerMove,
  PsdkBattleFieldState field = const PsdkBattleFieldState(),
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
