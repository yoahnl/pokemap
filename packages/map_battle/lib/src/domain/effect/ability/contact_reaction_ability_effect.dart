import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_move.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../psdk/domain/psdk_battle_state.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../handler/battle_ability_change_handler.dart';
import '../../handler/battle_handler_context.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';
import '../move/perish_song_effect.dart';
import '../side/hazard_effects.dart';
import 'ability_effect.dart';

final class ColorChangeEffect extends BattleAbilityEffect {
  const ColorChangeEffect({
    required BattleEffectScope scope,
  }) : super(abilityId: 'color_change', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return ColorChangeEffect(scope: scope);
  }

  @override
  BattleEffectPostDamageResult? onPostDamage(
    BattleEffectPostDamageContext context,
  ) {
    if (context.owner != context.target ||
        context.user == context.target ||
        context.damage <= 0 ||
        context.targetFainted ||
        context.move.category == PsdkBattleMoveCategory.status) {
      return null;
    }

    final moveType = _normalizedId(context.move.type);
    if (moveType.isEmpty ||
        context.state.battlerAt(context.owner).hasType(moveType)) {
      return null;
    }

    return BattleEffectPostDamageResult(
      state: context.state.updateBattler(
        context.owner,
        (battler) => battler.copyWith(
          types: PsdkBattleTypes(primary: moveType),
          type3: null,
          temporaryTypes: const <String>[],
        ),
      ),
      rng: context.rng,
      events: <PsdkBattleEvent>[
        PsdkBattleEffectEvent.added(
          turn: context.turn,
          target: context.owner,
          effectId: 'color_change:$moveType',
          reason: 'ability:color_change',
        ),
      ],
    );
  }
}

final class PerishBodyEffect extends BattleAbilityEffect {
  const PerishBodyEffect({
    required BattleEffectScope scope,
  }) : super(abilityId: 'perish_body', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return PerishBodyEffect(scope: scope);
  }

  @override
  BattleEffectPostDamageResult? onPostDamage(
    BattleEffectPostDamageContext context,
  ) {
    if (context.owner != context.target ||
        context.user == context.target ||
        context.damage <= 0 ||
        context.targetFainted ||
        !_madeContact(context)) {
      return null;
    }

    final target = context.state.battlerAt(context.owner);
    final user = context.state.battlerAt(context.user);
    if (target.effects.contains('perish_song') ||
        user.effects.contains('perish_song')) {
      return null;
    }

    var nextState = context.state.updateBattler(
      context.owner,
      (battler) => battler.copyWith(
        effects: battler.effects.addEffect(
          PerishSongEffect(
            scope: BattlerBattleEffectScope(context.owner),
            remainingTurns: 4,
          ),
        ),
      ),
    );
    nextState = nextState.updateBattler(
      context.user,
      (battler) => battler.copyWith(
        effects: battler.effects.addEffect(
          PerishSongEffect(
            scope: BattlerBattleEffectScope(context.user),
            remainingTurns: 4,
          ),
        ),
      ),
    );

    return BattleEffectPostDamageResult(
      state: nextState,
      rng: context.rng,
      events: <PsdkBattleEvent>[
        PsdkBattleEffectEvent.added(
          turn: context.turn,
          target: context.owner,
          effectId: 'perish_song',
          remainingTurns: 4,
          reason: 'ability:perish_body',
        ),
        PsdkBattleEffectEvent.added(
          turn: context.turn,
          target: context.user,
          effectId: 'perish_song',
          remainingTurns: 4,
          reason: 'ability:perish_body',
        ),
      ],
    );
  }
}

final class ToxicDebrisEffect extends BattleAbilityEffect {
  const ToxicDebrisEffect({
    required BattleEffectScope scope,
  }) : super(abilityId: 'toxic_debris', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return ToxicDebrisEffect(scope: scope);
  }

  @override
  BattleEffectPostDamageResult? onPostDamage(
    BattleEffectPostDamageContext context,
  ) {
    if (context.owner != context.target ||
        context.user == context.target ||
        context.damage <= 0 ||
        context.targetFainted ||
        context.move.category != PsdkBattleMoveCategory.physical) {
      return null;
    }

    final hazard = ToxicSpikesEffect(bank: context.user.bank);
    final nextState = _addOrEmpowerHazard(
      state: context.state,
      fallbackOwner: context.owner,
      hazard: hazard,
    );
    if (identical(nextState, context.state)) {
      return null;
    }
    return BattleEffectPostDamageResult(
      state: nextState,
      rng: context.rng,
      events: <PsdkBattleEvent>[
        PsdkBattleEffectEvent.added(
          turn: context.turn,
          target: context.user,
          effectId: 'toxic_spikes',
          reason: 'ability:toxic_debris',
        ),
      ],
    );
  }
}

final class ContactAbilityChangeEffect extends BattleAbilityEffect {
  const ContactAbilityChangeEffect({
    required String abilityId,
    required BattleEffectScope scope,
  }) : super(abilityId: abilityId, scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return ContactAbilityChangeEffect(
      abilityId: abilityId,
      scope: scope,
    );
  }

  @override
  BattleEffectPostDamageResult? onPostDamage(
    BattleEffectPostDamageContext context,
  ) {
    if (context.owner != context.target ||
        context.user == context.target ||
        context.damage <= 0 ||
        !_madeContact(context)) {
      return null;
    }

    final user = context.state.battlerAt(context.user);
    if (user.isFainted || _isMummyFamily(user.abilityId)) {
      return null;
    }

    const handler = BattleAbilityChangeHandler();
    if (!handler.canChangeAbility(
      state: context.state,
      target: context.user,
      launcher: context.owner,
    )) {
      return null;
    }

    final changed = handler.changeAbility(
      context: BattleHandlerContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: context.owner,
      ),
      target: context.user,
      abilityId: abilityId,
      triggerSwitchEvent: true,
    );
    if (!changed.applied && changed.events.isEmpty) {
      return null;
    }
    return BattleEffectPostDamageResult(
      state: changed.state,
      rng: changed.rng,
      events: changed.events,
    );
  }
}

final class WanderingSpiritEffect extends BattleAbilityEffect {
  const WanderingSpiritEffect({
    required BattleEffectScope scope,
  }) : super(abilityId: 'wandering_spirit', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return WanderingSpiritEffect(scope: scope);
  }

  @override
  BattleEffectPostDamageResult? onPostDamage(
    BattleEffectPostDamageContext context,
  ) {
    if (context.owner != context.target ||
        context.user == context.target ||
        context.damage <= 0 ||
        !_madeContact(context)) {
      return null;
    }

    final user = context.state.battlerAt(context.user);
    final owner = context.state.battlerAt(context.owner);
    if (user.isFainted || _normalizedId(user.abilityId) == 'wandering_spirit') {
      return null;
    }

    const handler = BattleAbilityChangeHandler();
    if (!handler.canChangeAbility(
          state: context.state,
          target: context.user,
          launcher: context.owner,
        ) ||
        !handler.canChangeAbility(
          state: context.state,
          target: context.owner,
          launcher: context.user,
        )) {
      return null;
    }

    final ownerAbilityId = owner.abilityId;
    final userAbilityId = user.abilityId;
    var changed = handler.changeAbility(
      context: BattleHandlerContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: context.owner,
      ),
      target: context.user,
      abilityId: ownerAbilityId,
    );
    var nextState = changed.state;
    var nextRng = changed.rng;
    final events = <PsdkBattleEvent>[...changed.events];

    changed = handler.changeAbility(
      context: BattleHandlerContext(
        state: nextState,
        rng: nextRng,
        turn: context.turn,
        user: context.user,
      ),
      target: context.owner,
      abilityId: userAbilityId,
    );
    nextState = changed.state;
    nextRng = changed.rng;
    events.addAll(changed.events);

    final ownerSwitch =
        nextState.battlerAt(context.owner).effects.dispatchSwitchEvent(
              BattleEffectSwitchEventContext(
                state: nextState,
                rng: nextRng,
                turn: context.turn,
                owner: context.owner,
                who: context.owner,
                replacement: context.owner,
              ),
            );
    nextState = ownerSwitch.state;
    nextRng = ownerSwitch.rng;
    events.addAll(ownerSwitch.events);

    final userSwitch =
        nextState.battlerAt(context.user).effects.dispatchSwitchEvent(
              BattleEffectSwitchEventContext(
                state: nextState,
                rng: nextRng,
                turn: context.turn,
                owner: context.user,
                who: context.user,
                replacement: context.user,
              ),
            );
    nextState = userSwitch.state;
    nextRng = userSwitch.rng;
    events.addAll(userSwitch.events);

    return BattleEffectPostDamageResult(
      state: nextState,
      rng: nextRng,
      events: events,
      applied: true,
    );
  }
}

bool _madeContact(BattleEffectPostDamageContext context) {
  if (!context.move.flags.contact) {
    return false;
  }
  final user = context.state.battlerAt(context.user);
  if (_normalizedId(user.abilityId) == 'long_reach') {
    return false;
  }
  return _normalizedId(user.heldItemId) != 'punching_glove' ||
      !context.move.flags.punch;
}

bool _isMummyFamily(String? abilityId) {
  return switch (_normalizedId(abilityId)) {
    'mummy' || 'lingering_aroma' => true,
    _ => false,
  };
}

String _normalizedId(String? id) {
  return id?.trim().toLowerCase() ?? '';
}

PsdkBattleState _addOrEmpowerHazard({
  required PsdkBattleState state,
  required PsdkBattleSlotRef fallbackOwner,
  required ToxicSpikesEffect hazard,
}) {
  final location = _firstBankEffectWithId(state, hazard);
  if (location != null) {
    if (location.effect.layers >= 2) {
      return state;
    }
    return state.updateBattler(
      location.owner,
      (battler) => battler.copyWith(
        effects: battler.effects.addEffect(location.effect.empower()),
      ),
    );
  }
  return state.updateBattler(
    fallbackOwner,
    (battler) => battler.copyWith(
      effects: battler.effects.addEffect(hazard),
    ),
  );
}

({PsdkBattleSlotRef owner, ToxicSpikesEffect effect})? _firstBankEffectWithId(
  PsdkBattleState state,
  ToxicSpikesEffect hazard,
) {
  for (final entry in state.combatants.entries) {
    for (final effect in entry.value.effects.effects) {
      final scope = effect.scope;
      if (effect.id == hazard.id &&
          effect is ToxicSpikesEffect &&
          scope is BankBattleEffectScope &&
          scope.bank == hazard.bank) {
        return (owner: entry.key, effect: effect);
      }
    }
  }
  return null;
}
