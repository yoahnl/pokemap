import 'package:avelune_studio/app/di/providers.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/controlled_project_session_port.dart';
import '../support/map_workspace_fixture.dart';

void main() {
  test(
    'root session survives listener changes and closes exactly once',
    () async {
      final port = ControlledProjectSessionPort();
      final container = ProviderContainer(
        overrides: [projectSessionPortProvider.overrideWithValue(port)],
      );
      final first = container.listen(
        projectSessionControllerProvider,
        (_, _) {},
      );
      final controller = first.read();
      final opening = controller.open(exampleA.directoryPath);
      port.pending.single.complete(exampleA);
      await opening;

      first.close();
      await container.pump();
      final second = container.listen(
        projectSessionControllerProvider,
        (_, _) {},
      );
      expect(second.read(), same(controller));
      expect(
        container.read(projectSessionControllerProvider),
        same(controller),
      );
      expect(controller.state.project, same(exampleA));
      expect(port.requests, [exampleA.directoryPath]);
      expect(port.released, isEmpty);

      container.dispose();
      await controller.dispose();
      expect(controller.disposed, isTrue);
      expect(port.released, [exampleA]);
    },
  );

  test(
    'disposing the root releases a late opening result exactly once',
    () async {
      final port = ControlledProjectSessionPort();
      final container = ProviderContainer(
        overrides: [projectSessionPortProvider.overrideWithValue(port)],
      );
      final controller = container.read(projectSessionControllerProvider);
      final opening = controller.open(exampleA.directoryPath);

      container.dispose();
      expect(controller.disposed, isTrue);
      expect(port.released, isEmpty);
      port.pending.single.complete(exampleA);
      await opening;
      await controller.dispose();

      expect(controller.state.project, isNull);
      expect(port.released, [exampleA]);
    },
  );

  test(
    'workspace scopes isolate projects and separate session instances',
    () async {
      final reopenedA = ProjectSession(
        sessionId: exampleA.sessionId,
        name: exampleA.name,
        directoryPath: exampleA.directoryPath,
      );
      final portA = WorkspaceMemoryPort();
      final portB = WorkspaceMemoryPort();
      final reopenedPort = WorkspaceMemoryPort();
      final container = ProviderContainer(
        overrides: [
          mapWorkspacePortProvider(exampleA).overrideWithValue(portA),
          mapWorkspacePortProvider(exampleB).overrideWithValue(portB),
          mapWorkspacePortProvider(reopenedA).overrideWithValue(reopenedPort),
        ],
      );
      addTearDown(container.dispose);
      final subscriptionA = container.listen(
        mapWorkspaceControllerProvider(exampleA),
        (_, _) {},
      );
      final subscriptionB = container.listen(
        mapWorkspaceControllerProvider(exampleB),
        (_, _) {},
      );
      final reopenedSubscription = container.listen(
        mapWorkspaceControllerProvider(reopenedA),
        (_, _) {},
      );
      final controllerA = subscriptionA.read();
      final controllerB = subscriptionB.read();
      final reopenedController = reopenedSubscription.read();
      await Future.wait([
        controllerA.initialize(),
        controllerB.initialize(),
        reopenedController.initialize(),
      ]);

      expect(controllerA, isNot(same(controllerB)));
      expect(controllerA, isNot(same(reopenedController)));
      expect(controllerA.session, same(exampleA));
      expect(controllerB.session, same(exampleB));
      expect(reopenedController.session, same(reopenedA));
      final documentA = controllerA.active!;
      documentA.commit(documentA.current.copyWith(name: 'Modification A'));
      expect(controllerA.dirty, isTrue);
      expect(controllerB.dirty, isFalse);
      expect(reopenedController.dirty, isFalse);
      expect(await controllerA.save(documentA), isTrue);
      expect(portA.writes, 1);
      expect(portB.writes, 0);
      expect(reopenedPort.writes, 0);
    },
  );

  test(
    'unmounting the last workspace listener disposes and recreates its scope',
    () async {
      final port = WorkspaceMemoryPort();
      final container = ProviderContainer(
        overrides: [
          mapWorkspacePortProvider(workspaceSession).overrideWithValue(port),
        ],
      );
      addTearDown(container.dispose);
      final provider = mapWorkspaceControllerProvider(workspaceSession);
      final first = container.listen(provider, (_, _) {});
      final second = container.listen(provider, (_, _) {});
      final previous = first.read();
      await previous.initialize();
      final document = previous.active!;
      document.commit(
        document.current.copyWith(name: 'Modification abandonnée'),
      );

      first.close();
      await container.pump();
      expect(second.read(), same(previous));
      expect(second.read().dirty, isTrue);
      second.close();
      await container.pump();

      expect(await previous.save(document), isFalse);
      expect(await previous.saveAll(), isFalse);
      expect(port.writes, 0);
      final replacement = container.listen(provider, (_, _) {});
      final current = replacement.read();
      expect(current, isNot(same(previous)));
      await current.initialize();
      expect(current.dirty, isFalse);
      expect(current.active!.current.name, workspaceEntries.first.id);
      expect(port.reads, 2);

      final currentDocument = current.active!;
      currentDocument.commit(
        currentDocument.current.copyWith(name: 'Modification conservée'),
      );
      expect(await current.save(currentDocument), isTrue);
      expect(port.writes, 1);
    },
  );
}
