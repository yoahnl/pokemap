import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_loader/src/bundled_runtime_project.dart';

void main() {
  test('resolves Selbrume from the macOS application resources first',
      () async {
    final root = await Directory.systemTemp.createTemp(
      'pokemap_bundled_runtime_project_',
    );
    addTearDown(() => root.delete(recursive: true));
    final executable = p.join(
      root.path,
      'PokeMap Selbrume.app',
      'Contents',
      'MacOS',
      'PokeMap Selbrume',
    );
    final project = File(
      p.join(
        root.path,
        'PokeMap Selbrume.app',
        'Contents',
        'Resources',
        'selbrume',
        'project.json',
      ),
    );
    await project.parent.create(recursive: true);
    await project.writeAsString('{}');

    final resolved = await const BundledRuntimeProject().resolve(
      executablePath: executable,
      workingDirectory: p.join(root.path, 'unrelated'),
    );

    expect(resolved, project.path);
  });

  test('falls back to an explicit development project without hiding absence',
      () async {
    final root = await Directory.systemTemp.createTemp(
      'pokemap_bundled_runtime_development_',
    );
    addTearDown(() => root.delete(recursive: true));
    final project = File(p.join(root.path, 'selbrume', 'project.json'));
    await project.parent.create(recursive: true);
    await project.writeAsString('{}');

    const resolver = BundledRuntimeProject();
    expect(
      await resolver.resolve(
        executablePath: p.join(root.path, 'plain_executable'),
        developmentProjectRoot: project.parent.path,
      ),
      project.path,
    );
    expect(
      await resolver.resolve(
        executablePath: p.join(root.path, 'plain_executable'),
        developmentProjectRoot: p.join(root.path, 'missing'),
      ),
      isNull,
    );
  });
}
