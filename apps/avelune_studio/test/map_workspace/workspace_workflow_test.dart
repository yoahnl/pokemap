import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_workflow.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  late WorkspaceMemoryPort port;
  late MapWorkspaceController controller;
  late WorkspaceWorkflow workflow;
  late WorkspaceCloseChoice choice;
  late List<String> launches;
  late int closePrompts;
  late int focusFlushes;

  setUp(() async {
    port = WorkspaceMemoryPort();
    controller = MapWorkspaceController(workspaceSession, port);
    await controller.initialize();
    choice = WorkspaceCloseChoice.cancel;
    launches = [];
    closePrompts = 0;
    focusFlushes = 0;
    workflow = WorkspaceWorkflow(
      controller: controller,
      isActive: () => true,
      changed: () {},
      resources: () => null,
      narrative: () => null,
      confirmClose: () async {
        closePrompts++;
        return choice;
      },
      flushFocus: () => focusFlushes++,
      launchMap: (entry, revision) async {
        expect(controller.active!.dirty, isFalse);
        expect(revision, controller.active!.base.revision);
        launches.add('map:${entry.id}');
      },
      launchGame: () async => launches.add('game'),
    );
  });

  tearDown(() => controller.dispose());

  test(
    'map test saves the real draft before invoking the launch port',
    () async {
      final document = controller.active!;
      document.commit(document.current.copyWith(name: 'Carte modifiée'));

      await workflow.test();

      expect(port.writes, 1);
      expect(port.saved[document.current.id]!.name, 'Carte modifiée');
      expect(launches, ['map:${document.current.id}']);
      expect(workflow.testing, isFalse);
      expect(focusFlushes, greaterThan(0));
    },
  );

  test('failed persistence retains the draft and never launches', () async {
    final document = controller.active!;
    document.commit(document.current.copyWith(name: 'Brouillon conservé'));
    port.failSave = true;

    await workflow.test();

    expect(document.dirty, isTrue);
    expect(document.current.name, 'Brouillon conservé');
    expect(launches, isEmpty);
    expect(workflow.testing, isFalse);
    expect(document.error, isNotNull);
  });

  test('cancel and discard decisions do not publish the draft', () async {
    final document = controller.active!;
    document.commit(document.current.copyWith(name: 'Décision en attente'));

    expect(await workflow.allowClose(), isFalse);
    expect(document.dirty, isTrue);
    choice = WorkspaceCloseChoice.discard;
    expect(await workflow.allowClose(), isTrue);

    expect(closePrompts, 2);
    expect(port.writes, 0);
    expect(document.current.name, 'Décision en attente');
    expect(workflow.closing, isFalse);
  });

  test('save close decision publishes and removes the pending state', () async {
    final document = controller.active!;
    document.commit(document.current.copyWith(name: 'Carte sauvegardée'));
    choice = WorkspaceCloseChoice.save;

    expect(await workflow.allowClose(), isTrue);

    expect(port.writes, 1);
    expect(port.saved[document.current.id]!.name, 'Carte sauvegardée');
    expect(workflow.hasPendingChanges, isFalse);
    expect(workflow.closing, isFalse);
  });

  test('game and map requests invoke distinct launch ports', () async {
    await workflow.test(fullProject: true);
    await workflow.test();

    expect(launches, ['game', 'map:${controller.active!.current.id}']);
    expect(workflow.testing, isFalse);
  });
}
