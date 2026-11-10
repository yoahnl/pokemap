import 'package:avelune_studio/features/project_session/application/project_session_controller.dart';
import 'package:avelune_studio/features/project_session/application/project_session_reopening.dart';
import 'package:avelune_studio/features/project_session/application/project_session_state.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/controlled_project_session_port.dart';

void main() {
  late ControlledProjectSessionPort port;
  late ProjectSessionController controller;

  const previous = ProjectSession(sessionId: 'recover-before', name: 'A',
    directoryPath: '/example/a', storage: ProjectSessionStorage.workingCatalog,
    recoveryOperationIds: ['pending-operation']);
  const recovered = ProjectSession(sessionId: 'recover-after', name: 'A',
    directoryPath: '/example/a', storage: ProjectSessionStorage.workingCatalog);

  setUp(() async {
    port = ControlledProjectSessionPort();
    controller = ProjectSessionController(port);
    final opening = controller.open(previous.directoryPath);
    port.pending.last.complete(previous);
    await opening;
  });

  tearDown(() => controller.dispose());

  test('recovery opens a fresh session and releases the old handle once', () async {
    final reopening = reopenRecoveredProject(controller, previous);
    expect(port.requests.last, previous.directoryPath);
    port.pending.last.complete(recovered);
    await reopening;
    expect(controller.state.project, same(recovered));
    expect(port.released, [previous]);
  });

  test('failed recovery reopen reports refusal and retains the original session', () async {
    final reopening = reopenRecoveredProject(controller, previous);
    final refused = expectLater(reopening, throwsStateError);
    port.pending.last.completeError(const ProjectOpenFailure(ProjectOpenProblem.readFailed));
    await refused;
    expect(controller.state.status, ProjectSessionStatus.failed);
    expect(controller.state.project, same(previous));
    expect(port.released, isEmpty);
  });

  test('cancelled recovery reopen rejects the stale result and releases only its handle', () async {
    final reopening = reopenRecoveredProject(controller, previous);
    final refused = expectLater(reopening, throwsStateError);
    controller.cancelOpening();
    port.pending.last.complete(recovered);
    await refused;
    expect(controller.state.project, same(previous));
    expect(port.released, [recovered]);
  });

  test('partition reopening requires the working catalog storage contract', () async {
    final reopening = reopenPartitionedProject(controller, previous);
    final refused = expectLater(reopening, throwsStateError);
    port.pending.last.complete(exampleA);
    await refused;
    expect(controller.state.project, same(exampleA));
    expect(port.released, [previous]);
  });

  test('partition reopening accepts the fresh canonical catalog session', () async {
    final reopening = reopenPartitionedProject(controller, previous);
    port.pending.last.complete(recovered);
    await reopening;
    expect(controller.state.project, same(recovered));
    expect(port.released, [previous]);
  });
}
