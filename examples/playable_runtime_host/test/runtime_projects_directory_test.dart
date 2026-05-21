import 'dart:io';

import 'package:pokemap_loader/src/runtime_projects_directory.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('creates playable_projects under the app documents directory', () async {
    final tempRoot = await Directory.systemTemp.createTemp(
      'runtime_projects_directory_test',
    );
    addTearDown(() async {
      if (await tempRoot.exists()) {
        await tempRoot.delete(recursive: true);
      }
    });

    final documentsDirectory = Directory(p.join(tempRoot.path, 'app_docs'));
    await documentsDirectory.create(recursive: true);

    final projectsDirectory = await ensureRuntimeProjectsDirectory(
      getDocumentsDirectory: () async => documentsDirectory,
    );

    expect(projectsDirectory.path,
        p.join(documentsDirectory.path, 'playable_projects'));
    expect(await projectsDirectory.exists(), isTrue);
  });
}
