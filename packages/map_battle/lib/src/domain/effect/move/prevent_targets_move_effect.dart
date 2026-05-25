import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../move/battle_move_prevention.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';

final class PreventTargetsMoveEffect extends BattleEffect {
  const PreventTargetsMoveEffect({
    required BattleEffectScope scope,
    this.targets = const <PsdkBattleSlotRef>[],
    int remainingTurns = 0,
  }) : super(
          id: 'prevent_targets_move',
          scope: scope,
          remainingTurns: remainingTurns,
        );

  final List<PsdkBattleSlotRef> targets;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return PreventTargetsMoveEffect(
      scope: scope,
      targets: targets,
      remainingTurns: remainingTurns,
    );
  }

  @override
  BattleEffectUserMovePreventionResult? onUserMovePrevention(
    BattleEffectUserMovePreventionContext context,
  ) {
    if (!_prevents(context.user)) {
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
  BattleEffectEndTurnResult? onEndTurn(BattleEffectEndTurnContext context) {
    final turns = remainingTurns;
    if (turns == null) {
      return null;
    }
    final nextEffects = turns <= 0
        ? context.state.battlerAt(context.owner).effects.remove(id)
        : context.state
            .battlerAt(context.owner)
            .effects
            .addEffect(copyWithRemainingTurns(turns - 1));
    return BattleEffectEndTurnResult(
      state: context.state.updateBattler(
        context.owner,
        (battler) => battler.copyWith(effects: nextEffects),
      ),
      rng: context.rng,
    );
  }

  bool _prevents(PsdkBattleSlotRef user) {
    if (targets.isNotEmpty) {
      return targets.contains(user);
    }
    final scope = this.scope;
    return scope is BattlerBattleEffectScope && scope.slot == user;
  }
}
