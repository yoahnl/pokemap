import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK weather-conditional move families', () {
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
  });
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

PsdkBattleTurnResult _runMove({
  required PsdkBattleFieldState field,
  required PsdkBattleMoveData playerMove,
  int moveAccuracySeed = 3,
}) {
  return _engine(
    field: field,
    playerMove: playerMove,
    moveAccuracySeed: moveAccuracySeed,
  ).submit(const PsdkBattleDecision.fight(moveSlot: 0));
}

PsdkBattleEngine _engine({
  required PsdkBattleFieldState field,
  required PsdkBattleMoveData playerMove,
  int moveAccuracySeed = 3,
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
    target: PsdkBattleMoveTarget.adjacentFoe,
  );
}

PsdkBattleFieldState _weather(PsdkBattleWeatherId id) {
  return PsdkBattleFieldState(
    weather: PsdkBattleWeatherState(id: id, remainingTurns: 5),
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

int _damage(PsdkBattleTurnResult result, {required String moveId}) {
  return _damageEvents(result, moveId: moveId).single.damage;
}
