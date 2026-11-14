import 'package:avelune_studio/features/project_session/application/project_opening_progress.dart';
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

  test('opening reports the session phases it went through', () async {
    final opening = controller.open('/example/requested');
    final progress = controller.state.progress!;
    expect(
      progress[ProjectOpeningPhase.project].status,
      ProjectOpeningStepStatus.running,
    );

    port.phaseReporters.single!(ProjectOpeningPhase.workshop);
    expect(
      progress[ProjectOpeningPhase.project].status,
      ProjectOpeningStepStatus.done,
    );
    expect(
      progress[ProjectOpeningPhase.workshop].status,
      ProjectOpeningStepStatus.running,
    );

    port.pending.single.complete(exampleA);
    await opening;

    expect(controller.state.progress, same(progress));
    expect(
      progress[ProjectOpeningPhase.workshop].status,
      ProjectOpeningStepStatus.done,
    );
    expect(
      progress[ProjectOpeningPhase.map].status,
      ProjectOpeningStepStatus.pending,
    );
    for (final phase in const [
      ProjectOpeningPhase.narrativeTitles,
      ProjectOpeningPhase.narrativeUsages,
    ]) {
      expect(progress[phase].status, ProjectOpeningStepStatus.skipped);
    }
  });

  test('narrative indexes prepared at opening finish as phases', () async {
    final opening = controller.open('/example/requested');
    final progress = controller.state.progress!;
    final report = port.phaseReporters.single!;

    report(ProjectOpeningPhase.workshop);
    report(ProjectOpeningPhase.narrativeTitles);
    expect(
      progress[ProjectOpeningPhase.workshop].status,
      ProjectOpeningStepStatus.done,
    );
    report(ProjectOpeningPhase.narrativeUsages);
    expect(
      progress[ProjectOpeningPhase.narrativeTitles].status,
      ProjectOpeningStepStatus.done,
    );
    expect(
      progress[ProjectOpeningPhase.narrativeUsages].status,
      ProjectOpeningStepStatus.running,
    );

    port.pending.single.complete(exampleA);
    await opening;

    expect(
      progress[ProjectOpeningPhase.narrativeUsages].status,
      ProjectOpeningStepStatus.done,
    );
    expect(progress[ProjectOpeningPhase.narrativeUsages].elapsed, isNotNull);
  });

  test('a superseded opening no longer moves its progress', () async {
    final first = controller.open('/example/a');
    final stale = controller.state.progress!;
    final second = controller.open('/example/b');

    port.phaseReporters.first!(ProjectOpeningPhase.workshop);
    expect(
      stale[ProjectOpeningPhase.workshop].status,
      ProjectOpeningStepStatus.pending,
    );

    port.pending.first.complete(exampleA);
    port.pending.last.complete(exampleB);
    await Future.wait([first, second]);
    expect(controller.state.project, same(exampleB));
    expect(controller.state.progress, isNot(same(stale)));
  });

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
