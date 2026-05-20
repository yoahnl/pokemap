import '../../../psdk/domain/psdk_battle_field.dart';
import '../../../psdk/domain/psdk_battle_move.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../battler/battle_grounding_resolver.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_status_change_handler.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';

final class DrowsinessEffect extends BattleEffect {
  const DrowsinessEffect({
    required BattleEffectScope scope,
    required this.origin,
    int remainingTurns = 2,
  }) : super(
          id: 'drowsiness',
          scope: scope,
          remainingTurns: remainingTurns,
        );

  final PsdkBattleSlotRef origin;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return DrowsinessEffect(
      scope: scope,
      origin: origin,
      remainingTurns: remainingTurns,
    );
  }

  @override
  BattleEffectEndTurnResult? onEndTurn(BattleEffectEndTurnContext context) {
    final turns = remainingTurns;
    if (turns != null && turns > 1) {
      return BattleEffectEndTurnResult(
        state: context.state.updateBattler(
          context.owner,
          (battler) => battler.copyWith(
            effects:
                battler.effects.addEffect(copyWithRemainingTurns(turns - 1)),
          ),
        ),
        rng: context.rng,
        events: <PsdkBattleEvent>[
          PsdkBattleEffectEvent.ticked(
            turn: context.turn,
            target: context.owner,
            effectId: id,
            remainingTurns: turns - 1,
            reason: 'drowsiness_countdown',
          ),
        ],
      );
    }

    final target = context.state.battlerAt(context.owner);
    if (target.isFainted ||
        target.majorStatus != null ||
        _terrainPreventsSleep(context)) {
      return _clear(context);
    }

    final status = const BattleStatusChangeHandler().applyMajorStatus(
      context: BattleHandlerContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: origin,
      ),
      target: context.owner,
      moveId: 'effect:drowsiness',
      status: PsdkBattleMajorStatus.sleep,
    );
    final cleared = status.state.updateBattler(
      context.owner,
      (battler) => battler.copyWith(effects: battler.effects.remove(id)),
    );
    return BattleEffectEndTurnResult(
      state: cleared,
      rng: status.rng,
      events: status.events,
      applied: true,
    );
  }

  @override
  BattleEffectSwitchEventResult? onSwitchEvent(
    BattleEffectSwitchEventContext context,
  ) {
    if (context.who != context.owner) {
      return null;
    }
    return BattleEffectSwitchEventResult(
      state: context.state.updateBattler(
        context.owner,
        (battler) => battler.copyWith(effects: battler.effects.remove(id)),
      ),
      rng: context.rng,
    );
  }

  BattleEffectEndTurnResult _clear(BattleEffectEndTurnContext context) {
    return BattleEffectEndTurnResult(
      state: context.state.updateBattler(
        context.owner,
        (battler) => battler.copyWith(effects: battler.effects.remove(id)),
      ),
      rng: context.rng,
      applied: true,
    );
  }

  bool _terrainPreventsSleep(BattleEffectEndTurnContext context) {
    final terrain = context.state.field.terrain?.id;
    if (terrain != PsdkBattleTerrainId.electricTerrain &&
        terrain != PsdkBattleTerrainId.mistyTerrain) {
      return false;
    }
    return const BattleGroundingResolver().isGrounded(
      context.state.battlerAt(context.owner),
    );
  }
}
