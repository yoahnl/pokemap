import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../battle_move_behavior.dart';
import 'battle_move_behavior_support.dart';

/// Ports PSDK Power Trick's base Attack/Defense exchange.
///
/// Ruby PSDK writes `atk_basis` and `dfe_basis` on the affected target. The
/// Dart lane mirrors that through immutable stat snapshots and leaves stat
/// stages untouched.
final class PowerTrickMoveBehavior implements BattleMoveBehavior {
  const PowerTrickMoveBehavior();

  @override
  String get battleEngineMethod => 's_power_trick';

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    var state = prepared.state;
    for (final targetSlot in prepared.psdkTargets) {
      final target = state.battlerAt(targetSlot);
      state = state.replaceBattler(
        targetSlot,
        target.copyWith(
          stats: _statsWith(
            target.stats,
            attack: target.stats.defense,
            defense: target.stats.attack,
          ),
        ),
      );
    }

    return BattleMoveBehaviorResolution(
      state: state,
      rng: prepared.rng,
      events: <PsdkBattleEvent>[...prepared.events],
    );
  }
}

PsdkBattleStats _statsWith(
  PsdkBattleStats stats, {
  int? attack,
  int? defense,
}) {
  return PsdkBattleStats(
    attack: attack ?? stats.attack,
    defense: defense ?? stats.defense,
    specialAttack: stats.specialAttack,
    specialDefense: stats.specialDefense,
    speed: stats.speed,
  );
}
