import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('writes rich Smart Tiles core scaling evidence', () async {
    final output = await _temporaryOutput('smart_tiles_rich_core');
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
    expect(payload['benchmark'], 'smart_tiles_rich_map_scaling');
    final rows =
        (payload['results']! as List<Object?>).cast<Map<String, Object?>>();
    expect(rows.map((row) => row['extent']), <Object?>[128, 256]);
    for (final row in rows) {
      expect('${row['fixtureChecksum']}', isNotEmpty);
      expect(row['rssBytesAfterSamples'], isA<int>());
      final work = Map<String, Object?>.from(row['workCounts']! as Map);
      final extent = row['extent']! as int;
      expect(work['totalCells'], extent * extent);
      final profiles = Map<String, Object?>.from(row['profiles']! as Map);
      expect(
        profiles.keys,
        containsAll(<String>[
          'generation',
          'fullFieldResolve',
          'viewportResolve',
          'lineEdit',
          'rectangleEdit',
          'floodFillEdit',
          'jsonRoundtrip',
        ]),
      );
      for (final raw in profiles.values) {
        final profile = Map<String, Object?>.from(raw! as Map);
        expect(profile['samplesUs'], hasLength(1));
        expect(profile['p50Us'], isA<int>());
        expect(profile['p95Us'], isA<int>());
        expect(profile['maxUs'], isA<int>());
        expect('${profile['checksum']}', isNotEmpty);
      }
      final viewport = Map<String, Object?>.from(
        row['viewportWorkCounts']! as Map,
      );
      expect(viewport['requestedCellCount'], 24 * 18);
      expect(viewport['resolvedVisualCount'], isA<int>());
    }
  });

  test('rejects unsupported extents and escaped output', () async {
    final unsupported = await _run(const <String>[
      '--samples',
      '1',
      '--extents',
      '64',
      '--output',
      'build/test/rich-invalid.json',
    ]);
    final escaped = await _run(const <String>[
      '--samples',
      '1',
      '--extents',
      '128',
      '--output',
      '../rich-escape.json',
    ]);

    expect(unsupported.exitCode, 64);
    expect('${unsupported.stderr}', contains('extent must be one of'));
    expect(escaped.exitCode, 64);
    expect('${escaped.stderr}', contains('must stay inside packages/map_core'));
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
        'benchmark/smart_tiles_rich_map_scaling.dart',
        ...arguments,
      ],
      workingDirectory: Directory.current.path,
    );
