import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../battle_move_behavior.dart';
import 'battle_move_behavior_support.dart';

enum _StatSplitKind { power, guard }

/// Ports PSDK Power Split and Guard Split base-stat sharing.
///
/// Ruby PSDK writes the averaged `*_basis` values directly on both battlers.
/// The Dart lane mirrors that by replacing the immutable battle stat snapshots;
/// stat stages are intentionally left untouched.
final class StatSplitMoveBehavior implements BattleMoveBehavior {
  const StatSplitMoveBehavior.power()
      : battleEngineMethod = 's_power_split',
        _kind = _StatSplitKind.power;

  const StatSplitMoveBehavior.guard()
      : battleEngineMethod = 's_guard_split',
        _kind = _StatSplitKind.guard;

  @override
  final String battleEngineMethod;
  final _StatSplitKind _kind;

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    final targetSlot = prepared.psdkTargets.single;
    final user = prepared.state.battlerAt(context.user);
    final target = prepared.state.battlerAt(targetSlot);

    final nextUserStats = switch (_kind) {
      _StatSplitKind.power => _statsWith(
          user.stats,
          attack: _average(user.stats.attack, target.stats.attack),
          specialAttack: _average(
            user.stats.specialAttack,
            target.stats.specialAttack,
          ),
        ),
      _StatSplitKind.guard => _statsWith(
          user.stats,
          defense: _average(user.stats.defense, target.stats.defense),
          specialDefense: _average(
            user.stats.specialDefense,
            target.stats.specialDefense,
          ),
        ),
    };
    final nextTargetStats = switch (_kind) {
      _StatSplitKind.power => _statsWith(
          target.stats,
          attack: nextUserStats.attack,
          specialAttack: nextUserStats.specialAttack,
        ),
      _StatSplitKind.guard => _statsWith(
          target.stats,
          defense: nextUserStats.defense,
          specialDefense: nextUserStats.specialDefense,
        ),
    };

    final nextState = prepared.state
        .replaceBattler(context.user, user.copyWith(stats: nextUserStats))
        .replaceBattler(targetSlot, target.copyWith(stats: nextTargetStats));

    return BattleMoveBehaviorResolution(
      state: nextState,
      rng: prepared.rng,
      events: <PsdkBattleEvent>[...prepared.events],
    );
  }
}

int _average(int left, int right) => (left + right) ~/ 2;

PsdkBattleStats _statsWith(
  PsdkBattleStats stats, {
  int? attack,
  int? defense,
  int? specialAttack,
  int? specialDefense,
  int? speed,
}) {
  return PsdkBattleStats(
    attack: attack ?? stats.attack,
    defense: defense ?? stats.defense,
    specialAttack: specialAttack ?? stats.specialAttack,
    specialDefense: specialDefense ?? stats.specialDefense,
    speed: speed ?? stats.speed,
  );
}
