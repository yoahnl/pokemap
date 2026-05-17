import '../../psdk/domain/psdk_battle_combatant.dart';
import '../../psdk/domain/psdk_battle_field.dart';
import '../../psdk/domain/psdk_battle_move.dart';
import '../../psdk/domain/psdk_battle_slots.dart';
import '../battle/battle_slot.dart';
import '../battler/battle_grounding_resolver.dart';
import '../effect/battle_effect_hooks.dart';
import '../effect/battle_effect_scope.dart';
import '../timeline/battle_timeline_event.dart';
import 'battle_move_execution.dart';
import 'battle_move_prevention.dart';
import 'battle_move_procedure.dart';
import 'battle_move_type_processor.dart';

/// PSDK-style target blocking and immunity filter.
///
/// This mirrors the `accuracy_immunity_test` slice from Pokemon SDK:
/// type/ground immunity is checked before target-prevention hooks such as
/// Protect. Ability and effect-specific immunities stay behind later effect
/// hooks; FIGHT-11 only extracts the deterministic logic that already existed
/// in Dart.
final class BattleMoveImmunityResolver {
  const BattleMoveImmunityResolver({
    BattleMoveTypeProcessor typeProcessor = const BattleMoveTypeProcessor(),
    BattleGroundingResolver groundingResolver = const BattleGroundingResolver(),
  })  : _typeProcessor = typeProcessor,
        _groundingResolver = groundingResolver;

  final BattleMoveTypeProcessor _typeProcessor;
  final BattleGroundingResolver _groundingResolver;

  BattleMoveTargetPrecheckResult precheck(
      BattleMoveProcedureExecution execution, List<BattlePositionRef> targets,
      {bool ignoreProtect = false}) {
    final unblockedTargets = <BattlePositionRef>[];
    var failureReason = BattleMoveFailureReason.immunity;
    final shouldCheckTypeImmunity =
        execution.move.category != PsdkBattleMoveCategory.status &&
            execution.move.power > 0;

    for (final targetRef in targets) {
      if (shouldCheckTypeImmunity && _isTypeImmune(execution, targetRef)) {
        execution.timeline.add(
          BattleMoveImmuneTimelineEvent(
            turn: execution.turn,
            user: execution.actualUser,
            target: targetRef,
            moveId: execution.move.id,
          ),
        );
        continue;
      }

      if (_isBlockedByPsychicTerrain(execution, targetRef)) {
        failureReason = BattleMoveFailureReason.terrain;
        execution.timeline.add(
          BattleMoveFailedTimelineEvent(
            turn: execution.turn,
            user: execution.actualUser,
            target: targetRef,
            moveId: execution.move.id,
            reason: BattleMoveFailureReason.terrain.jsonName,
          ),
        );
        continue;
      }

      final effectPrevention = _targetEffectPreventionReason(
        execution,
        targetRef,
      );
      if (effectPrevention != null &&
          !(ignoreProtect &&
              effectPrevention == BattleMoveFailureReason.protected)) {
        failureReason = effectPrevention;
        execution.timeline.add(
          BattleMoveFailedTimelineEvent(
            turn: execution.turn,
            user: execution.actualUser,
            target: targetRef,
            moveId: execution.move.id,
            reason: effectPrevention.jsonName,
          ),
        );
        continue;
      }

      unblockedTargets.add(targetRef);
    }

    return BattleMoveTargetPrecheckResult(
      targets: unblockedTargets,
      reason: failureReason,
    );
  }

  bool _isTypeImmune(
    BattleMoveProcedureExecution execution,
    BattlePositionRef targetRef,
  ) {
    final target = execution.context.state.battlerAt(
      _psdkSlotFromBattlePosition(targetRef),
    );
    final moveType = _effectiveMoveType(execution);
    if (_isGroundMoveBlockedByGrounding(moveType, target)) {
      return true;
    }

    final effectiveness = _typeProcessor.resolveEffectiveness(
      moveType: moveType,
      targetTypes: target.types,
      extraTargetTypes: _extraTypes(target),
      forceGrounded:
          moveType == 'ground' && _groundingResolver.isGrounded(target),
      foresight: target.effects.contains('foresight'),
      miracleEye: target.effects.contains('miracle_eye'),
    );
    return effectiveness.isImmune;
  }

  bool _isBlockedByPsychicTerrain(
    BattleMoveProcedureExecution execution,
    BattlePositionRef targetRef,
  ) {
    if (!execution.context.state.field
            .isTerrainActive(PsdkBattleTerrainId.psychicTerrain) ||
        execution.move.priority < 1 ||
        !execution.move.flags.protectable) {
      return false;
    }
    final target = execution.context.state.battlerAt(
      _psdkSlotFromBattlePosition(targetRef),
    );
    return _groundingResolver.isGrounded(target);
  }

  bool _isGroundMoveBlockedByGrounding(
    String moveType,
    PsdkBattleCombatant target,
  ) {
    return moveType == 'ground' && !_groundingResolver.isGrounded(target);
  }

  BattleMoveFailureReason? _targetEffectPreventionReason(
    BattleMoveProcedureExecution execution,
    BattlePositionRef targetRef,
  ) {
    final target = execution.context.state.battlerAt(
      _psdkSlotFromBattlePosition(targetRef),
    );
    final localReason = target.effects.targetMovePreventionReason(
      user: execution.actualUser,
      target: targetRef,
      move: execution.move,
    );
    if (localReason != null) {
      return localReason;
    }

    final context = BattleEffectMoveContext(
      user: execution.actualUser,
      target: targetRef,
      move: execution.move,
    );
    for (final owner in execution.context.state.combatants.values) {
      for (final effect in owner.effects.effects) {
        final scope = effect.scope;
        if (scope is! BankBattleEffectScope || scope.bank != targetRef.bank) {
          continue;
        }
        final reason = effect.onMovePreventionTarget(context);
        if (reason != null) {
          return reason;
        }
      }
    }
    return null;
  }
}

String _effectiveMoveType(BattleMoveProcedureExecution execution) {
  final user = execution.context.state.battlerAt(execution.psdkActualUser);
  final moveType = execution.move.type.toLowerCase();
  if (user.effects.contains('electrify')) {
    return 'electric';
  }
  if (user.effects.contains('ion_deluge') && moveType == 'normal') {
    return 'electric';
  }
  return moveType;
}

Iterable<String> _extraTypes(PsdkBattleCombatant battler) {
  return <String>[
    if (battler.type3 != null) battler.type3!,
    ...battler.temporaryTypes,
  ];
}

PsdkBattleSlotRef _psdkSlotFromBattlePosition(BattlePositionRef slot) {
  return PsdkBattleSlotRef(bank: slot.bank, position: slot.position);
}
