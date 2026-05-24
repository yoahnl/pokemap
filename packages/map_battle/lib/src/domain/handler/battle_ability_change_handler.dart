import '../../psdk/domain/psdk_battle_slots.dart';
import '../../psdk/domain/psdk_battle_combatant.dart';
import '../../psdk/domain/psdk_battle_state.dart';
import '../../psdk/domain/psdk_battle_timeline.dart';
import '../effect/battle_effect_hooks.dart';
import '../move/battle_move_data.dart';
import 'battle_handler_context.dart';
import 'battle_handler_result.dart';

final class BattleAbilityChangeHandler {
  const BattleAbilityChangeHandler();

  BattleHandlerResult changeAbility({
    required BattleHandlerContext context,
    required PsdkBattleSlotRef target,
    required String? abilityId,
    bool triggerSwitchEvent = false,
  }) {
    final normalizedAbilityId = _normalizedAbilityId(abilityId);
    final currentAbilityId =
        _normalizedAbilityId(context.state.battlerAt(target).abilityId);
    if (currentAbilityId == normalizedAbilityId) {
      return BattleHandlerResult(
        state: context.state,
        rng: context.rng,
        applied: false,
      );
    }

    final baseState = currentAbilityId == 'forecast'
        ? _resetForecastForm(context.state, target)
        : context.state;
    var nextState = baseState.updateBattler(
      target,
      (battler) => battler
          .copyWith(
              abilityId:
                  normalizedAbilityId.isEmpty ? null : normalizedAbilityId)
          .withAbilityEffect(target),
    );
    var nextRng = context.rng;
    var events = const <PsdkBattleEvent>[];
    if (triggerSwitchEvent) {
      final switchResult =
          nextState.battlerAt(target).effects.dispatchSwitchEvent(
                BattleEffectSwitchEventContext(
                  state: nextState,
                  rng: nextRng,
                  turn: context.turn,
                  owner: target,
                  who: target,
                  replacement: target,
                ),
              );
      nextState = switchResult.state;
      nextRng = switchResult.rng;
      events = switchResult.events;
    }

    return BattleHandlerResult(
      state: nextState,
      rng: nextRng,
      events: events,
    );
  }

  bool canChangeAbility({
    required PsdkBattleState state,
    required PsdkBattleSlotRef target,
    PsdkBattleSlotRef? launcher,
    BattleMoveDefinition? move,
  }) {
    final targetAbilityId =
        _normalizedAbilityId(state.battlerAt(target).abilityId);
    if (_cantOverwriteAbilities.contains(targetAbilityId)) {
      return false;
    }
    if (launcher != null) {
      final launcherAbilityId =
          _normalizedAbilityId(state.battlerAt(launcher).abilityId);
      if (launcherAbilityId == '__undef__' ||
          _receiverCantCopyAbilities.contains(launcherAbilityId)) {
        return false;
      }
    }
    final blockedAbilities = _skillBlockingAbilities[move?.dbSymbol];
    return blockedAbilities == null ||
        !blockedAbilities.contains(targetAbilityId);
  }
}

String _normalizedAbilityId(String? abilityId) {
  return abilityId?.trim().toLowerCase() ?? '';
}

const _cantOverwriteAbilities = <String>{
  'as_one',
  'battle_bond',
  'comatose',
  'commander',
  'disguise',
  'gulp_missile',
  'hadron_engine',
  'hunger_switch',
  'ice_face',
  'imposter',
  'multitype',
  'orichalcum_pulse',
  'power_construct',
  'protosynthesis',
  'quark_drive',
  'rks_system',
  'schooling',
  'shields_down',
  'stance_change',
  'wonder_guard',
  'zen_mode',
  'zero_to_hero',
};

const _receiverCantCopyAbilities = <String>{
  'as_one',
  'battle_bond',
  'comatose',
  'commander',
  'disguise',
  'flower_gift',
  'forecast',
  'gulp_missile',
  'hadron_engine',
  'hunger_switch',
  'ice_face',
  'illusion',
  'imposter',
  'multitype',
  'neutralizing_gas',
  'orichalcum_pulse',
  'poison_puppeteer',
  'power_construct',
  'power_of_alchemy',
  'prokosynthesis',
  'protosynthesis',
  'quark_drive',
  'receiver',
  'rks_system',
  'schooling',
  'shields_down',
  'stance_change',
  'trace',
  'wonder_guard',
  'zen_mode',
  'zero_to_hero',
};

const _skillBlockingAbilities = <String, Set<String>>{
  'entrainment': <String>{'truant'},
  'simple_beam': <String>{'simple', 'truant'},
  'worry_seed': <String>{'insomnia', 'truant'},
};

PsdkBattleState _resetForecastForm(
  PsdkBattleState state,
  PsdkBattleSlotRef target,
) {
  return state.updateBattler(
    target,
    (battler) => battler.copyWith(
      form: 0,
      types: const PsdkBattleTypes(primary: 'normal'),
    ),
  );
}
