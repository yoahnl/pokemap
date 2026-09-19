import 'dart:async';

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

  test('late A is released without replacing or closing ready B', () async {
    final first = controller.open('/example/a');
    final second = controller.open('/example/b');
    port.pending[1].complete(exampleB);
    await second;
    port.pending[0].complete(exampleA);
    await first;

    expect(controller.state.project, same(exampleB));
    expect(controller.state.status, ProjectSessionStatus.ready);
    expect(port.released, [exampleA]);
  });

  test('late A failure leaves ready B unchanged', () async {
    final first = controller.open('/example/a');
    final second = controller.open('/example/b');
    port.pending[1].complete(exampleB);
    await second;
    port.pending[0].completeError(
      const ProjectOpenFailure(ProjectOpenProblem.manifestInvalid),
    );
    await first;

    expect(controller.state.project, same(exampleB));
    expect(controller.state.problem, isNull);
    expect(port.released, isEmpty);
  });

  test(
    'close during a read releases its late success and stays idle',
    () async {
      final opening = controller.open('/example/a');
      await controller.close();
      port.pending.single.complete(exampleA);
      await opening;

      expect(controller.state.status, ProjectSessionStatus.idle);
      expect(controller.state.project, isNull);
      expect(port.released, [exampleA]);
    },
  );

  test('close during a read ignores its late failure', () async {
    final opening = controller.open('/example/a');
    await controller.close();
    port.pending.single.completeError(
      const ProjectOpenFailure(ProjectOpenProblem.accessDenied),
    );
    await opening;

    expect(controller.state.status, ProjectSessionStatus.idle);
    expect(controller.state.problem, isNull);
  });

  test(
    'dispose rejects late success without notifying detached views',
    () async {
      var calls = 0;
      controller.addListener(() => calls++);
      final opening = controller.open('/example/a');
      await controller.dispose();
      final callsAtDisposal = calls;
      port.pending.single.complete(exampleA);
      await opening;

      expect(controller.disposed, isTrue);
      expect(controller.state.project, isNull);
      expect(port.released, [exampleA]);
      expect(calls, callsAtDisposal);
    },
  );

  test(
    'opening B retains A and a failed replacement leaves A available',
    () async {
      final first = controller.open('/example/a');
      port.pending.single.complete(exampleA);
      await first;
      final second = controller.open('/example/b');
      expect(controller.state.status, ProjectSessionStatus.opening);
      expect(controller.state.project, same(exampleA));
      expect(controller.state.requestedPath, '/example/b');
      expect(port.released, isEmpty);
      port.pending.last.completeError(
        const ProjectOpenFailure(ProjectOpenProblem.manifestMissing),
      );
      await second;

      expect(controller.state.status, ProjectSessionStatus.failed);
      expect(controller.state.project, same(exampleA));
      expect(port.released, isEmpty);
    },
  );

  test(
    'close while replacing releases previous and late candidate once each',
    () async {
      final first = controller.open('/example/a');
      port.pending.single.complete(exampleA);
      await first;
      final second = controller.open('/example/b');
      await controller.close();
      port.pending.last.complete(exampleB);
      await second;

      expect(port.requests, ['/example/a', '/example/b']);
      expect(port.released, [exampleA, exampleB]);
      expect(controller.state.status, ProjectSessionStatus.idle);
    },
  );

  test('successful replacement publishes B before releasing A', () async {
    final first = controller.open('/example/a');
    port.pending.single.complete(exampleA);
    await first;
    port.releaseGate = Completer<void>();
    final second = controller.open('/example/b');
    expect(port.released, isEmpty);
    port.pending.last.complete(exampleB);
    await Future<void>.delayed(Duration.zero);
    expect(controller.state.status, ProjectSessionStatus.ready);
    expect(controller.state.project, same(exampleB));
    expect(port.released, [exampleA]);
    port.releaseGate!.complete();
    await second;
  });

  test('cancel keeps A ready and closes late B', () async {
    final first = controller.open('/example/a');
    port.pending.single.complete(exampleA);
    await first;
    final second = controller.open('/example/b');
    controller.cancelOpening();
    expect(controller.state.status, ProjectSessionStatus.ready);
    expect(controller.state.project, same(exampleA));
    expect(controller.state.requestedPath, exampleA.directoryPath);
    expect(port.released, isEmpty);
    port.pending.last.complete(exampleB);
    await second;
    expect(controller.state.project, same(exampleA));
    expect(port.released, [exampleB]);
  });

  test(
    'cancel without previous project stays idle after late failure',
    () async {
      final opening = controller.open('/example/b');
      controller.cancelOpening();
      port.pending.single.completeError(
        const ProjectOpenFailure(ProjectOpenProblem.manifestInvalid),
      );
      await opening;
      expect(controller.state.status, ProjectSessionStatus.idle);
      expect(controller.state.project, isNull);
      expect(controller.state.problem, isNull);
      expect(port.released, isEmpty);
    },
  );

  test(
    'dispose while replacing releases previous and late candidate',
    () async {
      final first = controller.open('/example/a');
      port.pending.single.complete(exampleA);
      await first;
      final second = controller.open('/example/b');
      await controller.dispose();
      expect(port.released, [exampleA]);
      port.pending.last.complete(exampleB);
      await second;
      expect(port.released, [exampleA, exampleB]);
      expect(controller.state.project, isNull);
    },
  );

  test('latest replacement failure retains A despite older success', () async {
    final first = controller.open('/example/a');
    port.pending.single.complete(exampleA);
    await first;
    final second = controller.open('/example/b');
    final third = controller.open('/example/broken');
    port.pending.last.completeError(
      const ProjectOpenFailure(ProjectOpenProblem.manifestMissing),
    );
    await third;
    port.pending[1].complete(exampleB);
    await second;
    expect(controller.state.status, ProjectSessionStatus.failed);
    expect(controller.state.project, same(exampleA));
    expect(port.released, [exampleB]);
    await controller.close();
    expect(port.released, [exampleB, exampleA]);
  });
}
