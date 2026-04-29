import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../battle_move_behavior.dart';
import 'battle_move_behavior_support.dart';

/// Ports PSDK `OHKO`'s direct HP removal once the shared move procedure hits.
///
/// The local behavior intentionally remains partial in the manifest: Ruby PSDK
/// also customizes chance of hit by level difference and applies Sheer Cold's
/// post-Gen-7 Ice immunity. Those belong in the accuracy/effect hook layer.
final class OhkoMoveBehavior implements BattleMoveBehavior {
  const OhkoMoveBehavior();

  @override
  String get battleEngineMethod => 's_ohko';

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    var state = prepared.state;
    var rng = prepared.rng;
    final events = <PsdkBattleEvent>[...prepared.events];

    for (final targetSlot in prepared.psdkTargets) {
      final target = state.battlerAt(targetSlot);
      final damage = applyDirectDamage(
        state: state,
        user: context.user,
        target: targetSlot,
        moveId: context.move.id,
        rng: rng,
        turn: context.turn,
        amount: target.maxHp,
      );
      state = damage.state;
      rng = damage.rng;
      if (damage.event != null) {
        events.add(damage.event!);
      }
    }

    return BattleMoveBehaviorResolution(
      state: state,
      rng: rng,
      events: events,
    );
  }
}
