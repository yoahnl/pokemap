import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK battle field state', () {
    test('defaults to no terrain and no weather', () {
      final state = PsdkBattleState.fromSetup(_setup());

      expect(state.field.terrain, isNull);
      expect(state.field.weather, isNull);
      expect(state.field.hasTerrain, isFalse);
      expect(state.field.hasWeather, isFalse);
    });

    test('can be seeded from setup for deterministic move-family tests', () {
      final state = PsdkBattleState.fromSetup(
        _setup(
          field: const PsdkBattleFieldState(
            terrain: PsdkBattleTerrainState(
              id: PsdkBattleTerrainId.electricTerrain,
              remainingTurns: 5,
            ),
            weather: PsdkBattleWeatherState(
              id: PsdkBattleWeatherId.rain,
              remainingTurns: 5,
            ),
          ),
        ),
      );

      expect(state.field.terrain?.id, PsdkBattleTerrainId.electricTerrain);
      expect(state.field.terrain?.remainingTurns, 5);
      expect(state.field.weather?.id, PsdkBattleWeatherId.rain);
      expect(state.field.weather?.remainingTurns, 5);
      expect(state.field.hasTerrain, isTrue);
      expect(state.field.hasWeather, isTrue);
    });

    test('copyWith creates a new immutable field snapshot', () {
      const field = PsdkBattleFieldState();
      final next = field.withTerrain(
        PsdkBattleTerrainId.mistyTerrain,
        remainingTurns: 7,
      );

      expect(field.terrain, isNull);
      expect(next.terrain?.id, PsdkBattleTerrainId.mistyTerrain);
      expect(next.terrain?.remainingTurns, 7);
      expect(next.isTerrainActive(PsdkBattleTerrainId.mistyTerrain), isTrue);
      expect(
          next.isTerrainActive(PsdkBattleTerrainId.electricTerrain), isFalse);
    });

    test('clear and tick create new field snapshots', () {
      const field = PsdkBattleFieldState(
        terrain: PsdkBattleTerrainState(
          id: PsdkBattleTerrainId.psychicTerrain,
          remainingTurns: 2,
        ),
        weather: PsdkBattleWeatherState(
          id: PsdkBattleWeatherId.rain,
          remainingTurns: 1,
        ),
      );

      final ticked = field.tickEndTurn();

      expect(ticked.terrain?.id, PsdkBattleTerrainId.psychicTerrain);
      expect(ticked.terrain?.remainingTurns, 1);
      expect(ticked.weather, isNull);
      expect(field.clearTerrain().terrain, isNull);
      expect(field.clearWeather().weather, isNull);
    });

    test('Air Lock and Cloud Nine suppress weather effects without clearing it',
        () {
      final state = PsdkBattleState(
        field: const PsdkBattleFieldState(
          weather: PsdkBattleWeatherState(
            id: PsdkBattleWeatherId.rain,
            remainingTurns: 5,
          ),
        ),
        combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
          psdkPlayerSlot: PsdkBattleCombatant.fromSetup(
            _combatant(
              id: 'player',
              speed: 100,
              abilityId: 'air_lock',
              move: _move(id: 'tackle', power: 40),
            ),
          ),
          psdkOpponentSlot: PsdkBattleCombatant.fromSetup(
            _combatant(
              id: 'opponent',
              speed: 1,
              move: _move(id: 'splash', power: 0),
            ),
          ),
        },
      );

      expect(state.field.isWeatherActive(PsdkBattleWeatherId.rain), isTrue);
      expect(state.weatherEffectsSuppressed, isTrue);
      expect(state.isWeatherEffectActive(PsdkBattleWeatherId.rain), isFalse);
    });

    test('a regular move advances seeded field durations at end turn', () {
      final result = _submitPlayerMove(
        _move(
          id: 'tackle',
          power: 40,
        ),
        field: const PsdkBattleFieldState(
          terrain: PsdkBattleTerrainState(
            id: PsdkBattleTerrainId.grassyTerrain,
            remainingTurns: 3,
          ),
          weather: PsdkBattleWeatherState(
            id: PsdkBattleWeatherId.sandstorm,
            remainingTurns: 4,
          ),
        ),
      );

      expect(result.state.field.terrain?.id, PsdkBattleTerrainId.grassyTerrain);
      expect(result.state.field.terrain?.remainingTurns, 2);
      expect(result.state.field.weather?.id, PsdkBattleWeatherId.sandstorm);
      expect(result.state.field.weather?.remainingTurns, 3);
    });
  });
}

PsdkBattleTurnResult _submitPlayerMove(
  PsdkBattleMoveData move, {
  PsdkBattleFieldState field = const PsdkBattleFieldState(),
}) {
  final engine =
      PsdkBattleEngine(setup: _setup(playerMove: move, field: field));
  return engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
}

PsdkBattleSetup _setup({
  PsdkBattleFieldState field = const PsdkBattleFieldState(),
  PsdkBattleMoveData? playerMove,
}) {
  return PsdkBattleSetup.singles(
    player: _combatant(
      id: 'player',
      speed: 100,
      move: playerMove ??
          _move(
            id: 'tackle',
            power: 40,
          ),
    ),
    opponent: _combatant(
      id: 'opponent',
      speed: 1,
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
  String? abilityId,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: 100,
    currentHp: 100,
    types: const PsdkBattleTypes(primary: 'fire'),
    stats: PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: speed,
    ),
    moves: <PsdkBattleMoveData>[move],
    abilityId: abilityId,
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
