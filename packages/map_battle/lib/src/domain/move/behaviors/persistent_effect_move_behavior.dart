import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../effect/battle_effect_scope.dart';
import '../../effect/move/aqua_ring_effect.dart';
import '../battle_move_behavior.dart';
import '../battle_move_prevention.dart';
import 'battle_move_behavior_support.dart';

enum _PersistentEffectKind {
  aquaRing,
}

final class PersistentEffectMoveBehavior
    implements BattleMoveUserPreventionBehavior {
  const PersistentEffectMoveBehavior.aquaRing()
      : battleEngineMethod = 's_aqua_ring',
        _kind = _PersistentEffectKind.aquaRing;

  @override
  final String battleEngineMethod;
  final _PersistentEffectKind _kind;

  @override
  BattleMoveUserPreventionResult? preventUser(
    BattleMoveBehaviorContext context,
  ) {
    return switch (_kind) {
      _PersistentEffectKind.aquaRing =>
        context.state.battlerAt(context.target).effects.contains('aqua_ring')
            ? const BattleMoveUserPreventionResult(
                reason: BattleMoveFailureReason.unusableByUser,
              )
            : null,
    };
  }

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    var state = prepared.state;
    final events = <PsdkBattleEvent>[...prepared.events];
    for (final target in prepared.psdkTargets) {
      if (state.battlerAt(target).effects.contains('aqua_ring')) {
        continue;
      }
      state = state.updateBattler(
        target,
        (battler) => battler.copyWith(
          effects: battler.effects.addEffect(
            AquaRingEffect(scope: BattlerBattleEffectScope(target)),
          ),
        ),
      );
    }

    return BattleMoveBehaviorResolution(
      state: state,
      rng: prepared.rng,
      events: events,
    );
  }
}
