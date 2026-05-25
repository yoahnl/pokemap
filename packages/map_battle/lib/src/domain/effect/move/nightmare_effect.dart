import '../../../psdk/domain/psdk_battle_move.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../handler/battle_damage_handler.dart';
import '../../handler/battle_handler_context.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';

final class NightmareEffect extends BattleEffect {
  const NightmareEffect({
    required BattleEffectScope scope,
  }) : super(
          id: 'nightmare',
          scope: scope,
        );

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return NightmareEffect(scope: scope);
  }

  @override
  BattleEffectEndTurnResult? onEndTurn(BattleEffectEndTurnContext context) {
    final owner = context.owner;
    final battler = context.state.battlerAt(owner);
    if (battler.isFainted || battler.abilityId == 'magic_guard') {
      return null;
    }
    if (battler.majorStatus != PsdkBattleMajorStatus.sleep &&
        battler.abilityId != 'comatose') {
      final cleared = context.state.updateBattler(
        owner,
        (current) => current.copyWith(effects: current.effects.remove(id)),
      );
      return BattleEffectEndTurnResult(
        state: cleared,
        rng: context.rng,
        events: <PsdkBattleEvent>[
          PsdkBattleEffectEvent.removed(
            turn: context.turn,
            target: owner,
            effectId: id,
            remainingTurns: 0,
            reason: 'target_not_asleep',
          ),
        ],
      );
    }

    final damage = (battler.maxHp ~/ 4).clamp(1, battler.currentHp).toInt();
    final result = const BattleDamageHandler().applyDamage(
      context: BattleHandlerContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: owner,
      ),
      target: owner,
      moveId: 'effect:nightmare',
      rawDamage: damage,
    );
    if (!result.applied) {
      return null;
    }
    return BattleEffectEndTurnResult(
      state: result.state,
      rng: result.rng,
      events: result.events,
    );
  }
}
