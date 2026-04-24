import 'package:flutter_test/flutter_test.dart';

import '../tool/battle_animation_visual_source_report.dart';

void main() {
  group('BattleAnimationVisualSourceReport', () {
    test('reports one row per normalized move id with target counters', () {
      final report = buildBattleAnimationVisualSourceReport();

      expect(
        report.rows.map((row) => row.moveId).toSet(),
        hasLength(report.rows.length),
      );
      expect(report.rows, hasLength(952));
      expect(report.countBySource['needs visual retune'] ?? 0, equals(0));
      expect(
        report.countBySource['SDK family fallback'] ?? 0,
        lessThanOrEqualTo(222),
      );
      expect(report.countBySource['exact Ruby verified'] ?? 0, equals(18));
      expect(report.countBySource['adapted'] ?? 0, greaterThanOrEqualTo(56));
    });

    test('lists duplicate aliases separately instead of duplicate rows', () {
      final report = buildBattleAnimationVisualSourceReport();
      final duplicateIds = report.duplicateAliases
          .map((duplicate) => duplicate.normalizedMoveId)
          .toSet();

      expect(
        duplicateIds,
        containsAll(<String>{
          'aquatail',
          'leechseed',
          'poisonpowder',
          'sleeppowder',
          'stunspore',
          'thunderwave',
          'vinewhip',
        }),
      );
    });

    test('retuned sdk variants are adapted instead of visual retune', () {
      final report = buildBattleAnimationVisualSourceReport();
      final rowsById = <String, BattleAnimationVisualSourceRow>{
        for (final row in report.rows) row.moveId: row,
      };

      for (final moveId in const <String>[
        'aciddownpour2',
        'alloutpummeling2',
        'blackholeeclipse2',
        'bloomdoom2',
        'breakneckblitz2',
        'continentalcrush2',
        'corkscrewcrash2',
        'devastatingdrake2',
        'gigavolthavoc2',
        'hydrovortex2',
        'infernooverdrive2',
        'neverendingnightmare2',
        'savagespinout2',
        'shatteredpsyche2',
        'subzeroslammer2',
        'supersonicskystrike2',
        'tectonicrage2',
        'twinkletackle2',
        's10000000voltthunderbolt',
        '10000000voltthunderbolt',
      ]) {
        expect(rowsById[moveId]?.visualSource, equals('adapted'));
        expect(rowsById[moveId]?.recipeId, isNotNull);
      }
    });

    test('aliases into exact Ruby recipes do not inflate exact counts', () {
      final report = buildBattleAnimationVisualSourceReport();
      final rowsById = <String, BattleAnimationVisualSourceRow>{
        for (final row in report.rows) row.moveId: row,
      };

      expect(rowsById['electrify']?.visualSource, 'exact RMXP verified');
      expect(rowsById['razorwind']?.visualSource, 'exact RMXP verified');
      expect(rowsById['synthesis']?.visualSource, 'exact RMXP verified');
      expect(rowsById['branchpoke']?.visualSource, 'SDK family fallback');
    });

    test('aliases into adapted Z and Max routes stay adapted', () {
      final report = buildBattleAnimationVisualSourceReport();
      final rowsById = <String, BattleAnimationVisualSourceRow>{
        for (final row in report.rows) row.moveId: row,
      };

      for (final moveId in const <String>[
        'maxlightning',
        'maxphantasm',
        'gmaxvinelash',
        'gmaxdepletion',
        'maxstrike',
        'poltergeist',
      ]) {
        expect(rowsById[moveId]?.visualSource, 'adapted', reason: moveId);
      }
    });

    test('critical RMXP position-3 moves have audited placement policies', () {
      final report = buildBattleAnimationVisualSourceReport();

      expect(report.rmxpPosition3Count, greaterThan(0));
      expect(
        report.rmxpPlacementPolicyCounts['projectileLine'] ?? 0,
        greaterThan(0),
      );
      expect(
        report.rmxpPlacementPolicyCounts['targetImpact'] ?? 0,
        greaterThan(0),
      );
      expect(
        report.criticalAnchorsVerified,
        containsAll(<String>[
          'megapunch',
          'swift',
          'dragonbreath',
          'watergun',
          'stringshot',
        ]),
      );
      expect(report.needsPlacementReview, isEmpty);
    });
  });
}
