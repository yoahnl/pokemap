import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../psdk/domain/psdk_battle_state.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../handler/battle_ability_change_handler.dart';
import '../../rng/battle_rng_streams.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';
import '../move/ability_suppressed_effect.dart';
import 'ability_effect.dart';

const neutralizingGasActivatedEffectId = 'neutralizing_gas_activated';

final class NeutralizingGasEffect extends BattleAbilityEffect {
  const NeutralizingGasEffect({
    required BattleEffectScope scope,
  }) : super(abilityId: 'neutralizing_gas', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return NeutralizingGasEffect(scope: scope);
  }

  @override
  BattleEffectSwitchEventResult? onSwitchEvent(
    BattleEffectSwitchEventContext context,
  ) {
    if (context.owner != owner ||
        context.state.battlerAt(context.owner).effects.contains(
              'ability_suppressed',
            )) {
      return null;
    }
    if (context.who != context.replacement && context.who == context.owner) {
      final result = _findReplacementOrRestore(
        state: context.state,
        owner: context.owner,
        rng: context.rng,
        turn: context.turn,
      );
      return result.applied
          ? BattleEffectSwitchEventResult(
              state: result.state,
              rng: result.rng,
              events: result.events,
            )
          : null;
    }
    if (context.replacement != context.owner) {
      return null;
    }
    final result = _suppressAbilities(
      state: context.state,
      owner: context.owner,
      rng: context.rng,
    );
    return result.applied
        ? BattleEffectSwitchEventResult(
            state: result.state,
            rng: context.rng,
          )
        : null;
  }

  @override
  BattleEffectSwitchOutResult? onSwitchOut(
    BattleEffectSwitchOutContext context,
  ) {
    if (context.owner != owner ||
        !context.state
            .battlerAt(context.owner)
            .effects
            .contains(neutralizingGasActivatedEffectId)) {
      return null;
    }
    final result = _findReplacementOrRestore(
      state: context.state,
      owner: context.owner,
      rng: context.rng,
      turn: context.turn,
    );
    return result.applied
        ? BattleEffectSwitchOutResult(
            state: result.state,
            rng: result.rng,
            events: result.events,
          )
        : null;
  }

  @override
  BattleEffectPostDamageResult? onPostDamage(
    BattleEffectPostDamageContext context,
  ) {
    if (context.owner != owner ||
        context.target != context.owner ||
        !context.targetFainted ||
        !context.state
            .battlerAt(context.owner)
            .effects
            .contains(neutralizingGasActivatedEffectId)) {
      return null;
    }
    final result = _findReplacementOrRestore(
      state: context.state,
      owner: context.owner,
      rng: context.rng,
      turn: context.turn,
    );
    return result.applied
        ? BattleEffectPostDamageResult(
            state: result.state,
            rng: result.rng,
            events: result.events,
          )
        : null;
  }

  @override
  BattleEffectLifecycleResult? onLifecycle(
    BattleEffectLifecycleContext context,
  ) {
    if (context.phase != BattleEffectLifecyclePhase.removed ||
        context.owner != owner ||
        !context.state
            .battlerAt(context.owner)
            .effects
            .contains(neutralizingGasActivatedEffectId)) {
      return null;
    }
    final result = _findReplacementOrRestore(
      state: context.state,
      owner: context.owner,
      rng: context.rng,
      turn: context.turn,
    );
    return result.applied
        ? BattleEffectLifecycleResult(
            state: result.state,
            rng: result.rng,
            events: result.events,
          )
        : null;
  }
}

_NeutralizingGasResult _suppressAbilities({
  required PsdkBattleState state,
  required PsdkBattleSlotRef owner,
  required BattleRngStreams rng,
}) {
  var nextState = state;
  var applied = false;
  for (final slot in state.aliveSlots()) {
    final battler = nextState.battlerAt(slot);
    if (slot == owner ||
        battler.effects.contains('ability_suppressed') ||
        _normalizedAbilityId(battler.abilityId) == 'neutralizing_gas' ||
        !const BattleAbilityChangeHandler().canChangeAbility(
          state: nextState,
          target: slot,
        )) {
      continue;
    }
    nextState = nextState.updateBattler(
      slot,
      (current) => current.copyWith(
        effects: current.effects.addEffect(
          AbilitySuppressedEffect(
            scope: BattlerBattleEffectScope(slot),
            origin: 'neutralizing_gas',
          ),
        ),
      ),
    );
    applied = true;
  }

  final ownerBattler = nextState.battlerAt(owner);
  if (!ownerBattler.effects.contains(neutralizingGasActivatedEffectId)) {
    nextState = nextState.updateBattler(
      owner,
      (current) => current.copyWith(
        effects: current.effects.addEffect(
          GenericBattleEffect(
            id: neutralizingGasActivatedEffectId,
            scope: BattlerBattleEffectScope(owner),
          ),
        ),
      ),
    );
    applied = true;
  }

  return _NeutralizingGasResult(
    state: nextState,
    rng: rng,
    applied: applied,
  );
}

_NeutralizingGasResult _findReplacementOrRestore({
  required PsdkBattleState state,
  required PsdkBattleSlotRef owner,
  required BattleRngStreams rng,
  required int turn,
}) {
  final replacement = _replacementOwner(state: state, owner: owner);
  var nextState = _removeActivatedMarker(state, owner);
  if (replacement == null) {
    return _restoreAbilities(
      state: nextState,
      owner: owner,
      rng: rng,
      turn: turn,
    );
  }

  final result = nextState.battlerAt(replacement).effects.dispatchSwitchEvent(
        BattleEffectSwitchEventContext(
          state: nextState,
          rng: rng,
          turn: turn,
          owner: replacement,
          who: replacement,
          replacement: replacement,
        ),
      );
  return _NeutralizingGasResult(
    state: result.state,
    rng: result.rng,
    events: result.events,
    applied: result.applied || result.events.isNotEmpty || nextState != state,
  );
}

_NeutralizingGasResult _restoreAbilities({
  required PsdkBattleState state,
  required PsdkBattleSlotRef owner,
  required BattleRngStreams rng,
  required int turn,
}) {
  var nextState = state;
  var nextRng = rng;
  final restoredSlots = <PsdkBattleSlotRef>[];
  var applied = false;

  for (final slot in state.aliveSlots()) {
    final suppression = _neutralizingGasSuppression(nextState.battlerAt(slot));
    if (suppression == null) {
      continue;
    }
    nextState = nextState.updateBattler(
      slot,
      (current) => current.copyWith(
        effects: current.effects.remove(suppression.id),
      ),
    );
    restoredSlots.add(slot);
    applied = true;
  }

  nextState = _removeActivatedMarker(nextState, owner);
  final events = <PsdkBattleEvent>[];
  for (final slot in restoredSlots) {
    final result = nextState.battlerAt(slot).effects.dispatchSwitchEvent(
          BattleEffectSwitchEventContext(
            state: nextState,
            rng: nextRng,
            turn: turn,
            owner: slot,
            who: slot,
            replacement: slot,
          ),
        );
    nextState = result.state;
    nextRng = result.rng;
    events.addAll(result.events);
    applied = applied || result.applied || result.events.isNotEmpty;
  }

  return _NeutralizingGasResult(
    state: nextState,
    rng: nextRng,
    events: events,
    applied: applied,
  );
}

PsdkBattleState _removeActivatedMarker(
  PsdkBattleState state,
  PsdkBattleSlotRef owner,
) {
  if (!state
      .battlerAt(owner)
      .effects
      .contains(neutralizingGasActivatedEffectId)) {
    return state;
  }
  return state.updateBattler(
    owner,
    (current) => current.copyWith(
      effects: current.effects.remove(neutralizingGasActivatedEffectId),
    ),
  );
}

PsdkBattleSlotRef? _replacementOwner({
  required PsdkBattleState state,
  required PsdkBattleSlotRef owner,
}) {
  final candidates = <PsdkBattleSlotRef>[
    for (final slot in state.aliveSlots())
      if (slot != owner &&
          _normalizedAbilityId(state.battlerAt(slot).abilityId) ==
              'neutralizing_gas' &&
          !state.battlerAt(slot).effects.contains('ability_suppressed'))
        slot,
  ];
  if (candidates.isEmpty) {
    return null;
  }
  candidates.sort((left, right) {
    final speed = state
        .battlerAt(right)
        .effectiveStat('speed')
        .compareTo(state.battlerAt(left).effectiveStat('speed'));
    return speed == 0 ? _compareSlots(left, right) : speed;
  });
  return candidates.first;
}

AbilitySuppressedEffect? _neutralizingGasSuppression(
  PsdkBattleCombatant battler,
) {
  for (final effect in battler.effects.effects) {
    if (effect is AbilitySuppressedEffect &&
        effect.origin == 'neutralizing_gas') {
      return effect;
    }
  }
  return null;
}

int _compareSlots(PsdkBattleSlotRef left, PsdkBattleSlotRef right) {
  final bank = left.bank.compareTo(right.bank);
  return bank == 0 ? left.position.compareTo(right.position) : bank;
}

String _normalizedAbilityId(String? abilityId) {
  return abilityId?.trim().toLowerCase().replaceAll('-', '_') ?? '';
}

final class _NeutralizingGasResult {
  const _NeutralizingGasResult({
    required this.state,
    required this.rng,
    this.events = const <PsdkBattleEvent>[],
    this.applied = true,
  });

  final PsdkBattleState state;
  final BattleRngStreams rng;
  final List<PsdkBattleEvent> events;
  final bool applied;
}
