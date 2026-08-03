import 'dart:io';

import 'package:map_core/map_core.dart';

import '../../../tools/performance/benchmark_support.dart';

Future<void> main(List<String> arguments) async {
  try {
    final cli = PerformanceCli.parse(
      arguments,
      allowed: const <String>{'warmups', 'samples', 'sizes', 'output'},
    );
    final warmups = cli.nonNegativeInt('warmups', fallback: 5);
    final samples = cli.positiveInt('samples', fallback: 30);
    final sizes = cli.positiveInts(
      'sizes',
      fallback: '10,100,400,800,1600,3200',
      singularLabel: 'size',
    );
    final outputPath = cli.requiredValue('output');
    validatedPackageOutput(outputPath, packageName: 'map_core');
    final results = <Map<String, Object?>>[];

    for (final size in sizes) {
      final manifest = _manifest(size);
      final fingerprint = stableFingerprint(manifest.toJson());
      for (var index = 0; index < warmups; index += 1) {
        ProjectValidator.validate(manifest);
      }
      final measured = <({int elapsedUs, String checksum})>[
        for (var index = 0; index < samples; index += 1) _measure(manifest),
      ];
      final checksum = measured.first.checksum;
      if (measured.any((sample) => sample.checksum != checksum)) {
        throw StateError('Unstable hierarchy result for $size groups.');
      }
      results.add(<String, Object?>{
        'groupCount': size,
        'hierarchyShape': 'balanced-parent-chain',
        'datasetFingerprint': fingerprint,
        'validationChecksum': checksum,
        'rssBytesAfterSamples': ProcessInfo.currentRss,
        ...percentileFields(
          measured.map((sample) => sample.elapsedUs).toList(growable: false),
        ),
      });
    }

    final receipt = await performanceReceipt(
      benchmark: 'group_hierarchy_scaling',
      warmups: warmups,
      sampleCount: samples,
      arguments: <String>[
        'benchmark/group_hierarchy_scaling.dart',
        ...arguments,
      ],
      metadata: <String, Object?>{'sizes': sizes},
      results: results,
    );
    await writePerformanceReceipt(
      outputPath: outputPath,
      packageName: 'map_core',
      receipt: receipt,
    );
  } on FormatException catch (error) {
    stderr.writeln('group_hierarchy_scaling: ${error.message}');
    exitCode = 64;
  }
}

// Validate the real manifest rather than timing fixture construction; the
// checksum prevents a future optimizer from turning the work into a no-op.
({int elapsedUs, String checksum}) _measure(ProjectManifest manifest) {
  final stopwatch = Stopwatch()..start();
  ProjectValidator.validate(manifest);
  stopwatch.stop();
  return (
    elapsedUs: stopwatch.elapsedMicroseconds,
    checksum: stableFingerprint(
      manifest.groups.map((group) => group.id).toList(growable: false),
    ),
  );
}

ProjectManifest _manifest(int size) => ProjectManifest(
      name: 'Hierarchy benchmark $size',
      version: ProjectVersion.v6,
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[],
      groups: List<ProjectMapGroup>.generate(
        size,
        (index) => ProjectMapGroup(
          id: 'group-$index',
          name: 'Group $index',
          type: MapGroupType.route,
          parentGroupId: index == 0 ? null : 'group-${(index - 1) ~/ 2}',
          sortOrder: index,
        ),
        growable: false,
      ),
    );
