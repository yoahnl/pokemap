import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/narrative_event_authoring_session.dart';
import 'package:map_editor/src/application/models/narrative_event_registry_persistence_models.dart';
import 'package:map_editor/src/infrastructure/repositories/narrative_event_registry_persistence.dart';

import 'support/event_registry_persistence_fixtures.dart';

void main() {
  test('NS-EVENT-V2 Phase E4 persistence performance measurements', () async {
    stdout.writeln(
      'NS_EVENT_V2_PHASE_E_PERF_ENV os=${Platform.operatingSystem} '
      'os_version=${Platform.operatingSystemVersion.replaceAll(' ', '_')} '
      'dart=${Platform.version.split(' ').first} mode=jit aot=not_measured '
      'catalog_build=excluded hashing=included',
    );
    final writeSamples = <int>[];
    for (var iteration = 0; iteration < 7; iteration++) {
      final fixture = await createPersistenceFixture();
      addTearDown(fixture.dispose);
      final request = persistenceRequest(
        fixture: fixture,
        operationId: 'e4_perf_write_$iteration',
        previousRegistry: null,
        nextRegistry: persistenceRegistry(),
      );
      final stopwatch = Stopwatch()..start();
      final result = await NarrativeEventRegistryPersistence().write(
        request,
      );
      stopwatch.stop();
      expect(result.status, NarrativeEventRegistryPersistenceStatus.committed);
      writeSamples.add(stopwatch.elapsedMicroseconds);
    }
    _emitMeasurement('journaled_write', 1, writeSamples);

    for (final count in [1, 100]) {
      final fixture = await createPersistenceFixture();
      addTearDown(fixture.dispose);
      await _populateCommittedJournals(fixture, count);
      final scanSamples = <int>[];
      for (var iteration = 0; iteration < 5; iteration++) {
        final stopwatch = Stopwatch()..start();
        final results = await NarrativeEventRegistryPersistence()
            .recoverProject(fixture.projectPath);
        stopwatch.stop();
        expect(results, hasLength(count));
        expect(
          results.map((result) => result.status),
          everyElement(NarrativeEventRegistryPersistenceStatus.noOp),
        );
        scanSamples.add(stopwatch.elapsedMicroseconds);
      }
      _emitMeasurement('recovery_scan', count, scanSamples);
    }
  });
}

Future<void> _populateCommittedJournals(
  EventRegistryPersistenceFixture fixture,
  int count,
) async {
  final service = NarrativeEventRegistryPersistence();
  NarrativeEventRegistry? previousRegistry;
  for (var index = 0; index < count; index++) {
    final nextRegistry = persistenceRegistry(
      records: [persistenceDraft(name: 'Version $index')],
    );
    final session = index == 0
        ? fixture.session
        : await NarrativeEventAuthoringSession.prepare(fixture.projectPath);
    final result = await service.write(
      persistenceRequest(
        fixture: fixture,
        operationId: 'e4_perf_history_$index',
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

void _emitMeasurement(String operation, int volume, List<int> samples) {
  final sorted = [...samples]..sort();
  final total = sorted.fold<int>(0, (sum, value) => sum + value);
  final mean = total / sorted.length;
  final median = sorted.length.isOdd
      ? sorted[sorted.length ~/ 2].toDouble()
      : (sorted[sorted.length ~/ 2 - 1] + sorted[sorted.length ~/ 2]) / 2;
  stdout.writeln(
    'NS_EVENT_V2_PHASE_E_PERF operation=$operation volume=$volume '
    'iterations=${sorted.length} mean_us=${mean.toStringAsFixed(1)} '
    'median_us=${median.toStringAsFixed(1)} mode=jit '
    'catalog_build=excluded hashing=included '
    'complexity=linear_in_scanned_bytes_and_artifacts aot=not_measured',
  );
}
