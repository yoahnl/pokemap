import 'dart:io';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_loader/src/bundled_runtime_project.dart';

void main() {
  test(
    'an undeclared repository-local game is never selected implicitly',
    () async {
      final root = await Directory.systemTemp.createTemp('undeclared-bundle-');
      addTearDown(() => root.delete(recursive: true));
      final project = File(p.join(root.path, 'selbrume', 'project.json'));
      await project.parent.create(recursive: true);
      await project.writeAsString('{}');
      expect(
        await const BundledRuntimeProject().resolve(
          executablePath: p.join(root.path, 'plain'),
        ),
        isNull,
      );
    },
  );
  test(
    'resolves the explicitly declared project from application resources',
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

      await File(
        p.join(
          project.parent.parent.path,
          BundledRuntimeProject.bundleManifestFileName,
        ),
      ).writeAsString(
        jsonEncode({
          'schemaVersion': 1,
          'projectFile': 'selbrume/project.json',
        }),
      );
      final resolved = await const BundledRuntimeProject().resolve(
      executablePath: executable,
      );

      expect(resolved, project.path);
    },
  );

  for (final relative in [
    '../outside/project.json',
    '/outside/project.json',
    'runtime-project/../outside/project.json',
  ]) {
    test(
      'rejects a nonrelative or traversing bundle declaration $relative',
      () async {
        final root = await Directory.systemTemp.createTemp('unsafe-bundle-');
        addTearDown(() => root.delete(recursive: true));
        final resources = Directory(p.join(root.path, 'Contents', 'Resources'));
        await resources.create(recursive: true);
        await File(
          p.join(resources.path, BundledRuntimeProject.bundleManifestFileName),
        ).writeAsString(
          jsonEncode({'schemaVersion': 1, 'projectFile': relative}),
        );
        await expectLater(
          const BundledRuntimeProject().resolve(
            executablePath: p.join(root.path, 'Contents', 'MacOS', 'Host'),
          ),
          throwsStateError,
        );
      },
    );
  }
  test('rejects a symbolic bundled project directory', () async {
    final root = await Directory.systemTemp.createTemp('symbolic-bundle-');
    addTearDown(() => root.delete(recursive: true));
    final resources = Directory(p.join(root.path, 'Contents', 'Resources'));
    await resources.create(recursive: true);
    final outside = Directory(p.join(root.path, 'outside'));
    await outside.create();
    await File(p.join(outside.path, 'project.json')).writeAsString('{}');
    await Link(p.join(resources.path, 'runtime-project')).create(outside.path);
    await File(
      p.join(resources.path, BundledRuntimeProject.bundleManifestFileName),
    ).writeAsString(
      jsonEncode({
        'schemaVersion': 1,
        'projectFile': 'runtime-project/project.json',
      }),
    );
    await expectLater(
      const BundledRuntimeProject().resolve(
        executablePath: p.join(root.path, 'Contents', 'MacOS', 'Host'),
      ),
      throwsStateError,
    );
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
  },
  );
}
