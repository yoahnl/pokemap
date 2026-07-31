import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/domain/models/map_document_persistence.dart';
import 'package:map_editor/src/infrastructure/repositories/atomic_map_document_persistence.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:path/path.dart' as p;

void main() {
  group('AtomicMapDocumentPersistence', () {
    test('rejects malformed revisions before filesystem I/O', () {
      expect(
        () => MapDocumentWritePrecondition.revision(''),
        throwsArgumentError,
      );
      expect(
        () => MapDocumentWritePrecondition.revision('sha256:not-a-hash'),
        throwsArgumentError,
      );
    });

    test('returns the SHA-256 revision of the exact durable map bytes',
        () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);

      final saved = await fixture.repository.saveMapDocument(
        _map(name: 'Initial'),
        fixture.mapPath,
        precondition: const MapDocumentWritePrecondition.absent(),
      );

      expect(
        saved.revision,
        narrativeEventBytesFingerprint(
          await File(fixture.mapPath).readAsBytes(),
        ),
      );
      final loaded = await fixture.repository.loadMapDocument(fixture.mapPath);
      expect(loaded.map, saved.map);
      expect(loaded.revision, saved.revision);
      expect(await fixture.artifacts(), isEmpty);
    });

    test(
        'saveMap persists canonical v3 and refuses future visual semantics '
        'without replacing it', () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final canonical = _visualStackMap(
        name: 'Canonical',
        visualStack: MapVisualStackConfig.canonicalV1,
      );

      await fixture.repository.saveMap(canonical, fixture.mapPath);
      final beforeBytes = await File(fixture.mapPath).readAsBytes();

      await expectLater(
        fixture.repository.saveMap(
          _visualStackMap(
            name: 'Unsupported future',
            visualStack: MapVisualStackConfig(semanticsVersion: 99),
          ),
          fixture.mapPath,
        ),
        throwsA(
          isA<ValidationException>().having(
            (error) => error.message,
            'message',
            contains('not supported for writes'),
          ),
        ),
      );

      expect(await File(fixture.mapPath).readAsBytes(), beforeBytes);
      expect(await fixture.repository.loadMap(fixture.mapPath), canonical);
      expect(await fixture.artifacts(), isEmpty);
    });

    test(
        'saveMapDocument persists canonical v3 and refuses future visual '
        'semantics without a durable CAS write', () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final canonical = _visualStackMap(
        name: 'Canonical',
        visualStack: MapVisualStackConfig.canonicalV1,
      );
      final saved = await fixture.repository.saveMapDocument(
        canonical,
        fixture.mapPath,
        precondition: const MapDocumentWritePrecondition.absent(),
      );
      final beforeBytes = await File(fixture.mapPath).readAsBytes();

      await expectLater(
        fixture.repository.saveMapDocument(
          _visualStackMap(
            name: 'Unsupported future',
            visualStack: MapVisualStackConfig(semanticsVersion: 99),
          ),
          fixture.mapPath,
          precondition: MapDocumentWritePrecondition.revision(saved.revision),
        ),
        throwsA(
          isA<ValidationException>().having(
            (error) => error.message,
            'message',
            contains('not supported for writes'),
          ),
        ),
      );

      expect(await File(fixture.mapPath).readAsBytes(), beforeBytes);
      final durable = await fixture.repository.loadMapDocument(fixture.mapPath);
      expect(durable.map, saved.map);
      expect(durable.revision, saved.revision);
      expect(await fixture.artifacts(), isEmpty);
    });

    test('expected absence refuses to replace an existing map', () async {
      final fixture = await _Fixture.createWithBaseline();
      addTearDown(fixture.dispose);
      final beforeBytes = await File(fixture.mapPath).readAsBytes();

      await expectLater(
        fixture.repository.saveMapDocument(
          _map(name: 'Unexpected replacement'),
          fixture.mapPath,
          precondition: const MapDocumentWritePrecondition.absent(),
        ),
        throwsA(isA<EditorConflictException>()),
      );

      expect(await File(fixture.mapPath).readAsBytes(), beforeBytes);
      expect(await fixture.artifacts(), isEmpty);
    });

    test('rejects a stale revision without changing external bytes', () async {
      final fixture = await _Fixture.createWithBaseline();
      addTearDown(fixture.dispose);
      final baseline =
          await fixture.repository.loadMapDocument(fixture.mapPath);
      await fixture.writeMap(_map(name: 'External'));
      final externalBytes = await File(fixture.mapPath).readAsBytes();

      await expectLater(
        fixture.repository.saveMapDocument(
          _map(name: 'Local'),
          fixture.mapPath,
          precondition:
              MapDocumentWritePrecondition.revision(baseline.revision),
        ),
        throwsA(isA<EditorConflictException>()),
      );

      expect(await File(fixture.mapPath).readAsBytes(), externalBytes);
      expect(await fixture.artifacts(), isEmpty);
    });

    test('revision-checked delete preserves an externally changed map',
        () async {
      final fixture = await _Fixture.createWithBaseline();
      addTearDown(fixture.dispose);
      final baseline =
          await fixture.repository.loadMapDocument(fixture.mapPath);
      await fixture.writeMap(_map(name: 'External before delete'));
      final externalBytes = await File(fixture.mapPath).readAsBytes();

      await expectLater(
        fixture.repository.deleteMapDocument(
          fixture.mapPath,
          expectedRevision: baseline.revision,
        ),
        throwsA(isA<EditorConflictException>()),
      );

      expect(await File(fixture.mapPath).readAsBytes(), externalBytes);
    });

    test('rejects a map target that is a symbolic link', () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final realPath = p.join(fixture.root.path, 'real-map.json');
      await fixture.repository.saveMap(
        _map(name: 'Real target'),
        realPath,
      );
      final originalBytes = await File(realPath).readAsBytes();
      await Directory(p.dirname(fixture.mapPath)).create(recursive: true);
      await Link(fixture.mapPath).create(realPath);

      await expectLater(
        fixture.repository.saveMapDocument(
          _map(name: 'Must not follow link'),
          fixture.mapPath,
          precondition: const MapDocumentWritePrecondition.absent(),
        ),
        throwsA(isA<EditorValidationException>()),
      );

      expect(await File(realPath).readAsBytes(), originalBytes);
    });

    test('flushes and verifies a sibling temp before target replacement',
        () async {
      final fixture = await _Fixture.createWithBaseline();
      addTearDown(fixture.dispose);
      final baseline =
          await fixture.repository.loadMapDocument(fixture.mapPath);
      final beforeBytes = await File(fixture.mapPath).readAsBytes();
      String? tempPath;
      final repository = FileMapRepository(
        mapPersistence: AtomicMapDocumentPersistence(
          faultInjector: (checkpoint, context) async {
            if (checkpoint ==
                AtomicMapDocumentWriteCheckpoint.afterTempFlushed) {
              tempPath = context.tempPath;
              expect(
                p.normalize(p.dirname(context.tempPath)),
                p.normalize(p.dirname(context.targetPath)),
              );
              expect(await File(context.tempPath).exists(), isTrue);
              expect(await File(context.targetPath).readAsBytes(), beforeBytes);
              expect(
                narrativeEventBytesFingerprint(
                  await File(context.tempPath).readAsBytes(),
                ),
                context.expectedAfterRevision,
              );
            }
          },
        ),
      );

      await repository.saveMapDocument(
        _map(name: 'Updated'),
        fixture.mapPath,
        precondition: MapDocumentWritePrecondition.revision(baseline.revision),
      );

      expect(tempPath, isNotNull);
      expect(await File(tempPath!).exists(), isFalse);
      expect(await fixture.artifacts(), isEmpty);
    });

    test('second CAS preserves an external write made before rename', () async {
      final fixture = await _Fixture.createWithBaseline();
      addTearDown(fixture.dispose);
      final baseline =
          await fixture.repository.loadMapDocument(fixture.mapPath);
      List<int>? externalBytes;
      final repository = FileMapRepository(
        mapPersistence: AtomicMapDocumentPersistence(
          faultInjector: (checkpoint, _) async {
            if (checkpoint ==
                AtomicMapDocumentWriteCheckpoint.beforeSecondCompareAndSwap) {
              await fixture.writeMap(_map(name: 'External during save'));
              externalBytes = await File(fixture.mapPath).readAsBytes();
            }
          },
        ),
      );

      await expectLater(
        repository.saveMapDocument(
          _map(name: 'Local'),
          fixture.mapPath,
          precondition:
              MapDocumentWritePrecondition.revision(baseline.revision),
        ),
        throwsA(isA<EditorConflictException>()),
      );

      expect(externalBytes, isNotNull);
      expect(await File(fixture.mapPath).readAsBytes(), externalBytes);
      expect(await fixture.artifacts(), isEmpty);
    });

    test('corrupted flushed temp is rejected without touching the target',
        () async {
      final fixture = await _Fixture.createWithBaseline();
      addTearDown(fixture.dispose);
      final baseline =
          await fixture.repository.loadMapDocument(fixture.mapPath);
      final beforeBytes = await File(fixture.mapPath).readAsBytes();
      final repository = FileMapRepository(
        mapPersistence: AtomicMapDocumentPersistence(
          faultInjector: (checkpoint, context) async {
            if (checkpoint ==
                AtomicMapDocumentWriteCheckpoint.afterTempFlushed) {
              await File(context.tempPath).writeAsString(
                '{"corrupted":true}',
                flush: true,
              );
            }
          },
        ),
      );

      await expectLater(
        repository.saveMapDocument(
          _map(name: 'Updated'),
          fixture.mapPath,
          precondition:
              MapDocumentWritePrecondition.revision(baseline.revision),
        ),
        throwsA(isA<EditorPersistenceException>()),
      );

      expect(await File(fixture.mapPath).readAsBytes(), beforeBytes);
      expect(await fixture.artifacts(), isEmpty);
    });

    test('failure before rename leaves original bytes visible', () async {
      final fixture = await _Fixture.createWithBaseline();
      addTearDown(fixture.dispose);
      final baseline =
          await fixture.repository.loadMapDocument(fixture.mapPath);
      final beforeBytes = await File(fixture.mapPath).readAsBytes();
      final repository = FileMapRepository(
        mapPersistence: AtomicMapDocumentPersistence(
          faultInjector: (checkpoint, _) {
            if (checkpoint ==
                AtomicMapDocumentWriteCheckpoint.afterJournalPrepared) {
              throw const FileSystemException('Injected pre-rename failure');
            }
          },
        ),
      );

      await expectLater(
        repository.saveMapDocument(
          _map(name: 'Updated'),
          fixture.mapPath,
          precondition:
              MapDocumentWritePrecondition.revision(baseline.revision),
        ),
        throwsA(isA<EditorPersistenceException>()),
      );

      expect(await File(fixture.mapPath).readAsBytes(), beforeBytes);
      expect(await fixture.artifacts(), isEmpty);
    });

    test('post-rename callback failure is verified as committed', () async {
      final fixture = await _Fixture.createWithBaseline();
      addTearDown(fixture.dispose);
      final baseline =
          await fixture.repository.loadMapDocument(fixture.mapPath);
      final repository = FileMapRepository(
        mapPersistence: AtomicMapDocumentPersistence(
          faultInjector: (checkpoint, _) {
            if (checkpoint ==
                AtomicMapDocumentWriteCheckpoint.afterMapRenamed) {
              throw const FileSystemException('Injected post-rename failure');
            }
          },
        ),
      );

      final saved = await repository.saveMapDocument(
        _map(name: 'Committed'),
        fixture.mapPath,
        precondition: MapDocumentWritePrecondition.revision(baseline.revision),
      );

      expect(
        (await repository.loadMapDocument(fixture.mapPath)).map.name,
        'Committed',
      );
      expect(
        saved.revision,
        narrativeEventBytesFingerprint(
          await File(fixture.mapPath).readAsBytes(),
        ),
      );
      expect(await fixture.artifacts(), isEmpty);
    });

    test('pre-verification callback failure is verified as committed',
        () async {
      final fixture = await _Fixture.createWithBaseline();
      addTearDown(fixture.dispose);
      final baseline =
          await fixture.repository.loadMapDocument(fixture.mapPath);
      final repository = FileMapRepository(
        mapPersistence: AtomicMapDocumentPersistence(
          faultInjector: (checkpoint, _) {
            if (checkpoint ==
                AtomicMapDocumentWriteCheckpoint.beforeCommitVerification) {
              throw const FileSystemException(
                'Injected commit-verification failure',
              );
            }
          },
        ),
      );

      final saved = await repository.saveMapDocument(
        _map(name: 'Committed before verification'),
        fixture.mapPath,
        precondition: MapDocumentWritePrecondition.revision(baseline.revision),
      );

      expect(
        (await repository.loadMapDocument(fixture.mapPath)).map.name,
        'Committed before verification',
      );
      expect(
        saved.revision,
        narrativeEventBytesFingerprint(
          await File(fixture.mapPath).readAsBytes(),
        ),
      );
      expect(await fixture.artifacts(), isEmpty);
    });

    test(
        'fresh repository completes a prepared crash once and later recovery is clear',
        () async {
      final fixture = await _Fixture.createWithBaseline();
      addTearDown(fixture.dispose);
      final baseline =
          await fixture.repository.loadMapDocument(fixture.mapPath);
      final baselineBytes = await File(fixture.mapPath).readAsBytes();
      final crashingRepository = FileMapRepository(
        mapPersistence: AtomicMapDocumentPersistence(
          faultInjector: (checkpoint, _) {
            if (checkpoint ==
                AtomicMapDocumentWriteCheckpoint.afterJournalPrepared) {
              throw const AtomicMapDocumentSimulatedCrash();
            }
          },
        ),
      );

      await expectLater(
        crashingRepository.saveMapDocument(
          _map(name: 'Recovered'),
          fixture.mapPath,
          precondition:
              MapDocumentWritePrecondition.revision(baseline.revision),
        ),
        throwsA(isA<AtomicMapDocumentSimulatedCrash>()),
      );

      // A prepared crash happens before rename: only recovery artifacts may
      // differ at this point, while the durable target remains the baseline.
      expect(await File(fixture.mapPath).readAsBytes(), baselineBytes);
      expect(await fixture.artifacts(), isNotEmpty);

      final recoveryRepository = FileMapRepository();
      final recovery =
          await recoveryRepository.recoverMapDocument(fixture.mapPath);
      expect(
        recovery.status,
        MapDocumentRecoveryStatus.completedInterruptedWrite,
      );
      final recovered =
          await recoveryRepository.loadMapDocument(fixture.mapPath);
      expect(recovered.map.name, 'Recovered');
      final recoveredBytes = await File(fixture.mapPath).readAsBytes();
      expect(recovered.revision, recovery.revision);
      expect(await fixture.artifacts(), isEmpty);

      // A second fresh process must observe a stable document, not replay the
      // prepared write a second time or manufacture another revision.
      final verificationRepository = FileMapRepository();
      final secondRecovery =
          await verificationRepository.recoverMapDocument(fixture.mapPath);
      expect(secondRecovery.status, MapDocumentRecoveryStatus.clear);
      final reopened =
          await verificationRepository.loadMapDocument(fixture.mapPath);
      expect(reopened.map, recovered.map);
      expect(reopened.revision, recovered.revision);
      expect(await File(fixture.mapPath).readAsBytes(), recoveredBytes);
      expect(await fixture.artifacts(), isEmpty);
    });

    test('post-rename crash is cleaned without rewriting the committed target',
        () async {
      final fixture = await _Fixture.createWithBaseline();
      addTearDown(fixture.dispose);
      final baseline =
          await fixture.repository.loadMapDocument(fixture.mapPath);
      final crashingRepository = FileMapRepository(
        mapPersistence: AtomicMapDocumentPersistence(
          faultInjector: (checkpoint, _) {
            if (checkpoint ==
                AtomicMapDocumentWriteCheckpoint.afterMapRenamed) {
              throw const AtomicMapDocumentSimulatedCrash();
            }
          },
        ),
      );

      await expectLater(
        crashingRepository.saveMapDocument(
          _map(name: 'Committed before crash'),
          fixture.mapPath,
          precondition:
              MapDocumentWritePrecondition.revision(baseline.revision),
        ),
        throwsA(isA<AtomicMapDocumentSimulatedCrash>()),
      );
      final committedBytes = await File(fixture.mapPath).readAsBytes();

      final recovery =
          await fixture.repository.recoverMapDocument(fixture.mapPath);

      expect(
        recovery.status,
        MapDocumentRecoveryStatus.cleanedCommittedWrite,
      );
      expect(await File(fixture.mapPath).readAsBytes(), committedBytes);
      expect(await fixture.artifacts(), isEmpty);
    });

    test('recovery blocks when target diverged from before and after',
        () async {
      final fixture = await _Fixture.createWithBaseline();
      addTearDown(fixture.dispose);
      final baseline =
          await fixture.repository.loadMapDocument(fixture.mapPath);
      final crashingRepository = FileMapRepository(
        mapPersistence: AtomicMapDocumentPersistence(
          faultInjector: (checkpoint, _) {
            if (checkpoint ==
                AtomicMapDocumentWriteCheckpoint.afterJournalPrepared) {
              throw const AtomicMapDocumentSimulatedCrash();
            }
          },
        ),
      );
      await expectLater(
        crashingRepository.saveMapDocument(
          _map(name: 'Interrupted local'),
          fixture.mapPath,
          precondition:
              MapDocumentWritePrecondition.revision(baseline.revision),
        ),
        throwsA(isA<AtomicMapDocumentSimulatedCrash>()),
      );
      await fixture.writeMap(_map(name: 'External after crash'));
      final externalBytes = await File(fixture.mapPath).readAsBytes();

      await expectLater(
        fixture.repository.recoverMapDocument(fixture.mapPath),
        throwsA(isA<EditorConflictException>()),
      );

      expect(await File(fixture.mapPath).readAsBytes(), externalBytes);
      expect(await fixture.artifacts(), isNotEmpty);
    });

    test('orphan temp without a journal is discarded safely', () async {
      final fixture = await _Fixture.createWithBaseline();
      addTearDown(fixture.dispose);
      final baseline =
          await fixture.repository.loadMapDocument(fixture.mapPath);
      final beforeBytes = await File(fixture.mapPath).readAsBytes();
      final crashingRepository = FileMapRepository(
        mapPersistence: AtomicMapDocumentPersistence(
          faultInjector: (checkpoint, _) {
            if (checkpoint ==
                AtomicMapDocumentWriteCheckpoint.afterTempFlushed) {
              throw const AtomicMapDocumentSimulatedCrash();
            }
          },
        ),
      );
      await expectLater(
        crashingRepository.saveMapDocument(
          _map(name: 'Never prepared'),
          fixture.mapPath,
          precondition:
              MapDocumentWritePrecondition.revision(baseline.revision),
        ),
        throwsA(isA<AtomicMapDocumentSimulatedCrash>()),
      );

      final recovery =
          await fixture.repository.recoverMapDocument(fixture.mapPath);

      expect(
        recovery.status,
        MapDocumentRecoveryStatus.discardedIncompleteWrite,
      );
      expect(await File(fixture.mapPath).readAsBytes(), beforeBytes);
      expect(await fixture.artifacts(), isEmpty);
    });

    test('concurrent writers serialize through the same OS lock', () async {
      final fixture = await _Fixture.createWithBaseline();
      addTearDown(fixture.dispose);
      final baseline =
          await fixture.repository.loadMapDocument(fixture.mapPath);
      final firstEntered = Completer<void>();
      final releaseFirst = Completer<void>();
      final secondEntered = Completer<void>();
      final firstRepository = FileMapRepository(
        mapPersistence: AtomicMapDocumentPersistence(
          faultInjector: (checkpoint, _) async {
            if (checkpoint ==
                AtomicMapDocumentWriteCheckpoint.afterInitialRead) {
              firstEntered.complete();
              await releaseFirst.future;
            }
          },
        ),
      );
      final secondRepository = FileMapRepository(
        mapPersistence: AtomicMapDocumentPersistence(
          faultInjector: (checkpoint, _) {
            if (checkpoint ==
                AtomicMapDocumentWriteCheckpoint.afterInitialRead) {
              secondEntered.complete();
            }
          },
        ),
      );

      final first = firstRepository.saveMapDocument(
        _map(name: 'First'),
        fixture.mapPath,
        precondition: MapDocumentWritePrecondition.revision(baseline.revision),
      );
      await firstEntered.future;
      final second = secondRepository.saveMapDocument(
        _map(name: 'Second'),
        fixture.mapPath,
        precondition: MapDocumentWritePrecondition.revision(baseline.revision),
      );
      final secondExpectation = expectLater(
        second,
        throwsA(isA<EditorConflictException>()),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(secondEntered.isCompleted, isFalse);
      releaseFirst.complete();
      await first;
      await secondExpectation;
      expect(secondEntered.isCompleted, isTrue);
      expect(
        (await fixture.repository.loadMapDocument(fixture.mapPath)).map.name,
        'First',
      );
    });
  });
}

final class _Fixture {
  _Fixture({
    required this.root,
    required this.mapPath,
    required this.repository,
  });

  static Future<_Fixture> create() async {
    final root =
        await Directory.systemTemp.createTemp('pokemap_atomic_map_document_');
    return _Fixture(
      root: root,
      mapPath: p.join(root.path, 'maps', 'alpha.json'),
      repository: FileMapRepository(),
    );
  }

  static Future<_Fixture> createWithBaseline() async {
    final fixture = await create();
    await fixture.repository.saveMapDocument(
      _map(name: 'Baseline'),
      fixture.mapPath,
      precondition: const MapDocumentWritePrecondition.absent(),
    );
    return fixture;
  }

  final Directory root;
  final String mapPath;
  final FileMapRepository repository;

  Future<void> writeMap(MapData map) async {
    final file = File(mapPath);
    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(map.toJson()),
      flush: true,
    );
  }

  Future<List<FileSystemEntity>> artifacts() async {
    final directory = Directory(p.dirname(mapPath));
    if (!await directory.exists()) return const [];
    return directory
        .list(followLinks: false)
        .where(
          (entry) => p.basename(entry.path).startsWith('.pokemap-map-'),
        )
        .toList();
  }

  Future<void> dispose() async {
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
  }
}

MapData _map({required String name}) => MapData(
      id: 'alpha',
      name: name,
      size: const GridSize(width: 1, height: 1),
      layers: const <MapLayer>[
        TileLayer(
          id: 'base',
          name: 'Base',
          tiles: <int>[0],
        ),
        TerrainLayer(
          id: 'terrain',
          name: 'Terrain',
          terrains: <TerrainType>[TerrainType.none],
        ),
        CollisionLayer(
          id: 'collision',
          name: 'Collision',
          collisions: <bool>[false],
        ),
      ],
    );

MapData _visualStackMap({
  required String name,
  required MapVisualStackConfig visualStack,
}) =>
    _map(name: name).copyWith(
      version: ProjectVersion.v3,
      visualStack: visualStack,
    );
