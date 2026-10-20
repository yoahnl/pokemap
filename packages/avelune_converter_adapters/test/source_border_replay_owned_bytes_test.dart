import 'dart:convert';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

import 'source_border_mutation_replay_test.dart' as fixture;

void main() {
  test('public resources retain protective copies of caller buffers', () {
    final bytes = <int>[1, 2, 3];
    final files = <String, List<int>>{'snapshot': bytes};
    final blobs = <String, List<int>>{'blob': bytes};
    final resources = SourceBorderReplayResources(files: files, blobs: blobs);
    bytes[0] = 99;
    files.clear();
    blobs.clear();
    expect(resources.files['snapshot'], [1, 2, 3]);
    expect(resources.blobs['blob'], [1, 2, 3]);
    expect(() => resources.files['snapshot']![0] = 0, throwsUnsupportedError);
    expect(() => resources.blobs['blob']![0] = 0, throwsUnsupportedError);
  });

  test(
      'successive publications share only their privately owned retained bytes',
      () async {
    final publications = <SourceBorderMutationReplay>[];
    final result = await fixture.publishPair(onPublication: publications.add);
    final first = publications.first.resources;
    for (final entry in first.files.entries) {
      expect(identical(entry.value, result.resources.files[entry.key]), isTrue);
    }
    for (final entry in first.blobs.entries) {
      expect(identical(entry.value, result.resources.blobs[entry.key]), isTrue);
    }
  });

  test('repeated replay and catalog refresh reuse real PNG validations',
      () async {
    const limits = NativeWriteLimits();
    var result = await fixture.publishPair(limits: limits);
    final first = result.resources;
    final validations = first.pngValidationCount;
    expect(validations, first.files.length + first.blobs.length);
    final watch = Stopwatch()..start();
    for (var index = 0; index < 12; index++) {
      final refreshed = result.resources
          .withCatalog(AssetCatalog(records: result.resources.catalog.records));
      result = fixture.applyChanges([],
          project: result.project, resources: refreshed, limits: limits);
      expect(result.resources.pngValidationCount, validations);
      for (final entry in first.files.entries) {
        expect(identical(entry.value, result.files[entry.key]), isTrue);
      }
      for (final entry in first.blobs.entries) {
        expect(
            identical(entry.value, result.resources.blobs[entry.key]), isTrue);
      }
    }
    print(jsonEncode({
      'kind': 'boundedBorderReplayValidationMeasurement',
      'replays': 12,
      'retainedPayloads': first.files.length + first.blobs.length,
      'pngValidationsBefore': validations,
      'pngValidationsAfter': result.resources.pngValidationCount,
      'elapsedMicroseconds': watch.elapsedMicroseconds
    }));
  });

  test('different limit instances revalidate and stricter limits still refuse',
      () async {
    final result = await fixture.publishPair();
    final first = result.resources;
    final initial = first.pngValidationCount;
    final otherLimits = NativeWriteLimits();
    final validated = fixture.applyChanges([],
        project: result.project, resources: first, limits: otherLimits);
    final nextCount = validated.resources.pngValidationCount;
    expect(nextCount, initial + first.files.length + first.blobs.length);
    fixture.applyChanges([],
        project: result.project,
        resources: validated.resources,
        limits: otherLimits);
    expect(first.pngValidationCount, nextCount);
    for (final limits in [
      const NativeWriteLimits(maxImagePixels: 1),
      const NativeWriteLimits(maxArtifactBytes: 1),
      const NativeWriteLimits(maxArtifacts: 1),
      const NativeWriteLimits(maxTotalArtifactBytes: 1),
      const NativeWriteLimits(maxTotalImagePixels: 1),
      const NativeWriteLimits(maxTotalDraftJsonBytes: 1),
    ]) {
      expect(
          () => fixture.applyChanges([],
              project: result.project, resources: first, limits: limits),
          throwsA(isA<NativeWriteException>()));
    }
  });

  test('cached bytes never bypass changed catalog metadata', () async {
    final result = await fixture.publishPair();
    final refresh = result.resources.withCatalog(AssetCatalog());
    expect(
        () => fixture
            .applyChanges([], project: result.project, resources: refresh),
        throwsA(fixture.failure('jumps.resource.catalog')));
  });

  test('public reconstruction never borrows validation from matching digests',
      () async {
    final result = await fixture.publishPair();
    final fresh = SourceBorderReplayResources(
        catalog: result.resources.catalog,
        files: result.files,
        blobs: result.resources.blobs);
    expect(fresh.pngValidationCount, 0);
    for (final entry in fresh.files.entries) {
      expect(identical(entry.value, result.files[entry.key]), isFalse);
    }
    final replay =
        fixture.applyChanges([], project: result.project, resources: fresh);
    expect(replay.resources.pngValidationCount,
        fresh.files.length + fresh.blobs.length);
  });

  test('reusing PNG validation never retains old project metadata', () async {
    final result = await fixture.publishPair();
    final count = result.resources.pngValidationCount;
    final replay = fixture.applyChanges([],
        project: result.project.copyWith(name: 'Updated project metadata'),
        resources: result.resources);
    expect(replay.project.name, 'Updated project metadata');
    expect(replay.resources.pngValidationCount, count);
  });

  test('new public buffers are copied and validated despite retained paths',
      () async {
    final result = await fixture.publishPair();
    final path = result.files.keys.first;
    final old = result.resources.catalog.findByLogicalPath(path)!;
    final broken = <int>[1, 2, 3];
    final artifact =
        ContentArtifactRef.fromBytes(broken, mediaType: 'image/png');
    final resources = SourceBorderReplayResources(
        catalog: AssetCatalog(records: [
          for (final record in result.resources.catalog.records)
            record.id == old.id ? record.copyWith(artifact: artifact) : record
        ]),
        files: {
          ...result.files,
          path: broken
        },
        blobs: {
          for (final entry in result.resources.blobs.entries)
            if (entry.key != old.artifact.digest) entry.key: entry.value,
          artifact.digest: broken
        });
    broken[0] = 137;
    expect(resources.files[path], [1, 2, 3]);
    expect(resources.pngValidationCount, 0);
    expect(
        () => fixture
            .applyChanges([], project: result.project, resources: resources),
        throwsA(fixture.failure('native.png.header')));
    expect(resources.pngValidationCount, greaterThan(0));
  });

  test('warm retained bytes still reject preimage and immutable path conflicts',
      () async {
    final result = await fixture.publishPair();
    final path = result.files.keys.first;
    final bytes = result.files[path]!;
    final snapshot = ProjectSnapshot(
        projectHandle: const ProjectHandle('owned-replay'),
        revision: 'sha256:${'0' * 64}',
        manifest: result.project,
        maps: const [],
        resourceFingerprints: {
          'borderSnapshot:$path':
              computeAuthoringBytesFingerprint(bytes, logicalName: path)
        },
        resourceStorageKeys: {
          'borderSnapshot:$path': path
        },
        resourceBytes: {
          'borderSnapshot:$path': bytes
        });
    for (final stale in [false, true]) {
      expect(
          () => SourceBorderMutationReplay.applyChanges(
                  snapshot: snapshot,
                  resources: result.resources,
                  changes: [
                    AuthoringResourceChange(
                        resource: AuthoringResourceRef(
                            kind: 'borderSnapshot', id: path),
                        storageKey: path,
                        beforeBytes: stale ? [1] : bytes,
                        afterBytes: [2, 3, 4])
                  ]),
          throwsA(fixture.failure(
              stale ? 'jumps.resource.preimage' : 'jumps.resource.conflict')));
    }
  });
}
