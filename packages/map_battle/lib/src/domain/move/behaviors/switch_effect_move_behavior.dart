import '../../effect/battle_effect_scope.dart';
import '../../effect/move/baton_pass_effect.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_switch_handler.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../battle_move_behavior.dart';
import '../battle_move_prevention.dart';
import 'battle_move_behavior_support.dart';

enum _SwitchEffectKind {
  batonPass,
}

final class SwitchEffectMoveBehavior implements BattleMoveBehavior {
  const SwitchEffectMoveBehavior.batonPass()
      : battleEngineMethod = 's_baton_pass',
        _kind = _SwitchEffectKind.batonPass;

  @override
  final String battleEngineMethod;
  final _SwitchEffectKind _kind;

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    return switch (_kind) {
      _SwitchEffectKind.batonPass => _resolveBatonPass(context, prepared),
    };
  }

  BattleMoveBehaviorResolution _resolveBatonPass(
    BattleMoveBehaviorContext context,
    PreparedBattleMove prepared,
  ) {
    const switchHandler = BattleSwitchHandler();
    if (!switchHandler.hasAvailableReplacement(
      state: prepared.state,
      target: context.user,
    )) {
      return BattleMoveBehaviorResolution(
        state: prepared.state,
        rng: prepared.rng,
        successful: false,
        events: <PsdkBattleEvent>[
          ...prepared.events,
          PsdkBattleMoveFailedEvent(
            user: context.user,
            target: context.user,
            moveId: context.move.id,
            reason: BattleMoveFailureReason.unusableByUser.jsonName,
          ),
        ],
      );
    }

    var state = prepared.state.updateBattler(
      context.user,
      (battler) => battler.copyWith(
        effects: battler.effects.addEffect(
          BatonPassEffect(scope: BattlerBattleEffectScope(context.user)),
        ),
      ),
    );
    final switching = switchHandler.markSwitching(
      context: BattleHandlerContext(
        state: state,
        rng: prepared.rng,
        turn: context.turn,
        user: context.user,
      ),
      target: context.user,
      switching: true,
    );
    state = switching.state;

    return BattleMoveBehaviorResolution(
      state: state,
      rng: switching.rng,
      events: prepared.events,
    );
  }
}
