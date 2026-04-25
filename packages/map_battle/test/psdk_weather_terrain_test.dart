import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK weather and terrain handlers', () {
    test('applies clears and blocks weather like PSDK hard weather', () {
      final state = PsdkBattleState.fromSetup(_setup());
      final context = BattleHandlerContext(
        state: state,
        rng: _rng(),
        turn: 1,
        user: psdkPlayerSlot,
      );

      final rain = const BattleWeatherChangeHandler().changeWeather(
        context: context,
        weather: PsdkBattleWeatherId.rain,
      );
      final hardRain = const BattleWeatherChangeHandler().changeWeather(
        context: BattleHandlerContext(
          state: rain.state.copyWith(
            field: rain.state.field.withWeather(PsdkBattleWeatherId.hardrain),
          ),
          rng: rain.rng,
          turn: 1,
          user: psdkPlayerSlot,
        ),
        weather: PsdkBattleWeatherId.sunny,
      );
      final cleared = const BattleWeatherChangeHandler().clearWeather(
        context: BattleHandlerContext(
          state: rain.state,
          rng: rain.rng,
          turn: 1,
          user: psdkPlayerSlot,
        ),
      );

      expect(rain.applied, isTrue);
      expect(rain.state.field.weather?.id, PsdkBattleWeatherId.rain);
      expect(rain.events.single, isA<PsdkBattleWeatherChangedEvent>());
      expect(hardRain.applied, isFalse);
      expect(hardRain.reason, 'hard_weather_active');
      expect(cleared.applied, isTrue);
      expect(cleared.state.field.weather, isNull);
    });

    test('applies clears and refresh-blocks terrain', () {
      final context = BattleHandlerContext(
        state: PsdkBattleState.fromSetup(_setup()),
        rng: _rng(),
        turn: 1,
        user: psdkPlayerSlot,
      );

      final electric = const BattleTerrainChangeHandler().changeTerrain(
        context: context,
        terrain: PsdkBattleTerrainId.electricTerrain,
      );
      final same = const BattleTerrainChangeHandler().changeTerrain(
        context: BattleHandlerContext(
          state: electric.state,
          rng: electric.rng,
          turn: 1,
          user: psdkPlayerSlot,
        ),
        terrain: PsdkBattleTerrainId.electricTerrain,
      );
      final cleared = const BattleTerrainChangeHandler().clearTerrain(
        context: BattleHandlerContext(
          state: electric.state,
          rng: electric.rng,
          turn: 1,
          user: psdkPlayerSlot,
        ),
      );

      expect(electric.state.field.terrain?.remainingTurns, 5);
      expect(electric.events.single, isA<PsdkBattleTerrainChangedEvent>());
      expect(same.applied, isFalse);
      expect(same.reason, 'terrain_already_active');
      expect(cleared.state.field.terrain, isNull);
    });

    test('end turn ticks weather and terrain and emits expiration events', () {
      final state = PsdkBattleState.fromSetup(
        _setup(
          field: const PsdkBattleFieldState(
            weather: PsdkBattleWeatherState(
              id: PsdkBattleWeatherId.rain,
              remainingTurns: 1,
            ),
            terrain: PsdkBattleTerrainState(
              id: PsdkBattleTerrainId.grassyTerrain,
              remainingTurns: 2,
            ),
          ),
        ),
      );

      final result = const BattleEndTurnHandler().resolveEndTurn(
        BattleHandlerContext(
          state: state,
          rng: _rng(),
          turn: 4,
          user: psdkPlayerSlot,
        ),
      );

      expect(result.state.field.weather, isNull);
      expect(result.state.field.terrain?.remainingTurns, 1);
      expect(
        result.events.whereType<PsdkBattleWeatherChangedEvent>().single.reason,
        'expired',
      );
      expect(result.events.whereType<PsdkBattleTerrainChangedEvent>(), isEmpty);
    });
  });

  group('PSDK weather and terrain moves', () {
    test('s_weather applies item-extended weather through the battle engine',
        () {
      final result = _runPlayerMove(
        _move(
          id: 'rain_dance',
          dbSymbol: 'rain_dance',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_weather',
          target: PsdkBattleMoveTarget.none,
        ),
        playerHeldItemId: 'damp_rock',
      );
      final weatherEvents =
          result.timeline.events.whereType<PsdkBattleWeatherChangedEvent>();

      expect(result.state.field.weather?.id, PsdkBattleWeatherId.rain);
      expect(result.state.field.weather?.remainingTurns, 7);
      expect(weatherEvents.single.remainingTurns, 8);
    });

    test('s_terrain applies Terrain Extender duration through the engine', () {
      final result = _runPlayerMove(
        _move(
          id: 'electric_terrain',
          dbSymbol: 'electric_terrain',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_terrain',
          target: PsdkBattleMoveTarget.none,
        ),
        playerHeldItemId: 'terrain_extender',
      );
      final terrainEvents =
          result.timeline.events.whereType<PsdkBattleTerrainChangedEvent>();

      expect(
          result.state.field.terrain?.id, PsdkBattleTerrainId.electricTerrain);
      expect(result.state.field.terrain?.remainingTurns, 7);
      expect(terrainEvents.single.remainingTurns, 8);
    });

    test('s_weather_ball uses active weather for power and type', () {
      final noWeather = _runPlayerMove(
        _move(
          id: 'weather_ball',
          dbSymbol: 'weather_ball',
          type: 'normal',
          category: PsdkBattleMoveCategory.special,
          power: 50,
          battleEngineMethod: 's_weather_ball',
        ),
      );
      final rain = _runPlayerMove(
        _move(
          id: 'weather_ball',
          dbSymbol: 'weather_ball',
          type: 'normal',
          category: PsdkBattleMoveCategory.special,
          power: 50,
          battleEngineMethod: 's_weather_ball',
        ),
        field: const PsdkBattleFieldState(
          weather: PsdkBattleWeatherState(
            id: PsdkBattleWeatherId.rain,
            remainingTurns: 3,
          ),
        ),
      );

      expect(_damage(rain, moveId: 'weather_ball'),
          greaterThan(_damage(noWeather, moveId: 'weather_ball')));
    });
  });
}

int _damage(PsdkBattleTurnResult result, {required String moveId}) {
  return result.timeline.events
      .whereType<PsdkBattleDamageEvent>()
      .singleWhere((event) => event.moveId == moveId)
      .damage;
}

PsdkBattleTurnResult _runPlayerMove(
  PsdkBattleMoveData move, {
  PsdkBattleFieldState field = const PsdkBattleFieldState(),
  String? playerHeldItemId,
}) {
  final engine = PsdkBattleEngine(
    setup: _setup(
      playerMove: move,
      field: field,
      playerHeldItemId: playerHeldItemId,
    ),
  );
  return engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
}

PsdkBattleSetup _setup({
  PsdkBattleFieldState field = const PsdkBattleFieldState(),
  PsdkBattleMoveData? playerMove,
  String? playerHeldItemId,
}) {
  return PsdkBattleSetup.singles(
    player: _combatant(
      id: 'player',
      speed: 100,
      heldItemId: playerHeldItemId,
      move: playerMove ?? _move(id: 'tackle', power: 40),
    ),
    opponent: _combatant(
      id: 'opponent',
      speed: 1,
      types: const PsdkBattleTypes(primary: 'fire'),
      move: _move(
        id: 'splash',
        category: PsdkBattleMoveCategory.status,
        power: 0,
        accuracy: 0,
        battleEngineMethod: 's_splash',
      ),
    ),
    rngSeeds: const PsdkBattleRngSeeds(
      moveDamage: 1,
      moveCritical: 99999,
      moveAccuracy: 3,
      generic: 4,
    ),
    field: field,
  );
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required int speed,
  required PsdkBattleMoveData move,
  PsdkBattleTypes types = const PsdkBattleTypes(primary: 'normal'),
  String? heldItemId,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: 100,
    currentHp: 100,
    types: types,
    stats: PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: speed,
    ),
    moves: <PsdkBattleMoveData>[move],
    heldItemId: heldItemId,
  );
}

PsdkBattleMoveData _move({
  required String id,
  String? dbSymbol,
  String type = 'normal',
  PsdkBattleMoveCategory category = PsdkBattleMoveCategory.physical,
  required int power,
  int accuracy = 100,
  String battleEngineMethod = 's_basic',
  PsdkBattleMoveTarget target = PsdkBattleMoveTarget.adjacentFoe,
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
    criticalRate: 1,
    battleEngineMethod: battleEngineMethod,
    target: target,
  );
}

BattleRngStreams _rng() {
  return BattleRngStreams.fromSeeds(
    moveDamageSeed: 1,
    moveCriticalSeed: 2,
    moveAccuracySeed: 3,
    genericSeed: 4,
  );
}
