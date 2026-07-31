import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectOpenService', () {
    test('opens the real fixture with opaque read-only handles', () async {
      final fixture = _realFixtureDirectory();
      final projectFile = File(_join(fixture.path, 'project.json'));
      final before = await projectFile.readAsBytes();
      final harness = await _Harness.create(fixture.parent);

      final opened = await harness.service.openProject(fixture.path);

      expect(opened.workspaceHandle.value, startsWith('ws_'));
      expect(opened.projectHandle.value, startsWith('prj_'));
      expect(opened.projectName, 'P3 Narrative Smoke Slice');
      expect(opened.fingerprint, matches(r'^sha256:[0-9a-f]{64}$'));
      expect(opened.readOnly, isTrue);
      expect(opened.expiresAt, harness.now.add(const Duration(minutes: 5)));
      final serialized = opened.toJson().toString();
      expect(serialized, isNot(contains(fixture.path)));
      expect(serialized, isNot(contains('/Users/')));

      final access = harness.handles.resolveProject(opened.projectHandle);
      final manifestBytes = await access.readBytes('project.json');
      expect(manifestBytes, before);
      expect(await projectFile.readAsBytes(), before);
    });

    test('computes the same initial fingerprint for identical bytes', () async {
      final fixture = _realFixtureDirectory();
      final harness = await _Harness.create(fixture.parent);

      final first = await harness.service.openProject(fixture.path);
      final second = await harness.service.openProject(fixture.path);

      expect(second.fingerprint, first.fingerprint);
      expect(second.projectHandle, isNot(first.projectHandle));
    });

    test('rejects malformed project JSON with a safe code', () async {
      final sandbox = await Directory.systemTemp.createTemp(
        'pokemap_open_invalid_',
      );
      addTearDown(() => sandbox.delete(recursive: true));
      final project = await Directory(_join(sandbox.path, 'project')).create();
      await File(_join(project.path, 'project.json')).writeAsString('{broken');
      final harness = await _Harness.create(sandbox);

      await expectLater(
        () => harness.service.openProject(project.path),
        throwsA(
          isA<ProjectOpenException>()
              .having(
                (error) => error.code,
                'code',
                'project.manifest_invalid',
              )
              .having(
                (error) => error.toString(),
                'safe message',
                isNot(contains(project.path)),
              ),
        ),
      );
    });

    test('rejects an unknown project handle', () {
      var token = 0;
      final handles = WorkspaceHandleStore(
        clock: () => DateTime.utc(2026, 7, 31, 12),
        tokenFactory: (prefix) => '$prefix${token++}',
        ttl: const Duration(minutes: 5),
      );

      expect(
        () => handles.resolveProject(
          const ProjectHandle('prj_unknown'),
        ),
        throwsA(
          isA<WorkspaceHandleException>().having(
            (error) => error.code,
            'code',
            'workspace.handle_unknown',
          ),
        ),
      );
    });

    test('rejects and removes an expired project handle', () async {
      final fixture = _realFixtureDirectory();
      final harness = await _Harness.create(fixture.parent);
      final opened = await harness.service.openProject(fixture.path);
      final retainedAccess =
          harness.handles.resolveProject(opened.projectHandle);
      harness.now = harness.now.add(const Duration(minutes: 6));

      await expectLater(
        () => retainedAccess.readBytes('project.json'),
        throwsA(
          isA<WorkspaceHandleException>().having(
            (error) => error.code,
            'code',
            'workspace.handle_expired',
          ),
        ),
      );
      expect(
        () => harness.handles.resolveProject(opened.projectHandle),
        throwsA(
          isA<WorkspaceHandleException>().having(
            (error) => error.code,
            'code',
            'workspace.handle_unknown',
          ),
        ),
      );
    });

    test('closes a workspace idempotently and invalidates its project',
        () async {
      final fixture = _realFixtureDirectory();
      final harness = await _Harness.create(fixture.parent);
      final opened = await harness.service.openProject(fixture.path);
      final retainedAccess =
          harness.handles.resolveProject(opened.projectHandle);

      expect(
        harness.service.closeWorkspace(opened.workspaceHandle),
        isTrue,
      );
      expect(
        harness.service.closeWorkspace(opened.workspaceHandle),
        isFalse,
      );
      expect(
        () => harness.handles.resolveProject(opened.projectHandle),
        throwsA(isA<WorkspaceHandleException>()),
      );
      await expectLater(
        () => retainedAccess.readBytes('project.json'),
        throwsA(
          isA<WorkspaceHandleException>().having(
            (error) => error.code,
            'code',
            'workspace.handle_unknown',
          ),
        ),
      );
    });
  });
}

final class _Harness {
  _Harness._({
    required this.policy,
    required this.handles,
    required this.service,
    required _MutableClock clock,
  }) : _clock = clock;

  static Future<_Harness> create(Directory allowedRoot) async {
    var token = 0;
    final clock = _MutableClock(DateTime.utc(2026, 7, 31, 12));
    final reader = const LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [allowedRoot.path],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore(
      clock: () => clock.value,
      tokenFactory: (prefix) => '$prefix${token++}',
      ttl: const Duration(minutes: 5),
    );
    return _Harness._(
      policy: policy,
      handles: handles,
      service: ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
      ),
      clock: clock,
    );
  }

  final WorkspacePolicy policy;
  final WorkspaceHandleStore handles;
  final ProjectOpenService service;
  final _MutableClock _clock;

  DateTime get now => _clock.value;

  set now(DateTime value) => _clock.value = value;
}

final class _MutableClock {
  _MutableClock(this.value);

  DateTime value;
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
]) =>
    [
      first,
      second,
      if (third != null) third,
      if (fourth != null) fourth,
    ].join(Platform.pathSeparator);
