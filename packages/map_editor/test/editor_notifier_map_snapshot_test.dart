import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/core_providers.dart';
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/domain/repositories/repositories.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

void main() {
  group('EditorNotifier.loadMap', () {
    test('preserves placedElements exactly and opens a clean snapshot',
        () async {
      const placement = MapPlacedElement(
        id: 'authored-house',
        layerId: 'decor',
        elementId: 'house',
        pos: GridPos(x: 1, y: 0),
        applyCollision: false,
        opacity: 0.75,
        properties: <String, String>{
          'pokemapPlacementOrigin': 'authored',
          'designerNote': 'must survive load',
        },
      );
      const loadedMap = MapData(
        id: 'town',
        name: 'Town',
        size: GridSize(width: 2, height: 1),
        layers: <MapLayer>[
          TileLayer(
            id: 'decor',
            name: 'Decor',
            tilesetId: 'nature',
            tiles: <int>[0, 0],
          ),
        ],
        placedElements: <MapPlacedElement>[placement],
      );
      final repo = _FakeMapRepository(
        mapsByPath: <String, MapData>{
          '/project/maps/town.json': loadedMap,
        },
      );
      const workspaceFactory = _FakeWorkspaceFactory(
        workspace: _FakeWorkspace(projectRoot: '/project'),
      );
      final container = ProviderContainer(
        overrides: [
          mapRepositoryProvider.overrideWith((ref) => repo),
          projectWorkspaceFactoryProvider
              .overrideWith((ref) => workspaceFactory),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = const EditorState(
        projectRootPath: '/project',
        project: ProjectManifest(
          surfaceCatalog: ProjectSurfaceCatalog.empty(),
          name: 'demo',
          maps: <ProjectMapEntry>[
            ProjectMapEntry(
              id: 'town',
              name: 'Town',
              relativePath: 'maps/town.json',
            ),
          ],
          tilesets: <ProjectTilesetEntry>[
            ProjectTilesetEntry(
              id: 'nature',
              name: 'Nature',
              relativePath: 'tilesets/nature.png',
            ),
          ],
          elements: <ProjectElementEntry>[
            ProjectElementEntry(
              id: 'house',
              name: 'House',
              tilesetId: 'nature',
              categoryId: 'building',
              frames: <TilesetVisualFrame>[
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 0, y: 0),
                ),
              ],
            ),
          ],
        ),
      );

      await notifier.loadMap('maps/town.json');

      expect(notifier.state.activeMap, same(loadedMap));
      expect(notifier.state.activeMap!.placedElements, const [placement]);
      expect(notifier.state.savedMapSnapshot, same(loadedMap));
      expect(notifier.state.isDirty, isFalse);
      expect(notifier.state.mapUndoStack, isEmpty);
      expect(notifier.state.mapRedoStack, isEmpty);
    });
  });

  group('EditorNotifier.loadMapSnapshotById', () {
    test('returns activeMap when requested map is already active', () async {
      const active = MapData(
        id: 'vova_center',
        name: 'Vova Center',
        size: GridSize(width: 10, height: 10),
      );
      final repo = _FakeMapRepository();
      const workspaceFactory = _FakeWorkspaceFactory(
        workspace: _FakeWorkspace(projectRoot: '/project'),
      );
      final container = ProviderContainer(
        overrides: [
          mapRepositoryProvider.overrideWith((ref) => repo),
          projectWorkspaceFactoryProvider
              .overrideWith((ref) => workspaceFactory),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = const EditorState(
        projectRootPath: '/project',
        project: ProjectManifest(
          surfaceCatalog: ProjectSurfaceCatalog.empty(),
          name: 'demo',
          maps: <ProjectMapEntry>[
            ProjectMapEntry(
              id: 'vova_center',
              name: 'Vova Center',
              relativePath: 'maps/vova_center.json',
            ),
          ],
          tilesets: <ProjectTilesetEntry>[],
        ),
        activeMap: active,
      );

      final snapshot = await notifier.loadMapSnapshotById('vova_center');

      expect(snapshot, same(active));
      expect(repo.loadedPaths, isEmpty);
    });

    test('loads non-active map snapshot from repository', () async {
      final repo = _FakeMapRepository(
        mapsByPath: <String, MapData>{
          '/project/maps/route_1.json': const MapData(
            id: 'route_1',
            name: 'Route 1',
            size: GridSize(width: 20, height: 20),
          ),
        },
      );
      const workspaceFactory = _FakeWorkspaceFactory(
        workspace: _FakeWorkspace(projectRoot: '/project'),
      );
      final container = ProviderContainer(
        overrides: [
          mapRepositoryProvider.overrideWith((ref) => repo),
          projectWorkspaceFactoryProvider
              .overrideWith((ref) => workspaceFactory),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = const EditorState(
        projectRootPath: '/project',
        project: ProjectManifest(
          surfaceCatalog: ProjectSurfaceCatalog.empty(),
          name: 'demo',
          maps: <ProjectMapEntry>[
            ProjectMapEntry(
              id: 'route_1',
              name: 'Route 1',
              relativePath: 'maps/route_1.json',
            ),
          ],
          tilesets: <ProjectTilesetEntry>[],
        ),
      );

      final snapshot = await notifier.loadMapSnapshotById('route_1');

      expect(snapshot, isNotNull);
      expect(snapshot!.id, 'route_1');
      expect(repo.loadedPaths, contains('/project/maps/route_1.json'));
    });
  });
}

class _FakeWorkspaceFactory implements ProjectWorkspaceFactory {
  const _FakeWorkspaceFactory({
    required this.workspace,
  });

  final ProjectWorkspace workspace;

  @override
  ProjectWorkspace create(String projectRoot) => workspace;
}

class _FakeWorkspace implements ProjectWorkspace {
  const _FakeWorkspace({
    required this.projectRoot,
  });

  @override
  final String projectRoot;

  @override
  String get projectManifestPath => '$projectRoot/project.json';

  @override
  Future<void> deleteRelativeFile(String relativePath) async {}

  @override
  Future<void> deleteDirectoryIfEmpty(String path) async {}

  @override
  Future<bool> directoryExists(String path) async => false;

  @override
  Future<void> ensureDirectoryExists(String path) async {}

  @override
  Future<bool> fileExists(String path) async => false;

  @override
  String getMapPath(String mapId) => '$projectRoot/maps/$mapId.json';

  @override
  String getMapRelativePath(String mapId) => 'maps/$mapId.json';

  @override
  Future<String> importTilesetImage(
    String sourcePath, {
    String? preferredName,
  }) async {
    return '$projectRoot/tilesets/imported.png';
  }

  @override
  Future<void> copyFile(String sourcePath, String destinationPath) async {}

  @override
  Future<void> moveDirectory(String sourcePath, String destinationPath) async {}

  @override
  Future<void> moveFile(String sourcePath, String destinationPath) async {}

  @override
  Future<String> readTextFile(String path) async => '';

  @override
  String resolveMapPath(String relativePath) => '$projectRoot/$relativePath';

  @override
  String resolveProjectRelativePath(String relativePath) =>
      '$projectRoot/$relativePath';

  @override
  String resolveTilesetPath(String relativePath) =>
      '$projectRoot/$relativePath';

  @override
  Future<void> writeTextFile(String path, String contents) async {}
}

class _FakeMapRepository implements MapRepository {
  _FakeMapRepository({
    Map<String, MapData>? mapsByPath,
  }) : _mapsByPath = mapsByPath ?? <String, MapData>{};

  final Map<String, MapData> _mapsByPath;
  final List<String> loadedPaths = <String>[];

  @override
  Future<void> deleteMap(String path) async {}

  @override
  Future<MapData> loadMap(String path) async {
    loadedPaths.add(path);
    final map = _mapsByPath[path];
    if (map == null) {
      throw StateError('Map not found at $path');
    }
    return map;
  }

  @override
  Future<void> renameMap(String oldPath, String newPath) async {}

  @override
  Future<void> saveMap(
    MapData map,
    String path, {
    ProjectManifest? projectDialogueContext,
  }) async {}
}
