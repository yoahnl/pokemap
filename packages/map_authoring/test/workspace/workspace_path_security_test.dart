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

    test('probes regular and missing resources without reading bytes',
        () async {
      final sandbox = await Directory.systemTemp.createTemp(
        'pokemap_resource_probe_',
      );
      addTearDown(() => sandbox.delete(recursive: true));
      final project = await Directory(_join(sandbox.path, 'project')).create();
      final assets = await Directory(_join(project.path, 'assets')).create();
      await File(_join(assets.path, 'front.png')).writeAsBytes(<int>[1, 2, 3]);
      final canonicalRoot = await project.resolveSymbolicLinks();
      const reader = LocalProjectFileReader();

      final existing = await reader.probeResource(
        projectRoot: canonicalRoot,
        relativePath: 'assets/front.png',
      );
      final missing = await reader.probeResource(
        projectRoot: canonicalRoot,
        relativePath: 'assets/missing.png',
      );

      expect(existing.status, ProjectResourceProbeStatus.exists);
      expect(existing.identity?.relativePath, 'assets/front.png');
      expect(existing.identity?.byteLength, 3);
      expect(missing.status, ProjectResourceProbeStatus.missing);
      expect(missing.identity, isNull);
    });

    test('maps traversal and outward symlinks to unsafe probes', () async {
      final sandbox = await Directory.systemTemp.createTemp(
        'pokemap_unsafe_resource_probe_',
      );
      addTearDown(() => sandbox.delete(recursive: true));
      final project = await Directory(_join(sandbox.path, 'project')).create();
      final assets = await Directory(_join(project.path, 'assets')).create();
      final outside =
          await File(_join(sandbox.path, 'outside.png')).writeAsBytes(<int>[1]);
      await Link(_join(assets.path, 'outward.png')).create(outside.path);
      final canonicalRoot = await project.resolveSymbolicLinks();
      const reader = LocalProjectFileReader();

      final traversal = await reader.probeResource(
        projectRoot: canonicalRoot,
        relativePath: '../outside.png',
      );
      final symlink = await reader.probeResource(
        projectRoot: canonicalRoot,
        relativePath: 'assets/outward.png',
      );

      expect(traversal.status, ProjectResourceProbeStatus.unsafePath);
      expect(symlink.status, ProjectResourceProbeStatus.unsafePath);
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
