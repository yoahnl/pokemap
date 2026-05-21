import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../handler/battle_damage_handler.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_heal_handler.dart';
import '../../handler/battle_item_change_handler.dart';
import '../../handler/battle_stat_change_handler.dart';
import '../../move/battle_move_type_processor.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';
import 'item_effect.dart';

final class TypeReactiveStatItemEffect extends BattleItemEffect {
  const TypeReactiveStatItemEffect({
    required super.itemId,
    required super.scope,
    required this.triggerType,
    required this.stat,
  });

  final String triggerType;
  final String stat;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return this;
  }

  @override
  BattleEffectPostDamageResult? onPostDamage(
    BattleEffectPostDamageContext context,
  ) {
    final owner = this.owner;
    if (owner == null ||
        context.owner != owner ||
        context.target != owner ||
        context.damage <= 0 ||
        context.targetFainted ||
        context.move.type.toLowerCase() != triggerType) {
      return null;
    }
    final holder = _activeHolder(context.state.battlerAt(owner), itemId);
    if (holder == null) {
      return null;
    }

    final changed = const BattleStatChangeHandler().applyStatChange(
      context: BattleHandlerContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: owner,
      ),
      target: owner,
      stat: stat,
      stages: 1,
      move: context.move,
    );
    if (!changed.applied) {
      return null;
    }

    final consumed = const BattleItemChangeHandler().consumeHeldItem(
      context: BattleHandlerContext(
        state: changed.state,
        rng: changed.rng,
        turn: context.turn,
        user: owner,
      ),
      target: owner,
    );
    if (!consumed.applied) {
      return null;
    }
    return BattleEffectPostDamageResult(
      state: consumed.state,
      rng: consumed.rng,
      events: <PsdkBattleEvent>[
        ...changed.events,
        ...consumed.events,
      ],
    );
  }
}

final class WeaknessPolicyEffect extends BattleItemEffect {
  const WeaknessPolicyEffect({
    required BattleEffectScope scope,
  }) : super(itemId: 'weakness_policy', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return WeaknessPolicyEffect(scope: scope);
  }

  @override
  BattleEffectPostDamageResult? onPostDamage(
    BattleEffectPostDamageContext context,
  ) {
    final owner = this.owner;
    if (owner == null ||
        context.owner != owner ||
        context.target != owner ||
        context.damage <= 0 ||
        context.targetFainted) {
      return null;
    }
    final target = _activeHolder(context.state.battlerAt(owner), itemId);
    if (target == null || !_isSuperEffective(context, target)) {
      return null;
    }

    var nextState = context.state;
    var nextRng = context.rng;
    final events = <PsdkBattleEvent>[];
    for (final stat in const <String>['attack', 'specialAttack']) {
      final changed = const BattleStatChangeHandler().applyStatChange(
        context: BattleHandlerContext(
          state: nextState,
          rng: nextRng,
          turn: context.turn,
          user: owner,
        ),
        target: owner,
        stat: stat,
        stages: 2,
        move: context.move,
      );
      nextState = changed.state;
      nextRng = changed.rng;
      events.addAll(changed.events);
    }

    final consumed = const BattleItemChangeHandler().consumeHeldItem(
      context: BattleHandlerContext(
        state: nextState,
        rng: nextRng,
        turn: context.turn,
        user: owner,
      ),
      target: owner,
    );
    if (!consumed.applied) {
      return null;
    }
    return BattleEffectPostDamageResult(
      state: consumed.state,
      rng: consumed.rng,
      events: <PsdkBattleEvent>[
        ...events,
        ...consumed.events,
      ],
    );
  }

  bool _isSuperEffective(
    BattleEffectPostDamageContext context,
    PsdkBattleCombatant target,
  ) {
    final effectiveness = const BattleMoveTypeProcessor().resolveEffectiveness(
      moveType: context.move.type,
      targetTypes: target.types,
      extraTargetTypes: <String>[
        if (target.type3 != null) target.type3!,
        ...target.temporaryTypes,
      ],
    );
    return effectiveness.multiplier > 1;
  }
}

final class RockyHelmetEffect extends BattleItemEffect {
  const RockyHelmetEffect({
    required BattleEffectScope scope,
  }) : super(itemId: 'rocky_helmet', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return RockyHelmetEffect(scope: scope);
  }

  @override
  BattleEffectPostDamageResult? onPostDamage(
    BattleEffectPostDamageContext context,
  ) {
    final owner = this.owner;
    if (owner == null ||
        context.owner != owner ||
        context.target != owner ||
        context.user == owner ||
        context.damage <= 0 ||
        !context.move.flags.contact ||
        _isInertDamage(context.move.id)) {
      return null;
    }
    if (!_hasActiveHeldItem(context.state.battlerAt(owner), itemId)) {
      return null;
    }

    final attacker = context.state.battlerAt(context.user);
    if (attacker.isFainted) {
      return null;
    }

    final amount = (attacker.maxHp ~/ 6).clamp(1, attacker.currentHp).toInt();
    final damaged = const BattleDamageHandler().applyDamage(
      context: BattleHandlerContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: owner,
      ),
      target: context.user,
      moveId: 'item:rocky_helmet',
      rawDamage: amount,
    );
    if (!damaged.applied) {
      return null;
    }
    return BattleEffectPostDamageResult(
      state: damaged.state,
      rng: damaged.rng,
      events: damaged.events,
    );
  }
}

final class StickyBarbEffect extends BattleItemEffect {
  const StickyBarbEffect({
    required BattleEffectScope scope,
  }) : super(itemId: 'sticky_barb', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return StickyBarbEffect(scope: scope);
  }

  @override
  BattleEffectPostDamageResult? onPostDamage(
    BattleEffectPostDamageContext context,
  ) {
    final owner = this.owner;
    if (owner == null ||
        context.owner != owner ||
        context.target != owner ||
        context.user == owner ||
        context.damage <= 0 ||
        !context.move.flags.contact ||
        _isInertDamage(context.move.id)) {
      return null;
    }
    if (!_hasActiveHeldItem(context.state.battlerAt(owner), itemId)) {
      return null;
    }

    final attacker = context.state.battlerAt(context.user);
    if (attacker.isFainted || attacker.heldItemId != null) {
      return null;
    }

    final transferred = const BattleItemChangeHandler().changeHeldItem(
      context: BattleHandlerContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: owner,
      ),
      target: context.user,
      heldItemId: itemId,
    );
    final removed = const BattleItemChangeHandler().changeHeldItem(
      context: BattleHandlerContext(
        state: transferred.state,
        rng: transferred.rng,
        turn: context.turn,
        user: owner,
      ),
      target: owner,
      heldItemId: null,
    );
    return BattleEffectPostDamageResult(
      state: removed.state,
      rng: removed.rng,
      events: <PsdkBattleEvent>[
        ...transferred.events,
        ...removed.events,
      ],
    );
  }

  @override
  BattleEffectEndTurnResult? onEndTurn(BattleEffectEndTurnContext context) {
    final owner = context.owner;
    if (!isOwnedBy(owner)) {
      return null;
    }
    final holder = context.state.battlerAt(owner);
    if (!_hasActiveHeldItem(holder, itemId) ||
        holder.isFainted ||
        holder.abilityId == 'magic_guard') {
      return null;
    }

    final amount = (holder.maxHp ~/ 8).clamp(1, holder.currentHp).toInt();
    final damaged = const BattleDamageHandler().applyDamage(
      context: BattleHandlerContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: owner,
      ),
      target: owner,
      moveId: 'item:sticky_barb',
      rawDamage: amount,
    );
    if (!damaged.applied) {
      return null;
    }
    return BattleEffectEndTurnResult(
      state: damaged.state,
      rng: damaged.rng,
      events: damaged.events,
    );
  }
}

final class ShellBellEffect extends BattleItemEffect {
  const ShellBellEffect({
    required BattleEffectScope scope,
  }) : super(itemId: 'shell_bell', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return ShellBellEffect(scope: scope);
  }

  @override
  BattleEffectPostDamageResult? onPostDamage(
    BattleEffectPostDamageContext context,
  ) {
    final owner = this.owner;
    if (owner == null ||
        context.owner != owner ||
        context.user != owner ||
        context.target == owner ||
        context.damage < 8 ||
        _isInertDamage(context.move.id)) {
      return null;
    }
    final holder = _activeHolder(context.state.battlerAt(owner), itemId);
    if (holder == null || holder.currentHp >= holder.maxHp) {
      return null;
    }

    final amount = context.damage ~/ 8;
    final healed = const BattleHealHandler().heal(
      context: BattleHandlerContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: owner,
      ),
      target: owner,
      amount: amount,
    );
    if (!healed.applied) {
      return null;
    }

    final current = healed.state.battlerAt(owner);
    return BattleEffectPostDamageResult(
      state: healed.state,
      rng: healed.rng,
      events: <PsdkBattleEvent>[
        PsdkBattleHealEvent(
          user: owner,
          target: owner,
          moveId: 'item:shell_bell',
          amount: healed.amount,
          remainingHp: current.currentHp,
        ),
      ],
    );
  }
}

final class ThroatSprayEffect extends BattleItemEffect {
  const ThroatSprayEffect({
    required BattleEffectScope scope,
  }) : super(itemId: 'throat_spray', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return ThroatSprayEffect(scope: scope);
  }

  @override
  BattleEffectPostActionResult? onPostAction(
    BattleEffectPostActionContext context,
  ) {
    final owner = this.owner;
    if (owner == null ||
        context.owner != owner ||
        context.user != owner ||
        !context.successful ||
        !context.move.flags.sound) {
      return null;
    }
    final holder = _activeHolder(context.state.battlerAt(owner), itemId);
    if (holder == null) {
      return null;
    }

    final changed = const BattleStatChangeHandler().applyStatChange(
      context: BattleHandlerContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: owner,
      ),
      target: owner,
      stat: 'specialAttack',
      stages: 1,
      move: context.move,
    );
    if (!changed.applied) {
      return null;
    }

    final consumed = const BattleItemChangeHandler().consumeHeldItem(
      context: BattleHandlerContext(
        state: changed.state,
        rng: changed.rng,
        turn: context.turn,
        user: owner,
      ),
      target: owner,
    );
    if (!consumed.applied) {
      return null;
    }

    return BattleEffectPostActionResult(
      state: consumed.state,
      rng: consumed.rng,
      events: <PsdkBattleEvent>[
        ...changed.events,
        ...consumed.events,
      ],
    );
  }
}

final class MirrorHerbEffect extends BattleItemEffect {
  const MirrorHerbEffect({
    required BattleEffectScope scope,
  }) : super(itemId: 'mirror_herb', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return MirrorHerbEffect(scope: scope);
  }

  @override
  BattleEffectStatChangePostResult? onStatChangePost(
    BattleEffectStatChangeContext context,
  ) {
    final owner = this.owner;
    if (owner == null ||
        context.owner != owner ||
        context.owner.bank == context.target.bank ||
        context.stages <= 0 ||
        context.sourceAbilityId == itemId) {
      return null;
    }
    final holder = _activeHolder(context.state.battlerAt(owner), itemId);
    if (holder == null) {
      return null;
    }

    final pending = _findMirrorHerbPending(holder, owner)
        .record(stat: context.stat, stages: context.stages);
    final nextState = context.state.updateBattler(
      owner,
      (current) => current.copyWith(
        effects: current.effects.addEffect(pending),
      ),
    );
    return BattleEffectStatChangePostResult(
      state: nextState,
      rng: context.rng,
    );
  }

  @override
  BattleEffectPostActionResult? onPostAction(
    BattleEffectPostActionContext context,
  ) {
    final owner = this.owner;
    if (owner == null || context.owner != owner || !context.successful) {
      return null;
    }
    final holder = _activeHolder(context.state.battlerAt(owner), itemId);
    final pending = holder == null ? null : _existingMirrorHerbPending(holder);
    if (holder == null || pending == null) {
      return null;
    }

    final consumed = const BattleItemChangeHandler().consumeHeldItem(
      context: BattleHandlerContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: owner,
      ),
      target: owner,
    );
    if (!consumed.applied) {
      return null;
    }

    var nextState = consumed.state.updateBattler(
      owner,
      (current) => current.copyWith(
        effects: current.effects.remove(_mirrorHerbPendingEffectId),
      ),
    );
    var nextRng = consumed.rng;
    final events = <PsdkBattleEvent>[...consumed.events];
    for (final boost in pending.boosts) {
      final copied = const BattleStatChangeHandler().applyStatChange(
        context: BattleHandlerContext(
          state: nextState,
          rng: nextRng,
          turn: context.turn,
          user: owner,
        ),
        target: owner,
        stat: boost.stat,
        stages: boost.stages,
        sourceAbilityId: itemId,
      );
      nextState = copied.state;
      nextRng = copied.rng;
      events.addAll(copied.events);
    }

    return BattleEffectPostActionResult(
      state: nextState,
      rng: nextRng,
      events: events,
    );
  }
}

const _mirrorHerbPendingEffectId = 'mirror_herb_pending';

final class _MirrorHerbPendingEffect extends BattleEffect {
  const _MirrorHerbPendingEffect({
    required super.scope,
    required this.boosts,
  }) : super(id: _mirrorHerbPendingEffectId);

  final List<_MirrorHerbBoost> boosts;

  _MirrorHerbPendingEffect record({
    required String stat,
    required int stages,
  }) {
    return _MirrorHerbPendingEffect(
      scope: scope,
      boosts: List<_MirrorHerbBoost>.unmodifiable(<_MirrorHerbBoost>[
        ...boosts,
        _MirrorHerbBoost(stat: stat, stages: stages),
      ]),
    );
  }

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return this;
  }
}

final class _MirrorHerbBoost {
  const _MirrorHerbBoost({
    required this.stat,
    required this.stages,
  });

  final String stat;
  final int stages;
}

_MirrorHerbPendingEffect _findMirrorHerbPending(
  PsdkBattleCombatant holder,
  PsdkBattleSlotRef owner,
) {
  return _existingMirrorHerbPending(holder) ??
      _MirrorHerbPendingEffect(
        scope: BattlerBattleEffectScope(owner),
        boosts: const <_MirrorHerbBoost>[],
      );
}

_MirrorHerbPendingEffect? _existingMirrorHerbPending(
  PsdkBattleCombatant holder,
) {
  for (final effect in holder.effects.effects) {
    if (effect is _MirrorHerbPendingEffect) {
      return effect;
    }
  }
  return null;
}

PsdkBattleCombatant? _activeHolder(PsdkBattleCombatant battler, String itemId) {
  if (battler.isFainted || !_hasActiveHeldItem(battler, itemId)) {
    return null;
  }
  return battler;
}

bool _hasActiveHeldItem(PsdkBattleCombatant battler, String itemId) {
  return battler.heldItemId == itemId &&
      !battler.itemConsumed &&
      !battler.itemEffectsSuppressed;
}

bool _isInertDamage(String moveId) {
  return moveId.startsWith('item:') || moveId.startsWith('status:');
}
