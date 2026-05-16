import 'generated/psdk_move_registry_manifest.dart';
import 'psdk_fight_parity_audit.dart';

/// Non-regression gate based on the latest 2026-05-16 parity audit.
const psdkLot02ParityGate = PsdkParityGatePolicy(
  minimumStrictAttacks: 136,
  minimumStrictMethods: 27,
  minimumKnownOrPartialEffects: 25,
  maximumUnknownMethods: 0,
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
