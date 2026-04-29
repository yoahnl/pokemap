import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../battle_move_behavior.dart';
import '../battle_move_prevention.dart';
import 'battle_move_behavior_support.dart';

enum _CounterDamageKind {
  counter,
  mirrorCoat,
  metalBurst,
  bide,
}

/// Ports local direct-damage retaliation formulas.
///
/// This remains partial because the clean damage history does not yet record
/// incoming move category, so Counter/Mirror Coat cannot filter physical vs
/// special damage as strictly as PSDK.
final class CounterDamageMoveBehavior implements BattleMoveBehavior {
  const CounterDamageMoveBehavior.counter()
      : battleEngineMethod = 's_counter',
        _kind = _CounterDamageKind.counter;

  const CounterDamageMoveBehavior.mirrorCoat()
      : battleEngineMethod = 's_mirror_coat',
        _kind = _CounterDamageKind.mirrorCoat;

  const CounterDamageMoveBehavior.metalBurst()
      : battleEngineMethod = 's_metal_burst',
        _kind = _CounterDamageKind.metalBurst;

  const CounterDamageMoveBehavior.bide()
      : battleEngineMethod = 's_bide',
        _kind = _CounterDamageKind.bide;

  @override
  final String battleEngineMethod;
  final _CounterDamageKind _kind;

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(context, forceAccuracyBypass: true);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    final targetSlot = prepared.psdkTargets.single;
    final user = prepared.state.battlerAt(context.user);
    final amount = _damageAmount(user, context.turn);
    if (amount <= 0) {
      return BattleMoveBehaviorResolution(
        state: prepared.state,
        rng: prepared.rng,
        successful: false,
        events: <PsdkBattleEvent>[
          ...prepared.events,
          PsdkBattleMoveFailedEvent(
            user: context.user,
            target: targetSlot,
            moveId: context.move.id,
            reason: BattleMoveFailureReason.unusableByUser.jsonName,
          ),
        ],
      );
    }

    final applied = applyDirectDamage(
      state: prepared.state,
      user: context.user,
      target: targetSlot,
      moveId: context.move.id,
      rng: prepared.rng,
      turn: context.turn,
      amount: amount,
    );
    return BattleMoveBehaviorResolution(
      state: applied.state,
      rng: applied.rng,
      events: <PsdkBattleEvent>[
        ...prepared.events,
        if (applied.event != null) applied.event!,
      ],
    );
  }

  int _damageAmount(PsdkBattleCombatant user, int turn) {
    final relevantEntries = switch (_kind) {
      _CounterDamageKind.bide => user.damageHistory.entries,
      _ => user.damageHistory.entries.where((entry) => entry.turn == turn),
    };
    final damage = relevantEntries.fold<int>(
      0,
      (sum, entry) => sum + entry.damage,
    );
    return switch (_kind) {
      _CounterDamageKind.counter ||
      _CounterDamageKind.mirrorCoat ||
      _CounterDamageKind.bide =>
        damage * 2,
      _CounterDamageKind.metalBurst => (damage * 1.5).floor(),
    };
  }
}
