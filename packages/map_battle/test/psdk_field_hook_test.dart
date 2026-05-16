import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK generic field hooks', () {
    test('weather prevention hooks can block a weather change', () {
      final context = _context(
        state: PsdkBattleState.fromSetup(
          _setup(
            playerEffects: const PsdkBattleEffectStack.empty().addEffect(
              _WeatherPreventionFixtureEffect(),
            ),
          ),
        ),
      );

      final result = const BattleWeatherChangeHandler().changeWeather(
        context: context,
        weather: PsdkBattleWeatherId.rain,
      );

      expect(result.applied, isFalse);
      expect(result.reason, 'fixture_weather_prevented');
      expect(result.events, isEmpty);
      expect(result.state.field.weather, isNull);
    });

    test('weather post hooks are dispatched after the field changes', () {
      final context = _context(
        state: PsdkBattleState.fromSetup(
          _setup(
            playerEffects: const PsdkBattleEffectStack.empty().addEffect(
              _WeatherPostFixtureEffect(),
            ),
          ),
        ),
      );

      final result = const BattleWeatherChangeHandler().changeWeather(
        context: context,
        weather: PsdkBattleWeatherId.sunny,
      );

      expect(result.applied, isTrue);
      expect(result.events.first, isA<PsdkBattleWeatherChangedEvent>());
      expect(
        result.events.whereType<PsdkBattleEffectEvent>().single.reason,
        'fixture_post_weather_change',
      );
    });

    test('terrain prevention hooks can block a terrain change', () {
      final context = _context(
        state: PsdkBattleState.fromSetup(
          _setup(
            opponentEffects: const PsdkBattleEffectStack.empty().addEffect(
              _TerrainPreventionFixtureEffect(),
            ),
          ),
        ),
      );

      final result = const BattleTerrainChangeHandler().changeTerrain(
        context: context,
        terrain: PsdkBattleTerrainId.electricTerrain,
      );

      expect(result.applied, isFalse);
      expect(result.reason, 'fixture_terrain_prevented');
      expect(result.events, isEmpty);
      expect(result.state.field.terrain, isNull);
    });

    test('terrain post hooks can mutate state after the field changes', () {
      final context = _context(
        state: PsdkBattleState.fromSetup(
          _setup(
            playerEffects: const PsdkBattleEffectStack.empty().addEffect(
              _TerrainPostFixtureEffect(),
            ),
          ),
        ),
      );

      final result = const BattleTerrainChangeHandler().changeTerrain(
        context: context,
        terrain: PsdkBattleTerrainId.grassyTerrain,
      );

      expect(result.applied, isTrue);
      expect(result.events.first, isA<PsdkBattleTerrainChangedEvent>());
      expect(result.state.field.terrain?.remainingTurns, 8);
      expect(
        result.events.whereType<PsdkBattleEffectEvent>().single.reason,
        'fixture_post_terrain_change',
      );
    });
  });
}

final class _WeatherPreventionFixtureEffect extends BattleEffect {
  const _WeatherPreventionFixtureEffect()
      : super(
          id: 'fixture_weather_prevention',
          scope: const BattlerBattleEffectScope(psdkPlayerSlot),
        );

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) => this;

  @override
  String? onWeatherPrevention(BattleEffectWeatherPreventionContext context) {
    return context.weather == PsdkBattleWeatherId.rain
        ? 'fixture_weather_prevented'
        : null;
  }
}

final class _WeatherPostFixtureEffect extends BattleEffect {
  const _WeatherPostFixtureEffect()
      : super(
          id: 'fixture_post_weather',
          scope: const BattlerBattleEffectScope(psdkPlayerSlot),
        );

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) => this;

  @override
  BattleEffectFieldChangeResult? onPostWeatherChange(
    BattleEffectWeatherChangeContext context,
  ) {
    return BattleEffectFieldChangeResult(
      state: context.state,
      rng: context.rng,
      events: <PsdkBattleEvent>[
        PsdkBattleEffectEvent.ticked(
          turn: context.turn,
          target: context.owner,
          effectId: id,
          reason: 'fixture_post_weather_change',
        ),
      ],
    );
  }
}

final class _TerrainPreventionFixtureEffect extends BattleEffect {
  const _TerrainPreventionFixtureEffect()
      : super(
          id: 'fixture_terrain_prevention',
          scope: const BattlerBattleEffectScope(psdkOpponentSlot),
        );

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) => this;

  @override
  String? onTerrainPrevention(BattleEffectTerrainPreventionContext context) {
    return context.terrain == PsdkBattleTerrainId.electricTerrain
        ? 'fixture_terrain_prevented'
        : null;
  }
}

final class _TerrainPostFixtureEffect extends BattleEffect {
  const _TerrainPostFixtureEffect()
      : super(
          id: 'fixture_post_terrain',
          scope: const BattlerBattleEffectScope(psdkPlayerSlot),
        );

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) => this;

  @override
  BattleEffectFieldChangeResult? onPostTerrainChange(
    BattleEffectTerrainChangeContext context,
  ) {
    if (context.terrain == null) {
      return null;
    }
    return BattleEffectFieldChangeResult(
      state: context.state.copyWith(
        field: context.state.field.withTerrain(
          context.terrain!,
          remainingTurns: 8,
        ),
      ),
      rng: context.rng,
      events: <PsdkBattleEvent>[
        PsdkBattleEffectEvent.ticked(
          turn: context.turn,
          target: context.owner,
          effectId: id,
          reason: 'fixture_post_terrain_change',
        ),
      ],
    );
  }
}

BattleHandlerContext _context({required PsdkBattleState state}) {
  return BattleHandlerContext(
    state: state,
    rng: BattleRngStreams.fromSeeds(
      moveDamageSeed: 1,
      moveCriticalSeed: 1,
      moveAccuracySeed: 1,
      genericSeed: 1,
    ),
    turn: 7,
    user: psdkPlayerSlot,
  );
}

PsdkBattleSetup _setup({
  PsdkBattleEffectStack? playerEffects,
  PsdkBattleEffectStack? opponentEffects,
}) {
  return PsdkBattleSetup.singles(
    player: _combatant('player', effects: playerEffects),
    opponent: _combatant('opponent', effects: opponentEffects),
    rngSeeds: const PsdkBattleRngSeeds(
      moveDamage: 1,
      moveCritical: 1,
      moveAccuracy: 1,
      generic: 1,
    ),
  );
}

PsdkBattleCombatantSetup _combatant(
  String id, {
  PsdkBattleEffectStack? effects,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 10,
    maxHp: 40,
    currentHp: 40,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: const PsdkBattleStats(
      attack: 20,
      defense: 20,
      specialAttack: 20,
      specialDefense: 20,
      speed: 20,
    ),
    moves: <PsdkBattleMoveData>[
      PsdkBattleMoveData(
        id: 'scratch',
        dbSymbol: 'scratch',
        name: 'Scratch',
        type: 'normal',
        category: PsdkBattleMoveCategory.physical,
        power: 40,
        accuracy: 100,
        pp: 35,
        priority: 0,
        battleEngineMethod: 's_basic',
        target: PsdkBattleMoveTarget.adjacentFoe,
      ),
    ],
    effects: effects,
  );
}
