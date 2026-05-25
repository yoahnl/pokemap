import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_field.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../psdk/domain/psdk_battle_state.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_weather_change_handler.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';
import 'ability_effect.dart';

final class PrimalWeatherAbilityEffect extends BattleAbilityEffect {
  const PrimalWeatherAbilityEffect({
    required String abilityId,
    required BattleEffectScope scope,
    required this.weather,
  }) : super(abilityId: abilityId, scope: scope);

  final PsdkBattleWeatherId weather;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return PrimalWeatherAbilityEffect(
      abilityId: abilityId,
      scope: scope,
      weather: weather,
    );
  }

  @override
  BattleEffectSwitchEventResult? onSwitchEvent(
    BattleEffectSwitchEventContext context,
  ) {
    if (context.owner != context.replacement) {
      return null;
    }
    final result = const BattleWeatherChangeHandler().changeWeather(
      context: BattleHandlerContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: context.owner,
      ),
      weather: weather,
      remainingTurns: null,
    );
    if (!result.applied) {
      return null;
    }
    return BattleEffectSwitchEventResult(
      state: result.state,
      rng: result.rng,
      events: result.events,
    );
  }

  @override
  BattleEffectSwitchOutResult? onSwitchOut(
    BattleEffectSwitchOutContext context,
  ) {
    if (context.state.field.weather?.id != weather ||
        _hasOtherAliveHolder(
          state: context.state,
          owner: context.owner,
          replacement: context.replacement,
          abilityId: abilityId,
        )) {
      return null;
    }
    final result = const BattleWeatherChangeHandler().clearWeather(
      context: BattleHandlerContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: context.owner,
      ),
      reason: 'ability:$abilityId',
    );
    if (!result.applied) {
      return null;
    }
    return BattleEffectSwitchOutResult(
      state: result.state,
      rng: result.rng,
      events: result.events,
    );
  }

  @override
  BattleEffectPostDamageResult? onPostDamage(
    BattleEffectPostDamageContext context,
  ) {
    if (context.target != context.owner ||
        !context.targetFainted ||
        context.state.field.weather?.id != weather ||
        _hasOtherAliveHolder(
          state: context.state,
          owner: context.owner,
          abilityId: abilityId,
        )) {
      return null;
    }
    final result = const BattleWeatherChangeHandler().clearWeather(
      context: BattleHandlerContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: context.owner,
      ),
      reason: 'ability:$abilityId',
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
}

bool _hasOtherAliveHolder({
  required PsdkBattleState state,
  required PsdkBattleSlotRef owner,
  required String abilityId,
  PsdkBattleCombatant? replacement,
}) {
  if (replacement != null &&
      !replacement.isFainted &&
      replacement.abilityId == abilityId) {
    return true;
  }
  return state.combatants.entries.any(
    (entry) =>
        entry.key != owner &&
        !entry.value.isFainted &&
        entry.value.abilityId == abilityId,
  );
}
