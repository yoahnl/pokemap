import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/core/repository_providers.dart';
import 'package:map_editor/src/app/providers/editor/map_use_case_providers.dart';
import 'package:map_editor/src/domain/repositories/repositories.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';

void main() {
  test(
    'product Create provider injects DS-05 instead of legacy compensation',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'pokemap_ds05_provider_',
      );
      addTearDown(() => root.delete(recursive: true));
      final workspace = ProjectFileSystem(root.path);
      const project = ProjectManifest(
        name: 'DS-05 provider',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
      );
      await File(workspace.projectManifestPath).writeAsString(
        const JsonEncoder.withIndent('  ').convert(project.toJson()),
        flush: true,
      );
      final throwingProjects = _ThrowingProjectRepository();
      final container = ProviderContainer(
        overrides: <Override>[
          mapRepositoryProvider.overrideWithValue(FileMapRepository()),
          projectRepositoryProvider.overrideWithValue(throwingProjects),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(createMapUseCaseProvider)
          .execute(workspace, project, 'harbor', 2, 2);

      expect(throwingProjects.saveCalls, 0);
      expect(
        (await FileProjectRepository().loadProject(
          workspace.projectManifestPath,
        )).maps.single.id,
        'harbor',
      );
      expect(await File(workspace.getMapPath('harbor')).exists(), isTrue);
    },
  );
}

final class _ThrowingProjectRepository implements ProjectRepository {
  int saveCalls = 0;

  @override
  Future<ProjectManifest> loadProject(String path) {
    throw UnimplementedError();
  }

  @override
  Future<void> saveProject(ProjectManifest project, String path) async {
    saveCalls += 1;
    throw StateError('legacy project repository must not be called');
  }
}
