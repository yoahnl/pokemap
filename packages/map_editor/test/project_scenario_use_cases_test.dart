import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/application/use_cases/project_scenario_use_cases.dart';
import 'package:map_editor/src/domain/repositories/repositories.dart';

class _InMemoryProjectRepository implements ProjectRepository {
  ProjectManifest? savedProject;
  String? savedPath;

  @override
  Future<ProjectManifest> loadProject(String path) async {
    if (savedProject == null) {
      throw StateError('No project saved');
    }
    return savedProject!;
  }

  @override
  Future<void> saveProject(ProjectManifest project, String path) async {
    savedProject = project;
    savedPath = path;
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
  Future<String> importTilesetImage(String sourcePath,
      {String? preferredName}) {
    throw UnimplementedError();
  }

  @override
  String resolveMapPath(String relativePath) => '/tmp/$relativePath';

  @override
  String resolveProjectRelativePath(String relativePath) =>
      '/tmp/$relativePath';

  @override
  String resolveTilesetPath(String relativePath) => '/tmp/$relativePath';
}

ProjectManifest _baseProject({
  List<ScenarioAsset> scenarios = const <ScenarioAsset>[],
}) {
  return ProjectManifest(
    name: 'Scenario Project',
    maps: const [],
    tilesets: const [],
    scenarios: scenarios,
  );
}

void main() {
  group('project_scenario_use_cases', () {
    late _InMemoryProjectRepository repository;
    late _FakeWorkspace workspace;

    setUp(() {
      repository = _InMemoryProjectRepository();
      workspace = _FakeWorkspace();
    });

    test('create scenario adds default start/end graph', () async {
      final useCase = CreateProjectScenarioUseCase(repository);
      final project = _baseProject();

      final updated = await useCase.execute(
        workspace,
        project,
        name: 'Main Story',
      );

      expect(updated.scenarios, hasLength(1));
      final scenario = updated.scenarios.single;
      expect(scenario.id, 'main_story');
      expect(scenario.entryNodeId, 'start');
      expect(
          scenario.nodes.map((node) => node.id), containsAll(['start', 'end']));
      expect(scenario.edges, hasLength(1));
    });

    test('add node creates unique id for repeated type', () async {
      final addUseCase = AddScenarioNodeUseCase(repository);
      final project = _baseProject(
        scenarios: const [
          ScenarioAsset(
            id: 'main',
            name: 'Main',
            entryNodeId: 'start',
            nodes: [
              ScenarioNode(id: 'start', type: ScenarioNodeType.start),
              ScenarioNode(id: 'action', type: ScenarioNodeType.action),
            ],
          ),
        ],
      );

      final updated = await addUseCase.execute(
        workspace,
        project,
        scenarioId: 'main',
        type: ScenarioNodeType.action,
        title: 'Action 2',
      );

      final scenario = updated.scenarios.single;
      expect(
        scenario.nodes.map((node) => node.id),
        contains('action_1'),
      );
    });

    test('add edge rejects duplicates between same endpoints', () async {
      final addUseCase = AddScenarioEdgeUseCase(repository);
      final project = _baseProject(
        scenarios: const [
          ScenarioAsset(
            id: 'main',
            name: 'Main',
            entryNodeId: 'start',
            nodes: [
              ScenarioNode(id: 'start', type: ScenarioNodeType.start),
              ScenarioNode(id: 'end', type: ScenarioNodeType.end),
            ],
            edges: [
              ScenarioEdge(
                id: 's_to_e',
                fromNodeId: 'start',
                toNodeId: 'end',
              ),
            ],
          ),
        ],
      );

      expect(
        () => addUseCase.execute(
          workspace,
          project,
          scenarioId: 'main',
          fromNodeId: 'start',
          toNodeId: 'end',
        ),
        throwsA(isA<EditorValidationException>()),
      );
    });

    test('delete node removes related edges and updates entry node', () async {
      final deleteUseCase = DeleteScenarioNodeUseCase(repository);
      final project = _baseProject(
        scenarios: const [
          ScenarioAsset(
            id: 'main',
            name: 'Main',
            entryNodeId: 'middle',
            nodes: [
              ScenarioNode(id: 'start', type: ScenarioNodeType.start),
              ScenarioNode(id: 'middle', type: ScenarioNodeType.action),
              ScenarioNode(id: 'end', type: ScenarioNodeType.end),
            ],
            edges: [
              ScenarioEdge(
                id: 's_to_m',
                fromNodeId: 'start',
                toNodeId: 'middle',
              ),
              ScenarioEdge(
                id: 'm_to_e',
                fromNodeId: 'middle',
                toNodeId: 'end',
              ),
            ],
          ),
        ],
      );

      final updated = await deleteUseCase.execute(
        workspace,
        project,
        scenarioId: 'main',
        nodeId: 'middle',
      );

      final scenario = updated.scenarios.single;
      expect(scenario.nodes.map((node) => node.id), isNot(contains('middle')));
      expect(scenario.edges, isEmpty);
      expect(scenario.entryNodeId, isNot('middle'));
    });
  });
}
