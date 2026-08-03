import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/services/map_lifecycle_transaction_service.dart';
import 'package:map_editor/src/domain/models/map_document_persistence.dart';

void main() {
  group('MapLifecycleTransactionCoordinator', () {
    test('create commits the target and manifest before clearing its journal',
        () async {
      final fixture = _Fixture();
      final request = fixture.createRequest();

      final result = await fixture.coordinator.execute(request);

      expect(result.project, fixture.afterCreate);
      expect(result.targetMap, fixture.target);
      expect(
        result.targetRevision,
        mapDocumentRevisionFor(fixture.target),
      );
      expect(fixture.gateway.project, fixture.afterCreate);
      expect(fixture.gateway.maps[_Fixture.targetPath]!.map, fixture.target);
      expect(fixture.gateway.journal, isNull);
      expect(
        fixture.gateway.writtenStatuses,
        <MapLifecycleTransactionStatus>[
          MapLifecycleTransactionStatus.prepared,
          MapLifecycleTransactionStatus.targetWritten,
          MapLifecycleTransactionStatus.projectWritten,
          MapLifecycleTransactionStatus.committed,
        ],
      );
    });

    test('prepared create rolls forward after a process restart', () async {
      final fixture = _Fixture(
        crashAt: MapLifecycleTransactionCheckpoint.afterJournalPrepared,
      );

      await expectLater(
        fixture.coordinator.execute(fixture.createRequest()),
        throwsA(isA<MapLifecycleSimulatedCrash>()),
      );
      expect(fixture.gateway.maps, isEmpty);
      expect(fixture.gateway.project, fixture.before);
      expect(fixture.gateway.journal, isNotNull);

      final recovered =
          await MapLifecycleTransactionCoordinator(fixture.gateway).recover(
        _Fixture.projectPath,
      );

      expect(recovered.status, MapLifecycleRecoveryStatus.recovered);
      expect(fixture.gateway.project, fixture.afterCreate);
      expect(fixture.gateway.maps[_Fixture.targetPath]!.map, fixture.target);
      expect(fixture.gateway.journal, isNull);
      expect(
        (await MapLifecycleTransactionCoordinator(fixture.gateway).recover(
          _Fixture.projectPath,
        ))
            .status,
        MapLifecycleRecoveryStatus.clear,
      );
    });

    test('rename recovery finishes source cleanup after manifest commit',
        () async {
      final fixture = _Fixture(
        crashAt: MapLifecycleTransactionCheckpoint.afterProjectWritten,
      )..seedSource();

      await expectLater(
        fixture.coordinator.execute(fixture.renameRequest()),
        throwsA(isA<MapLifecycleSimulatedCrash>()),
      );
      expect(fixture.gateway.project, fixture.afterRename);
      expect(fixture.gateway.maps, contains(_Fixture.sourcePath));
      expect(fixture.gateway.maps, contains(_Fixture.targetPath));

      await MapLifecycleTransactionCoordinator(fixture.gateway).recover(
        _Fixture.projectPath,
      );

      expect(fixture.gateway.project, fixture.afterRename);
      expect(fixture.gateway.maps, isNot(contains(_Fixture.sourcePath)));
      expect(fixture.gateway.maps[_Fixture.targetPath]!.map, fixture.target);
      expect(fixture.gateway.journal, isNull);
    });

    test('delete recovery removes the exact source after manifest commit',
        () async {
      final fixture = _Fixture(
        crashAt: MapLifecycleTransactionCheckpoint.afterProjectWritten,
      )..seedSource();

      await expectLater(
        fixture.coordinator.execute(fixture.deleteRequest()),
        throwsA(isA<MapLifecycleSimulatedCrash>()),
      );
      expect(fixture.gateway.project, fixture.afterDelete);
      expect(fixture.gateway.maps, contains(_Fixture.sourcePath));

      await MapLifecycleTransactionCoordinator(fixture.gateway).recover(
        _Fixture.projectPath,
      );

      expect(fixture.gateway.project, fixture.afterDelete);
      expect(fixture.gateway.maps, isNot(contains(_Fixture.sourcePath)));
      expect(fixture.gateway.journal, isNull);
    });

    test('recovery blocks and preserves evidence after project divergence',
        () async {
      final fixture = _Fixture(
        crashAt: MapLifecycleTransactionCheckpoint.afterJournalPrepared,
      );
      await expectLater(
        fixture.coordinator.execute(fixture.createRequest()),
        throwsA(isA<MapLifecycleSimulatedCrash>()),
      );
      fixture.gateway.setProject(
        fixture.before.copyWith(name: 'External project edit'),
      );

      await expectLater(
        MapLifecycleTransactionCoordinator(fixture.gateway).recover(
          _Fixture.projectPath,
        ),
        throwsA(isA<ProjectRecoveryBlockedException>()),
      );

      expect(fixture.gateway.maps, isEmpty);
      expect(fixture.gateway.journal, isNotNull);
    });

    test('recovery blocks when a rename source revision changed', () async {
      final fixture = _Fixture(
        crashAt: MapLifecycleTransactionCheckpoint.afterJournalPrepared,
      )..seedSource();
      await expectLater(
        fixture.coordinator.execute(fixture.renameRequest()),
        throwsA(isA<MapLifecycleSimulatedCrash>()),
      );
      fixture.gateway.seedMap(
        _Fixture.sourcePath,
        fixture.source.copyWith(name: 'External map edit'),
      );

      await expectLater(
        MapLifecycleTransactionCoordinator(fixture.gateway).recover(
          _Fixture.projectPath,
        ),
        throwsA(isA<ProjectRecoveryBlockedException>()),
      );

      expect(fixture.gateway.project, fixture.before);
      expect(fixture.gateway.maps, isNot(contains(_Fixture.targetPath)));
      expect(fixture.gateway.journal, isNotNull);
    });

    test('stale source before prepare is a conflict without recovery evidence',
        () async {
      final fixture = _Fixture()..seedSource();
      final request = fixture.renameRequest();
      fixture.gateway.seedMap(
        _Fixture.sourcePath,
        fixture.source.copyWith(name: 'External edit before prepare'),
      );

      await expectLater(
        fixture.coordinator.execute(request),
        throwsA(isA<EditorConflictException>()),
      );

      expect(fixture.gateway.project, fixture.before);
      expect(fixture.gateway.maps, isNot(contains(_Fixture.targetPath)));
      expect(fixture.gateway.journal, isNull);
    });

    for (final operation in <MapLifecycleOperation>[
      MapLifecycleOperation.rename,
      MapLifecycleOperation.duplicate,
      MapLifecycleOperation.delete,
    ]) {
      test(
          '${operation.name} rejects future visual semantics before preparing '
          'a journal', () async {
        final fixture = _Fixture();
        final futureSource = fixture.source.copyWith(
          version: ProjectVersion.v6,
          visualStack: MapVisualStackConfig(semanticsVersion: 99),
        );
        fixture.gateway.seedMap(_Fixture.sourcePath, futureSource);

        await expectLater(
          fixture.coordinator.execute(
            switch (operation) {
              MapLifecycleOperation.rename => fixture.renameRequest(),
              MapLifecycleOperation.duplicate => fixture.duplicateRequest(),
              MapLifecycleOperation.delete => fixture.deleteRequest(),
              MapLifecycleOperation.create => throw StateError(
                  'Create is outside this source lifecycle guard test.',
                ),
            },
          ),
          throwsA(
            isA<EditorInvalidOperationException>().having(
              (error) => error.message,
              'message',
              contains('strictement en lecture seule'),
            ),
          ),
        );

        expect(fixture.gateway.project, fixture.before);
        expect(fixture.gateway.maps[_Fixture.sourcePath]!.map, futureSource);
        expect(fixture.gateway.maps, isNot(contains(_Fixture.targetPath)));
        expect(fixture.gateway.writtenStatuses, isEmpty);
        expect(fixture.gateway.journal, isNull);
      });
    }

    test('recovery blocks a pre-existing journal for a future visual stack',
        () async {
      final fixture = _Fixture();
      final futureSource = fixture.source.copyWith(
        version: ProjectVersion.v6,
        visualStack: MapVisualStackConfig(semanticsVersion: 99),
      );
      fixture.gateway.seedMap(_Fixture.sourcePath, futureSource);
      fixture.gateway.journal = MapLifecycleTransactionRecord.fromRequest(
        request: fixture.renameRequest(),
        canonicalProjectPath: _Fixture.projectPath,
        projectBeforeRevision: fixture.gateway.projectRevision,
      );

      await expectLater(
        MapLifecycleTransactionCoordinator(fixture.gateway).recover(
          _Fixture.projectPath,
        ),
        throwsA(
          isA<ProjectRecoveryBlockedException>()
              .having(
                (error) => error.code,
                'code',
                'mapLifecycleRecoveryBlocked',
              )
              .having(
                (error) => error.message,
                'message',
                contains('strictement en lecture seule'),
              ),
        ),
      );

      expect(fixture.gateway.project, fixture.before);
      expect(fixture.gateway.maps[_Fixture.sourcePath]!.map, futureSource);
      expect(fixture.gateway.maps, isNot(contains(_Fixture.targetPath)));
      expect(fixture.gateway.journal, isNotNull);
    });

    test('recovery blocks instead of overwriting a target collision', () async {
      final fixture = _Fixture(
        crashAt: MapLifecycleTransactionCheckpoint.afterJournalPrepared,
      );
      await expectLater(
        fixture.coordinator.execute(fixture.createRequest()),
        throwsA(isA<MapLifecycleSimulatedCrash>()),
      );
      fixture.gateway.seedMap(_Fixture.targetPath, _map('foreign'));

      await expectLater(
        MapLifecycleTransactionCoordinator(fixture.gateway).recover(
          _Fixture.projectPath,
        ),
        throwsA(isA<ProjectRecoveryBlockedException>()),
      );

      expect(fixture.gateway.maps[_Fixture.targetPath]!.map.id, 'foreign');
      expect(fixture.gateway.project, fixture.before);
      expect(fixture.gateway.journal, isNotNull);
    });

    test('exact project revision is revalidated even for the same model',
        () async {
      final fixture = _Fixture(
        crashAt: MapLifecycleTransactionCheckpoint.afterJournalPrepared,
      );
      await expectLater(
        fixture.coordinator.execute(fixture.createRequest()),
        throwsA(isA<MapLifecycleSimulatedCrash>()),
      );
      fixture.gateway.projectRevision = _revision('unknown-root-edit');

      await expectLater(
        MapLifecycleTransactionCoordinator(fixture.gateway).recover(
          _Fixture.projectPath,
        ),
        throwsA(isA<ProjectRecoveryBlockedException>()),
      );

      expect(fixture.gateway.project, fixture.before);
      expect(fixture.gateway.maps, isEmpty);
      expect(fixture.gateway.journal, isNotNull);
    });

    test('committed evidence is idempotently cleared after restart', () async {
      final fixture = _Fixture(
        crashAt: MapLifecycleTransactionCheckpoint.beforeJournalCleared,
      );

      await expectLater(
        fixture.coordinator.execute(fixture.createRequest()),
        throwsA(isA<MapLifecycleSimulatedCrash>()),
      );
      expect(
        fixture.gateway.journal!.status,
        MapLifecycleTransactionStatus.committed,
      );
      expect(fixture.gateway.project, fixture.afterCreate);

      final recovered =
          await MapLifecycleTransactionCoordinator(fixture.gateway).recover(
        _Fixture.projectPath,
      );

      expect(recovered.status, MapLifecycleRecoveryStatus.recovered);
      expect(fixture.gateway.project, fixture.afterCreate);
      expect(fixture.gateway.maps[_Fixture.targetPath]!.map, fixture.target);
      expect(fixture.gateway.journal, isNull);
    });

    test('request cannot smuggle unrelated project changes into create',
        () async {
      final fixture = _Fixture();
      final request = MapLifecycleTransactionRequest.create(
        projectPath: _Fixture.projectPath,
        beforeProject: fixture.before,
        afterProject: fixture.afterCreate.copyWith(name: 'Unrelated edit'),
        targetPath: _Fixture.targetPath,
        targetMap: fixture.target,
      );

      await expectLater(
        fixture.coordinator.execute(request),
        throwsA(isA<EditorValidationException>()),
      );

      expect(fixture.gateway.project, fixture.before);
      expect(fixture.gateway.maps, isEmpty);
      expect(fixture.gateway.journal, isNull);
    });

    test('post-journal async failure is reported as recovery required',
        () async {
      final fixture = _Fixture();
      fixture.gateway.writeProjectError = StateError('disk unavailable');

      await expectLater(
        fixture.coordinator.execute(fixture.createRequest()),
        throwsA(
          isA<ProjectRecoveryRequiredException>().having(
            (error) => error.code,
            'code',
            'mapLifecycleRecoveryRequired',
          ),
        ),
      );

      expect(fixture.gateway.project, fixture.before);
      expect(fixture.gateway.maps, contains(_Fixture.targetPath));
      expect(fixture.gateway.journal, isNotNull);
    });

    test('journal parser rejects a lifecycle delta that changes other fields',
        () {
      final fixture = _Fixture();
      final record = MapLifecycleTransactionRecord.fromRequest(
        request: fixture.createRequest(),
        canonicalProjectPath: _Fixture.projectPath,
        projectBeforeRevision: fixture.gateway.projectRevision,
      );
      final json = record.toJson()
        ..['afterProject'] =
            fixture.afterCreate.copyWith(name: 'Tampered').toJson();

      expect(
        () => MapLifecycleTransactionRecord.fromJson(json),
        throwsFormatException,
      );
    });
  });
}

final class _Fixture {
  _Fixture({MapLifecycleTransactionCheckpoint? crashAt})
      : gateway = _MemoryGateway(_projectBefore()) {
    coordinator = MapLifecycleTransactionCoordinator(
      gateway,
      faultInjector: crashAt == null
          ? null
          : (checkpoint, _) {
              if (checkpoint == crashAt) {
                throw const MapLifecycleSimulatedCrash();
              }
            },
    );
  }

  static const projectPath = '/project/project.json';
  static const sourcePath = '/project/maps/alpha.json';
  static const targetPath = '/project/maps/beta.json';

  final _MemoryGateway gateway;
  late final MapLifecycleTransactionCoordinator coordinator;

  ProjectManifest get before => _projectBefore();
  ProjectManifest get afterCreate => before.copyWith(
        maps: <ProjectMapEntry>[
          ...before.maps,
          const ProjectMapEntry(
            id: 'beta',
            name: 'beta',
            relativePath: 'maps/beta.json',
          ),
        ],
      );
  ProjectManifest get afterRename => before.copyWith(
        maps: const <ProjectMapEntry>[
          ProjectMapEntry(
            id: 'beta',
            name: 'beta',
            relativePath: 'maps/beta.json',
          ),
        ],
      );
  ProjectManifest get afterDelete => before.copyWith(
        maps: const <ProjectMapEntry>[],
      );
  MapData get source => _map('alpha');
  MapData get target => _map('beta');

  void seedSource() => gateway.seedMap(sourcePath, source);

  MapLifecycleTransactionRequest createRequest() {
    return MapLifecycleTransactionRequest.create(
      projectPath: projectPath,
      beforeProject: before,
      afterProject: afterCreate,
      targetPath: targetPath,
      targetMap: target,
    );
  }

  MapLifecycleTransactionRequest renameRequest() {
    final sourceRevision = gateway.maps[sourcePath]!.revision;
    return MapLifecycleTransactionRequest.rename(
      projectPath: projectPath,
      beforeProject: before,
      afterProject: afterRename,
      sourcePath: sourcePath,
      sourceRevision: sourceRevision,
      targetPath: targetPath,
      targetMap: target,
    );
  }

  MapLifecycleTransactionRequest duplicateRequest() {
    final sourceRevision = gateway.maps[sourcePath]!.revision;
    return MapLifecycleTransactionRequest.duplicate(
      projectPath: projectPath,
      beforeProject: before,
      afterProject: afterCreate,
      sourcePath: sourcePath,
      sourceRevision: sourceRevision,
      targetPath: targetPath,
      targetMap: target,
    );
  }

  MapLifecycleTransactionRequest deleteRequest() {
    final sourceRevision = gateway.maps[sourcePath]!.revision;
    return MapLifecycleTransactionRequest.delete(
      projectPath: projectPath,
      beforeProject: before,
      afterProject: afterDelete,
      sourcePath: sourcePath,
      sourceRevision: sourceRevision,
    );
  }
}

final class _MemoryGateway implements MapLifecycleTransactionGateway {
  _MemoryGateway(this.project)
      : projectRevision = _revision(jsonEncode(project.toJson()));

  ProjectManifest project;
  String projectRevision;
  Object? writeProjectError;
  MapLifecycleTransactionRecord? journal;
  final Map<String, RevisionedMapDocument> maps =
      <String, RevisionedMapDocument>{};
  final List<MapLifecycleTransactionStatus> writtenStatuses =
      <MapLifecycleTransactionStatus>[];

  void setProject(ProjectManifest value) {
    project = value;
    projectRevision = _revision(jsonEncode(value.toJson()));
  }

  void seedMap(String path, MapData map) {
    maps[path] = RevisionedMapDocument(
      map: map,
      revision: mapDocumentRevisionFor(map),
    );
  }

  @override
  Future<T> synchronized<T>(
    String projectPath,
    Future<T> Function(String canonicalProjectPath) action,
  ) {
    return action(projectPath);
  }

  @override
  String journalPath(String canonicalProjectPath) =>
      '$canonicalProjectPath.lifecycle.json';

  @override
  Future<MapLifecycleTransactionRecord?> readJournal(
    String canonicalProjectPath,
  ) async {
    return journal;
  }

  @override
  Future<void> writeJournal(
    String canonicalProjectPath,
    MapLifecycleTransactionRecord record,
  ) async {
    writtenStatuses.add(record.status);
    journal = MapLifecycleTransactionRecord.fromJson(
      jsonDecode(jsonEncode(record.toJson())) as Map<String, dynamic>,
    );
  }

  @override
  Future<void> clearJournal(String canonicalProjectPath) async {
    journal = null;
  }

  @override
  Future<MapLifecycleProjectSnapshot> readProject(
    String canonicalProjectPath,
  ) async {
    return MapLifecycleProjectSnapshot(
      project: project,
      revision: projectRevision,
    );
  }

  @override
  Future<MapLifecycleProjectSnapshot> writeProject(
    String canonicalProjectPath, {
    required String operationId,
    required ProjectManifest before,
    required ProjectManifest after,
    required String expectedRevision,
  }) async {
    final injectedError = writeProjectError;
    if (injectedError != null) throw injectedError;
    if (projectRevision != expectedRevision || project != before) {
      throw const EditorConflictException('stale project');
    }
    setProject(after);
    return readProject(canonicalProjectPath);
  }

  @override
  Future<RevisionedMapDocument?> readMap(String path) async => maps[path];

  @override
  Future<RevisionedMapDocument> writeMap(
    MapData map,
    String path, {
    required MapDocumentWritePrecondition precondition,
  }) async {
    final current = maps[path];
    switch (precondition) {
      case MapDocumentMustBeAbsent():
        if (current != null) {
          throw const EditorConflictException('target exists');
        }
      case MapDocumentMustMatchRevision(:final revision):
        if (current?.revision != revision) {
          throw const EditorConflictException('stale map');
        }
    }
    final saved = RevisionedMapDocument(
      map: map,
      revision: mapDocumentRevisionFor(map),
    );
    maps[path] = saved;
    return saved;
  }

  @override
  Future<void> deleteMap(
    String path, {
    required String expectedRevision,
  }) async {
    if (maps[path]?.revision != expectedRevision) {
      throw const EditorConflictException('stale delete');
    }
    maps.remove(path);
  }
}

ProjectManifest _projectBefore() => const ProjectManifest(
      name: 'DS-05',
      maps: <ProjectMapEntry>[
        ProjectMapEntry(
          id: 'alpha',
          name: 'Alpha',
          relativePath: 'maps/alpha.json',
        ),
      ],
      tilesets: <ProjectTilesetEntry>[],
    );

MapData _map(String id) => MapData(
      id: id,
      name: id,
      size: const GridSize(width: 2, height: 2),
      layers: const <MapLayer>[],
    );

String _revision(String seed) =>
    narrativeEventBytesFingerprint(utf8.encode(seed));
