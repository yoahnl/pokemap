import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/application/use_cases/project_tileset_use_cases.dart';
import 'package:map_editor/src/domain/repositories/repositories.dart';
import 'package:path/path.dart' as p;

void main() {
  group('ImportProjectTilesetUseCase', () {
    late Directory tempDir;
    late _FakeProjectRepository repo;
    late _FakeWorkspace workspace;
    late ImportProjectTilesetUseCase useCase;
    late ProjectManifest project;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('tileset_import_test_');
      repo = _FakeProjectRepository();
      workspace = _FakeWorkspace(tempDir.path);
      useCase = ImportProjectTilesetUseCase(repo);
      project = ProjectManifest(
        surfaceCatalog: const ProjectSurfaceCatalog.empty(),
        name: 'Test Project',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
      );
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('imports a tileset image that stays within the supported limits',
        () async {
      final sourcePath = p.join(tempDir.path, 'valid_tileset.png');
      await _writePng(sourcePath, width: 256, height: 4096);

      final updatedProject = await useCase.execute(
        workspace,
        project,
        sourcePath: sourcePath,
        name: 'Indoor',
        scope: TilesetScope.global,
      );

      expect(updatedProject.tilesets, hasLength(1));
      expect(updatedProject.tilesets.single.name, 'Indoor');
      expect(
          updatedProject.tilesets.single.relativePath, 'tilesets/indoor.png');
      expect(repo.savedProject, isNotNull);
    });

    test('rejects a tileset image that exceeds the supported height limit',
        () async {
      final sourcePath = p.join(tempDir.path, 'oversized_tileset.png');
      await _writePng(sourcePath, width: 256, height: 9000);

      expect(
        () => useCase.execute(
          workspace,
          project,
          sourcePath: sourcePath,
          name: 'Too Tall',
          scope: TilesetScope.global,
        ),
        throwsA(
          isA<EditorValidationException>().having(
            (error) => error.message,
            'message',
            contains('8192'),
          ),
        ),
      );
      expect(workspace.importedPaths, isEmpty);
      expect(repo.savedProject, isNull);
    });
  });

  group('UpdateProjectTilesetUseCase', () {
    late Directory tempDir;
    late _FakeProjectRepository repo;
    late _FakeWorkspace workspace;
    late UpdateProjectTilesetUseCase useCase;
    late ProjectManifest project;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('tileset_update_test_');
      repo = _FakeProjectRepository();
      workspace = _FakeWorkspace(tempDir.path);
      useCase = UpdateProjectTilesetUseCase(repo);
      project = ProjectManifest(
        surfaceCatalog: const ProjectSurfaceCatalog.empty(),
        name: 'Test Project',
        maps: <ProjectMapEntry>[],
        tilesets: const <ProjectTilesetEntry>[
          ProjectTilesetEntry(
            id: 'tech_nature_animations',
            name: 'TECH-Nature-animations',
            relativePath: 'tilesets/tech.png',
          ),
        ],
      );
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('persists a transparent color on the tileset entry', () async {
      final color = TilesetTransparentColor.fromHexRgb('f05ba1');

      final updated = await useCase.execute(
        workspace,
        project,
        tilesetId: 'tech_nature_animations',
        transparentColor: color,
      );

      expect(updated.tilesets.single.transparentColor, color);
      expect(repo.savedProject?.tilesets.single.transparentColor, color);
    });

    test('clears a transparent color from the tileset entry', () async {
      final color = TilesetTransparentColor.fromHexRgb('f05ba1');
      final projectWithColor = project.copyWith(
        tilesets: [
          project.tilesets.single.copyWith(transparentColor: color),
        ],
      );

      final updated = await useCase.execute(
        workspace,
        projectWithColor,
        tilesetId: 'tech_nature_animations',
        clearTransparentColor: true,
      );

      expect(updated.tilesets.single.transparentColor, isNull);
      expect(repo.savedProject?.tilesets.single.transparentColor, isNull);
    });
  });
}

Future<void> _writePng(
  String path, {
  required int width,
  required int height,
}) async {
  final image = img.Image(width: width, height: height);
  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(img.encodePng(image));
}

class _FakeProjectRepository implements ProjectRepository {
  ProjectManifest? savedProject;

  @override
  Future<ProjectManifest> loadProject(String path) {
    throw UnimplementedError();
  }

  @override
  Future<void> saveProject(ProjectManifest project, String path) async {
    savedProject = project;
  }
}

class _FakeWorkspace implements ProjectWorkspace {
  _FakeWorkspace(this.projectRoot);

  final List<String> importedPaths = <String>[];

  @override
  final String projectRoot;

  @override
  String get projectManifestPath => p.join(projectRoot, 'project.json');

  @override
  Future<void> copyFile(String sourcePath, String destinationPath) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteDirectoryIfEmpty(String path) async {}

  @override
  Future<void> deleteRelativeFile(String relativePath) async {}

  @override
  Future<bool> directoryExists(String path) async => false;

  @override
  Future<void> ensureDirectoryExists(String path) async {}

  @override
  Future<bool> fileExists(String path) async => false;

  @override
  String getMapPath(String mapId) => throw UnimplementedError();

  @override
  String getMapRelativePath(String mapId) => throw UnimplementedError();

  @override
  Future<String> importTilesetImage(
    String sourcePath, {
    String? preferredName,
  }) async {
    final relativePath =
        'tilesets/${preferredName ?? p.basename(sourcePath)}.png';
    importedPaths.add(relativePath);
    return relativePath;
  }

  @override
  Future<void> moveDirectory(String sourcePath, String destinationPath) {
    throw UnimplementedError();
  }

  @override
  Future<void> moveFile(String sourcePath, String destinationPath) {
    throw UnimplementedError();
  }

  @override
  Future<String> readTextFile(String path) {
    throw UnimplementedError();
  }

  @override
  String resolveMapPath(String relativePath) => throw UnimplementedError();

  @override
  String resolveProjectRelativePath(String relativePath) {
    return p.join(projectRoot, relativePath);
  }

  @override
  String resolveTilesetPath(String relativePath) {
    return p.join(projectRoot, relativePath);
  }

  @override
  Future<void> writeTextFile(String path, String contents) {
    throw UnimplementedError();
  }
}
