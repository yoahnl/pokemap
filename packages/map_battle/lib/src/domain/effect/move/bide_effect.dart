import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../move/battle_move_prevention.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';

/// PSDK Bide charge marker.
///
/// The effect forces the stored move, accumulates damage while charging, then
/// lets the move release once its counter reaches one.
final class BideEffect extends BattleEffect {
  const BideEffect({
    required BattleEffectScope scope,
    required this.forcedMoveId,
    required this.chargedTarget,
    this.storedDamage = 0,
    int remainingTurns = 3,
  }) : super(id: 'bide', scope: scope, remainingTurns: remainingTurns);

  final String forcedMoveId;
  final PsdkBattleSlotRef chargedTarget;
  final int storedDamage;

  bool get canUnleash => remainingTurns == 1;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return BideEffect(
      scope: scope,
      forcedMoveId: forcedMoveId,
      chargedTarget: chargedTarget,
      storedDamage: storedDamage,
      remainingTurns: remainingTurns,
    );
  }

  @override
  BattleEffectUserMovePreventionResult? onUserMovePrevention(
    BattleEffectUserMovePreventionContext context,
  ) {
    if (_sameMove(context.move.id)) {
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
    if (!_appliesTo(context.user) || _sameMove(context.move.id)) {
      return null;
    }
    return const BattleMoveSelectionPreventionResult(
      reason: BattleMoveFailureReason.unusableByUser,
    );
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

    return BattleEffectPostDamageResult(
      state: context.state.updateBattler(
        context.owner,
        (battler) => battler.copyWith(
          effects: battler.effects.addEffect(
            BideEffect(
              scope: scope,
              forcedMoveId: forcedMoveId,
              chargedTarget: chargedTarget,
              storedDamage: storedDamage + context.damage,
              remainingTurns: remainingTurns ?? 1,
            ),
          ),
        ),
      ),
      rng: context.rng,
    );
  }

  @override
  BattleEffectEndTurnResult? onEndTurn(BattleEffectEndTurnContext context) {
    final turns = remainingTurns;
    if (turns == null) {
      return null;
    }
    final nextTurns = turns - 1;
    final nextEffects = nextTurns <= 0
        ? context.state.battlerAt(context.owner).effects.remove(id)
        : context.state.battlerAt(context.owner).effects.addEffect(
              copyWithRemainingTurns(nextTurns),
            );
    return BattleEffectEndTurnResult(
      state: context.state.updateBattler(
        context.owner,
        (battler) => battler.copyWith(effects: nextEffects),
      ),
      rng: context.rng,
      events: <PsdkBattleEvent>[
        if (nextTurns <= 0)
          PsdkBattleEffectEvent.removed(
            turn: context.turn,
            target: context.owner,
            effectId: id,
            remainingTurns: 0,
            reason: 'expired',
          )
        else
          PsdkBattleEffectEvent.ticked(
            turn: context.turn,
            target: context.owner,
            effectId: id,
            remainingTurns: nextTurns,
            reason: 'duration_tick',
          ),
      ],
    );
  }

  bool _sameMove(String moveId) =>
      _normalizedId(moveId) ==
      _normalizedId(
        forcedMoveId,
      );

  bool _appliesTo(PsdkBattleSlotRef user) {
    final scope = this.scope;
    return scope is! BattlerBattleEffectScope || scope.slot == user;
  }
}

String _normalizedId(String value) {
  return value.trim().toLowerCase().replaceAll('-', '_');
}
