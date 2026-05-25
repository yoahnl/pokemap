import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK weather-conditional move families', () {
    for (final entry in <({
      String moveId,
      String type,
      PsdkBattleWeatherId weather,
    })>[
      (moveId: 'rain_dance', type: 'water', weather: PsdkBattleWeatherId.rain),
      (moveId: 'sunny_day', type: 'fire', weather: PsdkBattleWeatherId.sunny),
      (
        moveId: 'sandstorm',
        type: 'rock',
        weather: PsdkBattleWeatherId.sandstorm,
      ),
      (moveId: 'hail', type: 'ice', weather: PsdkBattleWeatherId.hail),
    ]) {
      test('s_weather applies ${entry.moveId} for five turns', () {
        final result = _runMove(
          field: const PsdkBattleFieldState(),
          playerMove: _move(
            id: entry.moveId,
            type: entry.type,
            category: PsdkBattleMoveCategory.status,
            power: 0,
            accuracy: 0,
            battleEngineMethod: 's_weather',
            target: PsdkBattleMoveTarget.none,
          ),
        );

        expect(result.state.field.weather?.id, entry.weather);
        expect(result.state.field.weather?.remainingTurns, 4);
        expect(
          result.timeline.events.whereType<PsdkBattleWeatherChangedEvent>(),
          hasLength(1),
        );
      });
    }

    for (final entry in <({String method, String moveId, String type})>[
      (method: 's_thunder', moveId: 'thunder', type: 'electric'),
      (method: 's_hurricane', moveId: 'hurricane', type: 'flying'),
    ]) {
      test('${entry.method} bypasses accuracy under rain', () {
        final result = _runMove(
          field: _weather(PsdkBattleWeatherId.rain),
          moveAccuracySeed: 99,
          playerMove: _move(
            id: entry.moveId,
            type: entry.type,
            category: PsdkBattleMoveCategory.special,
            power: 110,
            accuracy: 1,
            battleEngineMethod: entry.method,
          ),
        );

        expect(_missEvents(result, moveId: entry.moveId), isEmpty);
        expect(_damageEvents(result, moveId: entry.moveId), hasLength(1));
      });

      test('${entry.method} uses 50 accuracy under sun', () {
        final result = _runMove(
          field: _weather(PsdkBattleWeatherId.sunny),
          moveAccuracySeed: 74,
          playerMove: _move(
            id: entry.moveId,
            type: entry.type,
            category: PsdkBattleMoveCategory.special,
            power: 110,
            accuracy: 100,
            battleEngineMethod: entry.method,
          ),
        );

        expect(_missEvents(result, moveId: entry.moveId), hasLength(1));
        expect(_damageEvents(result, moveId: entry.moveId), isEmpty);
      });
    }

    test('s_genies_storm bypasses accuracy under rain only', () {
      final rain = _runMove(
        field: _weather(PsdkBattleWeatherId.rain),
        moveAccuracySeed: 99,
        playerMove: _move(
          id: 'bleakwind_storm',
          type: 'flying',
          category: PsdkBattleMoveCategory.special,
          power: 100,
          accuracy: 1,
          battleEngineMethod: 's_genies_storm',
        ),
      );
      final clear = _runMove(
        field: const PsdkBattleFieldState(),
        moveAccuracySeed: 99,
        playerMove: _move(
          id: 'bleakwind_storm',
          type: 'flying',
          category: PsdkBattleMoveCategory.special,
          power: 100,
          accuracy: 1,
          battleEngineMethod: 's_genies_storm',
        ),
      );

      expect(_missEvents(rain, moveId: 'bleakwind_storm'), isEmpty);
      expect(_damageEvents(rain, moveId: 'bleakwind_storm'), hasLength(1));
      expect(_missEvents(clear, moveId: 'bleakwind_storm'), hasLength(1));
      expect(_damageEvents(clear, moveId: 'bleakwind_storm'), isEmpty);
    });

    test('s_weather_ball doubles power and changes type under each weather',
        () {
      final noWeather = _weatherBallDamage(const PsdkBattleFieldState(),
          opponentType: 'fire');
      final rain = _weatherBallDamage(_weather(PsdkBattleWeatherId.rain),
          opponentType: 'fire');
      final sun = _weatherBallDamage(_weather(PsdkBattleWeatherId.sunny),
          opponentType: 'grass');
      final sand = _weatherBallDamage(
        _weather(PsdkBattleWeatherId.sandstorm),
        opponentType: 'ice',
      );
      final hail = _weatherBallDamage(
        _weather(PsdkBattleWeatherId.hail),
        opponentType: 'grass',
      );

      expect(rain, greaterThan(noWeather));
      expect(sun, greaterThan(noWeather));
      expect(sand, greaterThan(noWeather));
      expect(hail, greaterThan(noWeather));
    });

    test('hard rain prevents damaging Fire moves', () {
      final result = _runMove(
        field: _weather(PsdkBattleWeatherId.hardrain, remainingTurns: null),
        playerMove: _move(
          id: 'flamethrower',
          type: 'fire',
          category: PsdkBattleMoveCategory.special,
          power: 90,
          battleEngineMethod: 's_basic',
        ),
      );

      expect(_damageEvents(result, moveId: 'flamethrower'), isEmpty);
      expect(_failedEvents(result, moveId: 'flamethrower'), hasLength(1));
      expect(_failedEvents(result, moveId: 'flamethrower').single.reason,
          'weather');
    });

    test('hard sun prevents damaging Water moves', () {
      final result = _runMove(
        field: _weather(PsdkBattleWeatherId.hardsun, remainingTurns: null),
        playerMove: _move(
          id: 'hydro_pump',
          type: 'water',
          category: PsdkBattleMoveCategory.special,
          power: 110,
          battleEngineMethod: 's_basic',
        ),
      );

      expect(_damageEvents(result, moveId: 'hydro_pump'), isEmpty);
      expect(_failedEvents(result, moveId: 'hydro_pump'), hasLength(1));
      expect(
          _failedEvents(result, moveId: 'hydro_pump').single.reason, 'weather');
    });

    test('strong winds neutralizes only the Flying weakness component', () {
      final clearFlying = _damage(
        _runMove(
          field: const PsdkBattleFieldState(),
          playerMove: _rockMove(),
          opponentTypes: const PsdkBattleTypes(primary: 'flying'),
        ),
        moveId: 'stone_edge',
      );
      final strongFlying = _damage(
        _runMove(
          field:
              _weather(PsdkBattleWeatherId.strongWinds, remainingTurns: null),
          playerMove: _rockMove(),
          opponentTypes: const PsdkBattleTypes(primary: 'flying'),
        ),
        moveId: 'stone_edge',
      );
      final strongFireFlying = _damage(
        _runMove(
          field:
              _weather(PsdkBattleWeatherId.strongWinds, remainingTurns: null),
          playerMove: _rockMove(),
          opponentTypes:
              const PsdkBattleTypes(primary: 'fire', secondary: 'flying'),
        ),
        moveId: 'stone_edge',
      );
      final strongFire = _damage(
        _runMove(
          field:
              _weather(PsdkBattleWeatherId.strongWinds, remainingTurns: null),
          playerMove: _rockMove(),
          opponentTypes: const PsdkBattleTypes(primary: 'fire'),
        ),
        moveId: 'stone_edge',
      );

      expect(strongFlying, lessThan(clearFlying));
      expect(strongFireFlying, equals(strongFire));
      expect(strongFireFlying, greaterThan(strongFlying));
    });

    for (final weather in <PsdkBattleWeatherId>[
      PsdkBattleWeatherId.hail,
      PsdkBattleWeatherId.snow,
    ]) {
      test('s_basic Blizzard bypasses accuracy under ${weather.jsonName}', () {
        final result = _runMove(
          field: _weather(weather),
          moveAccuracySeed: 99,
          playerMove: _move(
            id: 'blizzard',
            type: 'ice',
            category: PsdkBattleMoveCategory.special,
            power: 110,
            accuracy: 1,
            battleEngineMethod: 's_basic',
          ),
        );

        expect(_missEvents(result, moveId: 'blizzard'), isEmpty);
        expect(_damageEvents(result, moveId: 'blizzard'), hasLength(1));
      });
    }

    test('s_basic Blizzard keeps normal accuracy outside snowing weather', () {
      final result = _runMove(
        field: const PsdkBattleFieldState(),
        moveAccuracySeed: 99,
        playerMove: _move(
          id: 'blizzard',
          type: 'ice',
          category: PsdkBattleMoveCategory.special,
          power: 110,
          accuracy: 1,
          battleEngineMethod: 's_basic',
        ),
      );

      expect(_missEvents(result, moveId: 'blizzard'), hasLength(1));
      expect(_damageEvents(result, moveId: 'blizzard'), isEmpty);
    });

    test('s_solar_beam charges first without sun then releases next turn', () {
      final engine = _engine(
        field: const PsdkBattleFieldState(),
        playerMove: _move(
          id: 'solar_beam',
          type: 'grass',
          category: PsdkBattleMoveCategory.special,
          power: 120,
          battleEngineMethod: 's_solar_beam',
        ),
      );

      final charge = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final release =
          engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));

      expect(_damageEvents(charge, moveId: 'solar_beam'), isEmpty);
      expect(_damageEvents(release, moveId: 'solar_beam'), hasLength(1));
    });

    test('s_solar_beam releases immediately under sun', () {
      final result = _runMove(
        field: _weather(PsdkBattleWeatherId.sunny),
        playerMove: _move(
          id: 'solar_beam',
          type: 'grass',
          category: PsdkBattleMoveCategory.special,
          power: 120,
          battleEngineMethod: 's_solar_beam',
        ),
      );

      expect(_damageEvents(result, moveId: 'solar_beam'), hasLength(1));
    });

    test('s_solar_beam releases with reduced power under rain', () {
      final clear = _releaseSolarBeam(const PsdkBattleFieldState());
      final rain = _releaseSolarBeam(_weather(PsdkBattleWeatherId.rain));

      expect(
        _damage(rain, moveId: 'solar_beam'),
        lessThan(_damage(clear, moveId: 'solar_beam')),
      );
    });

    test('s_solar_beam covers Solar Blade physical variants under weather', () {
      final sun = _runMove(
        field: _weather(PsdkBattleWeatherId.sunny),
        playerMove: _move(
          id: 'solar_blade',
          type: 'grass',
          category: PsdkBattleMoveCategory.physical,
          power: 125,
          battleEngineMethod: 's_solar_beam',
        ),
      );
      final rain = _releaseSolarBlade(_weather(PsdkBattleWeatherId.rain));
      final clear = _releaseSolarBlade(const PsdkBattleFieldState());

      expect(_damageEvents(sun, moveId: 'solar_blade'), hasLength(1));
      expect(
        _damage(rain, moveId: 'solar_blade'),
        lessThan(_damage(clear, moveId: 'solar_blade')),
      );
    });
  });
}

int _weatherBallDamage(
  PsdkBattleFieldState field, {
  required String opponentType,
}) {
  return _damage(
    _runMove(
      field: field,
      playerMove: _move(
        id: 'weather_ball',
        type: 'normal',
        category: PsdkBattleMoveCategory.special,
        power: 50,
        battleEngineMethod: 's_weather_ball',
      ),
      opponentTypes: PsdkBattleTypes(primary: opponentType),
    ),
    moveId: 'weather_ball',
  );
}

PsdkBattleTurnResult _releaseSolarBeam(PsdkBattleFieldState field) {
  final engine = _engine(
    field: field,
    playerMove: _move(
      id: 'solar_beam',
      type: 'grass',
      category: PsdkBattleMoveCategory.special,
      power: 120,
      battleEngineMethod: 's_solar_beam',
    ),
  );
  engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
  return engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
}

PsdkBattleTurnResult _releaseSolarBlade(PsdkBattleFieldState field) {
  final engine = _engine(
    field: field,
    playerMove: _move(
      id: 'solar_blade',
      type: 'grass',
      category: PsdkBattleMoveCategory.physical,
      power: 125,
      battleEngineMethod: 's_solar_beam',
    ),
  );
  engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
  return engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
}

PsdkBattleTurnResult _runMove({
  required PsdkBattleFieldState field,
  required PsdkBattleMoveData playerMove,
  int moveAccuracySeed = 3,
  PsdkBattleTypes opponentTypes = const PsdkBattleTypes(primary: 'normal'),
}) {
  return _engine(
    field: field,
    playerMove: playerMove,
    moveAccuracySeed: moveAccuracySeed,
    opponentTypes: opponentTypes,
  ).submit(const PsdkBattleDecision.fight(moveSlot: 0));
}

PsdkBattleEngine _engine({
  required PsdkBattleFieldState field,
  required PsdkBattleMoveData playerMove,
  int moveAccuracySeed = 3,
  PsdkBattleTypes opponentTypes = const PsdkBattleTypes(primary: 'normal'),
}) {
  return PsdkBattleEngine(
    setup: PsdkBattleSetup.singles(
      player: _combatant(
        id: 'player',
        speed: 100,
        move: playerMove,
      ),
      opponent: _combatant(
        id: 'opponent',
        speed: 1,
        types: opponentTypes,
        move: _move(
          id: 'opponent_wait',
          power: 0,
          accuracy: 0,
          category: PsdkBattleMoveCategory.status,
          battleEngineMethod: 's_splash',
        ),
      ),
      rngSeeds: PsdkBattleRngSeeds(
        moveDamage: 1,
        moveCritical: 99999,
        moveAccuracy: moveAccuracySeed,
        generic: 4,
      ),
      field: field,
    ),
  );
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required int speed,
  required PsdkBattleMoveData move,
  PsdkBattleTypes types = const PsdkBattleTypes(primary: 'normal'),
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
  );
}

PsdkBattleMoveData _move({
  required String id,
  String type = 'normal',
  PsdkBattleMoveCategory category = PsdkBattleMoveCategory.physical,
  required int power,
  int accuracy = 100,
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
    criticalRate: 1,
    battleEngineMethod: battleEngineMethod,
    target: target,
  );
}

PsdkBattleMoveData _rockMove() {
  return _move(
    id: 'stone_edge',
    type: 'rock',
    category: PsdkBattleMoveCategory.physical,
    power: 100,
    battleEngineMethod: 's_basic',
  );
}

PsdkBattleFieldState _weather(
  PsdkBattleWeatherId id, {
  int? remainingTurns = 5,
}) {
  return PsdkBattleFieldState(
    weather: PsdkBattleWeatherState(id: id, remainingTurns: remainingTurns),
  );
}

List<PsdkBattleMissEvent> _missEvents(
  PsdkBattleTurnResult result, {
  required String moveId,
}) {
  return result.timeline.events
      .whereType<PsdkBattleMissEvent>()
      .where((event) => event.moveId == moveId)
      .toList(growable: false);
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

List<PsdkBattleMoveFailedEvent> _failedEvents(
  PsdkBattleTurnResult result, {
  required String moveId,
}) {
  return result.timeline.events
      .whereType<PsdkBattleMoveFailedEvent>()
      .where((event) => event.moveId == moveId)
      .toList(growable: false);
}

int _damage(PsdkBattleTurnResult result, {required String moveId}) {
  return _damageEvents(result, moveId: moveId).single.damage;
}
