import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../battle_move_behavior.dart';
import '../battle_move_damage_calculator.dart';
import '../battle_move_prevention.dart';
import '../battle_move_secondary_effect_resolver.dart';
import 'battle_move_behavior_support.dart';

enum _PreAttackKind {
  base,
  beakBlast,
  shellTrap,
}

/// PSDK `PreAttackBase` family.
///
/// The actual preparation marker is installed by `BattleTurnRunner` before the
/// action loop, mirroring Ruby's dedicated `Actions::PreAttack`. This behavior
/// owns the later move-use gate and the normal Basic-style damage body.
final class PreAttackMoveBehavior implements BattleMoveUserPreventionBehavior {
  const PreAttackMoveBehavior.base()
      : battleEngineMethod = 's_pre_attack_base',
        _kind = _PreAttackKind.base;

  const PreAttackMoveBehavior.beakBlast()
      : battleEngineMethod = 's_beak_blast',
        _kind = _PreAttackKind.beakBlast;

  const PreAttackMoveBehavior.shellTrap()
      : battleEngineMethod = 's_shell_trap',
        _kind = _PreAttackKind.shellTrap;

  @override
  final String battleEngineMethod;
  final _PreAttackKind _kind;

  @override
  BattleMoveUserPreventionResult? preventUser(
    BattleMoveBehaviorContext context,
  ) {
    final user = context.state.battlerAt(context.user);
    if (_kind == _PreAttackKind.shellTrap &&
        user.effects.contains('shell_trap')) {
      return const BattleMoveUserPreventionResult(
        reason: BattleMoveFailureReason.unusableByUser,
      );
    }
    return null;
  }

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prevention = preventUser(context);
    if (prevention != null) {
      return BattleMoveBehaviorResolution(
        state: context.state,
        rng: context.rng,
        events: <PsdkBattleEvent>[
          PsdkBattleMoveFailedEvent(
            user: context.user,
            target: context.target,
            moveId: context.move.id,
            reason: prevention.reason.jsonName,
          ),
        ],
        successful: false,
      );
    }

    return _resolveBasicBody(context);
  }

  BattleMoveBehaviorResolution _resolveBasicBody(
    BattleMoveBehaviorContext context,
  ) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    var state = prepared.state;
    var rng = prepared.rng;
    final events = <PsdkBattleEvent>[...prepared.events];
    final successfulTargets = <PsdkBattleSlotRef>[];

    for (final targetSlot in prepared.psdkTargets) {
      final user = state.battlerAt(context.user);
      final target = state.battlerAt(targetSlot);
      final damage = const BattleMoveDamageCalculator().calculate(
        BattleMoveDamageContext(
          user: user,
          target: target,
          move: context.move,
          rng: rng,
          field: state.field,
          state: state,
          userSlot: context.user,
          targetSlot: targetSlot,
          isLastActionOfTurn: context.isLastActionOfTurn,
        ),
      );
      rng = damage.rng;
      if (damage.damage <= 0) {
        continue;
      }
      final adjustedDamage = screenAdjustedDamage(
        state: state,
        user: user,
        target: targetSlot,
        move: context.move,
        damage: damage.damage,
        isCritical: damage.isCritical,
      );

      final applied = applyDirectDamage(
        state: state,
        user: context.user,
        target: targetSlot,
        moveId: context.move.id,
        rng: rng,
        turn: context.turn,
        amount: adjustedDamage,
        moveCategory: context.move.category,
        move: context.move,
        criticalHit: damage.isCritical,
      );
      state = applied.state;
      rng = applied.rng;
      events.addAll(applied.events);
      if (applied.damage > 0) {
        successfulTargets.add(targetSlot);
      }
    }

    for (final targetSlot in successfulTargets) {
      final secondary = const BattleMoveSecondaryEffectResolver().resolve(
        state: state,
        rng: rng,
        user: context.user,
        target: targetSlot,
        move: context.move,
        turn: context.turn,
      );
      state = secondary.state;
      rng = secondary.rng;
      events.addAll(secondary.events);
    }

    return BattleMoveBehaviorResolution(
      state: state,
      rng: rng,
      events: events,
    );
  }
}
