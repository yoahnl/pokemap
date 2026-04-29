import '../../psdk/domain/psdk_battle_combatant.dart';
import '../../psdk/domain/psdk_battle_move.dart';
import '../../psdk/domain/psdk_battle_slots.dart';
import '../battle/battle_slot.dart';
import '../battler/battle_grounding_resolver.dart';
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

      if (!ignoreProtect && _isBlockedByProtect(execution, targetRef)) {
        failureReason = BattleMoveFailureReason.protected;
        execution.timeline.add(
          BattleMoveFailedTimelineEvent(
            turn: execution.turn,
            user: execution.actualUser,
            target: targetRef,
            moveId: execution.move.id,
            reason: BattleMoveFailureReason.protected.jsonName,
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

  bool _isGroundMoveBlockedByGrounding(
    String moveType,
    PsdkBattleCombatant target,
  ) {
    return moveType == 'ground' && !_groundingResolver.isGrounded(target);
  }

  bool _isBlockedByProtect(
    BattleMoveProcedureExecution execution,
    BattlePositionRef targetRef,
  ) {
    if (targetRef == execution.actualUser ||
        !execution.move.flags.protectable) {
      return false;
    }
    final target = execution.context.state.battlerAt(
      _psdkSlotFromBattlePosition(targetRef),
    );
    return target.effects.targetMovePreventionReason(
          user: execution.actualUser,
          target: targetRef,
          move: execution.move,
        ) ==
        BattleMoveFailureReason.protected;
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
