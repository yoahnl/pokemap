import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/project_session/application/project_session_controller.dart';
import 'package:avelune_studio/features/project_session/application/project_session_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/controlled_project_session_port.dart';

void main() {
  late ControlledProjectSessionPort port;
  late ProjectSessionController controller;

  setUp(() {
    port = ControlledProjectSessionPort();
    controller = ProjectSessionController(port);
  });

  tearDown(() async {
    await controller.dispose();
  });

  test('starts idle without reading a project', () {
    expect(controller.state.status, ProjectSessionStatus.idle);
    expect(controller.state.project, isNull);
    expect(port.requests, isEmpty);
    expect(controller.disposed, isFalse);
  });

  test(
    'opens the requested project and propagates its actual identity',
    () async {
      final states = <ProjectSessionState>[];
      controller.addListener(() => states.add(controller.state));

      final opening = controller.open('/example/requested');
      expect(controller.state.status, ProjectSessionStatus.opening);
      expect(controller.state.requestedPath, '/example/requested');
      expect(controller.state.project, isNull);
      expect(port.requests, ['/example/requested']);

      port.pending.single.complete(exampleA);
      await opening;

      expect(controller.state.status, ProjectSessionStatus.ready);
      expect(controller.state.project, same(exampleA));
      expect(controller.state.project?.name, 'Exemple A');
      expect(controller.state.project?.directoryPath, '/example/a');
      expect(controller.state.problem, isNull);
      expect(states.map((state) => state.status), [
        ProjectSessionStatus.opening,
        ProjectSessionStatus.ready,
      ]);
    },
  );

  test('closes its current session exactly once and resets state', () async {
    final opening = controller.open('/example/a');
    port.pending.single.complete(exampleA);
    await opening;

    await controller.close();
    await controller.close();

    expect(controller.state.status, ProjectSessionStatus.idle);
    expect(controller.state.project, isNull);
    expect(controller.state.requestedPath, isNull);
    expect(controller.state.problem, isNull);
    expect(port.released, [exampleA]);
  });

  for (final problem in ProjectOpenProblem.values) {
    test('exposes $problem and allows an explicit retry', () async {
      final opening = controller.open('/example/broken');
      port.pending.single.completeError(ProjectOpenFailure(problem));
      await opening;

      expect(controller.state.status, ProjectSessionStatus.failed);
      expect(controller.state.problem, problem);
      expect(controller.state.requestedPath, '/example/broken');
      expect(controller.state.project, isNull);
      expect(port.requests, ['/example/broken']);

      final retry = controller.open('/example/a');
      port.pending.last.complete(exampleA);
      await retry;

      expect(controller.state.project, same(exampleA));
      expect(controller.state.problem, isNull);
      expect(port.requests, ['/example/broken', '/example/a']);
    });
  }

  test('maps an unexpected read error to an explicit failure', () async {
    final opening = controller.open('/example/a');
    port.pending.single.completeError(StateError('unexpected read failure'));
    await opening;

    expect(controller.state.status, ProjectSessionStatus.failed);
    expect(controller.state.problem, ProjectOpenProblem.readFailed);
    expect(controller.state.project, isNull);
  });

  test('removing a listener stops future notifications', () async {
    var calls = 0;
    void listener() => calls++;
    controller.addListener(listener);
    final opening = controller.open('/example/a');
    expect(calls, 1);
    controller.removeListener(listener);
    port.pending.single.complete(exampleA);
    await opening;
    await controller.close();
    expect(calls, 1);
  });

  test('reading the projection never reopens the loaded project', () async {
    final opening = controller.open('/example/a');
    port.pending.single.complete(exampleA);
    await opening;

    for (var i = 0; i < 20; i++) {
      expect(controller.state.project, same(exampleA));
    }

    expect(port.requests, ['/example/a']);
    expect(port.released, isEmpty);
  });

  test(
    'dispose releases the active session and rejects future opens',
    () async {
      final opening = controller.open('/example/a');
      port.pending.single.complete(exampleA);
      await opening;
      await controller.dispose();
      await controller.dispose();

      expect(controller.disposed, isTrue);
      expect(controller.state.project, isNull);
      expect(port.released, [exampleA]);
      await expectLater(controller.open('/example/b'), throwsStateError);
      expect(port.requests, ['/example/a']);
    },
  );
}
