import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:path/path.dart' as p;

void main() {
  group('ProjectFileSystem map path confinement', () {
    late Directory projectRoot;
    late ProjectFileSystem workspace;
    final extraRoots = <Directory>[];

    setUp(() async {
      projectRoot = await Directory.systemTemp.createTemp(
        'pokemap_map_path_confinement_',
      );
      workspace = ProjectFileSystem(projectRoot.path);
    });

    tearDown(() async {
      if (await projectRoot.exists()) {
        await projectRoot.delete(recursive: true);
      }
      for (final root in extraRoots) {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      }
      extraRoots.clear();
    });

    test('resolves direct and nested JSON maps inside the map directory', () {
      expect(
        workspace.resolveMapPath('maps/town.json'),
        p.normalize(p.join(projectRoot.path, 'maps', 'town.json')),
      );
      expect(
        workspace.resolveMapPath('maps/regions/route_1.json'),
        p.normalize(
          p.join(projectRoot.path, 'maps', 'regions', 'route_1.json'),
        ),
      );
    });

    test('rejects traversal before any target file can be created', () {
      for (final relativePath in <String>[
        '../project.json',
        'maps/../project.json',
        'maps/sub/../../project.json',
      ]) {
        expect(
          () => workspace.resolveMapPath(relativePath),
          throwsA(isA<EditorValidationException>()),
          reason: relativePath,
        );
      }

      expect(
        File(p.join(projectRoot.path, 'project.json')).existsSync(),
        isFalse,
      );
    });

    test('rejects internal dot-segment and duplicate-separator aliases', () {
      for (final alias in <String>[
        'maps/./town.json',
        'maps/nested/../town.json',
        'maps//town.json',
      ]) {
        expect(
          () => workspace.resolveMapPath(alias),
          throwsA(isA<EditorValidationException>()),
          reason: alias,
        );
      }
    });

    test('rejects POSIX, drive-letter and UNC absolute paths', () {
      for (final path in <String>[
        '/tmp/evil.json',
        'C:/evil.json',
        r'C:\evil.json',
        r'\\server\share\evil.json',
      ]) {
        expect(
          () => workspace.resolveMapPath(path),
          throwsA(isA<EditorValidationException>()),
          reason: path,
        );
      }
    });

    test('rejects backslashes, non-map directories and non-JSON targets', () {
      for (final path in <String>[
        r'maps\town.json',
        'maps_evil/town.json',
        'assets/town.json',
        'maps/town.txt',
        'maps/',
      ]) {
        expect(
          () => workspace.resolveMapPath(path),
          throwsA(isA<EditorValidationException>()),
          reason: path,
        );
      }
    });

    test('getMapPath rejects an unsafe authoring identifier', () {
      expect(
        () => workspace.getMapPath('../project'),
        throwsA(isA<EditorValidationException>()),
      );
      expect(
        () => workspace.getMapRelativePath('Town'),
        throwsA(isA<EditorValidationException>()),
      );
    });

    test('rejects a maps directory symlink that leaves the project', () async {
      final outside = await Directory.systemTemp.createTemp(
        'pokemap_map_path_outside_',
      );
      extraRoots.add(outside);
      await Link(p.join(projectRoot.path, 'maps')).create(outside.path);

      expect(
        () => workspace.resolveMapPath('maps/town.json'),
        throwsA(isA<EditorValidationException>()),
      );
    });

    test('rejects a nested symlink whose target leaves maps', () async {
      final maps = Directory(p.join(projectRoot.path, 'maps'));
      await maps.create();
      final outside = await Directory.systemTemp.createTemp(
        'pokemap_nested_map_path_outside_',
      );
      extraRoots.add(outside);
      await Link(p.join(maps.path, 'linked')).create(outside.path);

      expect(
        () => workspace.resolveMapPath('maps/linked/town.json'),
        throwsA(isA<EditorValidationException>()),
      );
    });

    test('rejects an internal symlink alias even when it stays inside maps',
        () async {
      final maps = Directory(p.join(projectRoot.path, 'maps'));
      await maps.create();
      await Link(p.join(maps.path, 'alias')).create(maps.path);

      expect(
        () => workspace.resolveMapPath('maps/alias/town.json'),
        throwsA(isA<EditorValidationException>()),
      );
      expect(
        workspace.resolveMapPath('maps/town.json'),
        p.join(maps.path, 'town.json'),
      );
    });
  });
}
