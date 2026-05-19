import '../../../psdk/domain/psdk_battle_field.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_terrain_change_handler.dart';
import '../../handler/battle_weather_change_handler.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';
import '../item/item_effect.dart';
import 'ability_effect.dart';

final class SandSpitEffect extends BattleAbilityEffect {
  const SandSpitEffect({
    required BattleEffectScope scope,
  }) : super(abilityId: 'sand_spit', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return SandSpitEffect(scope: scope);
  }

  @override
  BattleEffectPostDamageResult? onPostDamage(
    BattleEffectPostDamageContext context,
  ) {
    if (context.owner != context.target ||
        context.user == context.target ||
        context.damage <= 0 ||
        context.targetFainted) {
      return null;
    }

    final result = const BattleWeatherChangeHandler().changeWeather(
      context: BattleHandlerContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: context.owner,
      ),
      weather: PsdkBattleWeatherId.sandstorm,
      remainingTurns: _weatherDuration(context),
    );
    if (!result.applied) {
      return null;
    }
    return BattleEffectPostDamageResult(
      state: result.state,
      rng: result.rng,
      events: result.events,
    );
  }

  int _weatherDuration(BattleEffectPostDamageContext context) {
    final battler = context.state.battlerAt(context.owner);
    for (final itemEffect in battler.activeItemEffects) {
      final duration = itemEffect.weatherDuration('sandstorm');
      if (duration != null) {
        return duration;
      }
    }
    return 5;
  }
}

final class SeedSowerEffect extends BattleAbilityEffect {
  const SeedSowerEffect({
    required BattleEffectScope scope,
  }) : super(abilityId: 'seed_sower', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return SeedSowerEffect(scope: scope);
  }

  @override
  BattleEffectPostDamageResult? onPostDamage(
    BattleEffectPostDamageContext context,
  ) {
    if (context.owner != context.target ||
        context.user == context.target ||
        context.damage <= 0 ||
        context.targetFainted) {
      return null;
    }

    final result = const BattleTerrainChangeHandler().changeTerrain(
      context: BattleHandlerContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: context.owner,
      ),
      terrain: PsdkBattleTerrainId.grassyTerrain,
      remainingTurns: _terrainDuration(context),
    );
    if (!result.applied) {
      return null;
    }
    return BattleEffectPostDamageResult(
      state: result.state,
      rng: result.rng,
      events: result.events,
    );
  }

  int _terrainDuration(BattleEffectPostDamageContext context) {
    final battler = context.state.battlerAt(context.owner);
    for (final itemEffect in battler.activeItemEffects) {
      final duration = itemEffect.terrainDuration('grassy_terrain');
      if (duration != null) {
        return duration;
      }
    }
    return 5;
  }
}
