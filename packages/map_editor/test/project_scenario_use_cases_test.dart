import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/application/use_cases/project_scenario_use_cases.dart';
import 'package:map_editor/src/domain/repositories/repositories.dart';

void main() {
  group('project_scenario_use_cases', () {
    test('create adds scenario and persists manifest', () async {
      final repo = _FakeProjectRepository();
      final workspace = _FakeWorkspace();
      final useCase = CreateProjectScenarioUseCase(repo);

      const project = ProjectManifest(
        name: 'demo',
        maps: <ProjectMapEntry>[
          ProjectMapEntry(
            id: 'vova_center',
            name: 'Vova Center',
            relativePath: 'maps/vova_center.json',
          ),
        ],
        tilesets: <ProjectTilesetEntry>[],
      );
      const scenario = ScenarioAsset(
        id: 'intro_scene',
        name: 'Intro Scene',
        scope: ScenarioScope.localEventFlow,
        entryNodeId: 'start',
        nodes: <ScenarioNode>[
          ScenarioNode(id: 'start', type: ScenarioNodeType.start),
          ScenarioNode(
            id: 'source',
            type: ScenarioNodeType.reference,
            payload: ScenarioNodePayload(actionKind: 'sourceMapEnter'),
            binding: ScenarioNodeBinding(mapId: 'vova_center'),
          ),
          ScenarioNode(id: 'end', type: ScenarioNodeType.end),
        ],
        edges: <ScenarioEdge>[
          ScenarioEdge(id: 'e1', fromNodeId: 'start', toNodeId: 'source'),
          ScenarioEdge(id: 'e2', fromNodeId: 'source', toNodeId: 'end'),
        ],
      );

      final updated = await useCase.execute(
        workspace,
        project,
        scenario: scenario,
      );

      expect(updated.scenarios.length, 1);
      expect(updated.scenarios.first.id, 'intro_scene');
      expect(repo.lastSavedProject?.scenarios.length, 1);
      expect(repo.lastSavedPath, workspace.projectManifestPath);
    });

    test('update replaces scenario by id', () async {
      final repo = _FakeProjectRepository();
      final workspace = _FakeWorkspace();
      final useCase = UpdateProjectScenarioUseCase(repo);

      const original = ScenarioAsset(
        id: 'intro_scene',
        name: 'Intro Scene',
        scope: ScenarioScope.localEventFlow,
        entryNodeId: 'start',
        nodes: <ScenarioNode>[
          ScenarioNode(id: 'start', type: ScenarioNodeType.start),
        ],
      );
      const project = ProjectManifest(
        name: 'demo',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        scenarios: <ScenarioAsset>[original],
      );

      const next = ScenarioAsset(
        id: 'intro_scene',
        name: 'Intro Scene Updated',
        scope: ScenarioScope.localEventFlow,
        entryNodeId: 'start',
        nodes: <ScenarioNode>[
          ScenarioNode(id: 'start', type: ScenarioNodeType.start),
        ],
      );

      final updated = await useCase.execute(
        workspace,
        project,
        scenarioId: 'intro_scene',
        nextScenario: next,
      );

      expect(updated.scenarios.length, 1);
      expect(updated.scenarios.first.name, 'Intro Scene Updated');
      expect(
          repo.lastSavedProject?.scenarios.first.name, 'Intro Scene Updated');
    });

    test('delete removes scenario and throws when missing', () async {
      final repo = _FakeProjectRepository();
      final workspace = _FakeWorkspace();
      final useCase = DeleteProjectScenarioUseCase(repo);

      const scenario = ScenarioAsset(
        id: 'intro_scene',
        name: 'Intro Scene',
        scope: ScenarioScope.localEventFlow,
        entryNodeId: 'start',
        nodes: <ScenarioNode>[
          ScenarioNode(id: 'start', type: ScenarioNodeType.start),
        ],
      );
      const project = ProjectManifest(
        name: 'demo',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        scenarios: <ScenarioAsset>[scenario],
      );

      final updated = await useCase.execute(
        workspace,
        project,
        scenarioId: 'intro_scene',
      );
      expect(updated.scenarios, isEmpty);

      await expectLater(
        () => useCase.execute(workspace, updated, scenarioId: 'unknown'),
        throwsA(isA<EditorNotFoundException>()),
      );
    });
  });
}

class _FakeProjectRepository implements ProjectRepository {
  ProjectManifest? lastSavedProject;
  String? lastSavedPath;

  @override
  Future<ProjectManifest> loadProject(String path) async {
    throw UnimplementedError();
  }

  @override
  Future<void> saveProject(ProjectManifest project, String path) async {
    lastSavedProject = project;
    lastSavedPath = path;
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
