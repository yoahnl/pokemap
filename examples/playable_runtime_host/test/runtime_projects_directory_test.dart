import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_loader/src/runtime_projects_directory.dart';

void main() {
  test('importRuntimeProjectToRuntimeProjectsDirectory replaces stale copy',
      () async {
    final temp =
        await Directory.systemTemp.createTemp('runtime_project_import_');
    addTearDown(() async {
      if (await temp.exists()) {
        await temp.delete(recursive: true);
      }
    });

    final source = Directory(p.join(temp.path, 'selbrume'));
    await File(p.join(source.path, 'project.json')).create(recursive: true);
    await File(p.join(source.path, 'maps', 'Selbrume.json'))
        .create(recursive: true);
    await File(p.join(source.path, 'data', 'pokemon', 'species', 'fresh.json'))
        .create(recursive: true);

    final projectsDirectory = Directory(p.join(temp.path, 'playable_projects'));
    final staleTarget = Directory(p.join(projectsDirectory.path, 'selbrume'));
    await File(p.join(staleTarget.path, 'project.json'))
        .create(recursive: true);
    await File(p.join(staleTarget.path, 'maps', 'old.json'))
        .create(recursive: true);
    await File(
            p.join(staleTarget.path, 'data', 'pokemon', 'species', 'old.json'))
        .create(recursive: true);

    final importedProjectJsonPath =
        await importRuntimeProjectToRuntimeProjectsDirectory(
      projectJsonPath: p.join(source.path, 'project.json'),
      projectsDirectory: projectsDirectory,
    );

    expect(
      importedProjectJsonPath,
      p.join(staleTarget.path, 'project.json'),
    );
    expect(await File(p.join(staleTarget.path, 'project.json')).exists(), true);
    expect(
        await File(p.join(staleTarget.path, 'maps', 'Selbrume.json')).exists(),
        true);
    expect(
      await File(
        p.join(staleTarget.path, 'data', 'pokemon', 'species', 'fresh.json'),
      ).exists(),
      true,
    );
    expect(await File(p.join(staleTarget.path, 'maps', 'old.json')).exists(),
        false);
    expect(
      await File(
        p.join(staleTarget.path, 'data', 'pokemon', 'species', 'old.json'),
      ).exists(),
      false,
    );
    expect(await File(p.join(source.path, 'project.json')).exists(), true);
  });
}
