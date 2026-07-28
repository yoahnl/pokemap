import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/application/services/map_dependency_preflight_service.dart';
import 'package:map_editor/src/application/use_cases/map_use_cases.dart';
import 'package:map_editor/src/application/use_cases/warp_use_cases.dart';
import 'package:map_editor/src/domain/models/map_document_persistence.dart';
import 'package:map_editor/src/domain/repositories/repositories.dart';

void main() {
  group('revisioned map lifecycle', () {
    test('Create uses expected absence instead of a legacy overwrite',
        () async {
      final fixture = _Fixture();

      await CreateMapUseCase(fixture.maps, fixture.projects).execute(
        fixture.workspace,
        fixture.project(),
        'alpha',
        2,
        2,
      );

      expect(fixture.maps.legacySaves, isEmpty);
      expect(fixture.maps.revisionedSaves, hasLength(1));
      expect(
        fixture.maps.revisionedSaves.single.precondition,
        isA<MapDocumentMustBeAbsent>(),
      );
      expect(
          fixture.maps.revisionedSaves.single.path, '/project/maps/alpha.json');
    });

    test('Duplicate uses expected absence for its target', () async {
      final fixture = _Fixture();
      fixture.maps.seed('/project/maps/alpha.json', _map('alpha'));

      await DuplicateMapUseCase(fixture.maps, fixture.projects).execute(
        fixture.workspace,
        fixture.project(entries: const <ProjectMapEntry>[
          ProjectMapEntry(
            id: 'alpha',
            name: 'Alpha',
            relativePath: 'maps/alpha.json',
          ),
        ]),
        'alpha',
      );

      expect(fixture.maps.legacySaves, isEmpty);
      expect(fixture.maps.revisionedLoads, <String>[
        '/project/maps/alpha.json',
      ]);
      expect(fixture.maps.revisionedSaves, hasLength(1));
      expect(
        fixture.maps.revisionedSaves.single.precondition,
        isA<MapDocumentMustBeAbsent>(),
      );
      expect(
        fixture.maps.revisionedSaves.single.path,
        '/project/maps/alpha_copy.json',
      );
    });

    test('Rename revision-checks its source deletion', () async {
      final fixture = _Fixture();
      final sourceRevision =
          fixture.maps.seed('/project/maps/alpha.json', _map('alpha'));

      await RenameMapUseCase(
        fixture.maps,
        fixture.projects,
        MapDependencyPreflightService(mapRepository: fixture.maps),
      ).execute(
        fixture.workspace,
        fixture.project(entries: const <ProjectMapEntry>[
          ProjectMapEntry(
            id: 'alpha',
            name: 'Alpha',
            relativePath: 'maps/alpha.json',
          ),
        ]),
        'alpha',
        'beta',
      );

      expect(fixture.maps.legacyLoads, isEmpty);
      expect(fixture.maps.legacySaves, isEmpty);
      expect(fixture.maps.legacyDeletes, isEmpty);
      expect(
        fixture.maps.revisionedSaves.single.precondition,
        isA<MapDocumentMustBeAbsent>(),
      );
      expect(
        fixture.maps.revisionedDeletes.single,
        (path: '/project/maps/alpha.json', revision: sourceRevision),
      );
    });

    test('Delete refuses to use an unversioned source delete', () async {
      final fixture = _Fixture();
      final sourceRevision =
          fixture.maps.seed('/project/maps/alpha.json', _map('alpha'));

      await DeleteMapUseCase(
        fixture.maps,
        fixture.projects,
        MapDependencyPreflightService(mapRepository: fixture.maps),
      ).execute(
        fixture.workspace,
        fixture.project(entries: const <ProjectMapEntry>[
          ProjectMapEntry(
            id: 'alpha',
            name: 'Alpha',
            relativePath: 'maps/alpha.json',
          ),
        ]),
        'alpha',
      );

      expect(fixture.maps.legacyLoads, isEmpty);
      expect(fixture.maps.legacyDeletes, isEmpty);
      expect(
        fixture.maps.revisionedDeletes.single,
        (path: '/project/maps/alpha.json', revision: sourceRevision),
      );
    });

    test('reciprocal warp saves the exact loaded target revision', () async {
      final fixture = _Fixture();
      final targetRevision =
          fixture.maps.seed('/project/maps/beta.json', _map('beta'));
      final source = _map('alpha').copyWith(
        warps: const <MapWarp>[
          MapWarp(
            id: 'to_beta',
            pos: GridPos(x: 0, y: 0),
            targetMapId: 'beta',
            targetPos: GridPos(x: 1, y: 1),
          ),
        ],
      );

      await CreateReciprocalWarpUseCase(fixture.maps).execute(
        fixture.workspace,
        fixture.project(entries: const <ProjectMapEntry>[
          ProjectMapEntry(
            id: 'alpha',
            name: 'Alpha',
            relativePath: 'maps/alpha.json',
          ),
          ProjectMapEntry(
            id: 'beta',
            name: 'Beta',
            relativePath: 'maps/beta.json',
          ),
        ]),
        sourceMap: source,
        sourceWarp: source.warps.single,
      );

      expect(fixture.maps.legacyLoads, isEmpty);
      expect(fixture.maps.legacySaves, isEmpty);
      expect(fixture.maps.revisionedSaves, hasLength(1));
      final precondition = fixture.maps.revisionedSaves.single.precondition;
      expect(precondition, isA<MapDocumentMustMatchRevision>());
      expect(
        (precondition as MapDocumentMustMatchRevision).revision,
        targetRevision,
      );
    });
  });
}

final class _Fixture {
  final _Workspace workspace = _Workspace();
  final _RevisionedRecordingMapRepository maps =
      _RevisionedRecordingMapRepository();
  final _RecordingProjectRepository projects = _RecordingProjectRepository();

  ProjectManifest project({
    List<ProjectMapEntry> entries = const <ProjectMapEntry>[],
  }) {
    return ProjectManifest(
      name: 'DS-03',
      maps: entries,
      tilesets: const <ProjectTilesetEntry>[],
    );
  }
}

final class _RevisionedRecordingMapRepository
    implements RevisionedMapRepository {
  final Map<String, RevisionedMapDocument> documents =
      <String, RevisionedMapDocument>{};
  final List<String> legacyLoads = <String>[];
  final List<({MapData map, String path})> legacySaves =
      <({MapData map, String path})>[];
  final List<String> legacyDeletes = <String>[];
  final List<String> revisionedLoads = <String>[];
  final List<
      ({
        MapData map,
        String path,
        MapDocumentWritePrecondition precondition,
      })> revisionedSaves = [];
  final List<({String path, String revision})> revisionedDeletes = [];

  String seed(String path, MapData map) {
    final revision = _revision('$path:${map.id}:${map.name}');
    documents[path] = RevisionedMapDocument(map: map, revision: revision);
    return revision;
  }

  @override
  Future<MapData> loadMap(String path) async {
    legacyLoads.add(path);
    return documents[path]!.map;
  }

  @override
  Future<RevisionedMapDocument> loadMapDocument(String path) async {
    revisionedLoads.add(path);
    return documents[path]!;
  }

  @override
  Future<void> saveMap(
    MapData map,
    String path, {
    ProjectManifest? projectDialogueContext,
  }) async {
    legacySaves.add((map: map, path: path));
  }

  @override
  Future<RevisionedMapDocument> saveMapDocument(
    MapData map,
    String path, {
    required MapDocumentWritePrecondition precondition,
    ProjectManifest? projectDialogueContext,
  }) async {
    revisionedSaves.add(
      (map: map, path: path, precondition: precondition),
    );
    final saved = RevisionedMapDocument(
      map: map,
      revision: _revision('$path:${map.id}:${map.name}:saved'),
    );
    documents[path] = saved;
    return saved;
  }

  @override
  Future<void> deleteMap(String path) async {
    legacyDeletes.add(path);
    documents.remove(path);
  }

  @override
  Future<void> deleteMapDocument(
    String path, {
    required String expectedRevision,
  }) async {
    revisionedDeletes.add((path: path, revision: expectedRevision));
    documents.remove(path);
  }

  @override
  Future<MapDocumentRecoveryResult> recoverMapDocument(String path) async {
    return MapDocumentRecoveryResult(
      status: MapDocumentRecoveryStatus.clear,
      targetPath: path,
      revision: documents[path]?.revision,
    );
  }

  @override
  Future<void> renameMap(String oldPath, String newPath) async {}
}

final class _RecordingProjectRepository implements ProjectRepository {
  final List<ProjectManifest> saves = <ProjectManifest>[];

  @override
  Future<ProjectManifest> loadProject(String path) async =>
      throw UnimplementedError();

  @override
  Future<void> saveProject(ProjectManifest project, String path) async {
    saves.add(project);
  }
}

final class _Workspace implements ProjectWorkspace {
  @override
  String get projectRoot => '/project';

  @override
  String get projectManifestPath => '/project/project.json';

  @override
  String resolveMapPath(String relativePath) => '/project/$relativePath';

  @override
  String getMapPath(String mapId) => '/project/maps/$mapId.json';

  @override
  String getMapRelativePath(String mapId) => 'maps/$mapId.json';

  @override
  String resolveProjectRelativePath(String relativePath) =>
      '/project/$relativePath';

  @override
  String resolveTilesetPath(String relativePath) => '/project/$relativePath';

  @override
  Future<void> ensureDirectoryExists(String path) async {}

  @override
  Future<bool> fileExists(String path) async => false;

  @override
  Future<bool> directoryExists(String path) async => false;

  @override
  Future<String> readTextFile(String path) async => '';

  @override
  Future<void> writeTextFile(String path, String contents) async {}

  @override
  Future<void> copyFile(String sourcePath, String destinationPath) async {}

  @override
  Future<void> moveFile(String sourcePath, String destinationPath) async {}

  @override
  Future<void> moveDirectory(String sourcePath, String destinationPath) async {}

  @override
  Future<void> deleteDirectoryIfEmpty(String path) async {}

  @override
  Future<String> importTilesetImage(
    String sourcePath, {
    String? preferredName,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> deleteRelativeFile(String relativePath) async {}
}

MapData _map(String id) => MapData(
      id: id,
      name: id,
      size: const GridSize(width: 2, height: 2),
      layers: const <MapLayer>[],
    );

String _revision(String seed) => narrativeEventBytesFingerprint(
      utf8.encode(seed),
    );
