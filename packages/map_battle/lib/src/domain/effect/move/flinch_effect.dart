import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../psdk/domain/psdk_battle_state.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_handler_result.dart';
import '../../handler/battle_stat_change_handler.dart';
import '../../rng/battle_rng_streams.dart';
import '../../move/battle_move_data.dart';
import '../../move/battle_move_prevention.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';

final class FlinchEffect extends BattleEffect {
  const FlinchEffect({
    required BattleEffectScope scope,
  }) : super(
          id: 'flinch',
          scope: scope,
          remainingTurns: 0,
        );

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return FlinchEffect(scope: scope);
  }

  @override
  BattleEffectUserMovePreventionResult? onUserMovePrevention(
    BattleEffectUserMovePreventionContext context,
  ) {
    if (!_appliesTo(context.user)) {
      return null;
    }

    return BattleEffectUserMovePreventionResult(
      state: context.state,
      rng: context.rng,
      prevented: true,
      reason: BattleMoveFailureReason.unusableByUser,
    );
  }

  bool _appliesTo(PsdkBattleSlotRef user) {
    final scope = this.scope;
    return scope is! BattlerBattleEffectScope || scope.slot == user;
  }
}

BattleHandlerResult applyFlinchEffect({
  required PsdkBattleState state,
  required BattleRngStreams rng,
  required int turn,
  required PsdkBattleSlotRef target,
  required String reason,
  BattleMoveDefinition? move,
}) {
  if (state.battlerAt(target).effects.contains('flinch')) {
    return BattleHandlerResult(
      state: state,
      rng: rng,
      applied: false,
      reason: 'flinch',
    );
  }

  final flinch = FlinchEffect(
    scope: BattlerBattleEffectScope(target),
  );
  var nextState = state.updateBattler(
    target,
    (battler) => battler.copyWith(
      effects: battler.effects.addEffect(flinch),
    ),
  );
  var nextRng = rng;
  final events = <PsdkBattleEvent>[
    PsdkBattleEffectEvent.added(
      turn: turn,
      target: target,
      effectId: flinch.id,
      remainingTurns: flinch.remainingTurns,
      reason: reason,
    ),
  ];

  if (nextState.battlerAt(target).abilityId == 'steadfast') {
    final boosted = const BattleStatChangeHandler().applyStatChange(
      context: BattleHandlerContext(
        state: nextState,
        rng: nextRng,
        turn: turn,
        user: target,
      ),
      target: target,
      stat: 'speed',
      stages: 1,
      move: move,
      sourceAbilityId: 'steadfast',
    );
    nextState = boosted.state;
    nextRng = boosted.rng;
    events.addAll(boosted.events);
  }

  return BattleHandlerResult(
    state: nextState,
    rng: nextRng,
    events: events,
  );
}
