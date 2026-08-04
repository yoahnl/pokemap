import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('writes transactional rich import and recovery evidence', () async {
    final output = await _temporaryOutput('smart_tiles_rich_authoring');
    final result = await _run(<String>[
      '--warmups',
      '0',
      '--samples',
      '1',
      '--recovery-samples',
      '1',
      '--extents',
      '128',
      '--output',
      output.path,
    ]);

    expect(result.exitCode, 0, reason: '${result.stderr}');
    final payload =
        jsonDecode(await output.readAsString()) as Map<String, Object?>;
    expect(payload['schemaVersion'], 2);
    expect(payload['benchmark'], 'smart_tiles_rich_authoring_scaling');
    final rows =
        (payload['results']! as List<Object?>).cast<Map<String, Object?>>();
    expect(rows, hasLength(1));
    final row = rows.single;
    expect(row['extent'], 128);
    expect('${row['datasetFingerprint']}', isNotEmpty);
    expect(row['rssBytesAfterSamples'], isA<int>());

    final profiles = Map<String, Object?>.from(row['profiles']! as Map);
    expect(
      profiles.keys,
      containsAll(<String>['plan', 'apply', 'reopen', 'recovery']),
    );
    for (final name in const <String>['plan', 'apply', 'reopen']) {
      final profile = Map<String, Object?>.from(profiles[name]! as Map);
      expect(profile['samplesUs'], hasLength(1));
      expect(profile['p50Us'], isA<int>());
      expect(profile['p95Us'], isA<int>());
      expect(profile['maxUs'], isA<int>());
      expect('${profile['checksum']}', isNotEmpty);
    }
    final recovery = Map<String, Object?>.from(profiles['recovery']! as Map);
    expect(recovery['samplesUs'], hasLength(1));
    expect('${recovery['checksum']}', isNotEmpty);

    final work = Map<String, Object?>.from(row['workCounts']! as Map);
    expect(work['sourceCellCount'], 128 * 128 * 3);
    expect(work['tileLayerCount'], 3);
    expect(work['objectCount'], greaterThan(0));
    expect(work['affectedResourceCount'], greaterThanOrEqualTo(4));
    expect(work['diffEntryCount'], greaterThanOrEqualTo(4));
    expect(work['journalBytes'], greaterThan(0));
    expect(work['recoveredResourceCount'], greaterThanOrEqualTo(4));
    expect('${row['reopenedSnapshotChecksum']}', isNotEmpty);
  });

  test('rejects unsupported extents and escaped output', () async {
    final unsupported = await _run(const <String>[
      '--samples',
      '1',
      '--extents',
      '64',
      '--output',
      'build/test/rich-authoring-invalid.json',
    ]);
    final escaped = await _run(const <String>[
      '--samples',
      '1',
      '--extents',
      '128',
      '--output',
      '../rich-authoring-escape.json',
    ]);

    expect(unsupported.exitCode, 64);
    expect('${unsupported.stderr}', contains('extent must be one of'));
    expect(escaped.exitCode, 64);
    expect(
      '${escaped.stderr}',
      contains('must stay inside packages/map_authoring'),
    );
  });
}

Future<File> _temporaryOutput(String prefix) async {
  await Directory('build/test').create(recursive: true);
  final directory = await Directory('build/test').createTemp('${prefix}_cli_');
  addTearDown(() => directory.delete(recursive: true));
  return File('${directory.path}/result.json');
}

Future<ProcessResult> _run(List<String> arguments) => Process.run(
      Platform.resolvedExecutable,
      <String>[
        'run',
        'benchmark/smart_tiles_rich_authoring_scaling.dart',
        ...arguments,
      ],
      workingDirectory: Directory.current.path,
    );
