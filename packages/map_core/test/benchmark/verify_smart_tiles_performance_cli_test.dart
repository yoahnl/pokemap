import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../../../../tools/performance/benchmark_support.dart';

void main() {
  test('verifies portable budgets and optional target timings', () async {
    await Directory('build/test').create(recursive: true);
    final directory = await Directory('build/test').createTemp(
      'smart_tiles_baseline_cli_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final baseline = File('${directory.path}/baseline.json');
    final receipt = File('${directory.path}/receipt.json');
    await baseline.writeAsString(
      jsonEncode(<String, Object?>{
        'schemaVersion': 1,
        'target': <String, Object?>{'id': 'test-target'},
        'benchmarks': <String, Object?>{
          'example': <String, Object?>{
            'rows': <String, Object?>{
              '128': <String, Object?>{
                'workBudgets': <String, Object?>{'work.count': 2},
                'timingBudgetsUs': <String, Object?>{
                  'profiles.paint.p95Us': 10,
                },
              },
            },
          },
        },
      }),
    );
    final sourceIdentity = await currentPerformanceSourceIdentity();
    await receipt.writeAsString(
      jsonEncode(<String, Object?>{
        'benchmark': 'example',
        ...sourceIdentity,
        'results': <Object?>[
          <String, Object?>{
            'extent': 128,
            'work': <String, Object?>{'count': 2},
            'profiles': <String, Object?>{
              'paint': <String, Object?>{'p95Us': 11},
            },
          },
        ],
      }),
    );

    final portable = await _run(<String>[
      '--baseline',
      baseline.path,
      '--receipt',
      receipt.path,
    ]);
    final timed = await _run(<String>[
      '--baseline',
      baseline.path,
      '--receipt',
      receipt.path,
      '--enforce-time',
      'test-target',
    ]);

    expect(portable.exitCode, 0, reason: '${portable.stderr}');
    expect('${portable.stdout}', contains('"status":"pass"'));
    expect(timed.exitCode, 1);
    expect(
      '${timed.stderr}',
      contains('profiles.paint.p95Us=11 exceeds 10'),
    );
  });

  test('rejects historical receipts unless explicitly allowed', () async {
    await Directory('build/test').create(recursive: true);
    final directory = await Directory('build/test').createTemp(
      'smart_tiles_historical_receipt_cli_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final baseline = File('${directory.path}/baseline.json');
    final receipt = File('${directory.path}/receipt.json');
    await baseline.writeAsString(
      jsonEncode(<String, Object?>{
        'schemaVersion': 1,
        'target': <String, Object?>{'id': 'test-target'},
        'benchmarks': <String, Object?>{
          'example': <String, Object?>{
            'rows': <String, Object?>{
              '128': <String, Object?>{},
            },
          },
        },
      }),
    );
    await receipt.writeAsString(
      jsonEncode(<String, Object?>{
        'benchmark': 'example',
        'commit': 'historical-commit',
        'treeState': 'clean',
        'treeFingerprint': 'historical-fingerprint',
        'results': <Object?>[
          <String, Object?>{'extent': 128},
        ],
      }),
    );

    final currentOnly = await _run(<String>[
      '--baseline',
      baseline.path,
      '--receipt',
      receipt.path,
    ]);
    final historical = await _run(<String>[
      '--baseline',
      baseline.path,
      '--receipt',
      receipt.path,
      '--allow-historical',
    ]);

    expect(currentOnly.exitCode, 1);
    expect('${currentOnly.stderr}', contains('receipt commit'));
    expect(historical.exitCode, 0, reason: '${historical.stderr}');
  });
}

Future<ProcessResult> _run(List<String> arguments) => Process.run(
      Platform.resolvedExecutable,
      <String>[
        'run',
        '../../tools/performance/verify_smart_tiles_performance.dart',
        ...arguments,
      ],
      workingDirectory: Directory.current.path,
    );
