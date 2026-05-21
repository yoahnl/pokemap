import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_move.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../handler/battle_damage_handler.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_item_change_handler.dart';
import '../../move/battle_move_data.dart';
import '../../move/battle_move_prevention.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';
import 'item_effect.dart';

typedef HeldItemDamageCondition = bool Function(
  BattleItemDamageModifierContext context,
);

typedef HeldItemStatCondition = bool Function(PsdkBattleCombatant battler);

final class HeldItemModifierEffect extends BattleItemEffect {
  const HeldItemModifierEffect({
    required String itemId,
    required BattleEffectScope scope,
    this.basePowerMultiplier = 1,
    this.finalDamageMultiplier = 1,
    this.statMultipliers = const <String, double>{},
    HeldItemDamageCondition? damageCondition,
    HeldItemStatCondition? statCondition,
  })  : _damageCondition = damageCondition,
        _statCondition = statCondition,
        super(itemId: itemId, scope: scope);

  final double basePowerMultiplier;
  final double finalDamageMultiplier;
  final Map<String, double> statMultipliers;
  final HeldItemDamageCondition? _damageCondition;
  final HeldItemStatCondition? _statCondition;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return this;
  }

  @override
  double damageBasePowerMultiplier(BattleItemDamageModifierContext context) {
    if (!_canApplyTo(context.user) ||
        !(_damageCondition?.call(context) ?? true)) {
      return 1;
    }
    return basePowerMultiplier;
  }

  @override
  double damageFinalMultiplier(BattleItemDamageModifierContext context) {
    if (!_canApplyTo(context.user) ||
        !(_damageCondition?.call(context) ?? true)) {
      return 1;
    }
    return finalDamageMultiplier;
  }

  @override
  double statMultiplier(PsdkBattleCombatant battler, String stat) {
    if (!_canApplyTo(battler) || !(_statCondition?.call(battler) ?? true)) {
      return 1;
    }
    return statMultipliers[stat] ?? 1;
  }

  bool _canApplyTo(PsdkBattleCombatant battler) {
    return battler.heldItemId == itemId &&
        !battler.itemConsumed &&
        !battler.itemEffectsSuppressed;
  }
}

final class DriveItemEffect extends BattleItemEffect {
  const DriveItemEffect({
    required String itemId,
    required BattleEffectScope scope,
    required this.moveType,
  }) : super(itemId: itemId, scope: scope);

  final String moveType;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return this;
  }

  @override
  String? moveTypeOverride(BattleItemMoveTypeContext context) {
    if (context.user.heldItemId != itemId ||
        context.user.itemConsumed ||
        context.user.itemEffectsSuppressed ||
        context.user.speciesId != 'genesect' ||
        context.move.battleEngineMethod != 's_techno_blast') {
      return null;
    }
    return moveType;
  }
}

final class AccuracyModifierItemEffect extends BattleItemEffect {
  const AccuracyModifierItemEffect({
    required String itemId,
    required BattleEffectScope scope,
    required this.multiplier,
    required this.appliesToTarget,
  }) : super(itemId: itemId, scope: scope);

  final double multiplier;
  final bool appliesToTarget;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return this;
  }

  @override
  double accuracyMultiplier(BattleItemAccuracyContext context) {
    final holder = appliesToTarget ? context.target : context.user;
    if (holder.heldItemId != itemId ||
        holder.itemConsumed ||
        holder.itemEffectsSuppressed) {
      return 1;
    }
    return multiplier;
  }
}

final class ZoomLensEffect extends BattleItemEffect {
  const ZoomLensEffect({
    required BattleEffectScope scope,
  }) : super(itemId: 'zoom_lens', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return this;
  }

  @override
  double accuracyMultiplier(BattleItemAccuracyContext context) {
    if (context.user.heldItemId != itemId ||
        context.user.itemConsumed ||
        context.user.itemEffectsSuppressed ||
        !_targetAlreadyAttackedThisTurn(context)) {
      return 1;
    }
    return 1.2;
  }

  bool _targetAlreadyAttackedThisTurn(BattleItemAccuracyContext context) {
    return context.target.moveHistory.attempts.any(
      (entry) => entry.turn == context.turn,
    );
  }
}

final class ChoiceItemEffect extends BattleItemEffect {
  const ChoiceItemEffect({
    required String itemId,
    required BattleEffectScope scope,
    required this.statMultipliers,
  }) : super(itemId: itemId, scope: scope);

  final Map<String, double> statMultipliers;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return this;
  }

  @override
  BattleEffectUserMovePreventionResult? onUserMovePrevention(
    BattleEffectUserMovePreventionContext context,
  ) {
    final user = context.state.battlerAt(context.user);
    if (_canUseMove(user, context.move)) {
      return null;
    }
    return BattleEffectUserMovePreventionResult(
      state: context.state,
      rng: context.rng,
      prevented: true,
      reason: BattleMoveFailureReason.unusableByUser,
    );
  }

  @override
  BattleMoveSelectionPreventionResult? onMoveSelectionPrevention(
    BattleMoveSelectionPreventionContext context,
  ) {
    final user = context.state.battlerAt(context.user);
    if (_canUseMove(user, context.move)) {
      return null;
    }
    return const BattleMoveSelectionPreventionResult(
      reason: BattleMoveFailureReason.unusableByUser,
    );
  }

  @override
  double statMultiplier(PsdkBattleCombatant battler, String stat) {
    if (!_canApplyTo(battler)) {
      return 1;
    }
    return statMultipliers[stat] ?? 1;
  }

  bool _canUseMove(PsdkBattleCombatant user, BattleMoveDefinition move) {
    if (!_canApplyTo(user)) {
      return true;
    }
    if (_isStruggle(move.id) || _isStruggle(move.dbSymbol)) {
      return true;
    }
    final lastMove = _lastNonStruggleAttempt(user);
    if (lastMove == null) {
      return true;
    }
    final lastSentTurn = user.lastSentTurn;
    if (lastSentTurn != null && lastMove.turn < lastSentTurn) {
      return true;
    }
    return _sameMove(lastMove.moveId, move);
  }

  bool _canApplyTo(PsdkBattleCombatant battler) {
    return battler.heldItemId == itemId &&
        !battler.itemConsumed &&
        !battler.itemEffectsSuppressed;
  }
}

final class AssaultVestEffect extends BattleItemEffect {
  const AssaultVestEffect({
    required BattleEffectScope scope,
  }) : super(itemId: 'assault_vest', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return this;
  }

  @override
  BattleEffectUserMovePreventionResult? onUserMovePrevention(
    BattleEffectUserMovePreventionContext context,
  ) {
    final user = context.state.battlerAt(context.user);
    if (_canUseMove(user, context.move)) {
      return null;
    }
    return BattleEffectUserMovePreventionResult(
      state: context.state,
      rng: context.rng,
      prevented: true,
      reason: BattleMoveFailureReason.unusableByUser,
    );
  }

  @override
  BattleMoveSelectionPreventionResult? onMoveSelectionPrevention(
    BattleMoveSelectionPreventionContext context,
  ) {
    final user = context.state.battlerAt(context.user);
    if (_canUseMove(user, context.move)) {
      return null;
    }
    return const BattleMoveSelectionPreventionResult(
      reason: BattleMoveFailureReason.unusableByUser,
    );
  }

  @override
  double statMultiplier(PsdkBattleCombatant battler, String stat) {
    if (!_canApplyTo(battler) || stat != 'specialDefense') {
      return 1;
    }
    return 1.5;
  }

  bool _canUseMove(PsdkBattleCombatant user, BattleMoveDefinition move) {
    if (!_canApplyTo(user) || move.category != PsdkBattleMoveCategory.status) {
      return true;
    }
    if (_normalizedMoveId(move.id) == 'me_first' ||
        _normalizedMoveId(move.dbSymbol) == 'me_first') {
      return true;
    }
    return user.effects.contains('instruct');
  }

  bool _canApplyTo(PsdkBattleCombatant battler) {
    return battler.heldItemId == itemId &&
        !battler.itemConsumed &&
        !battler.itemEffectsSuppressed;
  }
}

final class GemItemEffect extends BattleItemEffect {
  const GemItemEffect({
    required String itemId,
    required BattleEffectScope scope,
    required this.moveType,
  }) : super(itemId: itemId, scope: scope);

  final String moveType;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return this;
  }

  @override
  double damageFinalMultiplier(BattleItemDamageModifierContext context) {
    return _canUseGem(context) ? 1.3 : 1;
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
        context.damage <= 0 ||
        context.targetFainted) {
      return null;
    }

    final user = context.state.battlerAt(owner);
    if (user.heldItemId != itemId ||
        user.itemConsumed ||
        user.itemEffectsSuppressed ||
        context.move.type.toLowerCase() != moveType ||
        context.move.power <= 0 ||
        context.move.battleEngineMethod == 's_pledge') {
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
    return BattleEffectPostDamageResult(
      state: consumed.state,
      rng: consumed.rng,
      events: consumed.events,
    );
  }

  bool _canUseGem(BattleItemDamageModifierContext context) {
    return context.user.heldItemId == itemId &&
        !context.user.itemConsumed &&
        !context.user.itemEffectsSuppressed &&
        context.moveType == moveType &&
        context.move.power > 0 &&
        context.move.battleEngineMethod != 's_pledge';
  }
}

PsdkBattleMoveHistoryEntry? _lastNonStruggleAttempt(
  PsdkBattleCombatant battler,
) {
  for (final entry in battler.moveHistory.attempts.reversed) {
    if (!_isStruggle(entry.moveId)) {
      return entry;
    }
  }
  return null;
}

bool _sameMove(String lockedMoveId, BattleMoveDefinition move) {
  final locked = _normalizedMoveId(lockedMoveId);
  return locked == _normalizedMoveId(move.id) ||
      locked == _normalizedMoveId(move.dbSymbol);
}

bool _isStruggle(String moveId) {
  return _normalizedMoveId(moveId) == 'struggle';
}

String _normalizedMoveId(String moveId) {
  return moveId.trim().toLowerCase().replaceAll('-', '_');
}

final class LifeOrbEffect extends BattleItemEffect {
  const LifeOrbEffect({
    required BattleEffectScope scope,
  }) : super(itemId: 'life_orb', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return LifeOrbEffect(scope: scope);
  }

  @override
  double damageFinalMultiplier(BattleItemDamageModifierContext context) {
    if (context.user.heldItemId != itemId ||
        context.user.itemConsumed ||
        context.user.itemEffectsSuppressed ||
        context.move.power <= 0) {
      return 1;
    }
    return 1.3;
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
        context.damage <= 0) {
      return null;
    }
    final user = context.state.battlerAt(owner);
    if (user.heldItemId != itemId ||
        user.itemConsumed ||
        user.itemEffectsSuppressed ||
        user.isFainted ||
        user.abilityId == 'magic_guard') {
      return null;
    }

    final amount = (user.maxHp ~/ 10).clamp(1, user.currentHp).toInt();
    final damaged = const BattleDamageHandler().applyDamage(
      context: BattleHandlerContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: owner,
      ),
      target: owner,
      moveId: 'item:life_orb',
      rawDamage: amount,
    );
    if (!damaged.applied) {
      return null;
    }
    return BattleEffectPostDamageResult(
      state: damaged.state,
      rng: damaged.rng,
      events: <PsdkBattleEvent>[...damaged.events],
    );
  }
}
