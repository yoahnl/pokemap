import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/application/use_cases/project_element_use_cases.dart';
import 'package:map_editor/src/domain/repositories/repositories.dart';

void main() {
  group('UpdateProjectElementUseCase shadow updates', () {
    test('persists element shadow without changing collisionProfile', () async {
      final repo = _FakeProjectRepository();
      final workspace = _FakeWorkspace();
      final useCase = UpdateProjectElementUseCase(repo);
      final collisionProfile = _collisionProfile();
      final initial = _project(
        _element(collisionProfile: collisionProfile),
      );
      final shadow = ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: 'tree_large',
        offsetX: 4,
        scaleY: 0.5,
        opacity: 0.35,
      );

      final updated = await useCase.execute(
        workspace,
        initial,
        elementId: 'tree_element',
        shadow: shadow,
      );

      final element = updated.elements.single;
      expect(element.shadow, shadow);
      expect(element.collisionProfile, collisionProfile);
      expect(repo.lastSavedProject!.elements.single.shadow, shadow);
      expect(
        repo.lastSavedProject!.elements.single.collisionProfile,
        collisionProfile,
      );
    });

    test('clearShadow resets shadow to null', () async {
      final repo = _FakeProjectRepository();
      final workspace = _FakeWorkspace();
      final useCase = UpdateProjectElementUseCase(repo);
      final initial = _project(
        _element(
          shadow: ProjectElementShadowConfig(
            castsShadow: true,
            shadowProfileId: 'tree_large',
          ),
        ),
      );

      final updated = await useCase.execute(
        workspace,
        initial,
        elementId: 'tree_element',
        clearShadow: true,
      );

      expect(updated.elements.single.shadow, isNull);
      expect(repo.lastSavedProject!.elements.single.shadow, isNull);
    });

    test('rejects setting and clearing shadow in the same update', () async {
      final repo = _FakeProjectRepository();
      final workspace = _FakeWorkspace();
      final useCase = UpdateProjectElementUseCase(repo);

      expect(
        () => useCase.execute(
          workspace,
          _project(_element()),
          elementId: 'tree_element',
          shadow: ProjectElementShadowConfig(
            castsShadow: true,
            shadowProfileId: 'tree_large',
          ),
          clearShadow: true,
        ),
        throwsA(isA<EditorValidationException>()),
      );
    });
  });
}

ProjectManifest _project(ProjectElementEntry element) {
  return ProjectManifest(
    name: 'Shadow use case test',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[
      ProjectTilesetEntry(
        id: 'tileset_main',
        name: 'Main tileset',
        relativePath: 'tilesets/main.png',
      ),
    ],
    elementCategories: const <ProjectElementCategory>[
      ProjectElementCategory(id: 'decor', name: 'Decor'),
    ],
    elements: <ProjectElementEntry>[element],
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
}

ProjectElementEntry _element({
  ElementCollisionProfile? collisionProfile,
  ProjectElementShadowConfig? shadow,
}) {
  return ProjectElementEntry(
    id: 'tree_element',
    name: 'Tree element',
    tilesetId: 'tileset_main',
    categoryId: 'decor',
    frames: const <TilesetVisualFrame>[
      TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
    ],
    collisionProfile: collisionProfile,
    shadow: shadow,
  );
}

ElementCollisionProfile _collisionProfile() {
  return const ElementCollisionProfile(
    source: ElementCollisionProfileSource.manual,
    cells: <GridPos>[
      GridPos(x: 0, y: 0),
      GridPos(x: 1, y: 0),
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
  Future<void> deleteDirectoryIfEmpty(String path) async {}

  @override
  Future<bool> directoryExists(String path) async => false;

  @override
  Future<void> ensureDirectoryExists(String path) async {}

  @override
  Future<bool> fileExists(String path) async => false;

  @override
  String resolveMapPath(String relativePath) => '/tmp/$relativePath';

  @override
  String getMapPath(String mapId) => '/tmp/maps/$mapId.json';

  @override
  String getMapRelativePath(String mapId) => 'maps/$mapId.json';

  @override
  String resolveTilesetPath(String relativePath) => '/tmp/$relativePath';

  @override
  String resolveProjectRelativePath(String relativePath) =>
      '/tmp/$relativePath';

  @override
  Future<String> readTextFile(String path) async => '';

  @override
  Future<void> writeTextFile(String path, String contents) async {}

  @override
  Future<String> importTilesetImage(
    String sourcePath, {
    String? preferredName,
  }) async {
    return '/tmp/tilesets/image.png';
  }

  @override
  Future<void> copyFile(String sourcePath, String destinationPath) async {}

  @override
  Future<void> moveFile(String sourcePath, String destinationPath) async {}

  @override
  Future<void> moveDirectory(String sourcePath, String destinationPath) async {}
}
