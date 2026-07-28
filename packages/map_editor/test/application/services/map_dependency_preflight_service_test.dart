import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/application/services/map_dependency_preflight_service.dart';
import 'package:map_editor/src/domain/repositories/repositories.dart';

void main() {
  group('MapDependencyPreflightService', () {
    test('allows a complete index without incoming references', () async {
      final fixture = _Fixture(
        project: _project(),
        mapsByPath: const <String, MapData>{
          '/project/maps/source.json': _sourceMap,
          '/project/maps/target.json': _targetMap,
        },
      );

      final result = await fixture.service.inspect(
        workspace: fixture.workspace,
        project: fixture.project,
        mapId: 'target',
        operation: MapDependencyPreflightOperation.rename,
      );

      expect(result.isComplete, isTrue);
      expect(result.inspection.isMissing, isFalse);
      expect(result.inspection.isAmbiguous, isFalse);
      expect(result.inspection.usages, isEmpty);
      expect(result.isAllowed, isTrue);
      expect(
        fixture.repository.loadedPaths,
        <String>[
          '/project/maps/source.json',
          '/project/maps/target.json',
        ],
      );
    });

    test('blocks every known incoming map usage with canonical navigation',
        () async {
      const sourceWithReferences = MapData(
        id: 'source',
        name: 'Source',
        size: GridSize(width: 8, height: 8),
        warps: <MapWarp>[
          MapWarp(
            id: 'warp_to_target',
            pos: GridPos(x: 1, y: 1),
            targetMapId: 'target',
            targetPos: GridPos(x: 2, y: 2),
          ),
        ],
        connections: <MapConnection>[
          MapConnection(
            direction: MapConnectionDirection.east,
            targetMapId: 'target',
          ),
        ],
      );
      final fixture = _Fixture(
        project: _project(
          newGame: const ProjectNewGameConfig(
            enabled: true,
            startMapId: 'target',
          ),
        ),
        mapsByPath: const <String, MapData>{
          '/project/maps/source.json': sourceWithReferences,
          '/project/maps/target.json': _targetMap,
        },
      );

      final result = await fixture.service.inspect(
        workspace: fixture.workspace,
        project: fixture.project,
        mapId: 'target',
        operation: MapDependencyPreflightOperation.delete,
      );

      expect(result.isComplete, isTrue);
      expect(result.isAllowed, isFalse);
      expect(
        result.inspection.usages.map((usage) => usage.path),
        containsAll(<String>[
          'maps[source].warps[0].targetMapId',
          'maps[source].connections[0].targetMapId',
          'newGame.startMapId',
        ]),
      );
      final warpUsage = result.inspection.usages.singleWhere(
        (usage) => usage.path == 'maps[source].warps[0].targetMapId',
      );
      expect(warpUsage.navigationIntent?.mapId, 'source');
      expect(warpUsage.navigationIntent?.sourceKind, 'warp');
      expect(warpUsage.navigationIntent?.assetId, 'warp_to_target');
      expect(result.blockingMessage, contains('3 usages'));
      expect(result.blockingMessage, contains('Aucune écriture'));
    });

    test('blocks a self-reference instead of treating it as ownership',
        () async {
      const targetWithSelfWarp = MapData(
        id: 'target',
        name: 'Target',
        size: GridSize(width: 8, height: 8),
        warps: <MapWarp>[
          MapWarp(
            id: 'loop',
            pos: GridPos(x: 1, y: 1),
            targetMapId: 'target',
            targetPos: GridPos(x: 4, y: 4),
          ),
        ],
      );
      final fixture = _Fixture(
        project: _project(),
        mapsByPath: const <String, MapData>{
          '/project/maps/source.json': _sourceMap,
          '/project/maps/target.json': targetWithSelfWarp,
        },
      );

      final result = await fixture.service.inspect(
        workspace: fixture.workspace,
        project: fixture.project,
        mapId: 'target',
        operation: MapDependencyPreflightOperation.rename,
      );

      expect(result.isComplete, isTrue);
      expect(result.isAllowed, isFalse);
      expect(
        result.inspection.usages.single.path,
        'maps[target].warps[0].targetMapId',
      );
    });

    test('fails closed and keeps known usages when one map cannot be loaded',
        () async {
      final fixture = _Fixture(
        project: _project(
          newGame: const ProjectNewGameConfig(
            enabled: true,
            startMapId: 'target',
          ),
          extraMaps: const <ProjectMapEntry>[
            ProjectMapEntry(
              id: 'unreadable',
              name: 'Unreadable',
              relativePath: 'maps/unreadable.json',
            ),
          ],
        ),
        mapsByPath: const <String, MapData>{
          '/project/maps/source.json': _sourceMap,
          '/project/maps/target.json': _targetMap,
        },
      );

      final result = await fixture.service.inspect(
        workspace: fixture.workspace,
        project: fixture.project,
        mapId: 'target',
        operation: MapDependencyPreflightOperation.delete,
      );

      expect(result.isComplete, isFalse);
      expect(result.isAllowed, isFalse);
      expect(result.indexIssues, hasLength(1));
      expect(result.indexIssues.single.mapId, 'unreadable');
      expect(result.indexIssues.single.relativePath, 'maps/unreadable.json');
      expect(result.inspection.usages.map((usage) => usage.path),
          contains('newGame.startMapId'));
      expect(result.blockingMessage, contains('index incomplet'));
      expect(result.blockingMessage, contains('Aucune écriture'));
    });

    test('fails closed when a loaded document identity mismatches its entry',
        () async {
      final fixture = _Fixture(
        project: _project(),
        mapsByPath: const <String, MapData>{
          '/project/maps/source.json': _sourceMap,
          '/project/maps/target.json': MapData(
            id: 'wrong',
            name: 'Wrong identity',
            size: GridSize(width: 8, height: 8),
          ),
        },
      );

      final result = await fixture.service.inspect(
        workspace: fixture.workspace,
        project: fixture.project,
        mapId: 'target',
        operation: MapDependencyPreflightOperation.rename,
      );

      expect(result.isComplete, isFalse);
      expect(result.isAllowed, isFalse);
      expect(result.indexIssues.single.mapId, 'target');
      expect(result.indexIssues.single.message, contains('wrong'));
    });

    test('fails closed when any manifest map id is duplicated', () async {
      final fixture = _Fixture(
        project: _project(
          extraMaps: const <ProjectMapEntry>[
            ProjectMapEntry(
              id: 'source',
              name: 'Duplicate source',
              relativePath: 'maps/duplicate-source.json',
            ),
          ],
        ),
        mapsByPath: const <String, MapData>{
          '/project/maps/source.json': _sourceMap,
          '/project/maps/target.json': _targetMap,
        },
      );

      final result = await fixture.service.inspect(
        workspace: fixture.workspace,
        project: fixture.project,
        mapId: 'target',
        operation: MapDependencyPreflightOperation.delete,
      );

      expect(result.isComplete, isFalse);
      expect(result.isAllowed, isFalse);
      expect(
        result.indexIssues,
        contains(
          isA<MapDependencyIndexIssue>()
              .having(
                (issue) => issue.kind,
                'kind',
                MapDependencyIndexIssueKind.duplicateManifestId,
              )
              .having((issue) => issue.mapId, 'map id', 'source'),
        ),
      );
      expect(
        fixture.repository.loadedPaths,
        isNot(contains('/project/maps/duplicate-source.json')),
      );
    });

    test('fails closed when the requested target is absent', () async {
      final fixture = _Fixture(
        project: _project(),
        mapsByPath: const <String, MapData>{
          '/project/maps/source.json': _sourceMap,
          '/project/maps/target.json': _targetMap,
        },
      );

      final result = await fixture.service.inspect(
        workspace: fixture.workspace,
        project: fixture.project,
        mapId: 'missing',
        operation: MapDependencyPreflightOperation.rename,
      );

      expect(result.isComplete, isFalse);
      expect(result.isAllowed, isFalse);
      expect(result.inspection.isMissing, isTrue);
      expect(
        result.indexIssues,
        contains(
          isA<MapDependencyIndexIssue>().having(
            (issue) => issue.kind,
            'kind',
            MapDependencyIndexIssueKind.missingTargetDefinition,
          ),
        ),
      );
    });

    test('requireAllowed exposes the structured blocked result', () async {
      final fixture = _Fixture(
        project: _project(
          newGame: const ProjectNewGameConfig(
            enabled: true,
            startMapId: 'target',
          ),
        ),
        mapsByPath: const <String, MapData>{
          '/project/maps/source.json': _sourceMap,
          '/project/maps/target.json': _targetMap,
        },
      );

      await expectLater(
        fixture.service.requireAllowed(
          workspace: fixture.workspace,
          project: fixture.project,
          mapId: 'target',
          operation: MapDependencyPreflightOperation.delete,
        ),
        throwsA(
          isA<MapDependencyPreflightBlockedException>()
              .having(
                (error) => error.result.mapId,
                'map id',
                'target',
              )
              .having(
                (error) => error.result.isComplete,
                'complete index',
                isTrue,
              ),
        ),
      );
      expect(fixture.repository.saveCalls, isZero);
      expect(fixture.repository.deleteCalls, isZero);
    });
  });
}

const _sourceMap = MapData(
  id: 'source',
  name: 'Source',
  size: GridSize(width: 8, height: 8),
);

const _targetMap = MapData(
  id: 'target',
  name: 'Target',
  size: GridSize(width: 8, height: 8),
);

ProjectManifest _project({
  ProjectNewGameConfig newGame = const ProjectNewGameConfig(),
  List<ProjectMapEntry> extraMaps = const <ProjectMapEntry>[],
}) {
  return ProjectManifest(
    name: 'DS-04',
    maps: <ProjectMapEntry>[
      const ProjectMapEntry(
        id: 'source',
        name: 'Source',
        relativePath: 'maps/source.json',
      ),
      const ProjectMapEntry(
        id: 'target',
        name: 'Target',
        relativePath: 'maps/target.json',
      ),
      ...extraMaps,
    ],
    tilesets: const <ProjectTilesetEntry>[],
    newGame: newGame,
  );
}

final class _Fixture {
  _Fixture({
    required this.project,
    required Map<String, MapData> mapsByPath,
  }) : repository = _MapRepository(mapsByPath);

  final ProjectManifest project;
  final _Workspace workspace = const _Workspace();
  final _MapRepository repository;

  MapDependencyPreflightService get service =>
      MapDependencyPreflightService(mapRepository: repository);
}

final class _MapRepository implements MapRepository {
  _MapRepository(this.mapsByPath);

  final Map<String, MapData> mapsByPath;
  final List<String> loadedPaths = <String>[];
  int saveCalls = 0;
  int deleteCalls = 0;

  @override
  Future<MapData> loadMap(String path) async {
    loadedPaths.add(path);
    return mapsByPath[path] ?? (throw StateError('Unreadable map at $path'));
  }

  @override
  Future<void> saveMap(
    MapData map,
    String path, {
    ProjectManifest? projectDialogueContext,
  }) async {
    saveCalls += 1;
  }

  @override
  Future<void> deleteMap(String path) async {
    deleteCalls += 1;
  }

  @override
  Future<void> renameMap(String oldPath, String newPath) async {
    throw UnimplementedError();
  }
}

final class _Workspace implements ProjectWorkspace {
  const _Workspace();

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
  Future<void> copyFile(String sourcePath, String destinationPath) =>
      throw UnimplementedError();

  @override
  Future<void> deleteDirectoryIfEmpty(String path) =>
      throw UnimplementedError();

  @override
  Future<void> deleteRelativeFile(String relativePath) =>
      throw UnimplementedError();

  @override
  Future<bool> directoryExists(String path) async => true;

  @override
  Future<void> ensureDirectoryExists(String path) async {}

  @override
  Future<bool> fileExists(String path) async => false;

  @override
  Future<String> importTilesetImage(
    String sourcePath, {
    String? preferredName,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> moveDirectory(String sourcePath, String destinationPath) =>
      throw UnimplementedError();

  @override
  Future<void> moveFile(String sourcePath, String destinationPath) =>
      throw UnimplementedError();

  @override
  Future<String> readTextFile(String path) => throw UnimplementedError();

  @override
  Future<void> writeTextFile(String path, String contents) =>
      throw UnimplementedError();
}
