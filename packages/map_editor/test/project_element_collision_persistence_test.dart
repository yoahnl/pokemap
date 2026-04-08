import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/application/use_cases/project_element_use_cases.dart';
import 'package:map_editor/src/domain/repositories/repositories.dart';

void main() {
  group('Project element collision persistence', () {
    test('create use case persists final cells and padding through json',
        () async {
      final repo = _FakeProjectRepository();
      final workspace = _FakeWorkspace();
      final useCase = CreateProjectElementUseCase(repo);
      final source = const TilesetSourceRect(x: 0, y: 0, width: 3, height: 2);
      final profile = ElementCollisionProfile(
        source: ElementCollisionProfileSource.manual,
        padding: const WarpTriggerPadding(left: 4, bottom: 2),
        cells: const <GridPos>[
          GridPos(x: 0, y: 0),
          GridPos(x: 1, y: 0),
          GridPos(x: 1, y: 1),
        ],
        manualAddedCells: const <GridPos>[GridPos(x: 1, y: 1)],
        manualRemovedCells: const <GridPos>[GridPos(x: 2, y: 1)],
      );

      await useCase.execute(
        workspace,
        _projectManifest(),
        name: 'Maison',
        tilesetId: 'tileset_main',
        categoryId: 'buildings',
        source: source,
        collisionProfile: profile,
      );

      final saved = repo.lastSavedProject!;
      final json = saved.toJson();
      final reloaded = ProjectManifest.fromJson(json);
      final reloadedProfile = reloaded.elements.single.collisionProfile!;

      expect(reloadedProfile.padding, profile.padding);
      expect(reloadedProfile.cells, profile.cells);
      expect(reloadedProfile.manualAddedCells, profile.manualAddedCells);
      expect(reloadedProfile.manualRemovedCells, profile.manualRemovedCells);
    });

    test('update use case keeps edited final cells after roundtrip', () async {
      final repo = _FakeProjectRepository();
      final workspace = _FakeWorkspace();
      final useCase = UpdateProjectElementUseCase(repo);
      final initial = _projectManifest().copyWith(
        elements: [
          ProjectElementEntry(
            id: 'house',
            name: 'House',
            tilesetId: 'tileset_main',
            categoryId: 'buildings',
            frames: const [
              TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
            ],
          ),
        ],
      );
      final editedProfile = ElementCollisionProfile(
        source: ElementCollisionProfileSource.manual,
        padding: const WarpTriggerPadding(top: 3, right: 5),
        cells: const <GridPos>[
          GridPos(x: 0, y: 0),
          GridPos(x: 0, y: 1),
          GridPos(x: 1, y: 1),
        ],
        manualAddedCells: const <GridPos>[GridPos(x: 1, y: 1)],
        manualRemovedCells: const <GridPos>[GridPos(x: 2, y: 0)],
      );

      final updated = await useCase.execute(
        workspace,
        initial,
        elementId: 'house',
        collisionProfile: editedProfile,
      );

      final json = updated.toJson();
      final reloaded = ProjectManifest.fromJson(json);
      final reloadedProfile = reloaded.elements.single.collisionProfile!;

      expect(reloadedProfile.padding, editedProfile.padding);
      expect(reloadedProfile.cells, editedProfile.cells);
      expect(reloadedProfile.manualAddedCells, editedProfile.manualAddedCells);
      expect(
          reloadedProfile.manualRemovedCells, editedProfile.manualRemovedCells);
    });
  });
}

ProjectManifest _projectManifest() {
  return const ProjectManifest(
    name: 'Test',
    maps: [],
    tilesets: [
      ProjectTilesetEntry(
        id: 'tileset_main',
        name: 'Main',
        relativePath: 'tilesets/main.png',
      ),
    ],
    elementCategories: [
      ProjectElementCategory(
        id: 'buildings',
        name: 'Buildings',
      ),
    ],
  );
}

class _FakeProjectRepository implements ProjectRepository {
  ProjectManifest? lastSavedProject;

  @override
  Future<ProjectManifest> loadProject(String path) {
    throw UnimplementedError();
  }

  @override
  Future<void> saveProject(ProjectManifest project, String path) async {
    // Simulate the persistence contract used by the real repository:
    // the manifest is serialized, then later reloaded from JSON.
    lastSavedProject = ProjectManifest.fromJson(project.toJson());
  }
}

class _FakeWorkspace implements ProjectWorkspace {
  @override
  String get projectManifestPath => '/tmp/project.json';

  @override
  String get projectRoot => '/tmp';

  @override
  Future<void> deleteRelativeFile(String relativePath) async {}

  @override
  Future<void> ensureDirectoryExists(String path) async {}

  @override
  String getMapPath(String mapId) => '/tmp/maps/$mapId.json';

  @override
  String getMapRelativePath(String mapId) => 'maps/$mapId.json';

  @override
  Future<String> importTilesetImage(
    String sourcePath, {
    String? preferredName,
  }) async {
    return '/tmp/tilesets/image.png';
  }

  @override
  String resolveMapPath(String relativePath) => '/tmp/$relativePath';

  @override
  String resolveProjectRelativePath(String relativePath) =>
      '/tmp/$relativePath';

  @override
  String resolveTilesetPath(String relativePath) => '/tmp/$relativePath';
}
