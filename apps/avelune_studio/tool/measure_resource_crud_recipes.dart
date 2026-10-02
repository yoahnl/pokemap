import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';

import '../test/support/resource_stress_fixture.dart';
import 'package:avelune_studio/features/resources/data/local_resource_usage_adapter.dart';
import '../../../tools/performance/benchmark_support.dart';

Future<void> main() async {
  stdout.writeln(
    jsonEncode({
      'kind': 'environment',
      'sdk': Platform.version,
      'os': Platform.operatingSystemVersion,
      'rssBytes': ProcessInfo.currentRss,
      'mode': 'dart-jit',
      'threshold': 'none; descriptive local measures',
      'fixture':
          'ResourceStressFixture, existing generator, 200 diagnostics retained',
      'configuration':
          'temporary resource-only projects with Pokemon explicitly disabled',
      'scales': {'S': 8, 'M': 132, 'L': 512},
      'warmSamples': 3,
    }),
  );
  for (final scale in {'S': 8, 'M': 132, 'L': 512}.entries) {
    final fixture = await ResourceStressFixture.create(atlasCount: scale.value);
    try {
      final manifest = fixture.manifest.copyWith(
        pokemon: const ProjectPokemonConfig(
          enabled: false,
          ruleset: PokemonRulesetProfile.pokeMapBetaV1,
        ),
      );
      await File(
        '${fixture.directory.path}/project.json',
      ).writeAsString(jsonEncode(manifest.toJson()));
      final manifestBytes = await File(
        '${fixture.directory.path}/project.json',
      ).length();
      final mapBytes = await Future.wait(
        manifest.maps.map(
          (entry) =>
              File('${fixture.directory.path}/${entry.relativePath}').length(),
        ),
      );
      final reader = MeasuredUsageReader();
      final profiles = <ProjectSnapshotLoadProfile>[];
      final port = LocalResourceUsageAdapter(
        session: fixture.session,
        reader: reader,
        profileSink: profiles.add,
      );
      try {
        final target = ResourceUsageTarget(
          family: 'images',
          id: fixture.lateAtlasId,
        );
        final cold = Stopwatch()..start();
        final report = await port.analyze(target);
        cold.stop();
        if (!report.complete) {
          stdout.writeln(
            jsonEncode({
              'kind': 'result',
              'scale': scale.key,
              'status': 'NON VERIF',
              'issues': report.coverageIssues,
            }),
          );
          continue;
        }
        final coldCounts = reader.counts();
        final warm = <int>[];
        final samples = <Map<String, Object?>>[];
        for (var index = 0; index < 3; index++) {
          reader.reset();
          final timer = Stopwatch()..start();
          final next = await port.analyze(target);
          timer.stop();
          if (!next.complete || next.revision != report.revision) {
            throw StateError('The measured fixture changed.');
          }
          warm.add(timer.elapsedMicroseconds);
          samples.add({
            'us': timer.elapsedMicroseconds,
            ...reader.counts(),
            'cacheHit': profiles.last.cacheHit,
          });
        }
        reader.reset();
        final verify = Stopwatch()..start();
        final current = await port.isCurrent(report);
        verify.stop();
        stdout.writeln(
          jsonEncode({
            'kind': 'result',
            'scale': scale.key,
            'status': 'MEASURED',
            'maps': manifest.maps.length,
            'tilesets': manifest.tilesets.length,
            'elements': manifest.elements.length,
            'diagnostics': fixture.errorCount,
            'atlasCount': fixture.atlasCount,
            'manifestBytes': manifestBytes,
            'mapsBytes': mapBytes.fold(0, (a, b) => a + b),
            'totalMapCells': fixture.maps.values.fold(
              0,
              (a, map) => a + map.size.width * map.size.height,
            ),
            'reportEntries': report.entries.length,
            'revision': report.revision,
            'cold': {'us': cold.elapsedMicroseconds, ...coldCounts},
            'warm': {'percentiles': percentileFields(warm), 'samples': samples},
            'freshness': {
              'us': verify.elapsedMicroseconds,
              'current': current,
              ...reader.counts(),
            },
            'rssBytes': ProcessInfo.currentRss,
          }),
        );
      } finally {
        await port.dispose();
      }
    } finally {
      await fixture.dispose();
    }
  }
}

final class MeasuredUsageReader
    implements
        ProjectFileReader,
        ProjectDirectoryReader,
        ProjectSnapshotCacheIdentityReader,
        ProjectResourceProbeReader {
  final delegate = const LocalProjectFileReader();
  int reads = 0;
  int bytes = 0;
  int identities = 0;
  int directories = 0;
  int probes = 0;
  int binaryReads = 0;
  void reset() {
    reads = bytes = identities = directories = probes = binaryReads = 0;
  }

  Map<String, Object?> counts() => {
    'reads': reads,
    'bytes': bytes,
    'identityReads': identities,
    'directoryReads': directories,
    'probes': probes,
    'binaryReads': binaryReads,
  };
  @override
  Future<String> canonicalizeDirectory(String path) =>
      delegate.canonicalizeDirectory(path);
  @override
  Future<List<String>> listFiles({
    required String projectRoot,
    required String relativeDirectory,
  }) {
    directories++;
    return delegate.listFiles(
      projectRoot: projectRoot,
      relativeDirectory: relativeDirectory,
    );
  }

  @override
  Future<ProjectResourceIdentity?> readIdentity({
    required String projectRoot,
    required String relativePath,
  }) {
    identities++;
    return delegate.readIdentity(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
  }

  @override
  Future<ProjectResourceProbe> probeResource({
    required String projectRoot,
    required String relativePath,
  }) {
    probes++;
    return delegate.probeResource(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
  }

  @override
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  }) async {
    reads++;
    if (relativePath.endsWith('.png') || relativePath.endsWith('.blob')) {
      binaryReads++;
    }
    final result = await delegate.readBytes(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
    bytes += result.length;
    return result;
  }
}
