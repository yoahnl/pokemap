import '../../../psdk/domain/psdk_battle_field.dart';
import '../../../psdk/domain/psdk_battle_state.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../rng/battle_rng_streams.dart';
import '../battle_move_behavior.dart';
import '../battle_move_damage_calculator.dart';
import '../battle_move_prevention.dart';
import '../battle_move_secondary_effect_resolver.dart';
import 'battle_move_behavior_support.dart';

enum _SelfDestructKind {
  explosion,
  mistyExplosion,
}

/// Ports PSDK `SelfDestruct`, registered as `s_explosion`.
///
/// PSDK keeps Self-Destruct and Explosion on the same Ruby class. Its local
/// effect removes the user's *current* HP after a successful Basic damage
/// pipeline, and also after target-immunity failures. The Dart procedure has a
/// distinct `protected` reason, so Protect is mapped to the same self-KO branch
/// because PSDK reaches it through the `:immunity` failure path.
///
/// `Damp` is handled by the ability move-prevention hook before this behavior
/// executes.
final class SelfDestructMoveBehavior implements BattleMoveBehavior {
  const SelfDestructMoveBehavior.explosion()
      : battleEngineMethod = 's_explosion',
        _kind = _SelfDestructKind.explosion;

  const SelfDestructMoveBehavior.mistyExplosion()
      : battleEngineMethod = 's_misty_explosion',
        _kind = _SelfDestructKind.mistyExplosion;

  @override
  final String battleEngineMethod;
  final _SelfDestructKind _kind;

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      if (_shouldSelfKoAfterFailure(prepared.failureReason)) {
        return _selfKoUser(
          context: context,
          state: prepared.state,
          rng: prepared.rng,
          events: <PsdkBattleEvent>[
            ...prepared.events,
            PsdkBattleAnimationCueEvent(
              user: context.user,
              target: context.target,
              moveId: context.move.id,
            ),
          ],
          successful: false,
        );
      }
      return prepared.toResolution();
    }

    final targetSlot = prepared.psdkTargets.single;
    final user = prepared.state.battlerAt(context.user);
    final target = prepared.state.battlerAt(targetSlot);
    final resolvedPower = _resolvePower(context, prepared.state);
    final damageResult = const BattleMoveDamageCalculator().calculate(
      BattleMoveDamageContext(
        user: user,
        target: target,
        move: context.move,
        rng: prepared.rng,
        overrides: BattleMoveDamageOverrides(power: resolvedPower),
      ),
    );
    if (damageResult.damage <= 0) {
      return _selfKoUser(
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

    // PSDK runs `deal_status` and `deal_stats` before `deal_effect` on
    // BasicWithSuccessfulEffect. Keeping riders before self-KO prevents a
    // future faint-process layer from masking successful secondary effects.
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

    return _selfKoUser(
      context: context,
      state: state,
      rng: secondary.rng,
      events: events,
    );
  }

  bool _shouldSelfKoAfterFailure(BattleMoveFailureReason? reason) {
    return switch (reason) {
      BattleMoveFailureReason.immunity => true,
      BattleMoveFailureReason.protected => true,
      _ => false,
    };
  }

  int _resolvePower(
    BattleMoveBehaviorContext context,
    PsdkBattleState state,
  ) {
    return switch (_kind) {
      _SelfDestructKind.explosion => context.move.power,
      _SelfDestructKind.mistyExplosion =>
        state.field.isTerrainActive(PsdkBattleTerrainId.mistyTerrain)
            ? (context.move.power * 1.5).floor()
            : context.move.power,
    };
  }

  BattleMoveBehaviorResolution _selfKoUser({
    required BattleMoveBehaviorContext context,
    required PsdkBattleState state,
    required BattleRngStreams rng,
    required List<PsdkBattleEvent> events,
    bool successful = true,
  }) {
    final user = state.battlerAt(context.user);
    final selfDamage = applyDirectDamage(
      state: state,
      user: context.user,
      target: context.user,
      moveId: context.move.id,
      rng: rng,
      turn: context.turn,
      amount: user.currentHp,
    );

    return BattleMoveBehaviorResolution(
      state: selfDamage.state,
      rng: selfDamage.rng,
      events: <PsdkBattleEvent>[
        ...events,
        if (selfDamage.event != null) selfDamage.event!,
      ],
      successful: successful,
    );
  }
}
