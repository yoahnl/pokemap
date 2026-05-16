import 'dart:convert';

import 'package:map_battle/src/data/generated/psdk_move_registry_manifest.dart';
import 'package:map_battle/src/data/psdk_attack_coverage_report.dart';
import 'package:map_battle/src/data/psdk_fight_parity_audit.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK fight parity audit', () {
    test('counts attacks methods effects and renders machine output', () {
      final audit = PsdkFightParityAudit.fromEntries(
        sourceDescription: 'fixture',
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
            dbSymbol: 'partial_move',
            battleEngineMethod: 's_partial',
            type: 'water',
            category: 'status',
            power: 0,
            accuracy: 'always',
            pp: 20,
            sourceFile: 'partial.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'unknown_move',
            battleEngineMethod: 's_unknown',
            type: 'grass',
            category: 'special',
            power: 80,
            accuracy: '90',
            pp: 10,
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
          PsdkMoveRegistryManifestEntry(
            battleEngineMethod: 's_partial',
            rubyClass: 'Partial',
            rubyPath: 'partial.rb',
            dartBehavior: 'PartialBehavior',
            status: PsdkPortStatus.partial,
          ),
        ],
        effects: const <PsdkEffectParityEntry>[
          PsdkEffectParityEntry(
            effectName: 'Protect',
            family: 'move',
            status: PsdkPortStatus.partial,
          ),
          PsdkEffectParityEntry(
            effectName: 'FlashFire',
            family: 'ability',
            status: PsdkPortStatus.missing,
          ),
        ],
      );

      expect(audit.attackMetrics.totalAttacks, 3);
      expect(audit.attackMetrics.fait, 1);
      expect(audit.attackMetrics.partiel, 1);
      expect(audit.attackMetrics.pasFait, 1);
      expect(audit.attackMetrics.unknownMethods, 1);
      expect(audit.methodMetrics.byStatus[PsdkPortStatus.ported], 1);
      expect(audit.methodMetrics.byStatus[PsdkPortStatus.partial], 1);
      expect(audit.effectMetrics.totalEffects, 2);
      expect(
        audit.effectMetrics.byFamilyAndStatus['move']![PsdkPortStatus.partial],
        1,
      );

      final json = audit.toJson();
      final runtimeBridge = json['runtimeBridge']! as Map<String, Object?>;
      expect(runtimeBridge['status'], 'not_measured');
      expect(jsonEncode(json), contains('"totalAttacks":3'));

      final markdown = audit.toMarkdown();
      expect(markdown, contains('| Studio attacks `fait` | 1 |'));
      expect(
        markdown,
        contains('`partiel` is executable coverage, not strict PSDK parity.'),
      );
      expect(markdown, contains('| move | 0 | 1 | 0 |'));
    });
  });
}
