import '../../../psdk/domain/psdk_battle_move.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect.dart';
import '../battle_effect_scope.dart';
import '../../handler/battle_damage_handler.dart';
import '../../handler/battle_handler_context.dart';
import 'status_effect_registry.dart';

final class ToxicEffect extends BattleMajorStatusEffect {
  const ToxicEffect({
    required BattleEffectScope scope,
    this.toxicCounter = 0,
  }) : super(id: 'toxic', scope: scope);

  final int toxicCounter;

  @override
  PsdkBattleMajorStatus get status => PsdkBattleMajorStatus.toxic;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return ToxicEffect(
      scope: scope,
      toxicCounter: toxicCounter,
    );
  }

  @override
  BattleEffectEndTurnResult? onEndTurn(BattleEffectEndTurnContext context) {
    final battler = context.state.battlerAt(context.owner);
    if (battler.majorStatus != status || battler.isFainted) {
      return null;
    }

    final nextCounter = battler.toxicCounter + 1;
    final advancedState = context.state.updateBattler(
      context.owner,
      (current) => current.copyWith(
        toxicCounter: nextCounter,
        effects: current.effects.addEffect(
          ToxicEffect(scope: scope, toxicCounter: nextCounter),
        ),
      ),
    );
    if (battler.abilityId == 'magic_guard') {
      return BattleEffectEndTurnResult(
        state: advancedState,
        rng: context.rng,
      );
    }

    final damage = ((battler.maxHp * nextCounter) / 16).floor().clamp(
          1,
          battler.currentHp,
        );
    if (damage <= 0) {
      return BattleEffectEndTurnResult(
        state: advancedState,
        rng: context.rng,
      );
    }

    final result = const BattleDamageHandler().applyDamage(
      context: BattleHandlerContext(
        state: advancedState,
        rng: context.rng,
        turn: context.turn,
        user: context.owner,
      ),
      target: context.owner,
      moveId: 'status:toxic',
      rawDamage: damage,
    );
    return BattleEffectEndTurnResult(
      state: result.state,
      rng: result.rng,
      events: result.events,
      applied: result.applied,
    );
  }
}
