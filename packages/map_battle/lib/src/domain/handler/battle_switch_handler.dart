import '../../psdk/domain/psdk_battle_combatant.dart';
import '../../psdk/domain/psdk_battle_move.dart';
import '../../psdk/domain/psdk_battle_slots.dart';
import '../../psdk/domain/psdk_battle_state.dart';
import '../../psdk/domain/psdk_battle_timeline.dart';
import '../battler/battle_grounding_resolver.dart';
import '../effect/ability/ability_effect.dart';
import '../effect/battle_effect_hooks.dart';
import '../effect/battle_effect.dart';
import '../effect/battle_effect_scope.dart';
import '../effect/side/hazard_effects.dart';
import '../move/battle_move_data.dart';
import '../move/battle_move_type_processor.dart';
import 'battle_damage_handler.dart';
import 'battle_handler_context.dart';
import 'battle_handler_result.dart';
import 'battle_stat_change_handler.dart';
import 'battle_status_change_handler.dart';

final class BattleSwitchHandler {
  const BattleSwitchHandler();

  BattleHandlerResult markSwitching({
    required BattleHandlerContext context,
    required PsdkBattleSlotRef target,
    required bool switching,
  }) {
    return BattleHandlerResult(
      state: context.state.updateBattler(
        target,
        (battler) => battler.copyWith(switching: switching),
      ),
      rng: context.rng,
    );
  }

  BattleHandlerResult resolveSwitchPrevention({
    required BattleHandlerContext context,
    required PsdkBattleSlotRef target,
    BattleMoveDefinition? move,
  }) {
    final switchContext = BattleEffectSwitchPreventionContext(
      state: context.state,
      rng: context.rng,
      turn: context.turn,
      target: target,
      move: move,
    );
    if (context.state.battlerAt(target).effects.switchPassthrough(
              switchContext,
            ) ||
        _hasSwitchPassthrough(
          effects: context.state.activeAbilityEffects(),
          context: switchContext,
        )) {
      return BattleHandlerResult(
        state: context.state,
        rng: context.rng,
      );
    }
    final reason =
        context.state.battlerAt(target).effects.switchPreventionReason(
                  switchContext,
                ) ??
            context.state.activeAbilityEffects().switchPreventionReason(
                  switchContext,
                );
    if (reason != null) {
      return BattleHandlerResult(
        state: context.state,
        rng: context.rng,
        applied: false,
        reason: reason,
      );
    }
    return BattleHandlerResult(
      state: context.state,
      rng: context.rng,
    );
  }

  BattleHandlerResult applyEntryHazards({
    required BattleHandlerContext context,
    required PsdkBattleSlotRef target,
  }) {
    final targetBattler = context.state.battlerAt(target);
    if (targetBattler.isFainted) {
      return BattleHandlerResult(state: context.state, rng: context.rng);
    }
    if (_hasHeavyDutyBoots(targetBattler)) {
      return BattleHandlerResult(state: context.state, rng: context.rng);
    }

    var state = context.state;
    var rng = context.rng;
    final events = <PsdkBattleEvent>[];
    final hazards = _bankHazards(state, target.bank);
    final grounded = const BattleGroundingResolver().isGrounded(targetBattler);
    final blocksHazardDamage = _hasMagicGuard(targetBattler);

    final spikes = _hazardWithId(hazards, 'spikes');
    if (grounded && spikes != null && !blocksHazardDamage) {
      final layers = spikes is SpikesEffect ? spikes.layers : 1;
      final result = const BattleDamageHandler().applyDamage(
        context: BattleHandlerContext(
          state: state,
          rng: rng,
          turn: context.turn,
          user: context.user,
        ),
        target: target,
        moveId: 'effect:spikes',
        rawDamage: _fractionalDamage(
          state.battlerAt(target).maxHp,
          10 - layers * 2,
        ),
      );
      state = result.state;
      rng = result.rng;
      events.addAll(result.events);
    }

    if (_hazardWithId(hazards, 'stealth_rock') != null && !blocksHazardDamage) {
      final targetAfterSpikes = state.battlerAt(target);
      final multiplier = const BattleMoveTypeProcessor()
          .resolveEffectiveness(
            moveType: 'rock',
            targetTypes: targetAfterSpikes.types,
          )
          .multiplier;
      final result = const BattleDamageHandler().applyDamage(
        context: BattleHandlerContext(
          state: state,
          rng: rng,
          turn: context.turn,
          user: context.user,
        ),
        target: target,
        moveId: 'effect:stealth_rock',
        rawDamage: _stealthRockDamage(targetAfterSpikes.maxHp, multiplier),
      );
      state = result.state;
      rng = result.rng;
      events.addAll(result.events);
    }

    final toxicSpikes = _hazardWithId(hazards, 'toxic_spikes');
    if (grounded && toxicSpikes != null) {
      final targetAfterDamage = state.battlerAt(target);
      if (targetAfterDamage.hasType('poison')) {
        state = _removeBankEffect(
          state: state,
          bank: target.bank,
          effectId: 'toxic_spikes',
        );
      } else {
        final result = const BattleStatusChangeHandler().applyMajorStatus(
          context: BattleHandlerContext(
            state: state,
            rng: rng,
            turn: context.turn,
            user: context.user,
          ),
          target: target,
          moveId: 'effect:toxic_spikes',
          status: toxicSpikes is ToxicSpikesEffect && toxicSpikes.layers >= 2
              ? PsdkBattleMajorStatus.toxic
              : PsdkBattleMajorStatus.poison,
        );
        state = result.state;
        rng = result.rng;
        events.addAll(result.events);
      }
    }

    if (grounded && _hazardWithId(hazards, 'sticky_web') != null) {
      final stickyWeb = _hazardWithId(hazards, 'sticky_web');
      final statTarget =
          _normalizedId(targetBattler.abilityId) == 'mirror_armor' &&
                  stickyWeb is StickyWebEffect &&
                  stickyWeb.origin != null
              ? stickyWeb.origin!
              : target;
      final result = const BattleStatChangeHandler().applyStatChange(
        context: BattleHandlerContext(
          state: state,
          rng: rng,
          turn: context.turn,
          user: context.user,
        ),
        target: statTarget,
        stat: 'speed',
        stages: -1,
      );
      state = result.state;
      rng = result.rng;
      events.addAll(result.events);
    }

    return BattleHandlerResult(state: state, rng: rng, events: events);
  }

  BattleHandlerResult batonPassTransfer({
    required BattleHandlerContext context,
    required PsdkBattleSlotRef source,
    required PsdkBattleSlotRef replacement,
  }) {
    final sourceBattler = context.state.battlerAt(source);
    if (!sourceBattler.effects.contains('baton_pass')) {
      return BattleHandlerResult(
        state: context.state,
        rng: context.rng,
        applied: false,
        reason: 'no_baton_pass_effect',
      );
    }

    final replacementBattler = context.state.battlerAt(replacement);
    final transferred = sourceBattler.effects.batonPassTransferEffects(
      source: source,
      target: replacement,
    );
    final sourceEffects = sourceBattler.effects
        .withoutBatonPassTransferableEffects(
          source: source,
          target: replacement,
        )
        .remove('baton_pass');
    final replacementEffects = replacementBattler.effects.addEffects(
      transferred.effects,
    );

    return BattleHandlerResult(
      state: context.state
          .updateBattler(
            source,
            (battler) => battler.copyWith(
              statStages: PsdkBattleStatStages.neutral(),
              effects: sourceEffects,
              switching: false,
            ),
          )
          .updateBattler(
            replacement,
            (battler) => battler.copyWith(
              statStages: sourceBattler.statStages,
              effects: replacementEffects,
            ),
          ),
      rng: context.rng,
    );
  }

  BattleHandlerResult dispatchSwitchEvents({
    required BattleHandlerContext context,
    required PsdkBattleSlotRef who,
    required PsdkBattleSlotRef replacement,
  }) {
    var nextState = context.state;
    var nextRng = context.rng;
    final events = <PsdkBattleEvent>[];
    var changed = false;
    final owners = context.state.combatants.keys.toList()..sort(_compareSlots);

    for (final owner in owners) {
      final result = nextState.battlerAt(owner).effects.dispatchSwitchEvent(
            BattleEffectSwitchEventContext(
              state: nextState,
              rng: nextRng,
              turn: context.turn,
              owner: owner,
              who: who,
              replacement: replacement,
            ),
          );
      nextState = result.state;
      nextRng = result.rng;
      events.addAll(result.events);
      changed = changed || result.applied || result.events.isNotEmpty;
    }

    return BattleHandlerResult(
      state: nextState,
      rng: nextRng,
      events: events,
      applied: changed,
      reason: changed ? null : 'no_switch_events',
    );
  }
}

int _compareSlots(PsdkBattleSlotRef left, PsdkBattleSlotRef right) {
  final bank = left.bank.compareTo(right.bank);
  if (bank != 0) {
    return bank;
  }
  return left.position.compareTo(right.position);
}

bool _hasSwitchPassthrough({
  required Iterable<BattleEffect> effects,
  required BattleEffectSwitchPreventionContext context,
}) {
  for (final effect in effects) {
    if (effect.onSwitchPassthrough(context)) {
      return true;
    }
  }
  return false;
}

List<BattleEffect> _bankHazards(PsdkBattleState state, int bank) {
  return <BattleEffect>[
    for (final effect in _bankEffects(state, bank))
      if (_entryHazardIds.contains(effect.id)) effect,
  ];
}

BattleEffect? _hazardWithId(List<BattleEffect> hazards, String id) {
  for (final hazard in hazards) {
    if (hazard.id == id) {
      return hazard;
    }
  }
  return null;
}

Iterable<BattleEffect> _bankEffects(PsdkBattleState state, int bank) sync* {
  for (final battler in state.combatants.values) {
    for (final effect in battler.effects.effects) {
      final scope = effect.scope;
      if (scope is BankBattleEffectScope && scope.bank == bank) {
        yield effect;
      }
    }
  }
}

PsdkBattleState _removeBankEffect({
  required PsdkBattleState state,
  required int bank,
  required String effectId,
}) {
  var next = state;
  for (final entry in state.combatants.entries) {
    final effects = entry.value.effects.effects.where((effect) {
      final scope = effect.scope;
      return effect.id != effectId ||
          scope is! BankBattleEffectScope ||
          scope.bank != bank;
    });
    next = next.updateBattler(
      entry.key,
      (battler) => battler.copyWith(
        effects: PsdkBattleEffectStack(effects: effects),
      ),
    );
  }
  return next;
}

int _fractionalDamage(int maxHp, int divisor) {
  final damage = maxHp ~/ divisor;
  return damage < 1 ? 1 : damage;
}

int _stealthRockDamage(int maxHp, double effectiveness) {
  final damage = (maxHp * effectiveness / 8).floor();
  return damage < 1 ? 1 : damage;
}

const _entryHazardIds = <String>{
  'spikes',
  'stealth_rock',
  'sticky_web',
  'toxic_spikes',
};

bool _hasHeavyDutyBoots(PsdkBattleCombatant battler) {
  return _normalizedId(battler.heldItemId) == 'heavy_duty_boots' &&
      !battler.itemConsumed;
}

bool _hasMagicGuard(PsdkBattleCombatant battler) {
  return _normalizedId(battler.abilityId) == 'magic_guard';
}

String _normalizedId(String? id) {
  return id?.trim().toLowerCase().replaceAll('-', '_') ?? '';
}

extension _BattleAbilitySwitchPrevention on Iterable<BattleAbilityEffect> {
  String? switchPreventionReason(BattleEffectSwitchPreventionContext context) {
    for (final effect in this) {
      final reason = effect.onSwitchPrevention(context);
      if (reason != null) {
        return reason;
      }
    }
    return null;
  }
}
