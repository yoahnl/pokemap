import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/narrative_event_authoring_session.dart';
import 'package:map_editor/src/application/models/narrative_event_registry_persistence_models.dart';
import 'package:map_editor/src/infrastructure/repositories/narrative_event_registry_persistence.dart';
import 'package:path/path.dart' as p;

import 'support/event_registry_persistence_fixtures.dart';

void main() {
  test('NS-EVENT-V2 Phase E-bis informative persistence measurements',
      () async {
    stdout.writeln(
      'NS_EVENT_V2_PHASE_E_BIS_PERF_ENV '
      'os=${Platform.operatingSystem} '
      'os_version=${_singleLine(Platform.operatingSystemVersion)} '
      'dart=${Platform.version.split(' ').first} '
      'processors=${Platform.numberOfProcessors} '
      'host=${_singleLine(Platform.localHostname)} mode=jit '
      'warmup=1 iterations=5 mutable_global_cache=none',
    );

    for (final mapCount in [10, 100, 500]) {
      final fixture = await _createSnapshotFixture(mapCount);
      addTearDown(fixture.dispose);
      await NarrativeEventAuthoringSession.prepare(fixture.projectPath);
      final prepareSamples = await _measure(
        5,
        () async {
          await NarrativeEventAuthoringSession.prepare(fixture.projectPath);
        },
      );
      _emitMeasurement(
        operation: 'session_prepare',
        volume: mapCount,
        samples: prepareSamples,
        bytesRead: fixture.totalSnapshotBytes,
        hashing: 'included',
        catalogBuild: 'included',
      );

      final session =
          await NarrativeEventAuthoringSession.prepare(fixture.projectPath);
      await _revalidateMaps(session);
      final revalidationSamples = await _measure(
        5,
        () => _revalidateMaps(session),
      );
      _emitMeasurement(
        operation: 'final_map_revalidation_workload',
        volume: mapCount,
        samples: revalidationSamples,
        bytesRead: fixture.totalMapBytes,
        hashing: 'included',
        catalogBuild: 'excluded',
      );
    }

    for (final journalCount in [0, 1, 100]) {
      final fixture = await createPersistenceFixture();
      addTearDown(fixture.dispose);
      await _populateCommittedHistory(fixture, journalCount);
      final persistence = NarrativeEventRegistryPersistence();
      final warmup = await persistence.inspectProject(fixture.projectPath);
      expect(warmup.status, NarrativeEventRegistryRecoveryGateStatus.clear);
      final scanSamples = await _measure(
        5,
        () async {
          final inspection =
              await persistence.inspectProject(fixture.projectPath);
          expect(
            inspection.status,
            NarrativeEventRegistryRecoveryGateStatus.clear,
          );
        },
      );
      _emitMeasurement(
        operation: 'recovery_gate_scan',
        volume: journalCount,
        samples: scanSamples,
        bytesRead: await _eventArtifactBytes(fixture.root),
        hashing: 'journal_validation',
        catalogBuild: 'excluded',
      );
    }
  });
}

Future<_SnapshotPerformanceFixture> _createSnapshotFixture(int mapCount) async {
  final root = await Directory.systemTemp.createTemp(
    'pokemap_event_v2_e_bis_perf_',
  );
  final projectPath = p.join(root.path, 'project.json');
  final entries = <ProjectMapEntry>[];
  var totalMapBytes = 0;
  for (var index = 0; index < mapCount; index++) {
    final suffix = index.toString().padLeft(4, '0');
    final mapId = 'map_$suffix';
    final relativePath = 'maps/$mapId.json';
    final map = MapData(
      id: mapId,
      name: 'Map $suffix',
      size: const GridSize(width: 8, height: 6),
    );
    final bytes = utf8.encode(
      const JsonEncoder.withIndent('  ').convert(map.toJson()),
    );
    final file = File(p.join(root.path, relativePath));
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
    totalMapBytes += bytes.length;
    entries.add(ProjectMapEntry(
      id: mapId,
      name: map.name,
      relativePath: relativePath,
    ));
  }
  final manifest = ProjectManifest(
    name: 'Phase E-bis performance fixture',
    maps: entries,
    tilesets: const [],
    scenes: [persistenceScene()],
    facts: [NarrativeFactDefinition(id: 'fact_a', label: 'Fact A')],
  );
  final projectBytes = utf8.encode(
    const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
  );
  await File(projectPath).writeAsBytes(projectBytes, flush: true);
  return _SnapshotPerformanceFixture(
    root: root,
    projectPath: await File(projectPath).resolveSymbolicLinks(),
    totalMapBytes: totalMapBytes,
    totalSnapshotBytes: totalMapBytes + projectBytes.length,
  );
}

Future<void> _revalidateMaps(NarrativeEventAuthoringSession session) async {
  final mapIds = session.mapPaths.keys.toList()
    ..sort(compareNarrativeEventUtf16);
  for (final mapId in mapIds) {
    final expectedPath = session.mapPaths[mapId]!;
    final file = File(expectedPath);
    expect(await file.exists(), isTrue);
    expect(
      p.normalize(await file.resolveSymbolicLinks()),
      expectedPath,
    );
    expect(
      narrativeEventBytesFingerprint(await file.readAsBytes()),
      session.mapByteHashes[mapId],
    );
  }
}

Future<void> _populateCommittedHistory(
  EventRegistryPersistenceFixture fixture,
  int count,
) async {
  final persistence = NarrativeEventRegistryPersistence();
  NarrativeEventRegistry? previousRegistry;
  for (var index = 0; index < count; index++) {
    final nextRegistry = persistenceRegistry(
      records: [persistenceDraft(name: 'Version $index')],
    );
    final session = index == 0
        ? fixture.session
        : await NarrativeEventAuthoringSession.prepare(fixture.projectPath);
    final result = await persistence.write(
      persistenceRequest(
        fixture: fixture,
        operationId: 'e_bis_perf_history_$index',
        session: session,
        previousRegistry: previousRegistry,
        nextRegistry: nextRegistry,
        mutation: index == 0 ? 'createDraft' : 'rename',
      ),
    );
    expect(result.status, NarrativeEventRegistryPersistenceStatus.committed);
    previousRegistry = nextRegistry;
  }
}

Future<int> _eventArtifactBytes(Directory root) async {
  var bytes = 0;
  await for (final entity in root.list(followLinks: false)) {
    if (entity is! File ||
        !p.basename(entity.path).startsWith(
              NarrativeEventRegistryPersistence.journalPrefix,
            )) {
      continue;
    }
    bytes += await entity.length();
  }
  return bytes;
}

Future<List<int>> _measure(
  int iterations,
  Future<void> Function() operation,
) async {
  final samples = <int>[];
  for (var iteration = 0; iteration < iterations; iteration++) {
    final stopwatch = Stopwatch()..start();
    await operation();
    stopwatch.stop();
    samples.add(stopwatch.elapsedMicroseconds);
  }
  return samples;
}

void _emitMeasurement({
  required String operation,
  required int volume,
  required List<int> samples,
  required int bytesRead,
  required String hashing,
  required String catalogBuild,
}) {
  final sorted = [...samples]..sort();
  final total = sorted.fold<int>(0, (sum, value) => sum + value);
  final mean = total / sorted.length;
  final median = sorted.length.isOdd
      ? sorted[sorted.length ~/ 2].toDouble()
      : (sorted[sorted.length ~/ 2 - 1] + sorted[sorted.length ~/ 2]) / 2;
  stdout.writeln(
    'NS_EVENT_V2_PHASE_E_BIS_PERF operation=$operation volume=$volume '
    'iterations=${sorted.length} mean_us=${mean.toStringAsFixed(1)} '
    'median_us=${median.toStringAsFixed(1)} bytes_read=$bytesRead '
    'hashing=$hashing catalog_build=$catalogBuild mode=jit '
    'threshold=informative_only mutable_global_cache=none',
  );
}

String _singleLine(String value) {
  return value.replaceAll(RegExp(r'\s+'), '_');
}

final class _SnapshotPerformanceFixture {
  const _SnapshotPerformanceFixture({
    required this.root,
    required this.projectPath,
    required this.totalMapBytes,
    required this.totalSnapshotBytes,
  });

  final Directory root;
  final String projectPath;
  final int totalMapBytes;
  final int totalSnapshotBytes;

  Future<void> dispose() async {
    if (await root.exists()) await root.delete(recursive: true);
  }
}
