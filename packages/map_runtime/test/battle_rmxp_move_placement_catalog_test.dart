import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_plan.dart';
import 'package:map_runtime/src/presentation/flame/battle_rmxp_move_placement_catalog.dart';
import 'package:map_runtime/src/presentation/flame/battle_sdk_rmxp_animation_catalog.dart';

void main() {
  group('RmxpMovePlacementCatalog', () {
    test('routes critical RMXP moves to explicit placement policies', () {
      const expectations =
          <String, ({int animationId, RmxpPlacementPolicy policy})>{
        'megapunch': (animationId: 5, policy: RmxpPlacementPolicy.targetImpact),
        'swift': (animationId: 129, policy: RmxpPlacementPolicy.projectileLine),
        'dragonbreath': (
          animationId: 225,
          policy: RmxpPlacementPolicy.projectileLine
        ),
        'watergun': (
          animationId: 55,
          policy: RmxpPlacementPolicy.projectileLine
        ),
        'stringshot': (
          animationId: 81,
          policy: RmxpPlacementPolicy.projectileLine
        ),
        'thundershock': (
          animationId: 84,
          policy: RmxpPlacementPolicy.targetImpact
        ),
        'thunderbolt': (
          animationId: 85,
          policy: RmxpPlacementPolicy.targetImpact
        ),
        'shockwave': (
          animationId: 351,
          policy: RmxpPlacementPolicy.targetImpact
        ),
      };

      for (final entry in expectations.entries) {
        final spec = RmxpMovePlacementCatalog.resolve(
          sdkMoveId: entry.key,
          animationId: entry.value.animationId,
          phase: RmxpPlacementPhase.target,
          animation:
              BattleSdkRmxpAnimationCatalog.require(entry.value.animationId),
        );

        expect(spec.policy, entry.value.policy, reason: entry.key);
        expect(spec.isImplicit, isFalse, reason: entry.key);
      }
    });

    test('defaults screen-position target animations to SDK stage, not line',
        () {
      final spec = RmxpMovePlacementCatalog.resolve(
        sdkMoveId: 'unknown-critical',
        animationId: 1,
        phase: RmxpPlacementPhase.target,
        animation: BattleSdkRmxpAnimationCatalog.require(1),
      );

      expect(spec.policy, equals(RmxpPlacementPolicy.sdkStage));
      expect(spec.isImplicit, isTrue);
    });

    test('defaults user animations to attacker cast', () {
      final spec = RmxpMovePlacementCatalog.resolve(
        sdkMoveId: 'megapunch',
        animationId: 440,
        phase: RmxpPlacementPhase.user,
        animation: BattleSdkRmxpAnimationCatalog.require(440),
      );

      expect(spec.policy, equals(RmxpPlacementPolicy.attackerCast));
      expect(spec.anchor, equals(BattleVisualAnchor.attackerBody));
    });

    test('documents every audited critical policy with a concrete override',
        () {
      for (final entry
          in RmxpMovePlacementCatalog.auditedCriticalMovePolicies.entries) {
        final override =
            RmxpMovePlacementCatalog.criticalMovePlacementSpecs[entry.key];

        expect(override, isNotNull, reason: entry.key);
        expect(override!.policy, equals(entry.value), reason: entry.key);
      }
    });
  });
}
