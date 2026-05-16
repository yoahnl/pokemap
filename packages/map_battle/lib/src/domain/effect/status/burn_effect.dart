import '../../../psdk/domain/psdk_battle_move.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect.dart';
import '../battle_effect_scope.dart';
import '../../handler/battle_damage_handler.dart';
import '../../handler/battle_handler_context.dart';
import 'status_effect_registry.dart';

final class BurnEffect extends BattleMajorStatusEffect {
  const BurnEffect({
    required BattleEffectScope scope,
  }) : super(id: 'burn', scope: scope);

  @override
  PsdkBattleMajorStatus get status => PsdkBattleMajorStatus.burn;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return BurnEffect(scope: scope);
  }

  @override
  BattleEffectEndTurnResult? onEndTurn(BattleEffectEndTurnContext context) {
    final battler = context.state.battlerAt(context.owner);
    if (battler.majorStatus != status || battler.isFainted) {
      return null;
    }
    if (battler.abilityId == 'magic_guard') {
      return null;
    }

    var damage = _residualDamage(battler.maxHp, 8).clamp(
      0,
      battler.currentHp,
    );
    if (battler.abilityId == 'heatproof' && damage > 1) {
      damage = (damage / 2).floor().clamp(1, battler.currentHp);
    }
    if (damage <= 0) {
      return null;
    }

    final result = const BattleDamageHandler().applyDamage(
      context: BattleHandlerContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: context.owner,
      ),
      target: context.owner,
      moveId: 'status:burn',
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

int _residualDamage(int maxHp, int denominator) {
  return (maxHp / denominator).floor().clamp(1, maxHp).toInt();
}
