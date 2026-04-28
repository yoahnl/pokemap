import 'package:map_battle/src/data/generated/psdk_move_registry_manifest.dart';
import 'package:map_battle/src/data/psdk_attack_coverage_report.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK attack coverage report', () {
    test('classifies Studio moves from their battle engine method status', () {
      final report = generatePsdkAttackCoverageReport(
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
            dbSymbol: 'missing_move',
            battleEngineMethod: 's_missing',
            type: 'grass',
            category: 'special',
            power: 80,
            accuracy: '90',
            pp: 10,
            sourceFile: 'missing.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'unknown|move',
            battleEngineMethod: 's_unknown',
            type: 'ghost',
            category: 'status',
            power: 0,
            accuracy: '0',
            pp: 5,
            sourceFile: 'unknown.json',
          ),
          PsdkStudioMoveCoverageEntry(
            dbSymbol: 'z_move',
            battleEngineMethod: 's_z_move',
            type: 'electric',
            category: 'physical',
            power: 210,
            accuracy: '0',
            pp: 1,
            sourceFile: 'z_move.json',
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
          PsdkMoveRegistryManifestEntry(
            battleEngineMethod: 's_missing',
            rubyClass: 'Missing',
            rubyPath: 'missing.rb',
            dartBehavior: 'TODO',
            status: PsdkPortStatus.missing,
          ),
        ],
        sourceDescription: 'test moves',
      );

      expect(report, contains('| total_attacks | 5 |'));
      expect(report, contains('| fait | 1 |'));
      expect(report, contains('| partiel | 2 |'));
      expect(report, contains('| pas_fait | 2 |'));
      expect(report, contains('| unknown_methods | 1 |'));
      expect(
        report,
        contains('| pas_fait | unknown\\|move | s_unknown | unknown_method |'),
      );
      expect(
        report,
        contains(
          '| partiel | z_move | s_z_move | partial | StaticBasicMoveRegistry.s_z_move |',
        ),
      );
    });
  });
}
