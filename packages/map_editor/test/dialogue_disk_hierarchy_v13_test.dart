import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/errors/application_errors.dart'
    show EditorConflictException, EditorValidationException;
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/application/use_cases/project_dialogue_library_use_cases.dart';
import 'package:map_editor/src/application/use_cases/project_dialogue_use_cases.dart';
import 'package:map_editor/src/domain/repositories/repositories.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('map_editor_v13_');
  });

  tearDown(() async {
    if (await tmp.exists()) {
      await tmp.delete(recursive: true);
    }
  });

  ProjectManifest baseManifest() {
    return const ProjectManifest(surfaceCatalog: const ProjectSurfaceCatalog.empty(), 
      name: 'p',
      maps: <ProjectMapEntry>[],
      tilesets: <ProjectTilesetEntry>[],
    );
  }

  test('create dialogue at project root uses dialogues/<id>.yarn on disk', () async {
    final repo = _FakeProjectRepository();
    final ws = _TempProjectWorkspace(tmp.path);
    final uc = CreateProjectDialogueUseCase(repo);
    final updated = await uc.execute(ws, baseManifest(), name: 'Intro');
    expect(updated.dialogues.single.relativePath, 'dialogues/intro.yarn');
    expect(
      await File(ws.resolveProjectRelativePath('dialogues/intro.yarn')).exists(),
      isTrue,
    );
  });

  test('buildDialogueLibraryTree tracks folderId after assign and toRoot', () async {
    final repo = _FakeProjectRepository();
    final ws = _TempProjectWorkspace(tmp.path);
    final createFolder = CreateDialogueLibraryFolderUseCase(repo);
    final createDlg = CreateProjectDialogueUseCase(repo);
    final assign = AssignDialogueToLibraryFolderUseCase(repo);
    final toRoot = MoveDialogueToLibraryRootUseCase(repo);

    var project = await createFolder.execute(ws, baseManifest(), name: 'Nest');
    final folderId = project.dialogueFolders.single.id;
    project = await createDlg.execute(ws, project, name: 'Item');
    final lineId = project.dialogues.single.id;

    var tree = buildDialogueLibraryTree(project);
    expect(tree.rootDialogues.map((e) => e.id), contains(lineId));
    expect(tree.rootFolders.single.dialogues, isEmpty);

    project = await assign.execute(ws, project, dialogueId: lineId, folderId: folderId);
    tree = buildDialogueLibraryTree(project);
    expect(tree.rootDialogues, isEmpty);
    expect(tree.rootFolders.single.dialogues.map((e) => e.id), contains(lineId));

    project = await toRoot.execute(ws, project, dialogueId: lineId);
    tree = buildDialogueLibraryTree(project);
    expect(tree.rootDialogues.map((e) => e.id), contains(lineId));
    expect(tree.rootFolders.single.dialogues, isEmpty);
  });

  test('assign dialogue to folder moves file into nested dialogues/<slug>/', () async {
    final repo = _FakeProjectRepository();
    final ws = _TempProjectWorkspace(tmp.path);
    final createFolder = CreateDialogueLibraryFolderUseCase(repo);
    final createDlg = CreateProjectDialogueUseCase(repo);
    final assign = AssignDialogueToLibraryFolderUseCase(repo);

    var project =
        await createFolder.execute(ws, baseManifest(), name: 'Chapter1');
    final folderId = project.dialogueFolders.single.id;
    project = await createDlg.execute(ws, project, name: 'Line');
    final id = project.dialogues.single.id;
    expect(project.dialogues.single.relativePath, 'dialogues/$id.yarn');

    project = await assign.execute(ws, project, dialogueId: id, folderId: folderId);
    expect(project.dialogues.single.folderId, folderId);
    expect(project.dialogues.single.relativePath, 'dialogues/chapter1/$id.yarn');
    expect(
      await File(ws.resolveProjectRelativePath(project.dialogues.single.relativePath))
          .exists(),
      isTrue,
    );
    expect(
      await File(ws.resolveProjectRelativePath('dialogues/$id.yarn')).exists(),
      isFalse,
    );
  });

  test('move dialogue to library root moves file back to dialogues/', () async {
    final repo = _FakeProjectRepository();
    final ws = _TempProjectWorkspace(tmp.path);
    final createFolder = CreateDialogueLibraryFolderUseCase(repo);
    final createDlg = CreateProjectDialogueUseCase(repo);
    final toRoot = MoveDialogueToLibraryRootUseCase(repo);

    var project = await createFolder.execute(ws, baseManifest(), name: 'Sub');
    final folderId = project.dialogueFolders.single.id;
    project = await createDlg.execute(ws, project, name: 'D', folderId: folderId);
    final id = project.dialogues.single.id;
    expect(project.dialogues.single.relativePath, contains('dialogues/sub/'));

    project = await toRoot.execute(ws, project, dialogueId: id);
    expect(project.dialogues.single.folderId, isNull);
    expect(project.dialogues.single.relativePath, 'dialogues/$id.yarn');
    expect(
      await File(ws.resolveProjectRelativePath('dialogues/$id.yarn')).exists(),
      isTrue,
    );
  });

  test('rename dialogue folder renames directory and rewrites dialogue paths', () async {
    final repo = _FakeProjectRepository();
    final ws = _TempProjectWorkspace(tmp.path);
    final mkFolder = CreateDialogueLibraryFolderUseCase(repo);
    final mkDlg = CreateProjectDialogueUseCase(repo);
    final rename = RenameDialogueLibraryFolderUseCase(repo);

    var project = await mkFolder.execute(ws, baseManifest(), name: 'OldName');
    final folderId = project.dialogueFolders.single.id;
    project = await mkDlg.execute(ws, project, name: 'X', folderId: folderId);
    expect(project.dialogues.single.relativePath, contains('dialogues/oldname/'));

    project = await rename.execute(ws, project, folderId: folderId, name: 'NewName');
    expect(project.dialogueFolders.single.name, 'NewName');
    expect(project.dialogues.single.relativePath, contains('dialogues/newname/'));
    expect(
      await File(ws.resolveProjectRelativePath(project.dialogues.single.relativePath))
          .exists(),
      isTrue,
    );
  });

  test('move dialogue folder under new parent moves subtree on disk', () async {
    final repo = _FakeProjectRepository();
    final ws = _TempProjectWorkspace(tmp.path);
    final mkFolder = CreateDialogueLibraryFolderUseCase(repo);
    final mkDlg = CreateProjectDialogueUseCase(repo);
    final moveFolder = MoveDialogueLibraryFolderUseCase(repo);

    var project = await mkFolder.execute(ws, baseManifest(), name: 'Outer');
    final outerId = project.dialogueFolders.single.id;
    project = await mkFolder.execute(ws, project, name: 'Inner', parentFolderId: outerId);
    final innerId =
        project.dialogueFolders.where((f) => f.id != outerId).single.id;
    project = await mkDlg.execute(ws, project, name: 'Z', folderId: innerId);
    expect(project.dialogues.single.relativePath, contains('dialogues/outer/inner/'));

    project = await moveFolder.execute(
      ws,
      project,
      folderId: innerId,
      newParentFolderId: null,
    );
    expect(
      project.dialogueFolders.where((f) => f.id == innerId).single.parentFolderId,
      isNull,
    );
    expect(project.dialogues.single.relativePath, isNot(contains('/outer/')));
    expect(
      await File(ws.resolveProjectRelativePath(project.dialogues.single.relativePath))
          .exists(),
      isTrue,
    );
  });

  test('delete non-empty dialogue folder is refused', () async {
    final repo = _FakeProjectRepository();
    final ws = _TempProjectWorkspace(tmp.path);
    final mkFolder = CreateDialogueLibraryFolderUseCase(repo);
    final mkDlg = CreateProjectDialogueUseCase(repo);
    final del = DeleteDialogueLibraryFolderUseCase(repo);

    var project = await mkFolder.execute(ws, baseManifest(), name: 'Full');
    final folderId = project.dialogueFolders.single.id;
    project = await mkDlg.execute(ws, project, name: 'Keep', folderId: folderId);

    await expectLater(
      del.execute(ws, project, folderId: folderId),
      throwsA(isA<EditorConflictException>()),
    );
  });

  test('duplicate relativePath in manifest fails ProjectValidator', () async {
    final repo = _FakeProjectRepository();
    final ws = _TempProjectWorkspace(tmp.path);
    final uc = CreateProjectDialogueUseCase(repo);
    final project = await uc.execute(ws, baseManifest(), name: 'One');
    final dup = project.copyWith(
      dialogues: [
        project.dialogues.single,
        project.dialogues.single.copyWith(id: 'other_id', name: 'Other'),
      ],
    );
    expect(
      () => ProjectValidator.validate(dup),
      throwsA(isA<ValidationException>()),
    );
  });

  test('create dialogue refuses when target file path already exists', () async {
    final repo = _FakeProjectRepository();
    final ws = _TempProjectWorkspace(tmp.path);
    await Directory(p.join(tmp.path, 'dialogues')).create(recursive: true);
    await File(p.join(tmp.path, 'dialogues', 'hello.yarn')).writeAsString('x');
    final uc = CreateProjectDialogueUseCase(repo);
    await expectLater(
      uc.execute(ws, baseManifest(), name: 'Hello'),
      throwsA(isA<EditorValidationException>()),
    );
  });

  test('assign dialogue refuses when destination file already exists on disk', () async {
    final repo = _FakeProjectRepository();
    final ws = _TempProjectWorkspace(tmp.path);
    final mkFolder = CreateDialogueLibraryFolderUseCase(repo);
    final mkDlg = CreateProjectDialogueUseCase(repo);
    final assign = AssignDialogueToLibraryFolderUseCase(repo);

    var project = await mkFolder.execute(ws, baseManifest(), name: 'Box');
    final folderId = project.dialogueFolders.single.id;
    project = await mkDlg.execute(ws, project, name: 'Alpha');
    final id = project.dialogues.single.id;

    final blocked = ws.resolveProjectRelativePath('dialogues/box/$id.yarn');
    await Directory(p.dirname(blocked)).create(recursive: true);
    await File(blocked).writeAsString('block');

    await expectLater(
      assign.execute(ws, project, dialogueId: id, folderId: folderId),
      throwsA(isA<EditorValidationException>()),
    );
  });

  test('import into nested folder writes under dialogues/<folderSlug>/', () async {
    final src = File(p.join(tmp.path, 'ext.yarn'));
    await src.writeAsString('title: Q\n---\n===\n');
    final repo = _FakeProjectRepository();
    final ws = _TempProjectWorkspace(tmp.path);
    final mkFolder = CreateDialogueLibraryFolderUseCase(repo);
    final imp = ImportProjectDialogueUseCase(repo);
    var project = await mkFolder.execute(ws, baseManifest(), name: 'Maman');
    final folderId = project.dialogueFolders.single.id;
    project = await imp.execute(
      ws,
      project,
      absoluteSourcePath: src.path,
      displayName: 'Speech',
      folderId: folderId,
    );
    expect(project.dialogues.single.relativePath, startsWith('dialogues/maman/'));
    expect(
      await File(ws.resolveProjectRelativePath(project.dialogues.single.relativePath))
          .exists(),
      isTrue,
    );
  });
}

class _FakeProjectRepository implements ProjectRepository {
  @override
  Future<ProjectManifest> loadProject(String path) async =>
      throw UnimplementedError();

  @override
  Future<void> saveProject(ProjectManifest project, String path) async {}
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
    final f = File(resolveProjectRelativePath(relativePath));
    if (await f.exists()) await f.delete();
  }

  @override
  Future<void> deleteDirectoryIfEmpty(String path) async {
    final directory = Directory(path);
    if (!await directory.exists()) return;
    try {
      await directory.delete(recursive: false);
    } on FileSystemException {
      // ignore non-empty directories in tests as the real implementation does
    }
  }

  @override
  Future<bool> directoryExists(String path) => Directory(path).exists();

  @override
  Future<void> ensureDirectoryExists(String path) async {
    await Directory(p.dirname(path)).create(recursive: true);
  }

  @override
  Future<bool> fileExists(String path) => File(path).exists();

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
  Future<void> copyFile(String sourcePath, String destinationPath) async {
    await ensureDirectoryExists(destinationPath);
    await File(sourcePath).copy(destinationPath);
  }

  @override
  Future<void> moveDirectory(String sourcePath, String destinationPath) async {
    final directory = Directory(sourcePath);
    if (!await directory.exists()) {
      return;
    }
    await Directory(p.dirname(destinationPath)).create(recursive: true);
    await directory.rename(destinationPath);
  }

  @override
  Future<void> moveFile(String sourcePath, String destinationPath) async {
    await ensureDirectoryExists(destinationPath);
    await File(sourcePath).rename(destinationPath);
  }

  @override
  Future<String> readTextFile(String path) => File(path).readAsString();

  @override
  String resolveMapPath(String relativePath) => p.join(root, relativePath);

  @override
  String resolveProjectRelativePath(String relativePath) =>
      p.join(root, relativePath);

  @override
  String resolveTilesetPath(String relativePath) =>
      p.join(root, relativePath);

  @override
  Future<void> writeTextFile(String path, String contents) async {
    await ensureDirectoryExists(path);
    await File(path).writeAsString(contents);
  }
}
