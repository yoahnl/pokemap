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
            rubyPath: '06 Effects/02 Move Effects/001 Protect.rb',
            status: PsdkPortStatus.partial,
          ),
          PsdkEffectParityEntry(
            effectName: 'FlashFire',
            family: 'ability',
            rubyPath: '06 Effects/04 Ability Effects/100 Flash Fire.rb',
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
      final attacks = (json['attacks']! as Map<String, Object?>)['entries']!
          as List<Object?>;
      expect(attacks, hasLength(3));
      expect(
        attacks.cast<Map<String, Object?>>().singleWhere(
              (entry) => entry['moveId'] == 'partial_move',
            ),
        containsPair('reason', 'method_partial'),
      );
      final methods = (json['methods']! as Map<String, Object?>)['entries']!
          as List<Object?>;
      expect(methods, hasLength(2));
      expect(
        methods.cast<Map<String, Object?>>().singleWhere(
              (entry) => entry['battleEngineMethod'] == 's_done',
            ),
        containsPair('rubyPath', 'done.rb'),
      );
      final effects = (json['effects']! as Map<String, Object?>)['entries']!
          as List<Object?>;
      expect(effects, hasLength(2));
      expect(
        effects.cast<Map<String, Object?>>().first,
        containsPair('rubyPath', '06 Effects/02 Move Effects/001 Protect.rb'),
      );
      final runtimeBridge = json['runtimeBridge']! as Map<String, Object?>;
      expect(runtimeBridge['status'], 'not_measured');
      expect(jsonEncode(json), contains('"totalAttacks":3'));

      final markdown = audit.toMarkdown();
      expect(markdown, contains('| Studio attacks `fait` | 1 |'));
      expect(markdown, contains('### Partial Attacks by Method'));
      expect(markdown, contains('| s_partial | 1 |'));
      expect(markdown, contains('### Partial Methods by Dependency'));
      expect(markdown, contains('| no_dependency_declared | 1 |'));
      expect(markdown, contains('### Missing Effects by Family'));
      expect(markdown, contains('| ability | 1 |'));
      expect(
        markdown,
        contains('`partiel` is executable coverage, not strict PSDK parity.'),
      );
      expect(markdown, contains('| move | 0 | 1 | 0 |'));
    });

    test('renders imported runtime bridge diagnostics', () {
      final runtimeBridge = PsdkRuntimeBridgeParity.fromJson(
        const <String, Object?>{
          'status': 'explained',
          'reason': 'All rejected moves carry diagnostics.',
          'totalMoves': 2,
          'bridgeableMoves': 1,
          'rejectedMoves': 1,
          'explainedRejectedMoves': 1,
          'unexplainedRejectedMoves': 0,
          'moves': <Object?>[
            <String, Object?>{
              'moveId': 'tackle',
              'bridgeable': true,
              'reason': 'bridgeable',
              'battleEngineMethod': 's_basic',
              'psdkRegistryStatus': 'ported',
              'unsupportedReasons': <Object?>[],
            },
            <String, Object?>{
              'moveId': 'baton_pass',
              'bridgeable': false,
              'reason': 'unsupported_effect_kind:self_switch',
              'battleEngineMethod': 's_baton_pass',
              'psdkRegistryStatus': 'partial',
              'unsupportedReasons': <Object?>[
                'unsupported_effect_kind:self_switch',
              ],
            },
          ],
        },
      );
      final audit = PsdkFightParityAudit(
        sourceDescription: 'fixture',
        attackMetrics: const PsdkAttackParityMetrics(
          totalAttacks: 0,
          uniqueBattleEngineMethods: 0,
          fait: 0,
          partiel: 0,
          pasFait: 0,
          unknownMethods: 0,
        ),
        methodMetrics: const PsdkMethodParityMetrics(
          totalMethods: 0,
          byStatus: <PsdkPortStatus, int>{},
        ),
        effectMetrics: const PsdkEffectParityMetrics(
          totalEffects: 0,
          byStatus: <PsdkPortStatus, int>{},
          byFamilyAndStatus: <String, Map<PsdkPortStatus, int>>{},
        ),
        runtimeBridge: runtimeBridge,
      );

      final json = audit.toJson()['runtimeBridge']! as Map<String, Object?>;

      expect(json['status'], 'explained');
      expect(json['unexplainedRejectedMoves'], 0);
      expect(json['moves'], isA<List<Object?>>());
      expect(audit.toMarkdown(), contains('| Total moves | 2 |'));
      expect(
          audit.toMarkdown(), contains('| Unexplained rejected moves | 0 |'));
    });
  });
}
