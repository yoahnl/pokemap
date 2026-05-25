import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../effect/battle_effect.dart';
import '../../effect/battle_effect_hooks.dart';
import '../../effect/battle_effect_scope.dart';
import 'substitute_effect.dart';

final class ShedTailEffect extends BattleEffect {
  const ShedTailEffect({
    required BattleEffectScope scope,
    required this.remainingHp,
  }) : super(
          id: 'shed_tail',
          scope: scope,
        );

  final int remainingHp;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return ShedTailEffect(
      scope: scope,
      remainingHp: remainingHp,
    );
  }

  @override
  BattleEffectSwitchEventResult? onSwitchEvent(
    BattleEffectSwitchEventContext context,
  ) {
    if (context.owner != context.replacement) {
      return null;
    }

    final owner = context.state.battlerAt(context.owner);
    final nextEffects = owner.isFainted || owner.effects.contains('substitute')
        ? owner.effects.remove(id)
        : owner.effects
            .remove(id)
            .addEffect(
              SubstituteEffect(
                scope: BattlerBattleEffectScope(context.owner),
                remainingHp: remainingHp,
              ),
            );

    return BattleEffectSwitchEventResult(
      state: context.state.updateBattler(
        context.owner,
        (battler) => battler.copyWith(effects: nextEffects),
      ),
      rng: context.rng,
      events: <PsdkBattleEvent>[
        PsdkBattleEffectEvent.removed(
          turn: context.turn,
          target: context.owner,
          effectId: id,
          reason: 'switch_transfer',
        ),
      ],
    );
  }
}
