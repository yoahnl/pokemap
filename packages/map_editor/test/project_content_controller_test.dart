import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/application/use_cases/project_dialogue_library_use_cases.dart';
import 'package:map_editor/src/application/use_cases/project_dialogue_use_cases.dart';
import 'package:map_editor/src/application/use_cases/project_scenario_use_cases.dart';
import 'package:map_editor/src/domain/repositories/repositories.dart';
import 'package:map_editor/src/features/editor/application/project_content_controller.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('map_editor_content_ctrl_');
  });

  tearDown(() async {
    if (await tmp.exists()) {
      await tmp.delete(recursive: true);
    }
  });

  group('ProjectContentController', () {
    test('createProjectDialogue updates manifest, selection and status',
        () async {
      final repo = _FakeProjectRepository();
      final controller = _buildController(repo);
      final workspace = _TempProjectWorkspace(tmp.path);

      const current = EditorState(
        projectRootPath: '/tmp/demo',
        project: ProjectManifest(surfaceCatalog: ProjectSurfaceCatalog(), 
          name: 'demo',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[],
        ),
      );

      final next = await controller.createProjectDialogue(
        current: current,
        workspace: workspace,
        name: 'Intro Dialogue',
      );

      expect(next.project?.dialogues, hasLength(1));
      expect(next.selectedProjectDialogueId, next.project?.dialogues.single.id);
      expect(next.statusMessage, 'Dialogue created');
      expect(next.errorMessage, isNull);

      final written = File(
        workspace.resolveProjectRelativePath(
          next.project!.dialogues.single.relativePath,
        ),
      );
      expect(await written.exists(), isTrue);
      expect(repo.lastSavedProject?.dialogues, hasLength(1));
    });

    test('deleteProjectDialogue clears selection when deleting selected entry',
        () async {
      final repo = _FakeProjectRepository();
      final controller = _buildController(repo);
      final workspace = _TempProjectWorkspace(tmp.path);
      const relativePath = 'dialogues/intro_scene.yarn';
      await File(workspace.resolveProjectRelativePath(relativePath))
          .create(recursive: true);

      const entry = ProjectDialogueEntry(
        id: 'intro_scene',
        name: 'Intro Scene',
        relativePath: 'dialogues/intro_scene.yarn',
      );
      const current = EditorState(
        projectRootPath: '/tmp/demo',
        project: ProjectManifest(surfaceCatalog: ProjectSurfaceCatalog(), 
          name: 'demo',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[],
          dialogues: <ProjectDialogueEntry>[entry],
        ),
        selectedProjectDialogueId: 'intro_scene',
      );

      final next = await controller.deleteProjectDialogue(
        current: current,
        workspace: workspace,
        dialogueId: 'intro_scene',
      );

      expect(next.project?.dialogues, isEmpty);
      expect(next.selectedProjectDialogueId, isNull);
      expect(next.statusMessage, 'Dialogue deleted');
      expect(repo.lastSavedProject?.dialogues, isEmpty);
    });

    test('createProjectScenario updates manifest and status', () async {
      final repo = _FakeProjectRepository();
      final controller = _buildController(repo);
      final workspace = _TempProjectWorkspace(tmp.path);
      const scenario = ScenarioAsset(
        id: 'intro_scene',
        name: 'Intro Scene',
        scope: ScenarioScope.localEventFlow,
        entryNodeId: 'start',
        nodes: <ScenarioNode>[
          ScenarioNode(id: 'start', type: ScenarioNodeType.start),
        ],
      );
      const current = EditorState(
        projectRootPath: '/tmp/demo',
        project: ProjectManifest(surfaceCatalog: ProjectSurfaceCatalog(), 
          name: 'demo',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[],
        ),
      );

      final next = await controller.createProjectScenario(
        current: current,
        workspace: workspace,
        scenario: scenario,
      );

      expect(next.project?.scenarios, hasLength(1));
      expect(next.project?.scenarios.single.id, 'intro_scene');
      expect(next.statusMessage, 'Cutscene "Intro Scene" created');
      expect(next.errorMessage, isNull);
      expect(repo.lastSavedProject?.scenarios, hasLength(1));
    });
  });
}

ProjectContentController _buildController(_FakeProjectRepository repo) {
  return ProjectContentController(
    createProjectDialogueUseCase: CreateProjectDialogueUseCase(repo),
    importProjectDialogueUseCase: ImportProjectDialogueUseCase(repo),
    updateProjectDialogueUseCase: UpdateProjectDialogueUseCase(repo),
    deleteProjectDialogueUseCase:
        DeleteProjectDialogueUseCase(repo, _FakeMapRepository()),
    createDialogueLibraryFolderUseCase: CreateDialogueLibraryFolderUseCase(repo),
    renameDialogueLibraryFolderUseCase: RenameDialogueLibraryFolderUseCase(repo),
    moveDialogueLibraryFolderUseCase: MoveDialogueLibraryFolderUseCase(repo),
    deleteDialogueLibraryFolderUseCase: DeleteDialogueLibraryFolderUseCase(repo),
    assignDialogueToLibraryFolderUseCase:
        AssignDialogueToLibraryFolderUseCase(repo),
    moveDialogueToLibraryRootUseCase: MoveDialogueToLibraryRootUseCase(repo),
    saveDialogueYarnBodyUseCase: SaveDialogueYarnBodyUseCase(),
    createProjectScenarioUseCase: CreateProjectScenarioUseCase(repo),
    updateProjectScenarioUseCase: UpdateProjectScenarioUseCase(repo),
    deleteProjectScenarioUseCase: DeleteProjectScenarioUseCase(repo),
  );
}

class _FakeProjectRepository implements ProjectRepository {
  ProjectManifest? lastSavedProject;

  @override
  Future<ProjectManifest> loadProject(String path) async {
    throw UnimplementedError();
  }

  @override
  Future<void> saveProject(ProjectManifest project, String path) async {
    lastSavedProject = project;
  }
}

class _FakeMapRepository implements MapRepository {
  @override
  Future<void> deleteMap(String path) async {}

  @override
  Future<MapData> loadMap(String path) async {
    throw UnimplementedError();
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

class _TempProjectWorkspace implements ProjectWorkspace {
  _TempProjectWorkspace(this.root);

  final String root;

  @override
  String get projectManifestPath => p.join(root, 'project.json');

  @override
  String get projectRoot => root;

  @override
  Future<void> deleteRelativeFile(String relativePath) async {
    final file = File(resolveProjectRelativePath(relativePath));
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<void> deleteDirectoryIfEmpty(String path) async {}

  @override
  Future<bool> directoryExists(String path) async => Directory(path).exists();

  @override
  Future<void> ensureDirectoryExists(String path) async {
    await Directory(p.dirname(path)).create(recursive: true);
  }

  @override
  Future<bool> fileExists(String path) async => File(path).exists();

  @override
  String getMapPath(String mapId) => p.join(root, 'maps', '$mapId.json');

  @override
  String getMapRelativePath(String mapId) => 'maps/$mapId.json';

  @override
  Future<String> importTilesetImage(
    String sourcePath, {
    String? preferredName,
  }) async =>
      p.join(root, 'tilesets', 'image.png');

  @override
  Future<void> copyFile(String sourcePath, String destinationPath) async {
    await ensureDirectoryExists(destinationPath);
    await File(sourcePath).copy(destinationPath);
  }

  @override
  Future<void> moveDirectory(String sourcePath, String destinationPath) async {}

  @override
  Future<void> moveFile(String sourcePath, String destinationPath) async {
    await ensureDirectoryExists(destinationPath);
    final source = File(sourcePath);
    if (!await source.exists()) {
      return;
    }
    await source.rename(destinationPath);
  }

  @override
  Future<String> readTextFile(String path) => File(path).readAsString();

  @override
  String resolveMapPath(String relativePath) => p.join(root, relativePath);

  @override
  String resolveProjectRelativePath(String relativePath) =>
      p.join(root, relativePath);

  @override
  String resolveTilesetPath(String relativePath) => p.join(root, relativePath);

  @override
  Future<void> writeTextFile(String path, String contents) async {
    await ensureDirectoryExists(path);
    await File(path).writeAsString(contents);
  }
}
