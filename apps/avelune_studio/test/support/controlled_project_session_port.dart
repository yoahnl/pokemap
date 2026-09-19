import 'dart:async';

import 'package:avelune_studio/src/features/project_session/application/project_session.dart';

class ControlledProjectSessionPort implements ProjectSessionPort {
  final requests = <String>[];
  final pending = <Completer<ProjectSession>>[];
  final released = <ProjectSession>[];
  Completer<void>? releaseGate;

  @override
  Future<ProjectSession> open(String directoryPath) {
    requests.add(directoryPath);
    final result = Completer<ProjectSession>();
    pending.add(result);
    return result.future;
  }

  @override
  Future<void> close(ProjectSession session) async {
    released.add(session);
    await releaseGate?.future;
  }
}

const exampleA = ProjectSession(
  sessionId: 'example-session-a',
  name: 'Exemple A',
  directoryPath: '/example/a',
);

const exampleB = ProjectSession(
  sessionId: 'example-session-b',
  name: 'Exemple B',
  directoryPath: '/example/b',
);
