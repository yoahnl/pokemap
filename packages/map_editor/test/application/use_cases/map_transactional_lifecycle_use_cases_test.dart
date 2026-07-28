import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/services/map_dependency_preflight_service.dart';
import 'package:map_editor/src/application/services/map_lifecycle_transaction_service.dart';
import 'package:map_editor/src/application/use_cases/map_use_cases.dart';
import 'package:map_editor/src/domain/models/map_document_persistence.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:map_editor/src/infrastructure/repositories/map_lifecycle_transaction_file_gateway.dart';
import 'package:path/path.dart' as p;

void main() {
  group('transactional map lifecycle use cases', () {
    test('Create commits map and manifest through the DS-05 coordinator',
        () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      await fixture.writeProject(_project());

      final created = await CreateMapUseCase(
        fixture.maps,
        fixture.projects,
        lifecycleTransactions: fixture.coordinator,
      ).execute(
        fixture.workspace,
        _project(),
        'harbor',
        3,
        2,
      );

      final durableProject = await fixture.projects.loadProject(
        fixture.workspace.projectManifestPath,
      );
      final durableMap = await fixture.maps.loadMapDocument(
        fixture.workspace.getMapPath('harbor'),
      );
      expect(created.id, 'harbor');
      expect(durableProject.maps.single.id, 'harbor');
      expect(durableMap.map, created);
      expect(
        await File(fixture.gateway.journalPath(fixture.projectPath)).exists(),
        isFalse,
      );
    });

    test('Duplicate journals the exact source revision before writing',
        () async {
      final fixture = await _Fixture.create(
        crashAt: MapLifecycleTransactionCheckpoint.afterJournalPrepared,
      );
      addTearDown(fixture.dispose);
      final project = _project(entries: <ProjectMapEntry>[_entry('alpha')]);
      await fixture.writeProject(project);
      final source = await fixture.seedMap(_map('alpha'));

      await expectLater(
        DuplicateMapUseCase(
          fixture.maps,
          fixture.projects,
          lifecycleTransactions: fixture.coordinator,
        ).execute(fixture.workspace, project, 'alpha'),
        throwsA(isA<MapLifecycleSimulatedCrash>()),
      );

      final journal = await fixture.gateway.readJournal(fixture.projectPath);
      expect(journal, isNotNull);
      expect(journal!.operation, MapLifecycleOperation.duplicate);
      expect(journal.sourceRevision, source.revision);
      expect(journal.targetMap!.id, 'alpha_copy');
      expect(await File(fixture.workspace.getMapPath('alpha_copy')).exists(),
          isFalse);

      await MapLifecycleTransactionCoordinator(
        MapLifecycleTransactionFileGateway(
          mapRepository: FileMapRepository(),
        ),
      ).recover(fixture.projectPath);
      expect(
        (await fixture.maps.loadMap(fixture.workspace.getMapPath('alpha_copy')))
            .id,
        'alpha_copy',
      );
    });

    test('Rename commits target and manifest before deleting exact source',
        () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final project = _project(entries: <ProjectMapEntry>[_entry('alpha')]);
      await fixture.writeProject(project);
      await fixture.seedMap(_map('alpha'));

      final result = await RenameMapUseCase(
        fixture.maps,
        fixture.projects,
        MapDependencyPreflightService(mapRepository: fixture.maps),
        lifecycleTransactions: fixture.coordinator,
      ).executeRevisioned(
        fixture.workspace,
        project,
        'alpha',
        'beta',
      );

      expect(result.project.maps.single.id, 'beta');
      expect(result.map!.id, 'beta');
      expect(
        result.revision,
        mapDocumentRevisionFor(result.map!),
      );
      expect(await File(fixture.workspace.getMapPath('alpha')).exists(), false);
      expect(await File(fixture.workspace.getMapPath('beta')).exists(), true);
      expect(
        (await fixture.projects.loadProject(fixture.projectPath))
            .maps
            .single
            .id,
        'beta',
      );
    });

    test('Delete commits manifest before deleting the exact source', () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final project = _project(entries: <ProjectMapEntry>[_entry('alpha')]);
      await fixture.writeProject(project);
      await fixture.seedMap(_map('alpha'));

      final result = await DeleteMapUseCase(
        fixture.maps,
        fixture.projects,
        MapDependencyPreflightService(mapRepository: fixture.maps),
        lifecycleTransactions: fixture.coordinator,
      ).execute(fixture.workspace, project, 'alpha');

      expect(result.maps, isEmpty);
      expect(await File(fixture.workspace.getMapPath('alpha')).exists(), false);
      expect(
        (await fixture.projects.loadProject(fixture.projectPath)).maps,
        isEmpty,
      );
      expect(
        await File(fixture.gateway.journalPath(fixture.projectPath)).exists(),
        false,
      );
    });

    for (final operation in _ReadOnlyLifecycleOperation.values) {
      test(
          '${operation.name} keeps an unknown future visual stack byte-exact '
          'and creates no lifecycle evidence', () async {
        final fixture = await _Fixture.create();
        addTearDown(fixture.dispose);
        final project = _project(
          entries: <ProjectMapEntry>[_entry('alpha')],
        );
        await fixture.writeProject(project);
        await fixture.seedRawMap(_futureVisualStackMap('alpha'));
        final before = await _snapshotFiles(fixture.root);

        await expectLater(
          switch (operation) {
            _ReadOnlyLifecycleOperation.rename => RenameMapUseCase(
                fixture.maps,
                fixture.projects,
                MapDependencyPreflightService(mapRepository: fixture.maps),
                lifecycleTransactions: fixture.coordinator,
              ).executeRevisioned(
                fixture.workspace,
                project,
                'alpha',
                'beta',
              ),
            _ReadOnlyLifecycleOperation.duplicate => DuplicateMapUseCase(
                fixture.maps,
                fixture.projects,
                lifecycleTransactions: fixture.coordinator,
              ).execute(
                fixture.workspace,
                project,
                'alpha',
              ),
            _ReadOnlyLifecycleOperation.delete => DeleteMapUseCase(
                fixture.maps,
                fixture.projects,
                MapDependencyPreflightService(mapRepository: fixture.maps),
                lifecycleTransactions: fixture.coordinator,
              ).execute(
                fixture.workspace,
                project,
                'alpha',
              ),
          },
          throwsA(
            isA<EditorInvalidOperationException>()
                .having(
                  (error) => error.message,
                  'message',
                  contains('strictement en lecture seule'),
                )
                .having(
                  (error) => error.message,
                  'semantic version',
                  contains('99'),
                ),
          ),
        );

        expect(await _snapshotFiles(fixture.root), before);
        expect(
          await Directory(p.join(fixture.root.path, '.pokemap')).exists(),
          isFalse,
          reason: 'the lifecycle coordinator must not be entered',
        );
        expect(
          await File(
            fixture.gateway.journalPath(fixture.projectPath),
          ).exists(),
          isFalse,
        );
        expect(
          await File(
            fixture.gateway.journalRewritePath(fixture.projectPath),
          ).exists(),
          isFalse,
        );
        expect(
          await File(fixture.workspace.getMapPath('beta')).exists(),
          isFalse,
        );
        expect(
          await File(fixture.workspace.getMapPath('alpha_copy')).exists(),
          isFalse,
        );
      });
    }
  });
}

enum _ReadOnlyLifecycleOperation { rename, duplicate, delete }

final class _Fixture {
  _Fixture._({
    required this.root,
    required this.workspace,
    required this.maps,
    required this.gateway,
    required this.coordinator,
    required this.projects,
  });

  static Future<_Fixture> create({
    MapLifecycleTransactionCheckpoint? crashAt,
  }) async {
    final root = await Directory.systemTemp.createTemp('pokemap_ds05_uc_');
    final workspace = ProjectFileSystem(root.path);
    final maps = FileMapRepository();
    final gateway = MapLifecycleTransactionFileGateway(mapRepository: maps);
    final coordinator = MapLifecycleTransactionCoordinator(
      gateway,
      faultInjector: crashAt == null
          ? null
          : (checkpoint, _) {
              if (checkpoint == crashAt) {
                throw const MapLifecycleSimulatedCrash();
              }
            },
    );
    final projects = FileProjectRepository(
      mapLifecycleTransactions: coordinator,
    );
    return _Fixture._(
      root: root,
      workspace: workspace,
      maps: maps,
      gateway: gateway,
      coordinator: coordinator,
      projects: projects,
    );
  }

  final Directory root;
  final ProjectFileSystem workspace;
  final FileMapRepository maps;
  final MapLifecycleTransactionFileGateway gateway;
  final MapLifecycleTransactionCoordinator coordinator;
  final FileProjectRepository projects;

  String get projectPath => workspace.projectManifestPath;

  Future<void> writeProject(ProjectManifest project) async {
    await File(projectPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(project.toJson()),
      flush: true,
    );
  }

  Future<RevisionedMapDocument> seedMap(MapData map) {
    return maps.saveMapDocument(
      map,
      p.join(root.path, 'maps', '${map.id}.json'),
      precondition: const MapDocumentWritePrecondition.absent(),
    );
  }

  Future<void> seedRawMap(MapData map) async {
    final file = File(workspace.getMapPath(map.id));
    await file.parent.create(recursive: true);
    await file.writeAsBytes(encodeMapDocumentBytes(map), flush: true);
  }

  Future<void> dispose() async {
    if (await root.exists()) await root.delete(recursive: true);
  }
}

ProjectManifest _project({
  List<ProjectMapEntry> entries = const <ProjectMapEntry>[],
}) {
  return ProjectManifest(
    name: 'DS-05',
    maps: entries,
    tilesets: const <ProjectTilesetEntry>[],
  );
}

ProjectMapEntry _entry(String id) => ProjectMapEntry(
      id: id,
      name: id,
      relativePath: 'maps/$id.json',
    );

MapData _map(String id) => MapData(
      id: id,
      name: id,
      size: const GridSize(width: 2, height: 2),
      layers: const <MapLayer>[],
    );

MapData _futureVisualStackMap(String id) => _map(id).copyWith(
      version: ProjectVersion.v3,
      visualStack: MapVisualStackConfig(semanticsVersion: 99),
    );

Future<Map<String, List<int>>> _snapshotFiles(Directory root) async {
  final files = await root
      .list(recursive: true, followLinks: false)
      .where((entity) => entity is File)
      .cast<File>()
      .toList();
  files.sort((left, right) => left.path.compareTo(right.path));
  return <String, List<int>>{
    for (final file in files)
      p.relative(file.path, from: root.path): await file.readAsBytes(),
  };
}
