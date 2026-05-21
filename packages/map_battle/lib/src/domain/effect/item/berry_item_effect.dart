import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_move.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../psdk/domain/psdk_battle_state.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../handler/battle_damage_handler.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_handler_result.dart';
import '../../handler/battle_heal_handler.dart';
import '../../handler/battle_item_change_handler.dart';
import '../../handler/battle_stat_change_handler.dart';
import '../../handler/battle_status_change_handler.dart';
import '../../move/battle_move_type_processor.dart';
import '../../rng/battle_rng_streams.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';
import 'item_effect.dart';

enum BerryItemEffectKind {
  hpHeal,
  statusCure,
  statPinch,
}

final class BerryItemEffect extends BattleItemEffect {
  const BerryItemEffect.hpHeal({
    required String itemId,
    required BattleEffectScope scope,
    required int Function(PsdkBattleCombatant battler) healAmount,
    double Function(PsdkBattleCombatant battler) hpThreshold = _halfHpThreshold,
    bool mayConfuseFromNature = false,
  })  : kind = BerryItemEffectKind.hpHeal,
        _healAmount = healAmount,
        _hpThreshold = hpThreshold,
        _curedStatuses = const <PsdkBattleMajorStatus>{},
        _curesConfusion = false,
        _stat = null,
        _mayConfuseFromNature = mayConfuseFromNature,
        super(itemId: itemId, scope: scope);

  const BerryItemEffect.statusCure({
    required String itemId,
    required BattleEffectScope scope,
    required Set<PsdkBattleMajorStatus> statuses,
    bool curesConfusion = false,
  })  : kind = BerryItemEffectKind.statusCure,
        _healAmount = null,
        _hpThreshold = null,
        _curedStatuses = statuses,
        _curesConfusion = curesConfusion,
        _stat = null,
        _mayConfuseFromNature = false,
        super(itemId: itemId, scope: scope);

  const BerryItemEffect.statPinch({
    required String itemId,
    required BattleEffectScope scope,
    required String stat,
    double Function(PsdkBattleCombatant battler) hpThreshold = _pinchThreshold,
    bool mayConfuseFromNature = false,
  })  : kind = BerryItemEffectKind.statPinch,
        _healAmount = null,
        _hpThreshold = hpThreshold,
        _curedStatuses = const <PsdkBattleMajorStatus>{},
        _curesConfusion = false,
        _stat = stat,
        _mayConfuseFromNature = mayConfuseFromNature,
        super(itemId: itemId, scope: scope);

  final BerryItemEffectKind kind;
  final int Function(PsdkBattleCombatant battler)? _healAmount;
  final double Function(PsdkBattleCombatant battler)? _hpThreshold;
  final Set<PsdkBattleMajorStatus> _curedStatuses;
  final bool _curesConfusion;
  final String? _stat;
  final bool _mayConfuseFromNature;

  bool get mayConfuseFromNature => _mayConfuseFromNature;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return this;
  }

  BattleEffectEndTurnResult? forceExecute({
    required PsdkBattleState state,
    required BattleRngStreams rng,
    required int turn,
    required PsdkBattleSlotRef owner,
  }) {
    final battler = state.battlerAt(owner);
    if (battler.isFainted || battler.itemEffectsSuppressed) {
      return null;
    }
    return switch (kind) {
      BerryItemEffectKind.hpHeal => _forceHpHeal(
          state: state,
          rng: rng,
          turn: turn,
          owner: owner,
        ),
      BerryItemEffectKind.statPinch => _forceStatPinch(
          state: state,
          rng: rng,
          turn: turn,
          owner: owner,
        ),
      BerryItemEffectKind.statusCure => _forceStatusCure(
          state: state,
          rng: rng,
          turn: turn,
          owner: owner,
        ),
    };
  }

  @override
  BattleEffectEndTurnResult? onEndTurn(BattleEffectEndTurnContext context) {
    final owner = context.owner;
    if (!isOwnedBy(owner)) {
      return null;
    }
    return switch (kind) {
      BerryItemEffectKind.hpHeal => _triggerHpHeal(
          state: context.state,
          rng: context.rng,
          turn: context.turn,
          owner: owner,
        ),
      BerryItemEffectKind.statPinch => _triggerStatPinch(
          state: context.state,
          rng: context.rng,
          turn: context.turn,
          owner: owner,
        ),
      BerryItemEffectKind.statusCure => null,
    };
  }

  @override
  BattleEffectPostDamageResult? onPostDamage(
    BattleEffectPostDamageContext context,
  ) {
    final owner = context.owner;
    if (!isOwnedBy(owner) ||
        context.target != owner ||
        context.targetFainted ||
        context.damage <= 0) {
      return null;
    }

    return switch (kind) {
      BerryItemEffectKind.hpHeal => context.move.battleEngineMethod == 's_pluck'
          ? null
          : _triggerHpHeal(
              state: context.state,
              rng: context.rng,
              turn: context.turn,
              owner: owner,
            )?.toPostDamageResult(),
      BerryItemEffectKind.statPinch => _triggerStatPinch(
          state: context.state,
          rng: context.rng,
          turn: context.turn,
          owner: owner,
        )?.toPostDamageResult(),
      BerryItemEffectKind.statusCure => null,
    };
  }

  @override
  BattleEffectStatusChangeResult? onPostStatusChange(
    BattleEffectStatusChangeContext context,
  ) {
    final owner = context.owner;
    if (kind != BerryItemEffectKind.statusCure ||
        context.cured ||
        context.moveId == 'rest' ||
        !isOwnedBy(owner) ||
        context.target != owner ||
        !_curedStatuses.contains(context.status)) {
      return null;
    }

    final battler = context.state.battlerAt(owner);
    if (!_canConsume(state: context.state, owner: owner, battler: battler)) {
      return null;
    }

    final consumed = _consume(
      state: context.state,
      rng: context.rng,
      turn: context.turn,
      owner: owner,
    );
    if (consumed == null) {
      return null;
    }

    final cured = const BattleStatusChangeHandler().cureMajorStatus(
      context: BattleHandlerContext(
        state: consumed.state,
        rng: consumed.rng,
        turn: context.turn,
        user: owner,
      ),
      target: owner,
      moveId: context.moveId ?? 'item:$itemId',
    );
    final confusionCured = _cureConfusion(
      state: cured.state,
      rng: cured.rng,
      turn: context.turn,
      owner: owner,
      moveId: context.moveId ?? 'item:$itemId',
    );
    return BattleEffectStatusChangeResult(
      state: confusionCured.state,
      rng: confusionCured.rng,
      events: <PsdkBattleEvent>[
        ...consumed.events,
        ...cured.events,
        ...confusionCured.events,
      ],
      applied: consumed.applied || cured.applied || confusionCured.applied,
    );
  }

  @override
  BattleEffectVolatileStatusChangeResult? onPostVolatileStatusChange(
    BattleEffectVolatileStatusChangeContext context,
  ) {
    final owner = context.owner;
    if (kind != BerryItemEffectKind.statusCure ||
        !_curesConfusion ||
        context.cured ||
        context.effectId != 'confusion' ||
        !isOwnedBy(owner) ||
        context.target != owner) {
      return null;
    }

    final battler = context.state.battlerAt(owner);
    if (!_canConsume(state: context.state, owner: owner, battler: battler)) {
      return null;
    }

    final consumed = _consume(
      state: context.state,
      rng: context.rng,
      turn: context.turn,
      owner: owner,
    );
    if (consumed == null) {
      return null;
    }

    final cured = _cureConfusion(
      state: consumed.state,
      rng: consumed.rng,
      turn: context.turn,
      owner: owner,
      moveId: context.moveId ?? 'item:$itemId',
    );
    return BattleEffectVolatileStatusChangeResult(
      state: cured.state,
      rng: cured.rng,
      events: <PsdkBattleEvent>[
        ...consumed.events,
        ...cured.events,
      ],
      applied: consumed.applied || cured.applied,
    );
  }

  BattleEffectEndTurnResult? _triggerHpHeal({
    required PsdkBattleState state,
    required BattleRngStreams rng,
    required int turn,
    required PsdkBattleSlotRef owner,
  }) {
    final battler = state.battlerAt(owner);
    if (!_canConsume(state: state, owner: owner, battler: battler) ||
        !_isAtThreshold(battler)) {
      return null;
    }

    final amount = _healAmount!(battler);
    final healed = const BattleHealHandler().heal(
      context: BattleHandlerContext(
        state: state,
        rng: rng,
        turn: turn,
        user: owner,
      ),
      target: owner,
      amount: amount,
    );
    if (!healed.applied) {
      return null;
    }

    final consumed = _consume(
      state: healed.state,
      rng: healed.rng,
      turn: turn,
      owner: owner,
    );
    if (consumed == null) {
      return null;
    }

    final current = healed.state.battlerAt(owner);
    return BattleEffectEndTurnResult(
      state: consumed.state,
      rng: consumed.rng,
      events: <PsdkBattleEvent>[
        PsdkBattleHealEvent(
          user: owner,
          target: owner,
          moveId: 'item:$itemId',
          amount: healed.amount,
          remainingHp: current.currentHp,
        ),
        ...consumed.events,
      ],
    );
  }

  BattleEffectEndTurnResult? _forceHpHeal({
    required PsdkBattleState state,
    required BattleRngStreams rng,
    required int turn,
    required PsdkBattleSlotRef owner,
  }) {
    final battler = state.battlerAt(owner);
    final healed = const BattleHealHandler().heal(
      context: BattleHandlerContext(
        state: state,
        rng: rng,
        turn: turn,
        user: owner,
      ),
      target: owner,
      amount: _healAmount!(battler),
    );
    if (!healed.applied) {
      return null;
    }

    final current = healed.state.battlerAt(owner);
    return BattleEffectEndTurnResult(
      state: healed.state,
      rng: healed.rng,
      events: <PsdkBattleEvent>[
        PsdkBattleHealEvent(
          user: owner,
          target: owner,
          moveId: 'item:$itemId',
          amount: healed.amount,
          remainingHp: current.currentHp,
        ),
      ],
    );
  }

  BattleEffectEndTurnResult? _triggerStatPinch({
    required PsdkBattleState state,
    required BattleRngStreams rng,
    required int turn,
    required PsdkBattleSlotRef owner,
  }) {
    final battler = state.battlerAt(owner);
    if (!_canConsume(state: state, owner: owner, battler: battler) ||
        !_isAtThreshold(battler)) {
      return null;
    }

    final consumed = _consume(
      state: state,
      rng: rng,
      turn: turn,
      owner: owner,
    );
    if (consumed == null) {
      return null;
    }

    final stat = _stat == 'random' ? _randomStat(consumed.rng) : _stat!;
    final statRng = _stat == 'random' ? _advanceRandomStat(consumed.rng) : null;
    final changed = const BattleStatChangeHandler().applyStatChange(
      context: BattleHandlerContext(
        state: consumed.state,
        rng: statRng ?? consumed.rng,
        turn: turn,
        user: owner,
      ),
      target: owner,
      stat: stat,
      stages: battler.abilityId == 'ripen' ? 2 : 1,
    );
    return BattleEffectEndTurnResult(
      state: changed.state,
      rng: changed.rng,
      events: <PsdkBattleEvent>[
        ...consumed.events,
        ...changed.events,
      ],
      applied: consumed.applied || changed.applied,
    );
  }

  BattleEffectEndTurnResult _forceStatPinch({
    required PsdkBattleState state,
    required BattleRngStreams rng,
    required int turn,
    required PsdkBattleSlotRef owner,
  }) {
    final battler = state.battlerAt(owner);
    final stat = _stat == 'random' ? _randomStat(rng) : _stat!;
    final statRng = _stat == 'random' ? _advanceRandomStat(rng) : null;
    final changed = const BattleStatChangeHandler().applyStatChange(
      context: BattleHandlerContext(
        state: state,
        rng: statRng ?? rng,
        turn: turn,
        user: owner,
      ),
      target: owner,
      stat: stat,
      stages: battler.abilityId == 'ripen' ? 2 : 1,
    );
    return BattleEffectEndTurnResult(
      state: changed.state,
      rng: changed.rng,
      events: changed.events,
      applied: changed.applied,
    );
  }

  BattleEffectEndTurnResult? _forceStatusCure({
    required PsdkBattleState state,
    required BattleRngStreams rng,
    required int turn,
    required PsdkBattleSlotRef owner,
  }) {
    final status = state.battlerAt(owner).majorStatus;
    if ((status == null || !_curedStatuses.contains(status)) &&
        !(_curesConfusion &&
            state.battlerAt(owner).effects.contains('confusion'))) {
      return null;
    }
    final cured = status == null || !_curedStatuses.contains(status)
        ? BattleHandlerResult(state: state, rng: rng, applied: false)
        : const BattleStatusChangeHandler().cureMajorStatus(
            context: BattleHandlerContext(
              state: state,
              rng: rng,
              turn: turn,
              user: owner,
            ),
            target: owner,
            moveId: 'item:$itemId',
          );
    final confusionCured = _cureConfusion(
      state: cured.state,
      rng: cured.rng,
      turn: turn,
      owner: owner,
      moveId: 'item:$itemId',
    );
    if (!cured.applied && !confusionCured.applied) {
      return null;
    }
    return BattleEffectEndTurnResult(
      state: confusionCured.state,
      rng: confusionCured.rng,
      events: <PsdkBattleEvent>[
        ...cured.events,
        ...confusionCured.events,
      ],
    );
  }

  BattleEffectEndTurnResult _cureConfusion({
    required PsdkBattleState state,
    required BattleRngStreams rng,
    required int turn,
    required PsdkBattleSlotRef owner,
    required String moveId,
  }) {
    if (!_curesConfusion ||
        !state.battlerAt(owner).effects.contains('confusion')) {
      return BattleEffectEndTurnResult(
        state: state,
        rng: rng,
        applied: false,
      );
    }
    return BattleEffectEndTurnResult(
      state: state.updateBattler(
        owner,
        (battler) => battler.copyWith(
          effects: battler.effects.remove('confusion'),
        ),
      ),
      rng: rng,
      events: <PsdkBattleEvent>[
        PsdkBattleEffectEvent.removed(
          turn: turn,
          target: owner,
          effectId: 'confusion',
          reason: moveId,
        ),
      ],
    );
  }

  bool _canConsume({
    required PsdkBattleState state,
    required PsdkBattleSlotRef owner,
    required PsdkBattleCombatant battler,
  }) {
    return !battler.isFainted &&
        battler.heldItemId == itemId &&
        !battler.itemConsumed &&
        !battler.itemEffectsSuppressed &&
        !psdkBerryBlockedByOpposingUnnerve(state: state, owner: owner);
  }

  bool _isAtThreshold(PsdkBattleCombatant battler) {
    return battler.currentHp / battler.maxHp <= _hpThreshold!(battler);
  }

  BattleEffectEndTurnResult? _consume({
    required PsdkBattleState state,
    required BattleRngStreams rng,
    required int turn,
    required PsdkBattleSlotRef owner,
  }) {
    final consumed = const BattleItemChangeHandler().consumeHeldItem(
      context: BattleHandlerContext(
        state: state,
        rng: rng,
        turn: turn,
        user: owner,
      ),
      target: owner,
    );
    if (!consumed.applied) {
      return null;
    }
    return BattleEffectEndTurnResult(
      state: consumed.state,
      rng: consumed.rng,
      events: consumed.events,
    );
  }
}

final class TypeResistingBerryEffect extends BattleItemEffect {
  const TypeResistingBerryEffect({
    required String itemId,
    required BattleEffectScope scope,
    required this.resistedType,
  }) : super(itemId: itemId, scope: scope);

  final String resistedType;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return this;
  }

  @override
  double damageFinalMultiplier(BattleItemDamageModifierContext context) {
    if (!_canConsumeTarget(context.target) ||
        _blockedByUnnerve(context) ||
        !_triggers(context)) {
      return 1;
    }
    return context.target.abilityId == 'ripen' ? 0.25 : 0.5;
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
        !_postDamageTriggers(context)) {
      return null;
    }

    final consumed = _consumeHeldBerry(
      state: context.state,
      rng: context.rng,
      turn: context.turn,
      owner: owner,
    );
    if (consumed == null) {
      return null;
    }
    return consumed.toPostDamageResult();
  }

  bool _triggers(BattleItemDamageModifierContext context) {
    if (context.move.power <= 0 || context.moveType != resistedType) {
      return false;
    }
    return resistedType == 'normal' || context.typeEffectivenessMultiplier > 1;
  }

  bool _postDamageTriggers(BattleEffectPostDamageContext context) {
    final target = context.state.battlerAt(context.target);
    if (!_canConsumeTarget(target) ||
        psdkBerryBlockedByOpposingUnnerve(
          state: context.state,
          owner: context.target,
        ) ||
        context.move.power <= 0 ||
        context.move.type.toLowerCase() != resistedType) {
      return false;
    }
    if (resistedType == 'normal') {
      return true;
    }
    return _isSuperEffective(
      moveType: resistedType,
      target: target,
    );
  }

  bool _canConsumeTarget(PsdkBattleCombatant target) {
    return !target.isFainted &&
        target.heldItemId == itemId &&
        !target.itemConsumed &&
        !target.itemEffectsSuppressed;
  }

  bool _blockedByUnnerve(BattleItemDamageModifierContext context) {
    final state = context.state;
    final targetSlot = context.targetSlot;
    if (state != null && targetSlot != null) {
      return psdkBerryBlockedByOpposingUnnerve(
        state: state,
        owner: targetSlot,
      );
    }
    return psdkBerryBlockedByDirectUnnerve(context.user);
  }
}

final class EnigmaBerryEffect extends BattleItemEffect {
  const EnigmaBerryEffect({
    required BattleEffectScope scope,
  }) : super(itemId: 'enigma_berry', scope: scope);

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
        context.targetFainted) {
      return null;
    }
    final target = context.state.battlerAt(owner);
    if (target.heldItemId != itemId ||
        !psdkCanConsumeBerry(state: context.state, owner: owner) ||
        !_isSuperEffective(
            moveType: context.move.type.toLowerCase(), target: target)) {
      return null;
    }

    final amount = (target.maxHp ~/ 4).clamp(1, target.maxHp).toInt();
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
    final consumed = _consumeHeldBerry(
      state: healed.state,
      rng: healed.rng,
      turn: context.turn,
      owner: owner,
    );
    if (consumed == null) {
      return null;
    }
    final current = healed.state.battlerAt(owner);
    return BattleEffectPostDamageResult(
      state: consumed.state,
      rng: consumed.rng,
      events: <PsdkBattleEvent>[
        PsdkBattleHealEvent(
          user: owner,
          target: owner,
          moveId: 'item:$itemId',
          amount: healed.amount,
          remainingHp: current.currentHp,
        ),
        ...consumed.events,
      ],
    );
  }
}

final class RetaliateBerryEffect extends BattleItemEffect {
  const RetaliateBerryEffect({
    required String itemId,
    required BattleEffectScope scope,
    required this.triggerCategory,
  }) : super(itemId: itemId, scope: scope);

  final PsdkBattleMoveCategory triggerCategory;

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
        context.user == owner ||
        context.damage <= 0 ||
        context.targetFainted) {
      return null;
    }
    final target = context.state.battlerAt(owner);
    if (target.heldItemId != itemId ||
        !psdkCanConsumeBerry(state: context.state, owner: owner)) {
      return null;
    }

    final consumed = _consumeHeldBerry(
      state: context.state,
      rng: context.rng,
      turn: context.turn,
      owner: owner,
    );
    if (consumed == null) {
      return null;
    }
    if (context.move.category != triggerCategory) {
      return consumed.toPostDamageResult();
    }
    final attacker = consumed.state.battlerAt(context.user);
    final amount = (attacker.maxHp ~/ 8).clamp(1, attacker.currentHp).toInt();
    final damaged = const BattleDamageHandler().applyDamage(
      context: BattleHandlerContext(
        state: consumed.state,
        rng: consumed.rng,
        turn: context.turn,
        user: owner,
      ),
      target: context.user,
      moveId: 'item:$itemId',
      rawDamage: amount,
    );
    return BattleEffectPostDamageResult(
      state: damaged.state,
      rng: damaged.rng,
      events: <PsdkBattleEvent>[
        ...consumed.events,
        ...damaged.events,
      ],
    );
  }
}

final class HitStatBerryEffect extends BattleItemEffect {
  const HitStatBerryEffect({
    required String itemId,
    required BattleEffectScope scope,
    required this.triggerCategory,
    required this.stat,
  }) : super(itemId: itemId, scope: scope);

  final PsdkBattleMoveCategory triggerCategory;
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
        context.targetFainted) {
      return null;
    }
    final target = context.state.battlerAt(owner);
    if (target.heldItemId != itemId ||
        !psdkCanConsumeBerry(state: context.state, owner: owner)) {
      return null;
    }

    final consumed = _consumeHeldBerry(
      state: context.state,
      rng: context.rng,
      turn: context.turn,
      owner: owner,
    );
    if (consumed == null) {
      return null;
    }
    if (context.move.category != triggerCategory) {
      return consumed.toPostDamageResult();
    }
    final changed = const BattleStatChangeHandler().applyStatChange(
      context: BattleHandlerContext(
        state: consumed.state,
        rng: consumed.rng,
        turn: context.turn,
        user: owner,
      ),
      target: owner,
      stat: stat,
      stages: target.abilityId == 'ripen' ? 2 : 1,
    );
    return BattleEffectPostDamageResult(
      state: changed.state,
      rng: changed.rng,
      events: <PsdkBattleEvent>[
        ...consumed.events,
        ...changed.events,
      ],
    );
  }
}

extension on BattleEffectEndTurnResult {
  BattleEffectPostDamageResult toPostDamageResult() {
    return BattleEffectPostDamageResult(
      state: state,
      rng: rng,
      events: events,
      applied: applied,
    );
  }
}

double _halfHpThreshold(PsdkBattleCombatant battler) => 0.5;

double _pinchThreshold(PsdkBattleCombatant battler) {
  return battler.abilityId == 'gluttony' ? 0.5 : 0.25;
}

String _randomStat(BattleRngStreams rng) {
  const stats = <String>[
    'attack',
    'defense',
    'specialAttack',
    'specialDefense',
    'speed',
  ];
  final roll = rng.generic.nextIntInclusive(min: 0, max: stats.length - 1);
  return stats[roll.value];
}

BattleRngStreams _advanceRandomStat(BattleRngStreams rng) {
  final roll = rng.generic.nextIntInclusive(min: 0, max: 4);
  return rng.copyWith(generic: roll.next);
}

bool psdkCanConsumeBerry({
  required PsdkBattleState state,
  required PsdkBattleSlotRef owner,
}) {
  final battler = state.battlerAt(owner);
  return !battler.isFainted &&
      battler.heldItemId != null &&
      !battler.itemConsumed &&
      !battler.itemEffectsSuppressed &&
      !psdkBerryBlockedByOpposingUnnerve(state: state, owner: owner);
}

bool psdkBerryBlockedByOpposingUnnerve({
  required PsdkBattleState state,
  required PsdkBattleSlotRef owner,
}) {
  for (final foe in state.foesOf(owner)) {
    if (psdkBerryBlockedByDirectUnnerve(state.battlerAt(foe))) {
      return true;
    }
  }
  return false;
}

bool psdkBerryBlockedByDirectUnnerve(PsdkBattleCombatant foe) {
  if (foe.isFainted || foe.effects.contains('ability_suppressed')) {
    return false;
  }
  final abilityId = foe.abilityId?.trim().toLowerCase();
  return abilityId == 'unnerve' || abilityId == 'as_one';
}

BattleEffectEndTurnResult? _consumeHeldBerry({
  required PsdkBattleState state,
  required BattleRngStreams rng,
  required int turn,
  required PsdkBattleSlotRef owner,
}) {
  final consumed = const BattleItemChangeHandler().consumeHeldItem(
    context: BattleHandlerContext(
      state: state,
      rng: rng,
      turn: turn,
      user: owner,
    ),
    target: owner,
  );
  if (!consumed.applied) {
    return null;
  }
  return BattleEffectEndTurnResult(
    state: consumed.state,
    rng: consumed.rng,
    events: consumed.events,
  );
}

bool _isSuperEffective({
  required String moveType,
  required PsdkBattleCombatant target,
}) {
  final effectiveness = const BattleMoveTypeProcessor().resolveEffectiveness(
    moveType: moveType,
    targetTypes: target.types,
    extraTargetTypes: <String>[
      if (target.type3 != null) target.type3!,
      ...target.temporaryTypes,
    ],
  );
  return effectiveness.multiplier > 1;
}

bool isPsdkBerryItemId(String itemId) {
  return itemId.endsWith('_berry');
}
