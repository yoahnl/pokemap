import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart' hide ElementAutoShadowBackfillStatus;
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/application/shadow/element_auto_shadow_backfill.dart';
import 'package:map_editor/src/application/use_cases/apply_element_auto_shadow_suggestions_use_case.dart';
import 'package:map_editor/src/domain/repositories/repositories.dart';

void main() {
  group('ApplyElementAutoShadowSuggestionsUseCase', () {
    test('saves when at least one element changes', () async {
      final repo = _FakeProjectRepository();
      final workspace = _FakeWorkspace();
      final useCase = ApplyElementAutoShadowSuggestionsUseCase(repo);
      final project = _project(
        elements: [
          _element(id: 'lamp', name: 'Lamp', width: 1, height: 4),
        ],
        shadowCatalog: _defaultCatalog(),
      );

      final result = await useCase.execute(workspace, project);

      expect(result.hasChanges, isTrue);
      expect(result.appliedCount, 1);
      expect(repo.savedPath, '/tmp/project.json');
      expect(repo.lastSavedProject, result.project);
      expect(repo.lastSavedProject!.elements.single.shadow, isNotNull);
    });

    test('does not save when no element is eligible', () async {
      final repo = _FakeProjectRepository();
      final workspace = _FakeWorkspace();
      final useCase = ApplyElementAutoShadowSuggestionsUseCase(repo);
      final project = _project(
        elements: [
          _element(
            id: 'manual',
            name: 'Manual',
            width: 2,
            height: 2,
            shadow: ProjectElementShadowConfig(
              castsShadow: true,
              shadowProfileId: 'custom-ground-shadow',
            ),
          ),
        ],
        shadowCatalog: ProjectShadowCatalog(
          profiles: [
            ...createDefaultGroundStaticShadowProfiles(),
            ProjectShadowProfile(
              id: 'custom-ground-shadow',
              name: 'Custom ground shadow',
              mode: ShadowCasterMode.ellipse,
              renderPass: ShadowRenderPass.groundStatic,
            ),
          ],
        ),
      );

      final result = await useCase.execute(workspace, project);

      expect(result.hasChanges, isFalse);
      expect(result.appliedCount, 0);
      expect(
        result.entries.single.status,
        ElementAutoShadowBackfillStatus.skippedManual,
      );
      expect(repo.lastSavedProject, isNull);
      expect(repo.savedPath, isNull);
    });

    test('saves when cleanup removes recognized auto shadow', () async {
      final repo = _FakeProjectRepository();
      final workspace = _FakeWorkspace();
      final useCase = ApplyElementAutoShadowSuggestionsUseCase(repo);
      final project = _project(
        elements: [
          _element(
            id: 'small-square',
            name: 'Small square',
            width: 2,
            height: 2,
            shadow: _oldAutoSmallSquareShadow(),
          ),
        ],
        shadowCatalog: _defaultCatalog(),
      );

      final result = await useCase.execute(workspace, project);

      expect(result.hasChanges, isTrue);
      expect(result.appliedCount, 0);
      expect(result.changedCount, 1);
      expect(repo.savedPath, '/tmp/project.json');
      expect(repo.lastSavedProject, result.project);
      expect(repo.lastSavedProject!.elements.single.shadow, isNull);
      expect(
        result.entries.single.status,
        ElementAutoShadowBackfillStatus.clearedAutoNoSuggestion,
      );
    });

    test('returns counts and saves projects that round trip through JSON',
        () async {
      final repo = _FakeProjectRepository();
      final workspace = _FakeWorkspace();
      final useCase = ApplyElementAutoShadowSuggestionsUseCase(repo);
      final project = _project(
        elements: [
          _element(id: 'lamp', name: 'Lamp', width: 1, height: 4),
          _element(
            id: 'disabled',
            name: 'Disabled',
            width: 4,
            height: 3,
            shadow: ProjectElementShadowConfig(castsShadow: false),
          ),
        ],
        shadowCatalog: const ProjectShadowCatalog.empty(),
      );

      final result = await useCase.execute(workspace, project);

      expect(result.addedDefaultProfiles, isTrue);
      expect(result.appliedCount, 1);
      expect(result.skippedCount, 1);
      expect(result.entries.map((entry) => entry.status), [
        ElementAutoShadowBackfillStatus.appliedMissing,
        ElementAutoShadowBackfillStatus.skippedDisabled,
      ]);
      expect(
        ProjectManifest.fromJson(repo.lastSavedProject!.toJson()),
        repo.lastSavedProject,
      );
    });
  });
}

ProjectManifest _project({
  required List<ProjectElementEntry> elements,
  required ProjectShadowCatalog shadowCatalog,
}) {
  return ProjectManifest(
    name: 'Apply auto shadows test',
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
    elements: elements,
    shadowCatalog: shadowCatalog,
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
  );
}

ProjectShadowCatalog _defaultCatalog() {
  return ProjectShadowCatalog(
    profiles: createDefaultGroundStaticShadowProfiles(),
  );
}

ProjectElementShadowConfig _oldAutoSmallSquareShadow() {
  return ProjectElementShadowConfig(
    castsShadow: true,
    shadowProfileId: 'default-ground-contact-blob',
    offsetX: 0,
    offsetY: 0,
    scaleX: 0.78,
    scaleY: 0.70,
    opacity: 0.26,
    family: StaticShadowFamily.compactProp,
    footprint: StaticShadowFootprintConfig(
      anchorXRatio: 0.5,
      anchorYRatio: 0.96,
      footprintWidthRatio: 0.46,
      footprintHeightRatio: 0.10,
    ),
  );
}

ProjectElementEntry _element({
  required String id,
  required String name,
  required int width,
  required int height,
  ProjectElementShadowConfig? shadow,
}) {
  return ProjectElementEntry(
    id: id,
    name: name,
    tilesetId: 'tileset_main',
    categoryId: 'decor',
    frames: [
      TilesetVisualFrame(
        source: TilesetSourceRect(x: 0, y: 0, width: width, height: height),
      ),
    ],
    shadow: shadow,
  );
}

final class _FakeProjectRepository implements ProjectRepository {
  ProjectManifest? lastSavedProject;
  String? savedPath;

  @override
  Future<ProjectManifest> loadProject(String path) {
    throw UnimplementedError();
  }

  @override
  Future<void> saveProject(ProjectManifest project, String path) async {
    savedPath = path;
    lastSavedProject = ProjectManifest.fromJson(project.toJson());
  }
}

final class _FakeWorkspace implements ProjectWorkspace {
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
  Future<String> importTilesetImage(
    String sourcePath, {
    String? preferredName,
  }) async {
    return '/tmp/tilesets/image.png';
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
  String resolveMapPath(String relativePath) => '/tmp/$relativePath';

  @override
  String getMapPath(String mapId) => '/tmp/maps/$mapId.json';

  @override
  String getMapRelativePath(String mapId) => 'maps/$mapId.json';

  @override
  String resolveProjectRelativePath(String relativePath) =>
      '/tmp/$relativePath';

  @override
  String resolveTilesetPath(String relativePath) => '/tmp/$relativePath';

  @override
  Future<void> writeTextFile(String path, String contents) async {}
}
