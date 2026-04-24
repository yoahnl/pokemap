import 'battle_animation_plan.dart';
import 'battle_sdk_rmxp_animation_catalog.dart';

final class RmxpMovePlacementCatalog {
  const RmxpMovePlacementCatalog._();

  static const Map<String, RmxpPlacementPolicy> auditedCriticalMovePolicies =
      <String, RmxpPlacementPolicy>{
    'megapunch': RmxpPlacementPolicy.targetImpact,
    'swift': RmxpPlacementPolicy.projectileLine,
    'dragonbreath': RmxpPlacementPolicy.projectileLine,
    'watergun': RmxpPlacementPolicy.projectileLine,
    'stringshot': RmxpPlacementPolicy.projectileLine,
    'thundershock': RmxpPlacementPolicy.targetImpact,
    'thunderbolt': RmxpPlacementPolicy.targetImpact,
    'shockwave': RmxpPlacementPolicy.targetImpact,
    'electroball': RmxpPlacementPolicy.projectileLine,
  };

  static const Map<String, RmxpPlacementSpec> _targetOverrides =
      <String, RmxpPlacementSpec>{
    'megapunch': RmxpPlacementSpec(
      policy: RmxpPlacementPolicy.targetImpact,
      anchor: BattleVisualAnchor.defenderImpact,
    ),
    'swift': RmxpPlacementSpec(
      policy: RmxpPlacementPolicy.projectileLine,
      sourceAnchor: BattleVisualAnchor.attackerHand,
      targetAnchor: BattleVisualAnchor.defenderImpact,
    ),
    'dragonbreath': RmxpPlacementSpec(
      policy: RmxpPlacementPolicy.projectileLine,
      sourceAnchor: BattleVisualAnchor.attackerMouth,
      targetAnchor: BattleVisualAnchor.defenderImpact,
      rotateToLine: true,
    ),
    'watergun': RmxpPlacementSpec(
      policy: RmxpPlacementPolicy.projectileLine,
      sourceAnchor: BattleVisualAnchor.attackerMouth,
      targetAnchor: BattleVisualAnchor.defenderImpact,
      rotateToLine: true,
    ),
    'stringshot': RmxpPlacementSpec(
      policy: RmxpPlacementPolicy.projectileLine,
      sourceAnchor: BattleVisualAnchor.attackerMouth,
      targetAnchor: BattleVisualAnchor.defenderImpact,
      rotateToLine: true,
    ),
    'thundershock': RmxpPlacementSpec(
      policy: RmxpPlacementPolicy.targetImpact,
      anchor: BattleVisualAnchor.defenderImpact,
    ),
    'thunderbolt': RmxpPlacementSpec(
      policy: RmxpPlacementPolicy.targetImpact,
      anchor: BattleVisualAnchor.defenderImpact,
    ),
    'shockwave': RmxpPlacementSpec(
      policy: RmxpPlacementPolicy.targetImpact,
      anchor: BattleVisualAnchor.defenderImpact,
    ),
    'electroball': RmxpPlacementSpec(
      policy: RmxpPlacementPolicy.projectileLine,
      sourceAnchor: BattleVisualAnchor.attackerHand,
      targetAnchor: BattleVisualAnchor.defenderImpact,
      rotateToLine: true,
    ),
  };

  static RmxpPlacementSpec resolve({
    required String? sdkMoveId,
    required int animationId,
    required RmxpPlacementPhase phase,
    required RmxpAnimationSpec animation,
  }) {
    if (phase == RmxpPlacementPhase.target && sdkMoveId != null) {
      final override = _targetOverrides[sdkMoveId];
      if (override != null) {
        return override;
      }
    }

    if (phase == RmxpPlacementPhase.user) {
      return const RmxpPlacementSpec(
        policy: RmxpPlacementPolicy.attackerCast,
        anchor: BattleVisualAnchor.attackerBody,
        isImplicit: true,
      );
    }

    if (animation.position == 3) {
      return const RmxpPlacementSpec(
        policy: RmxpPlacementPolicy.sdkStage,
        anchor: BattleVisualAnchor.stageCenter,
        isImplicit: true,
      );
    }

    return const RmxpPlacementSpec(
      policy: RmxpPlacementPolicy.subjectAttached,
      anchor: BattleVisualAnchor.defenderImpact,
      isImplicit: true,
    );
  }

  static Map<String, RmxpPlacementSpec> get criticalMovePlacementSpecs =>
      Map<String, RmxpPlacementSpec>.unmodifiable(_targetOverrides);
}
