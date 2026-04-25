import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../battle_move_behavior.dart';
import 'battle_move_behavior_support.dart';

/// Ports the base PSDK `HealMove` behavior: heal each actual target by half of
/// its max HP after the shared move procedure succeeds.
///
/// Variants that depend on weather, Mega Launcher, Heal Block or Substitute
/// remain partial in the registry until those hooks exist as first-class
/// effects.
final class HealMoveBehavior implements BattleMoveBehavior {
  const HealMoveBehavior();

  @override
  String get battleEngineMethod => 's_heal';

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    var state = prepared.state;
    var rng = prepared.rng;
    final events = <PsdkBattleEvent>[...prepared.events];

    for (final target in prepared.psdkTargets) {
      final battler = state.battlerAt(target);
      final heal = applyDirectHeal(
        state: state,
        user: context.user,
        target: target,
        moveId: context.move.id,
        rng: rng,
        turn: context.turn,
        amount: battler.maxHp ~/ 2,
      );
      state = heal.state;
      rng = heal.rng;
      if (heal.event != null) {
        events.add(heal.event!);
      }
    }

    return BattleMoveBehaviorResolution(
      state: state,
      rng: rng,
      events: events,
    );
  }
}
