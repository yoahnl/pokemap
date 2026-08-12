import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('writes sparse tile and collision stroke scaling evidence', () async {
    final output = await _temporaryOutput('map_cell_stroke');
    final result = await _run(<String>[
      '--warmups',
      '0',
      '--samples',
      '1',
      '--extents',
      '128,256',
      '--output',
      output.path,
    ]);

    expect(result.exitCode, 0, reason: '${result.stderr}');
    final payload =
        jsonDecode(await output.readAsString()) as Map<String, Object?>;
    expect(payload['schemaVersion'], 2);
    expect(payload['benchmark'], 'map_cell_stroke_scaling');
    expect(payload['pointerSamplesP95BudgetUs'], 8000);
    final rows = (payload['results']! as List<Object?>)
        .cast<Map<String, Object?>>();
    expect(rows.map((row) => row['extent']), <Object?>[128, 256]);
    expect(rows.map((row) => row['strokeSamples']), <Object?>[1, 10]);
    for (final row in rows) {
      for (final key in <String>[
        'tilePointerSamples',
        'tileCommit',
        'collisionPointerSamples',
        'collisionCommit',
      ]) {
        final profile = Map<String, Object?>.from(row[key]! as Map);
        expect(profile['samplesUs'], hasLength(1));
        expect(profile['p50Us'], isA<int>());
        expect(profile['p95Us'], isA<int>());
        expect(profile['p99Us'], isA<int>());
        expect(profile['maxUs'], isA<int>());
        expect('${profile['checksum']}', isNotEmpty);
        if (key.endsWith('PointerSamples')) {
          expect(profile['p95Us'], lessThan(8000));
        }
      }
      final extent = row['extent']! as int;
      final strokeSamples = row['strokeSamples']! as int;
      expect(row['workCounts'], <String, Object?>{
        'legacyFullLayerCopiesDuringGesture': strokeSamples,
        'legacyMapMaterializationsDuringGesture': strokeSamples,
        'legacyValidationsDuringGesture': strokeSamples,
        'legacyLayerCellSlotsAllocated': extent * extent * strokeSamples,
        'touchedCellsBeforeCommit': strokeSamples,
        'fullLayerCopiesBeforeCommit': 0,
        'mapMaterializationsBeforeCommit': 0,
        'validationsBeforeCommit': 0,
        'sparseOverrideUpperBound': strokeSamples,
        'fullLayerCopiesAtCommit': 1,
        'mapMaterializationsAtCommit': 1,
        'validationsAtCommit': 1,
        'layerCellSlotsAllocatedAtCommit': extent * extent,
      });
      expect(row['rssBytesAfterSamples'], isA<int>());
    }
  });

  test('rejects unsupported extents and escaped output', () async {
    final unsupported = await _run(const <String>[
      '--samples',
      '1',
      '--extents',
      '64',
      '--output',
      'build/test/stroke-invalid.json',
    ]);
    final escaped = await _run(const <String>[
      '--samples',
      '1',
      '--extents',
      '128',
      '--output',
      '../stroke-escape.json',
    ]);

    expect(unsupported.exitCode, 64);
    expect('${unsupported.stderr}', contains('extent must be one of'));
    expect(escaped.exitCode, 64);
    expect(
      '${escaped.stderr}',
      contains('must stay inside packages/map_editor'),
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
  'dart',
  <String>['run', 'benchmark/map_cell_stroke_scaling.dart', ...arguments],
  workingDirectory: Directory.current.path,
);
