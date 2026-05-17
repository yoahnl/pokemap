import 'dart:io';

import 'package:map_battle/src/data/generated/psdk_move_registry_manifest.dart';
import 'package:map_battle/src/data/psdk_attack_coverage_report.dart';
import 'package:map_battle/src/data/psdk_fight_parity_audit.dart';
import 'package:map_battle/src/data/psdk_parity_gate.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK parity gate', () {
    test('passes the current Pokemon SDK parity baseline', () async {
      final audit = await buildPsdkFightParityAudit(
        movesDirectory:
            Directory('../../pokémon_sdk_test_project/Data/Studio/moves'),
        psdkBattleDirectory:
            Directory('../../pokemonsdk-development/scripts/5 Battle'),
      );

      final result = psdkLot02ParityGate.evaluate(audit);

      expect(result.passed, isTrue, reason: result.message);
      expect(audit.attackMetrics.fait, 307);
      expect(audit.attackMetrics.unknownMethods, 0);
      expect(audit.methodMetrics.byStatus[PsdkPortStatus.ported], 107);
      expect(audit.effectMetrics.byStatus[PsdkPortStatus.ported], 3);
      expect(audit.effectMetrics.byStatus[PsdkPortStatus.partial], 22);
    });

    test('reports every threshold regression with actionable messages', () {
      final audit = PsdkFightParityAudit.fromEntries(
        sourceDescription: 'regression fixture',
        moves: const <PsdkStudioMoveCoverageEntry>[
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'done_move',
            battleEngineMethod: 's_done',
            type: 'normal',
            category: 'physical',
            power: 40,
            accuracy: '100',
            pp: 35,
            sourceFile: 'done.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'unknown_move',
            battleEngineMethod: 's_unknown',
            type: 'normal',
            category: 'physical',
            power: 40,
            accuracy: '100',
            pp: 35,
            sourceFile: 'unknown.json',
          ),
        ],
        manifest: const <PsdkMoveRegistryManifestEntry>[
          PsdkMoveRegistryManifestEntry(
            battleEngineMethod: 's_done',
            rubyClass: 'Done',
            rubyPath: 'done.rb',
            dartBehavior: 'DoneBehavior',
            status: PsdkPortStatus.ported,
          ),
        ],
        effects: const <PsdkEffectParityEntry>[
          PsdkEffectParityEntry(
            effectName: 'MissingEffect',
            family: 'move',
            status: PsdkPortStatus.missing,
          ),
        ],
      );
      const gate = PsdkParityGatePolicy(
        minimumStrictAttacks: 2,
        minimumStrictMethods: 2,
        minimumKnownOrPartialEffects: 2,
        maximumUnknownMethods: 0,
      );

      final result = gate.evaluate(audit);

      expect(result.passed, isFalse);
      expect(result.failures, hasLength(4));
      expect(
        result.message,
        contains('unknown_methods=1 exceeds maximum 0'),
      );
      expect(
        result.message,
        contains('strict_attacks=1 is below minimum 2'),
      );
      expect(
        result.message,
        contains('strict_methods=1 is below minimum 2'),
      );
      expect(
        result.message,
        contains('known_or_partial_effects=0 is below minimum 2'),
      );
    });
  });
}
