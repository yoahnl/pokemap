import '../../../psdk/domain/psdk_battle_move.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../handler/battle_damage_handler.dart';
import '../../handler/battle_handler_context.dart';
import '../../move/battle_move_prevention.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';

final class DestinyBondEffect extends BattleEffect {
  const DestinyBondEffect({
    required BattleEffectScope scope,
    int? remainingTurns,
  }) : super(
          id: 'destiny_bond',
          scope: scope,
          remainingTurns: remainingTurns,
        );

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return DestinyBondEffect(
      scope: scope,
      remainingTurns: remainingTurns,
    );
  }

  @override
  BattleEffectUserMovePreventionResult? onUserMovePrevention(
    BattleEffectUserMovePreventionContext context,
  ) {
    if (!_appliesTo(context.user) ||
        context.move.id == 'destiny_bond' ||
        context.move.battleEngineMethod == 's_destiny_bond') {
      return null;
    }

    return BattleEffectUserMovePreventionResult(
      state: context.state.updateBattler(
        context.user,
        (battler) => battler.copyWith(effects: battler.effects.remove(id)),
      ),
      rng: context.rng,
      prevented: false,
      reason: BattleMoveFailureReason.unusableByUser,
    );
  }

  @override
  BattleEffectPostDamageResult? onPostDamage(BattleEffectPostDamageContext context) {
    if (!_appliesTo(context.owner) ||
        context.owner != context.target ||
        !context.targetFainted ||
        context.user == context.owner ||
        context.user.bank == context.owner.bank ||
        context.move.id.startsWith('effect:')) {
      return null;
    }

    final clearedState = context.state.updateBattler(
      context.owner,
      (battler) => battler.copyWith(effects: battler.effects.remove(id)),
    );
    final launcher = clearedState.battlerAt(context.user);
    if (launcher.isFainted) {
      return BattleEffectPostDamageResult(
        state: clearedState,
        rng: context.rng,
      );
    }

    final result = const BattleDamageHandler().applyDamage(
      context: BattleHandlerContext(
        state: clearedState,
        rng: context.rng,
        turn: context.turn,
        user: context.owner,
      ),
      target: context.user,
      moveId: 'effect:destiny_bond',
      rawDamage: launcher.currentHp,
      moveCategory: PsdkBattleMoveCategory.status,
    );
    return BattleEffectPostDamageResult(
      state: result.state,
      rng: result.rng,
      events: result.events,
      applied: result.applied,
    );
  }

  bool _appliesTo(PsdkBattleSlotRef owner) {
    final effectScope = scope;
    return effectScope is! BattlerBattleEffectScope || effectScope.slot == owner;
  }
}
