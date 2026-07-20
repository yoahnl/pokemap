import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/narrative_project_snapshot_loader.dart';
import 'package:map_editor/src/domain/repositories/repositories.dart';

void main() {
  test('loads inactive maps from disk and lets the dirty active map win',
      () async {
    const diskActive = MapData(
      id: 'map_active',
      name: 'Disk active',
      size: GridSize(width: 4, height: 4),
    );
    const dirtyActive = MapData(
      id: 'map_active',
      name: 'Dirty active',
      size: GridSize(width: 5, height: 5),
    );
    const inactive = MapData(
      id: 'map_inactive',
      name: 'Inactive disk map',
      size: GridSize(width: 6, height: 6),
    );
    final repository = _FakeMapRepository({
      '/project/maps/active.json': diskActive,
      '/project/maps/inactive.json': inactive,
    });
    final snapshot = await NarrativeProjectSnapshotLoader(
      mapRepository: repository,
    ).load(
      project: _project(),
      projectRootPath: '/project',
      activeMap: dirtyActive,
    );

    expect(snapshot.maps, [dirtyActive, inactive]);
    expect(snapshot.mapById('map_active')?.name, 'Dirty active');
    expect(repository.loadedPaths, ['/project/maps/inactive.json']);
  });

  test('rejects a manifest path escaping the project root', () async {
    final project = _project().copyWith(
      maps: const [
        ProjectMapEntry(
          id: 'map_active',
          name: 'Escape',
          relativePath: '../escape.json',
        ),
      ],
    );

    expect(
      () => NarrativeProjectSnapshotLoader(
        mapRepository: _FakeMapRepository(const {}),
      ).load(project: project, projectRootPath: '/project'),
      throwsArgumentError,
    );
  });
}

ProjectManifest _project() => const ProjectManifest(
      name: 'Snapshot project',
      maps: [
        ProjectMapEntry(
          id: 'map_active',
          name: 'Active',
          relativePath: 'maps/active.json',
        ),
        ProjectMapEntry(
          id: 'map_inactive',
          name: 'Inactive',
          relativePath: 'maps/inactive.json',
        ),
      ],
      tilesets: [],
    );

final class _FakeMapRepository implements MapRepository {
  _FakeMapRepository(this.mapsByPath);

  final Map<String, MapData> mapsByPath;
  final List<String> loadedPaths = <String>[];

  @override
  Future<MapData> loadMap(String path) async {
    loadedPaths.add(path);
    return mapsByPath[path] ?? (throw StateError('Missing fake map $path'));
  }

  @override
  Future<void> deleteMap(String path) => throw UnimplementedError();

  @override
  Future<void> renameMap(String oldPath, String newPath) =>
      throw UnimplementedError();

  @override
  Future<void> saveMap(
    MapData map,
    String path, {
    ProjectManifest? projectDialogueContext,
  }) =>
      throw UnimplementedError();
}
