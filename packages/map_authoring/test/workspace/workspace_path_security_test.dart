import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

void main() {
  group('WorkspacePolicy', () {
    test('authorizes the real project below an allowed root', () async {
      final fixture = _realFixtureDirectory();
      final policy = await WorkspacePolicy.create(
        allowedRootPaths: [fixture.parent.path],
        fileReader: const LocalProjectFileReader(),
      );

      final authorized = await policy.authorizeProjectRoot(fixture.path);

      expect(authorized, await fixture.resolveSymbolicLinks());
    });

    test('rejects a project outside every allowed root', () async {
      final sandbox = await Directory.systemTemp.createTemp(
        'pokemap_workspace_policy_',
      );
      addTearDown(() => sandbox.delete(recursive: true));
      final allowed = await Directory(_join(sandbox.path, 'allowed')).create();
      final outside = await Directory(_join(sandbox.path, 'outside')).create();
      final policy = await WorkspacePolicy.create(
        allowedRootPaths: [allowed.path],
        fileReader: const LocalProjectFileReader(),
      );

      await expectLater(
        () => policy.authorizeProjectRoot(outside.path),
        throwsA(
          isA<WorkspaceAccessException>().having(
            (error) => error.code,
            'code',
            'workspace.path_outside_allowed_roots',
          ),
        ),
      );
    });

    test('rejects traversal before filesystem resolution', () async {
      final sandbox = await Directory.systemTemp.createTemp(
        'pokemap_workspace_traversal_',
      );
      addTearDown(() => sandbox.delete(recursive: true));
      final allowed = await Directory(_join(sandbox.path, 'allowed')).create();
      final project = await Directory(_join(allowed.path, 'project')).create();
      final sibling = await Directory(_join(allowed.path, 'sibling')).create();
      final policy = await WorkspacePolicy.create(
        allowedRootPaths: [allowed.path],
        fileReader: const LocalProjectFileReader(),
      );

      await expectLater(
        () => policy.authorizeProjectRoot(
          _join(project.path, '..', sibling.uri.pathSegments.last),
        ),
        throwsA(
          isA<WorkspaceAccessException>().having(
            (error) => error.code,
            'code',
            'workspace.path_traversal',
          ),
        ),
      );
    });
  });

  group('LocalProjectFileReader', () {
    test('reads a regular project-relative file', () async {
      final sandbox = await Directory.systemTemp.createTemp(
        'pokemap_file_reader_',
      );
      addTearDown(() => sandbox.delete(recursive: true));
      final project = await Directory(_join(sandbox.path, 'project')).create();
      final maps = await Directory(_join(project.path, 'maps')).create();
      await File(_join(maps.path, 'field.json')).writeAsString('{"id":"map"}');
      final canonicalRoot = await project.resolveSymbolicLinks();

      final bytes = await const LocalProjectFileReader().readBytes(
        projectRoot: canonicalRoot,
        relativePath: 'maps/field.json',
      );

      expect(String.fromCharCodes(bytes), '{"id":"map"}');
    });

    test('rejects an absolute project-relative path', () async {
      final project = _realFixtureDirectory();
      final canonicalRoot = await project.resolveSymbolicLinks();

      await expectLater(
        () => const LocalProjectFileReader().readBytes(
          projectRoot: canonicalRoot,
          relativePath: _join(canonicalRoot, 'project.json'),
        ),
        throwsA(
          isA<WorkspaceAccessException>().having(
            (error) => error.code,
            'code',
            'workspace.path_absolute',
          ),
        ),
      );
    });

    test('rejects a relative traversal', () async {
      final project = _realFixtureDirectory();
      final canonicalRoot = await project.resolveSymbolicLinks();

      await expectLater(
        () => const LocalProjectFileReader().readBytes(
          projectRoot: canonicalRoot,
          relativePath: '../project.json',
        ),
        throwsA(
          isA<WorkspaceAccessException>().having(
            (error) => error.code,
            'code',
            'workspace.path_traversal',
          ),
        ),
      );
    });

    test('rejects an outward symlink', () async {
      final sandbox = await Directory.systemTemp.createTemp(
        'pokemap_outward_symlink_',
      );
      addTearDown(() => sandbox.delete(recursive: true));
      final allowed = await Directory(_join(sandbox.path, 'allowed')).create();
      final project = await Directory(_join(allowed.path, 'project')).create();
      final maps = await Directory(_join(project.path, 'maps')).create();
      final outside = await Directory(_join(sandbox.path, 'outside')).create();
      final secret = File(_join(outside.path, 'secret.json'));
      await secret.writeAsString('{"secret":true}');
      await Link(_join(maps.path, 'outward.json')).create(secret.path);
      final canonicalRoot = await project.resolveSymbolicLinks();

      await expectLater(
        () => const LocalProjectFileReader().readBytes(
          projectRoot: canonicalRoot,
          relativePath: 'maps/outward.json',
        ),
        throwsA(
          isA<WorkspaceAccessException>().having(
            (error) => error.code,
            'code',
            'workspace.path_outside_project',
          ),
        ),
      );
    });

    test('does not expose a filesystem write method', () {
      final source = File(
        _join(
          Directory.current.path,
          'lib',
          'src',
          'ports',
          'project_file_reader.dart',
        ),
      ).readAsStringSync();

      expect(source, isNot(contains('writeAs')));
      expect(source, isNot(contains('delete(')));
      expect(source, isNot(contains('rename(')));
    });
  });
}

Directory _realFixtureDirectory() {
  return Directory(
    _join(
      Directory.current.parent.parent.path,
      'examples',
      'playable_runtime_host',
      'p3_narrative_smoke_slice',
    ),
  );
}

String _join(
  String first,
  String second, [
  String? third,
  String? fourth,
  String? fifth,
]) {
  final parts = [
    first,
    second,
    if (third != null) third,
    if (fourth != null) fourth,
    if (fifth != null) fifth,
  ];
  return parts.join(Platform.pathSeparator);
}
