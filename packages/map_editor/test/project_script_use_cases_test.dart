import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/application/use_cases/project_script_use_cases.dart';
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

class _NoopMapRepository implements MapRepository {
  @override
  Future<void> deleteMap(String path) async {}

  @override
  Future<MapData> loadMap(String path) {
    throw StateError('loadMap should not be called in this test');
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
  List<ProjectScriptEntry> scripts = const <ProjectScriptEntry>[],
}) {
  return ProjectManifest(
    name: 'Test Project',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    scripts: scripts,
  );
}

ProjectScriptEntry _scriptEntry({
  required String id,
  required String name,
  String defaultStartNode = 'start',
  List<ScriptNode> nodes = const <ScriptNode>[
    ScriptNode(id: 'start', title: 'Start'),
  ],
}) {
  return ProjectScriptEntry(
    id: id,
    name: name,
    asset: ScriptAsset(
      id: id,
      nodes: nodes,
      defaultStartNode: defaultStartNode,
    ),
  );
}

MapData _mapReferencingScript(String scriptId) {
  return MapData(
    id: 'map_1',
    name: 'Map 1',
    size: const GridSize(width: 20, height: 15),
    events: <MapEventDefinition>[
      MapEventDefinition(
        id: 'event_1',
        pages: <MapEventPage>[
          MapEventPage(
            pageNumber: 0,
            script: ScriptRef(scriptId: scriptId),
          ),
        ],
        position: const EventPosition(layerId: 'objects', x: 1, y: 1),
      ),
    ],
  );
}

void main() {
  group('project_script_use_cases', () {
    late _InMemoryProjectRepository projectRepository;
    late _NoopMapRepository mapRepository;
    late _FakeWorkspace workspace;

    setUp(() {
      projectRepository = _InMemoryProjectRepository();
      mapRepository = _NoopMapRepository();
      workspace = _FakeWorkspace();
    });

    test('create script adds a ScriptAsset with start node', () async {
      final useCase = CreateProjectScriptUseCase(projectRepository);
      final project = _baseProject();

      final updated = await useCase.execute(
        workspace,
        project,
        name: 'Intro Script',
      );

      expect(updated.scripts, hasLength(1));
      final script = updated.scripts.single;
      expect(script.id, 'intro_script');
      expect(script.name, 'Intro Script');
      expect(script.asset.id, script.id);
      expect(script.asset.defaultStartNode, 'start');
      expect(script.asset.nodes, hasLength(1));
      expect(script.asset.nodes.single.id, 'start');
    });

    test('rename script updates name only', () async {
      final useCase = RenameProjectScriptUseCase(projectRepository);
      final project = _baseProject(
        scripts: <ProjectScriptEntry>[
          _scriptEntry(id: 'intro', name: 'Intro'),
        ],
      );

      final updated = await useCase.execute(
        workspace,
        project,
        scriptId: 'intro',
        name: 'Opening',
      );

      expect(updated.scripts.single.id, 'intro');
      expect(updated.scripts.single.name, 'Opening');
    });

    test('add node generates unique node id', () async {
      final useCase = AddProjectScriptNodeUseCase(projectRepository);
      final project = _baseProject(
        scripts: <ProjectScriptEntry>[
          _scriptEntry(
            id: 'intro',
            name: 'Intro',
            nodes: const <ScriptNode>[
              ScriptNode(id: 'start', title: 'Start'),
            ],
          ),
        ],
      );

      final updated = await useCase.execute(
        workspace,
        project,
        scriptId: 'intro',
        title: 'Start',
      );

      expect(updated.scripts.single.asset.nodes, hasLength(2));
      expect(updated.scripts.single.asset.nodes.last.id, 'start_1');
      expect(updated.scripts.single.asset.nodes.last.title, 'Start');
    });

    test('delete node rejects default start node', () async {
      final useCase = DeleteProjectScriptNodeUseCase(projectRepository);
      final project = _baseProject(
        scripts: <ProjectScriptEntry>[
          _scriptEntry(
            id: 'intro',
            name: 'Intro',
            nodes: const <ScriptNode>[
              ScriptNode(id: 'start', title: 'Start'),
              ScriptNode(id: 'branch', title: 'Branch'),
            ],
            defaultStartNode: 'start',
          ),
        ],
      );

      expect(
        () => useCase.execute(
          workspace,
          project,
          scriptId: 'intro',
          nodeId: 'start',
        ),
        throwsA(isA<EditorValidationException>()),
      );
    });

    test('delete script rejects referenced scriptId in unsaved map', () async {
      final useCase = DeleteProjectScriptUseCase(
        projectRepository,
        mapRepository,
      );
      final project = _baseProject(
        scripts: <ProjectScriptEntry>[
          _scriptEntry(id: 'intro', name: 'Intro'),
        ],
      );
      final map = _mapReferencingScript('intro');

      expect(
        () => useCase.execute(
          workspace,
          project,
          scriptId: 'intro',
          alsoScanUnsavedMap: map,
        ),
        throwsA(isA<EditorValidationException>()),
      );
    });
  });
}
