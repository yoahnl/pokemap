import 'dart:io';

import 'package:avelune_studio/src/features/project_session/application/project_session.dart';
import 'package:avelune_studio/src/features/project_session/infrastructure/local_project_session_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:path/path.dart' as p;

import 'project_fixture.dart';

void main() {
  late Directory sandbox;

  setUp(() async {
    sandbox = await Directory.systemTemp.createTemp('avelune_example_test_');
  });

  tearDown(() async {
    await sandbox.delete(recursive: true);
  });

  test(
    'reads actual name and preserves every project byte and entry',
    () async {
      final project = await createProject(sandbox, 'Exemple réel Studio');
      await Directory(p.join(project.path, 'maps')).create();
      await File(
        p.join(project.path, 'maps', 'untouched.json'),
      ).writeAsString('{"untouched":true}');
      final beforeHash = await projectFingerprint(project);
      final beforeEntries = await projectInventory(project);
      final adapter = LocalProjectSessionAdapter();

      final session = await adapter.open(project.path);

      expect(session.name, 'Exemple réel Studio');
      expect(session.directoryPath, await project.resolveSymbolicLinks());
      expect(session.sessionId, isNotEmpty);
      await adapter.close(session);
      expect(await projectFingerprint(project), beforeHash);
      expect(await projectInventory(project), beforeEntries);
    },
  );

  test(
    'only reads project.json for identity and never rereads on close',
    () async {
      final project = await createProject(
        sandbox,
        'Exemple comptage',
        withUnreadMap: true,
      );
      final reader = CountingProjectReader();
      final adapter = LocalProjectSessionAdapter(fileReader: reader);

      final session = await adapter.open(project.path);
      await adapter.close(session);

      expect(reader.readPaths, ['project.json']);
    },
  );

  test('rejects invalid manifest without changing it', () async {
    final project = await createProject(sandbox, 'Exemple invalide');
    await File(p.join(project.path, 'project.json')).writeAsString('{invalid');
    final beforeHash = await projectFingerprint(project);
    final beforeEntries = await projectInventory(project);

    await expectLater(
      LocalProjectSessionAdapter().open(project.path),
      failsWith(ProjectOpenProblem.manifestInvalid),
    );

    expect(await projectFingerprint(project), beforeHash);
    expect(await projectInventory(project), beforeEntries);
  });

  test('reports a missing manifest without creating it', () async {
    await expectLater(
      LocalProjectSessionAdapter().open(sandbox.path),
      failsWith(ProjectOpenProblem.manifestMissing),
    );
    expect(await projectInventory(sandbox), isEmpty);
  });

  test('reports an absent directory', () async {
    await expectLater(
      LocalProjectSessionAdapter().open(p.join(sandbox.path, 'absent')),
      failsWith(ProjectOpenProblem.directoryUnavailable),
    );
  });

  test('reports a selected file instead of a directory', () async {
    final file = await File(
      p.join(sandbox.path, 'selected'),
    ).writeAsString('x');
    await expectLater(
      LocalProjectSessionAdapter().open(file.path),
      failsWith(ProjectOpenProblem.directoryUnavailable),
    );
  });

  for (final input in [
    '',
    'relative/project',
    '/tmp/../project',
    '/tmp/\u0000',
  ]) {
    test('rejects invalid path ${input.replaceAll('\u0000', 'NUL')}', () async {
      await expectLater(
        LocalProjectSessionAdapter().open(input),
        failsWith(ProjectOpenProblem.invalidPath),
      );
    });
  }

  test('rejects a manifest symlink escaping the selected root', () async {
    final outside = await createProject(sandbox, 'Exemple externe');
    final selected = await Directory(p.join(sandbox.path, 'selected')).create();
    await Link(
      p.join(selected.path, 'project.json'),
    ).create(p.join(outside.path, 'project.json'));
    final before = await projectFingerprint(outside);

    await expectLater(
      LocalProjectSessionAdapter().open(selected.path),
      failsWith(ProjectOpenProblem.accessDenied),
    );

    expect(await projectFingerprint(outside), before);
  });

  test('closing one session invalidates only its own handle', () async {
    final project = await createProject(sandbox, 'Exemple sessions');
    var token = 0;
    final handles = WorkspaceHandleStore(
      tokenFactory: (prefix) => '$prefix${token++}',
    );
    final adapter = LocalProjectSessionAdapter(handles: handles);
    final first = await adapter.open(project.path);
    final second = await adapter.open(project.path);

    expect(first.sessionId, isNot(second.sessionId));
    await adapter.close(first);
    await adapter.close(first);
    expect(
      () => handles.resolveProject(const ProjectHandle('prj_1')),
      throwsA(isA<WorkspaceHandleException>()),
    );
    expect(
      handles.resolveProject(const ProjectHandle('prj_3')).projectName,
      'Exemple sessions',
    );
    await adapter.close(second);
    expect(
      () => handles.resolveProject(const ProjectHandle('prj_3')),
      throwsA(isA<WorkspaceHandleException>()),
    );
  });
}

Matcher failsWith(ProjectOpenProblem problem) => throwsA(
  isA<ProjectOpenFailure>().having(
    (error) => error.problem,
    'problem',
    problem,
  ),
);
