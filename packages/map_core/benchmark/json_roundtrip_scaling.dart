import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';

import '../../../tools/performance/benchmark_support.dart';

Future<void> main(List<String> arguments) async {
  try {
    final cli = PerformanceCli.parse(
      arguments,
      allowed: const <String>{'warmups', 'samples', 'bytes', 'output'},
    );
    final warmups = cli.nonNegativeInt('warmups', fallback: 5);
    final samples = cli.positiveInt('samples', fallback: 30);
    final byteSizes = cli.positiveInts(
      'bytes',
      fallback: '1024,102400,2420033,10485760',
      singularLabel: 'byte size',
    );
    final outputPath = cli.requiredValue('output');
    validatedPackageOutput(outputPath, packageName: 'map_core');
    final results = <Map<String, Object?>>[];

    for (final targetBytes in byteSizes) {
      final fixture = _fixture(targetBytes);
      final encodedFixture = jsonEncode(fixture.toJson());
      final actualBytes = utf8.encode(encodedFixture).length;
      final fingerprint = stableFingerprint(encodedFixture);
      for (var index = 0; index < warmups; index += 1) {
        _measure(fixture);
      }
      final measured = <({int elapsedUs, String checksum})>[
        for (var index = 0; index < samples; index += 1) _measure(fixture),
      ];
      final checksum = measured.first.checksum;
      if (measured.any((sample) => sample.checksum != checksum)) {
        throw StateError('Unstable JSON result for $targetBytes bytes.');
      }
      results.add(<String, Object?>{
        'targetBytes': targetBytes,
        'actualBytes': actualBytes,
        'datasetFingerprint': fingerprint,
        'roundtripChecksum': checksum,
        'rssBytesAfterSamples': ProcessInfo.currentRss,
        ...percentileFields(
          measured.map((sample) => sample.elapsedUs).toList(growable: false),
        ),
      });
    }

    final receipt = await performanceReceipt(
      benchmark: 'json_roundtrip_scaling',
      warmups: warmups,
      sampleCount: samples,
      arguments: <String>[
        'benchmark/json_roundtrip_scaling.dart',
        ...arguments
      ],
      metadata: <String, Object?>{'targetBytes': byteSizes},
      results: results,
    );
    await writePerformanceReceipt(
      outputPath: outputPath,
      packageName: 'map_core',
      receipt: receipt,
    );
  } on FormatException catch (error) {
    stderr.writeln('json_roundtrip_scaling: ${error.message}');
    exitCode = 64;
  }
}

// The timed region deliberately covers both JSON directions and typed model
// reconstruction; encoded fixture sizing happens outside the measurement.
({int elapsedUs, String checksum}) _measure(ProjectManifest manifest) {
  final stopwatch = Stopwatch()..start();
  final encoded = jsonEncode(manifest.toJson());
  final decoded = ProjectManifest.fromJson(
    Map<String, dynamic>.from(jsonDecode(encoded) as Map),
  );
  stopwatch.stop();
  return (
    elapsedUs: stopwatch.elapsedMicroseconds,
    checksum: stableFingerprint(<Object?>[
      decoded.name,
      decoded.version.name,
      decoded.globalProperties['payload'],
    ]),
  );
}

ProjectManifest _fixture(int targetBytes) {
  ProjectManifest build(String payload) => ProjectManifest(
        name: 'JSON round-trip benchmark',
        version: ProjectVersion.v6,
        maps: const <ProjectMapEntry>[],
        tilesets: const <ProjectTilesetEntry>[],
        globalProperties: <String, dynamic>{'payload': payload},
      );

  final emptyBytes = utf8.encode(jsonEncode(build('').toJson())).length;
  final payloadLength = (targetBytes - emptyBytes).clamp(0, targetBytes);
  return build(_deterministicPayload(payloadLength));
}

String _deterministicPayload(int length) {
  const alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final buffer = StringBuffer();
  for (var index = 0; index < length; index += 1) {
    buffer.write(alphabet[index % alphabet.length]);
  }
  return buffer.toString();
}
