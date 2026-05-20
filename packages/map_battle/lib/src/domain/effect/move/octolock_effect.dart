import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_stat_change_handler.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';

final class OctolockEffect extends BattleEffect {
  const OctolockEffect({
    required BattleEffectScope scope,
    required this.origin,
  }) : super(
          id: 'octolock',
          scope: scope,
        );

  final PsdkBattleSlotRef origin;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return OctolockEffect(scope: scope, origin: origin);
  }

  @override
  String? onSwitchPrevention(BattleEffectSwitchPreventionContext context) {
    final originBattler = context.state.combatants[origin];
    if (originBattler == null || originBattler.isFainted) {
      return null;
    }
    return id;
  }

  @override
  BattleEffectEndTurnResult? onEndTurn(BattleEffectEndTurnContext context) {
    final originBattler = context.state.combatants[origin];
    if (originBattler == null || originBattler.isFainted) {
      return BattleEffectEndTurnResult(
        state: context.state.updateBattler(
          context.owner,
          (battler) => battler.copyWith(effects: battler.effects.remove(id)),
        ),
        rng: context.rng,
      );
    }
    if (context.state.battlerAt(context.owner).isFainted) {
      return null;
    }

    final defense = const BattleStatChangeHandler().applyStatChange(
      context: BattleHandlerContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: origin,
      ),
      target: context.owner,
      stat: 'defense',
      stages: -1,
    );
    final specialDefense = const BattleStatChangeHandler().applyStatChange(
      context: BattleHandlerContext(
        state: defense.state,
        rng: defense.rng,
        turn: context.turn,
        user: origin,
      ),
      target: context.owner,
      stat: 'specialDefense',
      stages: -1,
    );

    return BattleEffectEndTurnResult(
      state: specialDefense.state,
      rng: specialDefense.rng,
      events: <PsdkBattleEvent>[
        ...defense.events,
        ...specialDefense.events,
      ],
    );
  }
}
