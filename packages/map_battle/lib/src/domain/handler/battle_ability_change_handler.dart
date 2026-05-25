import '../../psdk/domain/psdk_battle_slots.dart';
import '../../psdk/domain/psdk_battle_combatant.dart';
import '../../psdk/domain/psdk_battle_state.dart';
import '../../psdk/domain/psdk_battle_timeline.dart';
import '../effect/battle_effect_hooks.dart';
import '../move/battle_move_data.dart';
import '../rng/battle_rng_streams.dart';
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

    final removed = context.state.battlerAt(target).effects.dispatchLifecycle(
          BattleEffectLifecycleContext(
            state: context.state,
            rng: context.rng,
            turn: context.turn,
            owner: target,
            phase: BattleEffectLifecyclePhase.removed,
          ),
        );
    final baseState = currentAbilityId == 'forecast'
        ? _resetForecastForm(removed.state, target)
        : removed.state;
    var nextState = baseState.updateBattler(
      target,
      (battler) => battler
          .copyWith(
              abilityId:
                  normalizedAbilityId.isEmpty ? null : normalizedAbilityId)
          .withAbilityEffect(target),
    );
    var nextRng = removed.rng;
    var events = removed.events;
    if (currentAbilityId == 'neutralizing_gas' &&
        normalizedAbilityId != 'neutralizing_gas') {
      final neutralizingGas = _resyncNeutralizingGasReplacement(
        state: nextState,
        rng: nextRng,
        turn: context.turn,
        previousOwner: target,
      );
      nextState = neutralizingGas.state;
      nextRng = neutralizingGas.rng;
      events = <PsdkBattleEvent>[
        ...events,
        ...neutralizingGas.events,
      ];
    }
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
      events = <PsdkBattleEvent>[
        ...events,
        ...switchResult.events,
      ];
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

BattleHandlerResult _resyncNeutralizingGasReplacement({
  required PsdkBattleState state,
  required BattleRngStreams rng,
  required int turn,
  required PsdkBattleSlotRef previousOwner,
}) {
  for (final slot in state.aliveSlots()) {
    final battler = state.battlerAt(slot);
    if (slot == previousOwner ||
        _normalizedAbilityId(battler.abilityId) != 'neutralizing_gas' ||
        battler.effects.contains('ability_suppressed') ||
        !battler.effects.contains('neutralizing_gas_activated')) {
      continue;
    }

    final result = battler.effects.dispatchSwitchEvent(
      BattleEffectSwitchEventContext(
        state: state,
        rng: rng,
        turn: turn,
        owner: slot,
        who: slot,
        replacement: slot,
      ),
      where: (effect) => effect.id == 'ability:neutralizing_gas',
    );
    return BattleHandlerResult(
      state: result.state,
      rng: result.rng,
      events: result.events,
      applied: result.applied || result.events.isNotEmpty,
    );
  }

  return BattleHandlerResult(
    state: state,
    rng: rng,
    applied: false,
  );
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
