import 'generated/psdk_move_registry_manifest.dart';
import 'psdk_fight_parity_audit.dart';

/// Non-regression gate based on the latest 2026-05-16 parity audit.
const psdkLot02ParityGate = PsdkParityGatePolicy(
  minimumStrictAttacks: 262,
  minimumStrictMethods: 63,
  minimumKnownOrPartialEffects: 25,
  maximumUnknownMethods: 0,
);

const psdkFinalParityGate = PsdkFinalParityGatePolicy(
  requiredTotalAttacks: 728,
  requiredTotalMethods: 330,
  requiredTotalEffects: 482,
  minimumGoldenFixtures: 1,
);

final class PsdkParityGatePolicy {
  const PsdkParityGatePolicy({
    required this.minimumStrictAttacks,
    required this.minimumStrictMethods,
    required this.minimumKnownOrPartialEffects,
    required this.maximumUnknownMethods,
  });

  final int minimumStrictAttacks;
  final int minimumStrictMethods;
  final int minimumKnownOrPartialEffects;
  final int maximumUnknownMethods;

  PsdkParityGateResult evaluate(PsdkFightParityAudit audit) {
    final failures = <String>[];
    final strictAttacks = audit.attackMetrics.fait;
    final unknownMethods = audit.attackMetrics.unknownMethods;
    final strictMethods =
        audit.methodMetrics.byStatus[PsdkPortStatus.ported] ?? 0;
    final knownOrPartialEffects =
        (audit.effectMetrics.byStatus[PsdkPortStatus.ported] ?? 0) +
            (audit.effectMetrics.byStatus[PsdkPortStatus.partial] ?? 0);

    if (unknownMethods > maximumUnknownMethods) {
      failures.add(
        'unknown_methods=$unknownMethods exceeds maximum '
        '$maximumUnknownMethods',
      );
    }
    if (strictAttacks < minimumStrictAttacks) {
      failures.add(
        'strict_attacks=$strictAttacks is below minimum '
        '$minimumStrictAttacks',
      );
    }
    if (strictMethods < minimumStrictMethods) {
      failures.add(
        'strict_methods=$strictMethods is below minimum '
        '$minimumStrictMethods',
      );
    }
    if (knownOrPartialEffects < minimumKnownOrPartialEffects) {
      failures.add(
        'known_or_partial_effects=$knownOrPartialEffects is below minimum '
        '$minimumKnownOrPartialEffects',
      );
    }

    return PsdkParityGateResult(failures: List.unmodifiable(failures));
  }
}

final class PsdkParityGateResult {
  const PsdkParityGateResult({required this.failures});

  final List<String> failures;

  bool get passed => failures.isEmpty;

  String get message {
    if (passed) {
      return 'PSDK parity gate passed.';
    }
    return 'PSDK parity gate failed:\n- ${failures.join('\n- ')}';
  }
}

final class PsdkFinalParityGatePolicy {
  const PsdkFinalParityGatePolicy({
    required this.requiredTotalAttacks,
    required this.requiredTotalMethods,
    required this.requiredTotalEffects,
    this.approvedOutOfScopeAttacks = 0,
    this.approvedOutOfScopeMethods = 0,
    this.approvedOutOfScopeEffects = 0,
    this.minimumGoldenFixtures = 0,
    this.requireRuntimeBridge = true,
  });

  final int requiredTotalAttacks;
  final int requiredTotalMethods;
  final int requiredTotalEffects;
  final int approvedOutOfScopeAttacks;
  final int approvedOutOfScopeMethods;
  final int approvedOutOfScopeEffects;
  final int minimumGoldenFixtures;
  final bool requireRuntimeBridge;

  PsdkParityGateResult evaluate(
    PsdkFightParityAudit audit, {
    required int goldenFixtureCount,
  }) {
    final failures = <String>[];
    final unknownMethods = audit.attackMetrics.unknownMethods;
    final attacksComplete = audit.attackMetrics.fait;
    final methodsComplete =
        audit.methodMetrics.byStatus[PsdkPortStatus.ported] ?? 0;
    final effectsComplete =
        audit.effectMetrics.byStatus[PsdkPortStatus.ported] ?? 0;

    if (audit.attackMetrics.totalAttacks != requiredTotalAttacks) {
      failures.add(
        'total_attacks=${audit.attackMetrics.totalAttacks} expected '
        '$requiredTotalAttacks',
      );
    }
    if (audit.methodMetrics.totalMethods != requiredTotalMethods) {
      failures.add(
        'total_methods=${audit.methodMetrics.totalMethods} expected '
        '$requiredTotalMethods',
      );
    }
    if (audit.effectMetrics.totalEffects != requiredTotalEffects) {
      failures.add(
        'total_effects=${audit.effectMetrics.totalEffects} expected '
        '$requiredTotalEffects',
      );
    }
    if (unknownMethods != 0) {
      failures.add('unknown_methods=$unknownMethods must be 0');
    }
    _requireCompleteOrApproved(
      failures: failures,
      label: 'attacks',
      complete: attacksComplete,
      required: requiredTotalAttacks,
      approvedOutOfScope: approvedOutOfScopeAttacks,
    );
    _requireCompleteOrApproved(
      failures: failures,
      label: 'methods',
      complete: methodsComplete,
      required: requiredTotalMethods,
      approvedOutOfScope: approvedOutOfScopeMethods,
    );
    _requireCompleteOrApproved(
      failures: failures,
      label: 'effects',
      complete: effectsComplete,
      required: requiredTotalEffects,
      approvedOutOfScope: approvedOutOfScopeEffects,
    );
    if (requireRuntimeBridge && audit.runtimeBridge.status == 'not_measured') {
      failures.add('runtime_bridge status is not measured');
    }
    if (goldenFixtureCount < minimumGoldenFixtures) {
      failures.add(
        'golden_fixtures=$goldenFixtureCount is below minimum '
        '$minimumGoldenFixtures',
      );
    }

    return PsdkParityGateResult(failures: List.unmodifiable(failures));
  }
}

void _requireCompleteOrApproved({
  required List<String> failures,
  required String label,
  required int complete,
  required int required,
  required int approvedOutOfScope,
}) {
  if (complete + approvedOutOfScope >= required) {
    return;
  }
  failures.add(
    '${label}_complete=$complete/$required, '
    'approved_out_of_scope=$approvedOutOfScope',
  );
}
