import '../../../psdk/domain/psdk_battle_state.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../rng/battle_rng_streams.dart';
import '../battle_move_behavior.dart';
import '../battle_move_damage_calculator.dart';
import '../battle_move_prevention.dart';
import '../battle_move_secondary_effect_resolver.dart';
import 'battle_move_behavior_support.dart';

/// Partially ports the PSDK `MindBlown` Ruby class.
///
/// Pokemon SDK registers Mind Blown, Steel Beam and Chloroblast on the same
/// class. They are not regular recoil moves: after a successful Basic hit they
/// run `deal_effect`, which removes half of the user's max HP. The same crash
/// also happens when accuracy or target immunity prevents the hit. `Damp` is
/// handled by the ability move-prevention hook, while the user's `Wonder Guard`
/// skips the crash damage like PSDK's `crash_procedure`.
final class MindBlownMoveBehavior implements BattleMoveBehavior {
  const MindBlownMoveBehavior.mindBlown() : battleEngineMethod = 's_mind_blown';

  const MindBlownMoveBehavior.steelBeam() : battleEngineMethod = 's_steel_beam';

  const MindBlownMoveBehavior.chloroblast()
      : battleEngineMethod = 's_chloroblast';

  @override
  final String battleEngineMethod;

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      if (_shouldCrashAfterFailure(prepared.failureReason)) {
        return _crashUser(
          context: context,
          state: prepared.state,
          rng: prepared.rng,
          events: prepared.events,
          successful: false,
        );
      }
      return prepared.toResolution();
    }

    final targetSlot = prepared.psdkTargets.single;
    final user = prepared.state.battlerAt(context.user);
    final target = prepared.state.battlerAt(targetSlot);
    final damageResult = const BattleMoveDamageCalculator().calculate(
      BattleMoveDamageContext(
        user: user,
        target: target,
        move: context.move,
        rng: prepared.rng,
      ),
    );
    if (damageResult.damage <= 0) {
      return _crashUser(
        context: context,
        state: prepared.state,
        rng: damageResult.rng,
        events: prepared.events,
      );
    }

    final targetDamage = applyDirectDamage(
      state: prepared.state,
      user: context.user,
      target: targetSlot,
      moveId: context.move.id,
      rng: damageResult.rng,
      turn: context.turn,
      amount: damageResult.damage,
    );
    var state = targetDamage.state;
    final events = <PsdkBattleEvent>[
      ...prepared.events,
      if (targetDamage.event != null) targetDamage.event!,
    ];

    // PSDK `MindBlown < Basic` reaches `deal_effect` after secondary status
    // and stat riders (`deal_status` / `deal_stats`). Keeping this order here
    // prevents the self-crash from hiding riders when the user faints.
    final secondary = const BattleMoveSecondaryEffectResolver().resolve(
      state: state,
      rng: targetDamage.rng,
      user: context.user,
      target: targetSlot,
      move: context.move,
      turn: context.turn,
    );
    state = secondary.state;
    events.addAll(secondary.events);

    return _crashUser(
      context: context,
      state: state,
      rng: secondary.rng,
      events: events,
    );
  }

  bool _shouldCrashAfterFailure(BattleMoveFailureReason? reason) {
    return switch (reason) {
      BattleMoveFailureReason.accuracy ||
      BattleMoveFailureReason.immunity =>
        true,
      // In Ruby PSDK, Protect-style target prevention removes all actual
      // targets inside `accuracy_immunity_test`, then calls `on_move_failure`
      // with `:immunity`. The Dart lane keeps a clearer `protected` reason for
      // event consumers, but the MindBlown crash semantics are the same.
      BattleMoveFailureReason.protected => true,
      _ => false,
    };
  }

  BattleMoveBehaviorResolution _crashUser({
    required BattleMoveBehaviorContext context,
    required PsdkBattleState state,
    required BattleRngStreams rng,
    required List<PsdkBattleEvent> events,
    bool successful = true,
  }) {
    final user = state.battlerAt(context.user);
    if (user.abilityId == 'wonder_guard') {
      return BattleMoveBehaviorResolution(
        state: state,
        rng: rng,
        events: events,
        successful: successful,
      );
    }

    final crash = applyDirectDamage(
      state: state,
      user: context.user,
      target: context.user,
      moveId: context.move.id,
      rng: rng,
      turn: context.turn,
      amount: user.maxHp ~/ 2,
    );

    return BattleMoveBehaviorResolution(
      state: crash.state,
      rng: crash.rng,
      events: <PsdkBattleEvent>[
        ...events,
        if (crash.event != null) crash.event!,
      ],
      successful: successful,
    );
  }
}
