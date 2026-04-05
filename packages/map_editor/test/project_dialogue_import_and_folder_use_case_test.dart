import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/application/use_cases/project_dialogue_use_cases.dart';
import 'package:map_editor/src/domain/repositories/repositories.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('map_editor_dialogue_uc_');
  });

  tearDown(() async {
    if (await tmp.exists()) {
      await tmp.delete(recursive: true);
    }
  });

  group('ImportProjectDialogueUseCase', () {
    test('creates manifest entry at root when folderId is null', () async {
      final src = File(p.join(tmp.path, 'source.yarn'));
      await src.writeAsString('title: T\n---\n===\n');

      final repo = _FakeProjectRepository();
      final ws = _TempProjectWorkspace(tmp.path);
      final uc = ImportProjectDialogueUseCase(repo);
      final project = _emptyManifest();

      final updated = await uc.execute(
        ws,
        project,
        absoluteSourcePath: src.path,
        displayName: 'Imported',
        folderId: null,
      );

      expect(updated.dialogues, hasLength(1));
      expect(updated.dialogues.single.name, 'Imported');
      expect(updated.dialogues.single.folderId, isNull);
      expect(repo.lastSavedProject, isNotNull);
    });

    test('assigns folderId when importing into an existing folder', () async {
      final src = File(p.join(tmp.path, 'npc.yarn'));
      await src.writeAsString('title: N\n---\n===\n');

      final repo = _FakeProjectRepository();
      final ws = _TempProjectWorkspace(tmp.path);
      final uc = ImportProjectDialogueUseCase(repo);
      final project = _emptyManifest().copyWith(
        dialogueFolders: [
          const ProjectDialogueFolder(id: 'fld', name: 'NPC'),
        ],
      );

      final updated = await uc.execute(
        ws,
        project,
        absoluteSourcePath: src.path,
        displayName: 'NpcLine',
        folderId: 'fld',
      );

      expect(updated.dialogues.single.folderId, 'fld');
      final dest = File(
        ws.resolveProjectRelativePath(updated.dialogues.single.relativePath),
      );
      expect(await dest.exists(), isTrue);
    });
  });

  group('CreateProjectDialogueUseCase', () {
    test('respects folderId for new dialogue entry', () async {
      final repo = _FakeProjectRepository();
      final ws = _TempProjectWorkspace(tmp.path);
      final uc = CreateProjectDialogueUseCase(repo);
      final project = _emptyManifest().copyWith(
        dialogueFolders: [
          const ProjectDialogueFolder(id: 'f', name: 'Box'),
        ],
      );

      final updated = await uc.execute(
        ws,
        project,
        name: 'Fresh',
        folderId: 'f',
      );

      expect(updated.dialogues.single.folderId, 'f');
      expect(updated.dialogues.single.name, 'Fresh');
    });
  });
}

ProjectManifest _emptyManifest() {
  return const ProjectManifest(
    name: 'testproj',
    maps: <ProjectMapEntry>[],
    tilesets: <ProjectTilesetEntry>[],
  );
}

class _FakeProjectRepository implements ProjectRepository {
  ProjectManifest? lastSavedProject;

  @override
  Future<ProjectManifest> loadProject(String path) async =>
      throw UnimplementedError();

  @override
  Future<void> saveProject(ProjectManifest project, String path) async {
    lastSavedProject = project;
  }
}

class _TempProjectWorkspace implements ProjectWorkspace {
  _TempProjectWorkspace(this.root);
  final String root;

  @override
  String get projectManifestPath => p.join(root, 'project.json');

  @override
  String get projectRoot => root;

  @override
  Future<void> deleteRelativeFile(String relativePath) async {}

  @override
  Future<void> ensureDirectoryExists(String path) async {
    await Directory(p.dirname(path)).create(recursive: true);
  }

  @override
  String getMapPath(String mapId) => p.join(root, 'maps', '$mapId.json');

  @override
  String getMapRelativePath(String mapId) => 'maps/$mapId.json';

  @override
  Future<String> importTilesetImage(
    String sourcePath, {
    String? preferredName,
  }) async =>
      p.join(root, 'tilesets', 'x.png');

  @override
  String resolveMapPath(String relativePath) => p.join(root, relativePath);

  @override
  String resolveProjectRelativePath(String relativePath) =>
      p.join(root, relativePath);

  @override
  String resolveTilesetPath(String relativePath) =>
      p.join(root, relativePath);
}
