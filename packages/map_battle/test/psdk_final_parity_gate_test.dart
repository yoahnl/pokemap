import 'package:map_battle/src/data/generated/psdk_move_registry_manifest.dart';
import 'package:map_battle/src/data/psdk_fight_parity_audit.dart';
import 'package:map_battle/src/data/psdk_parity_gate.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK final parity gate', () {
    test('requires the phase E golden fixture floor', () {
      expect(psdkFinalParityGate.minimumGoldenFixtures, 3);
      expect(
        psdkFinalParityGate.requiredGoldenTags,
        containsAll(<String>['move_method', 'status', 'field']),
      );
    });

    test('fails if any required axis lacks ported or approved status', () {
      final audit = PsdkFightParityAudit(
        sourceDescription: 'incomplete fixture',
        attackMetrics: const PsdkAttackParityMetrics(
          totalAttacks: 3,
          uniqueBattleEngineMethods: 3,
          fait: 1,
          partiel: 1,
          pasFait: 1,
          unknownMethods: 1,
        ),
        methodMetrics: PsdkMethodParityMetrics(
          totalMethods: 2,
          byStatus: _counts(ported: 1, partial: 1),
        ),
        effectMetrics: PsdkEffectParityMetrics(
          totalEffects: 2,
          byStatus: _counts(ported: 1, missing: 1),
          byFamilyAndStatus: <String, Map<PsdkPortStatus, int>>{
            'move': _counts(ported: 1, missing: 1),
          },
        ),
      );

      const gate = PsdkFinalParityGatePolicy(
        requiredTotalAttacks: 3,
        requiredTotalMethods: 2,
        requiredTotalEffects: 2,
        minimumGoldenFixtures: 2,
      );

      final result = gate.evaluate(
        audit,
        goldenFixtureCount: 0,
        goldenTags: const <String>{},
      );

      expect(result.passed, isFalse);
      expect(result.message, contains('unknown_methods=1 must be 0'));
      expect(
        result.message,
        contains('attacks_complete=1/3, approved_out_of_scope=0'),
      );
      expect(
        result.message,
        contains('methods_complete=1/2, approved_out_of_scope=0'),
      );
      expect(
        result.message,
        contains('effects_complete=1/2, approved_out_of_scope=0'),
      );
      expect(result.message, contains('runtime_bridge status is not measured'));
      expect(result.message, contains('golden_fixtures=0 is below minimum 2'));
    });

    test('fails if required golden evidence tags are missing', () {
      final audit = PsdkFightParityAudit(
        sourceDescription: 'complete fixture',
        attackMetrics: const PsdkAttackParityMetrics(
          totalAttacks: 1,
          uniqueBattleEngineMethods: 1,
          fait: 1,
          partiel: 0,
          pasFait: 0,
          unknownMethods: 0,
        ),
        methodMetrics: PsdkMethodParityMetrics(
          totalMethods: 1,
          byStatus: _counts(ported: 1),
        ),
        effectMetrics: PsdkEffectParityMetrics(
          totalEffects: 1,
          byStatus: _counts(ported: 1),
          byFamilyAndStatus: <String, Map<PsdkPortStatus, int>>{
            'move': _counts(ported: 1),
          },
        ),
        runtimeBridge: const PsdkRuntimeBridgeParity(
          status: 'explained',
          reason: 'fixture',
        ),
      );

      const gate = PsdkFinalParityGatePolicy(
        requiredTotalAttacks: 1,
        requiredTotalMethods: 1,
        requiredTotalEffects: 1,
        minimumGoldenFixtures: 1,
        requiredGoldenTags: <String>{'move_method', 'status', 'field'},
      );

      final result = gate.evaluate(
        audit,
        goldenFixtureCount: 1,
        goldenTags: const <String>{'move_method'},
      );

      expect(result.passed, isFalse);
      expect(
        result.message,
        contains('golden_tags missing required tags: field, status'),
      );
    });

    test('passes with complete coverage or explicit approved out-of-scope gaps',
        () {
      final audit = PsdkFightParityAudit(
        sourceDescription: 'complete fixture',
        attackMetrics: const PsdkAttackParityMetrics(
          totalAttacks: 3,
          uniqueBattleEngineMethods: 2,
          fait: 2,
          partiel: 1,
          pasFait: 0,
          unknownMethods: 0,
        ),
        methodMetrics: PsdkMethodParityMetrics(
          totalMethods: 2,
          byStatus: _counts(ported: 1, partial: 1),
        ),
        effectMetrics: PsdkEffectParityMetrics(
          totalEffects: 2,
          byStatus: _counts(ported: 1, missing: 1),
          byFamilyAndStatus: <String, Map<PsdkPortStatus, int>>{
            'move': _counts(ported: 1, missing: 1),
          },
        ),
        runtimeBridge: const PsdkRuntimeBridgeParity(
          status: 'explained',
          reason: 'All unsupported playable moves have diagnostics.',
        ),
      );

      const gate = PsdkFinalParityGatePolicy(
        requiredTotalAttacks: 3,
        requiredTotalMethods: 2,
        requiredTotalEffects: 2,
        approvedOutOfScopeAttacks: 1,
        approvedOutOfScopeMethods: 1,
        approvedOutOfScopeEffects: 1,
        minimumGoldenFixtures: 2,
      );

      final result = gate.evaluate(
        audit,
        goldenFixtureCount: 2,
        goldenTags: const <String>{'move_method'},
      );

      expect(result.passed, isTrue, reason: result.message);
    });
  });
}

Map<PsdkPortStatus, int> _counts({
  int ported = 0,
  int partial = 0,
  int missing = 0,
}) {
  return <PsdkPortStatus, int>{
    PsdkPortStatus.ported: ported,
    PsdkPortStatus.partial: partial,
    PsdkPortStatus.missing: missing,
  };
}
