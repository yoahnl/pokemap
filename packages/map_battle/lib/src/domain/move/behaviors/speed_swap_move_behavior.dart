import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../battle_move_behavior.dart';
import 'battle_move_behavior_support.dart';

/// Ports PSDK Speed Swap's `spd_basis` exchange between user and target.
final class SpeedSwapMoveBehavior implements BattleMoveBehavior {
  const SpeedSwapMoveBehavior();

  @override
  String get battleEngineMethod => 's_speed_swap';

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(context, forceAccuracyBypass: true);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    final targetSlot = prepared.psdkTargets.single;
    final user = prepared.state.battlerAt(context.user);
    final target = prepared.state.battlerAt(targetSlot);
    final nextState = prepared.state
        .replaceBattler(
          context.user,
          user.copyWith(
            stats: _statsWith(user.stats, speed: target.stats.speed),
          ),
        )
        .replaceBattler(
          targetSlot,
          target.copyWith(
            stats: _statsWith(target.stats, speed: user.stats.speed),
          ),
        );

    return BattleMoveBehaviorResolution(
      state: nextState,
      rng: prepared.rng,
      events: <PsdkBattleEvent>[...prepared.events],
    );
  }
}

PsdkBattleStats _statsWith(PsdkBattleStats stats, {required int speed}) {
  return PsdkBattleStats(
    attack: stats.attack,
    defense: stats.defense,
    specialAttack: stats.specialAttack,
    specialDefense: stats.specialDefense,
    speed: speed,
  );
}
