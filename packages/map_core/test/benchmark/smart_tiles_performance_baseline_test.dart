import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../../../../tools/performance/smart_tiles_performance_baseline.dart';

void main() {
  const targetId = 'macos-arm64-example';
  final baseline = <String, Object?>{
    'schemaVersion': 1,
    'target': <String, Object?>{'id': targetId},
    'benchmarks': <String, Object?>{
      'example': <String, Object?>{
        'rows': <String, Object?>{
          '128': <String, Object?>{
            'expectedValues': <String, Object?>{
              'fixtureChecksum': 'fixture-128',
            },
            'workBudgets': <String, Object?>{
              'viewportWorkCounts.resolvedVisualCount': 500,
            },
            'timingBudgetsUs': <String, Object?>{
              'profiles.viewportResolve.p95Us': 2000,
            },
          },
        },
      },
    },
  };

  Map<String, Object?> receipt({
    int work = 400,
    int p95Us = 1500,
    String checksum = 'fixture-128',
  }) =>
      <String, Object?>{
        'benchmark': 'example',
        'results': <Object?>[
          <String, Object?>{
            'extent': 128,
            'fixtureChecksum': checksum,
            'viewportWorkCounts': <String, Object?>{
              'resolvedVisualCount': work,
            },
            'profiles': <String, Object?>{
              'viewportResolve': <String, Object?>{'p95Us': p95Us},
            },
          },
        ],
      };

  test('accepts matching identity and portable work counts', () {
    expect(
      verifySmartTilesPerformanceBaseline(
        baseline: baseline,
        receipts: <Map<String, Object?>>[receipt(p95Us: 999999)],
      ),
      isEmpty,
    );
  });

  test('reports deterministic identity and work regressions', () {
    expect(
      verifySmartTilesPerformanceBaseline(
        baseline: baseline,
        receipts: <Map<String, Object?>>[
          receipt(work: 501, checksum: 'changed'),
        ],
      ),
      <String>[
        'example[128] fixtureChecksum expected fixture-128, got changed',
        'example[128] viewportWorkCounts.resolvedVisualCount=501 exceeds 500',
      ],
    );
  });

  test('enforces timings only for the explicitly matching target', () {
    expect(
      verifySmartTilesPerformanceBaseline(
        baseline: baseline,
        receipts: <Map<String, Object?>>[receipt(p95Us: 2001)],
        enforceTimingsForTargetId: targetId,
      ),
      <String>[
        'example[128] profiles.viewportResolve.p95Us=2001 exceeds 2000',
      ],
    );
    expect(
      () => verifySmartTilesPerformanceBaseline(
        baseline: baseline,
        receipts: <Map<String, Object?>>[receipt()],
        enforceTimingsForTargetId: 'another-target',
      ),
      throwsFormatException,
    );
  });

  test('requires every configured benchmark row', () {
    expect(
      verifySmartTilesPerformanceBaseline(
        baseline: baseline,
        receipts: const <Map<String, Object?>>[],
      ),
      <String>['missing receipt for benchmark example'],
    );
  });

  test('checked-in target baseline covers every STN-11 scaling harness', () {
    final decoded = jsonDecode(
      File(
        '../../tools/performance/baselines/'
        'smart_tiles_m1_pro_macos27.json',
      ).readAsStringSync(),
    );
    final checkedIn = Map<String, Object?>.from(decoded as Map);
    final benchmarks = Map<String, Object?>.from(
      checkedIn['benchmarks']! as Map,
    );

    expect(
      benchmarks.keys,
      <String>[
        'smart_tiles_rich_map_scaling',
        'smart_tiles_rich_authoring_scaling',
        'smart_tiles_rich_editor_scaling',
        'smart_tiles_rich_runtime_scaling',
      ],
    );
    for (final rawBenchmark in benchmarks.values) {
      final benchmark = Map<String, Object?>.from(rawBenchmark! as Map);
      final rows = Map<String, Object?>.from(benchmark['rows']! as Map);
      expect(rows.keys, <String>['128', '256', '512', '1024']);
    }
  });
}
