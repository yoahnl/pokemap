import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/platform/files/scoped_project_session_adapter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('map_editor/file_access');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'activates access before opening and remembers the canonical path',
    () async {
      final calls = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add('${call.method}:${(call.arguments as Map)['path']}');
            return true;
          });
      final delegate = _RecordingProjectSessionPort(calls);
      final adapter = ScopedProjectSessionAdapter(delegate);

      final session = await adapter.open('/selected/project');
      await adapter.close(session);

      expect(calls, [
        'activateProjectDirectory:/selected/project',
        'open:/selected/project',
        'rememberProjectDirectory:/canonical/project',
        'activateProjectDirectory:/canonical/project',
        'close:/canonical/project',
      ]);
    },
  );

  test('does not remember a project that fails to open', () async {
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          return true;
        });
    final adapter = ScopedProjectSessionAdapter(
      _RecordingProjectSessionPort(calls, failOpen: true),
    );

    await expectLater(
      adapter.open('/invalid/project'),
      throwsA(isA<ProjectOpenFailure>()),
    );
    expect(calls, ['activateProjectDirectory', 'open:/invalid/project']);
  });

  test(
    'new project acquires its own grant before the parent is released',
    () async {
      final calls = <String>[];
      final bookmarks = <String>{};
      final activeProjects = <String>{};
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            final path = (call.arguments as Map)['path'] as String;
            calls.add('${call.method}:$path');
            if (call.method == 'rememberProjectDirectory') {
              bookmarks.add(path);
              return true;
            }
            if (bookmarks.contains(path)) {
              activeProjects.add(path);
              return true;
            }
            return false;
          });
      final adapter = ScopedProjectSessionAdapter(
        _RecordingProjectSessionPort(calls),
      );

      final session = await adapter.open('/selected/project');

      expect(activeProjects, contains(session.directoryPath));
      expect(calls, [
        'activateProjectDirectory:/selected/project',
        'open:/selected/project',
        'rememberProjectDirectory:/canonical/project',
        'activateProjectDirectory:/canonical/project',
      ]);
    },
  );

  test('opens a valid project when the native bridge is unavailable', () async {
    final calls = <String>[];
    final adapter = ScopedProjectSessionAdapter(
      _RecordingProjectSessionPort(calls),
    );

    final session = await adapter.open('/selected/project');

    expect(session.directoryPath, '/canonical/project');
    expect(calls, ['open:/selected/project']);
  });
}

final class _RecordingProjectSessionPort implements ProjectSessionPort {
  _RecordingProjectSessionPort(this.calls, {this.failOpen = false});

  final List<String> calls;
  final bool failOpen;

  @override
  Future<ProjectSession> open(String directoryPath) async {
    calls.add('open:$directoryPath');
    if (failOpen) {
      throw const ProjectOpenFailure(ProjectOpenProblem.manifestInvalid);
    }
    return const ProjectSession(
      sessionId: 'session',
      name: 'Project',
      directoryPath: '/canonical/project',
    );
  }

  @override
  Future<void> close(ProjectSession session) async {
    calls.add('close:${session.directoryPath}');
  }
}
