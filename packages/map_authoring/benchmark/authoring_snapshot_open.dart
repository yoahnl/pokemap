import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';

import '../../../tools/performance/benchmark_support.dart';

const _knownFixtures = <String>{
  'small',
  'intermediate',
  'selbrume',
  'synthetic-10mb',
};

Future<void> main(List<String> arguments) async {
  try {
    final cli = PerformanceCli.parse(
      arguments,
      allowed: const <String>{
        'warmups',
        'samples',
        'fixtures',
        'roots',
        'cycles',
        'output',
      },
    );
    final warmups = cli.nonNegativeInt('warmups', fallback: 2);
    final samples = cli.positiveInt('samples', fallback: 15);
    final cycles = cli.positiveInt('cycles', fallback: 10);
    final fixtures = cli.strings(
      'fixtures',
      fallback: 'small,intermediate,selbrume,synthetic-10mb',
    );
    if (fixtures.isEmpty) {
      throw const FormatException('fixtures must not be empty');
    }
    for (final fixture in fixtures) {
      if (fixture == 'promotion_checkpoint') {
        throw const FormatException(
          'snapshot benchmark forbids promotion_checkpoint: its missing '
          'resource makes it JSON/validation-only',
        );
      }
      if (!_knownFixtures.contains(fixture)) {
        throw FormatException('unknown fixture: $fixture');
      }
    }
    final rootCounts = cli.positiveInts(
      'roots',
      fallback: '1,3,10',
      singularLabel: 'root count',
    );
    final outputPath = cli.requiredValue('output');
    validatedPackageOutput(outputPath, packageName: 'map_authoring');
    final results = <Map<String, Object?>>[];

    for (final fixtureName in fixtures) {
      final fixture = await _resolveFixture(fixtureName);
      final fingerprint = await _fixtureFingerprint(fixture);
      for (final rootCount in rootCounts) {
        final roots = await _allowedRoots(fixture, rootCount);
        for (var index = 0; index < warmups; index += 1) {
          await _measure(fixture, roots, cycles);
        }
        final measured = <({
          int elapsedUs,
          String checksum,
          int maps,
          int resourceCount,
          int resourceBytes,
          int initialReadUs,
          int decodeModelUs,
          int secondObservationUs,
          int fingerprintUs,
          int projectionUs,
          int loaderTotalUs,
        })>[];
        for (var index = 0; index < samples; index += 1) {
          measured.add(await _measure(fixture, roots, cycles));
        }
        final checksum = measured.first.checksum;
        if (measured.any((sample) => sample.checksum != checksum)) {
          throw StateError(
            'Unstable snapshot for $fixtureName with $rootCount roots.',
          );
        }
        results.add(<String, Object?>{
          'fixture': fixtureName,
          'fixturePath': _repositoryRelativePath(fixture),
          'rootCount': rootCount,
          'cyclesPerSample': cycles,
          'mapCount': measured.first.maps,
          'resourceCount': measured.first.resourceCount,
          'resourceBytes': measured.first.resourceBytes,
          'datasetFingerprint': fingerprint,
          'snapshotChecksum': checksum,
          'rssBytesAfterSamples': ProcessInfo.currentRss,
          'snapshotProfile': <String, Object?>{
            'initialRead': percentileFields(
              measured
                  .map((sample) => sample.initialReadUs)
                  .toList(growable: false),
            ),
            'decodeModel': percentileFields(
              measured
                  .map((sample) => sample.decodeModelUs)
                  .toList(growable: false),
            ),
            'secondObservation': percentileFields(
              measured
                  .map((sample) => sample.secondObservationUs)
                  .toList(growable: false),
            ),
            'fingerprint': percentileFields(
              measured
                  .map((sample) => sample.fingerprintUs)
                  .toList(growable: false),
            ),
            'projection': percentileFields(
              measured
                  .map((sample) => sample.projectionUs)
                  .toList(growable: false),
            ),
            'total': percentileFields(
              measured
                  .map((sample) => sample.loaderTotalUs)
                  .toList(growable: false),
            ),
          },
          ...percentileFields(
            measured.map((sample) => sample.elapsedUs).toList(growable: false),
          ),
        });
      }
    }

    final receipt = await performanceReceipt(
      benchmark: 'authoring_snapshot_open',
      warmups: warmups,
      sampleCount: samples,
      arguments: <String>[
        'benchmark/authoring_snapshot_open.dart',
        ...arguments,
      ],
      metadata: <String, Object?>{
        'fixtures': fixtures,
        'rootCounts': rootCounts,
        'cycles': cycles,
        'snapshotPolicy': ProjectSnapshotLoadPolicy.strict.name,
      },
      results: results,
    );
    await writePerformanceReceipt(
      outputPath: outputPath,
      packageName: 'map_authoring',
      receipt: receipt,
    );
  } on FormatException catch (error) {
    stderr.writeln('authoring_snapshot_open: ${error.message}');
    exitCode = 64;
  }
}

// Exercise the production policy, handle store, open service and strict
// snapshot loader. A JSON-only parse would under-report authoring open cost.
Future<
    ({
      int elapsedUs,
      String checksum,
      int maps,
      int resourceCount,
      int resourceBytes,
      int initialReadUs,
      int decodeModelUs,
      int secondObservationUs,
      int fingerprintUs,
      int projectionUs,
      int loaderTotalUs,
    })> _measure(
  Directory fixture,
  List<String> allowedRoots,
  int cycles,
) async {
  var token = 0;
  var mapCount = 0;
  final revisions = <String>[];
  final profiles = <ProjectSnapshotLoadProfile>[];
  const reader = LocalProjectFileReader();
  final stopwatch = Stopwatch()..start();
  for (var cycle = 0; cycle < cycles; cycle += 1) {
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: allowedRoots,
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore(
      clock: () => DateTime.utc(2026, 8, 1),
      tokenFactory: (prefix) => '$prefix${token++}',
    );
    final opened = await ProjectOpenService(
      policy: policy,
      fileReader: reader,
      handles: handles,
    ).openProject(fixture.path);
    final snapshot = await ProjectSnapshotLoader(
      handles: handles,
      profileSink: profiles.add,
    ).load(
      opened.projectHandle,
      policy: ProjectSnapshotLoadPolicy.strict,
    );
    mapCount += snapshot.maps.length;
    revisions.add(snapshot.revision);
  }
  stopwatch.stop();
  if (profiles.length != cycles) {
    throw StateError(
      'Expected $cycles snapshot profiles, received ${profiles.length}.',
    );
  }
  final resources = profiles.first;
  if (profiles.any(
    (profile) =>
        profile.resourceCount != resources.resourceCount ||
        profile.resourceBytes != resources.resourceBytes,
  )) {
    throw StateError('Snapshot resource volume changed between cycles.');
  }
  return (
    elapsedUs: stopwatch.elapsedMicroseconds,
    checksum: stableFingerprint(revisions),
    maps: mapCount ~/ cycles,
    resourceCount: resources.resourceCount,
    resourceBytes: resources.resourceBytes,
    initialReadUs: profiles.fold<int>(
      0,
      (total, profile) => total + profile.initialReadMicroseconds,
    ),
    decodeModelUs: profiles.fold<int>(
      0,
      (total, profile) => total + profile.decodeModelMicroseconds,
    ),
    secondObservationUs: profiles.fold<int>(
      0,
      (total, profile) => total + profile.secondObservationMicroseconds,
    ),
    fingerprintUs: profiles.fold<int>(
      0,
      (total, profile) => total + profile.fingerprintMicroseconds,
    ),
    projectionUs: profiles.fold<int>(
      0,
      (total, profile) => total + profile.projectionMicroseconds,
    ),
    loaderTotalUs: profiles.fold<int>(
      0,
      (total, profile) => total + profile.totalMicroseconds,
    ),
  );
}

Future<Directory> _resolveFixture(String name) async {
  final repository = Directory.current.parent.parent;
  switch (name) {
    case 'small':
      return Directory(
        '${repository.path}/examples/playable_runtime_host/golden_battle_slice',
      );
    case 'intermediate':
      return Directory(
        '${repository.path}/examples/playable_runtime_host/golden_fangame_slice',
      );
    case 'selbrume':
      return Directory('${repository.path}/selbrume');
    case 'synthetic-10mb':
      return _syntheticFixture();
  }
  throw FormatException('unknown fixture: $name');
}

Future<Directory> _syntheticFixture() async {
  final directory = Directory('build/performance/fixtures/synthetic-10mb');
  await directory.create(recursive: true);
  final project = File('${directory.path}/project.json');
  const targetBytes = 10 * 1024 * 1024;
  if (!await project.exists() || await project.length() < targetBytes) {
    const prefix = '{"name":"Synthetic 10 MiB","version":"v6","maps":[],'
        '"tilesets":[],"globalProperties":{"payload":"';
    const suffix = '"}}';
    final payloadLength = targetBytes - utf8.encode(prefix + suffix).length;
    final sink = project.openWrite();
    sink.write(prefix);
    const block = '0123456789abcdef';
    var remaining = payloadLength;
    while (remaining > 0) {
      final count = remaining.clamp(0, block.length);
      sink.write(block.substring(0, count));
      remaining -= count;
    }
    sink.write(suffix);
    await sink.close();
  }
  return Directory(directory.resolveSymbolicLinksSync());
}

Future<List<String>> _allowedRoots(Directory fixture, int count) async {
  final roots = <String>[fixture.resolveSymbolicLinksSync()];
  final dummyRoot = Directory('build/performance/roots');
  await dummyRoot.create(recursive: true);
  for (var index = 1; index < count; index += 1) {
    final root = Directory('${dummyRoot.path}/root-$index');
    await root.create(recursive: true);
    roots.add(root.resolveSymbolicLinksSync());
  }
  return List<String>.unmodifiable(roots);
}

Future<String> _fixtureFingerprint(Directory fixture) async {
  final files = <File>[];
  await for (final entity
      in fixture.list(recursive: true, followLinks: false)) {
    if (entity is File) files.add(entity);
  }
  files.sort((left, right) => left.path.compareTo(right.path));
  final entries = <Map<String, Object?>>[];
  for (final file in files) {
    entries.add(<String, Object?>{
      'path': file.path.substring(fixture.path.length + 1),
      'bytes': await file.length(),
      'content': stableBytesFingerprint(await file.readAsBytes()),
    });
  }
  return stableFingerprint(entries);
}

String _repositoryRelativePath(Directory fixture) {
  final repository = Directory.current.parent.parent.absolute.path;
  final absolute = fixture.absolute.path;
  return absolute.startsWith('$repository/')
      ? absolute.substring(repository.length + 1)
      : 'generated:${fixture.uri.pathSegments.lastWhere((part) => part.isNotEmpty)}';
}
