import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';

final class EchoedVoiceEffect extends BattleEffect {
  const EchoedVoiceEffect({
    required BattleEffectScope scope,
    this.successiveTurns = 0,
    this.hasIncreased = false,
  }) : super(id: 'echoed_voice', scope: scope);

  final int successiveTurns;
  final bool hasIncreased;

  EchoedVoiceEffect increase() {
    return EchoedVoiceEffect(
      scope: scope,
      successiveTurns: successiveTurns,
      hasIncreased: true,
    );
  }

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return EchoedVoiceEffect(
      scope: scope,
      successiveTurns: successiveTurns,
      hasIncreased: hasIncreased,
    );
  }

  @override
  BattleEffectEndTurnResult? onEndTurn(BattleEffectEndTurnContext context) {
    if (!hasIncreased) {
      return BattleEffectEndTurnResult(
        state: context.state.updateBattler(
          context.owner,
          (battler) => battler.copyWith(
            effects: battler.effects.remove(id),
          ),
        ),
        rng: context.rng,
        events: <PsdkBattleEvent>[
          PsdkBattleEffectEvent.removed(
            turn: context.turn,
            target: context.owner,
            effectId: id,
            reason: 'echoed_voice_reset',
          ),
        ],
      );
    }

    final next = EchoedVoiceEffect(
      scope: scope,
      successiveTurns: successiveTurns + 1,
      hasIncreased: false,
    );
    return BattleEffectEndTurnResult(
      state: context.state.updateBattler(
        context.owner,
        (battler) => battler.copyWith(
          effects: battler.effects.addEffect(next),
        ),
      ),
      rng: context.rng,
      events: <PsdkBattleEvent>[
        PsdkBattleEffectEvent.ticked(
          turn: context.turn,
          target: context.owner,
          effectId: id,
          remainingTurns: next.successiveTurns,
          reason: 'echoed_voice_chain',
        ),
      ],
    );
  }
}
