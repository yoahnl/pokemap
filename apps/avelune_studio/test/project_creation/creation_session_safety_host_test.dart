import 'dart:async';
import 'dart:io';

import 'package:avelune_studio/features/project_session/application/project_session_controller.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_workflow.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_local.dart';

import '../support/project_creation_workspace_fixture.dart';
import '../support/real_test_io.dart';
import '../support/synthetic_template_fixture.dart';

void main() {
  Future<ProjectCreationWorkspaceFixture> fixture(WidgetTester tester) async {
    final parent = (await RealTestIo.run(
      tester,
      () => Directory.systemTemp.createTemp('creation-session-'),
    ))!;
    final fixture = ProjectCreationWorkspaceFixture(
      tester,
      parent,
      File('${parent.path}/demo.avelunegame'),
    );
    addTearDown(() async {
      await fixture.dispose();
      await RealTestIo.run(tester, () => parent.delete(recursive: true));
    });
    return fixture;
  }

  testWidgets('created project switch preserves a cancelled narrative draft', (
    tester,
  ) async {
    final host = await fixture(tester);
    await host.mount(withNarrative: true);
    await host.create(32, name: 'Projet A');
    final session = host.session.state.project!;
    final manifestFile = File('${session.directoryPath}/project.json');
    final before = (await RealTestIo.run(tester, manifestFile.readAsBytes))!;
    final owner = host.viewport!.sessions.narrative!;
    owner.addStory('Histoire en cours', ['Une étape encore non publiée']);
    final draft = owner.pendingStories.values.single;
    await host.pump();
    expect(owner.dirty, isTrue);
    expect(host.maps.dirty, isFalse);
    host.closeChoice = WorkspaceCloseChoice.cancel;
    await host.submitCreation(32, name: 'Projet B');
    expect(host.creator!.openError, contains('Projet créé et conservé'));
    expect(host.session.state.project, same(session));
    expect(owner.pendingStories.values.single, same(draft));
    expect(owner.dirty, isTrue);
    expect(
      await RealTestIo.run(tester, manifestFile.readAsBytes),
      orderedEquals(before),
    );
    expect(await host.closeCreation(), isTrue);
    expect(host.viewport!.sessions.narrative, same(owner));
    expect(owner.pendingStories[draft.id], same(draft));
    expect(owner.dirty, isTrue);
    expect(
      await RealTestIo.run(tester, manifestFile.readAsBytes),
      orderedEquals(before),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'late canonical creation cannot open in a replaced session owner',
    (tester) async {
      final host = await fixture(tester);
      final replacement = ProjectSessionController(
        LocalProjectSessionAdapter(),
      );
      final targetPath = (await RealTestIo.run(tester, () async {
        final receipt = await const LocalProjectCreationService().create(
          ProjectCreationRequest(
            name: 'Projet B',
            folderName: 'projet-b',
            parentPath: host.parent.path,
          ),
        );
        return receipt.projectPath;
      }))!;
      final reached = Zone.root.run(() => Completer<void>());
      final release = Zone.root.run(() => Completer<void>());
      final service = _ObservedCreationPort(
        LocalProjectCreationService(
          templateCatalog: fixtureTemplateCatalog,
          readTemplate: readSyntheticTemplate,
          checkpoint: (point, _) async {
            if (point == ProjectCreationCheckpoint.beforeReservation) {
              reached.complete();
              await release.future;
            }
          },
        ),
      );
      await host.mount(creationPort: service, bridgeCreate: false);
      final previous = host.session;
      addTearDown(previous.dispose);
      addTearDown(() {
        if (!release.isCompleted) release.complete();
      });
      await host.submitCreation(32, name: 'Ancienne création', confirm: false);
      final pending = Zone.root.run(host.performCreation);
      await RealTestIo.run(tester, () => reached.future);
      expect(host.parent.listSync().whereType<Directory>(), hasLength(1));
      await host.mount(
        creationPort: service,
        sessionController: replacement,
        settle: false,
        bridgeCreate: false,
      );
      expect(host.session.state.project, isNull);
      await RealTestIo.run(tester, () => replacement.open(targetPath));
      await host.mountCurrent();
      final target = replacement.state.project!;
      expect(host.maps.project!.name, 'Projet B');
      release.complete();
      await RealTestIo.run(tester, () => service.completed.future);
      expect(await RealTestIo.run(tester, () => pending), isFalse);
      await host.pump();
      expect(reached.isCompleted, isTrue);
      expect(host.session.state.project, same(target));
      expect(previous.state.project, isNull);
      expect(host.creator!.receipt, isNotNull);
      expect(host.creator!.openError, contains('Projet créé et conservé'));
      expect(host.parent.listSync().whereType<Directory>(), hasLength(2));
      expect(
        (await host.recents.load()).any(
          (entry) => entry.name == 'Ancienne création',
        ),
        isFalse,
      );
      expect(await host.closeCreation(), isTrue);
      expect(host.session.state.project, same(target));
      expect(host.maps.session, same(target));
      expect(host.maps.project!.name, 'Projet B');
      expect(tester.takeException(), isNull);
    },
  );
}

class _ObservedCreationPort implements ProjectCreationPort {
  _ObservedCreationPort(this.delegate);
  final ProjectCreationPort delegate;
  @override
  ProjectTemplateCatalog get templateCatalog => delegate.templateCatalog;
  final completed = Zone.root.run(() => Completer<void>());
  @override
  Future<List<int>?> preview(ProjectCreationRequest request) =>
      delegate.preview(request);
  @override
  Future<String> validateDestination(ProjectCreationRequest request) =>
      delegate.validateDestination(request);
  @override
  Future<ProjectCreationReceipt> create(
    ProjectCreationRequest request, {
    void Function(ProjectCreationPhase)? onPhase,
    bool Function()? isCancelled,
    String? expectedDestination,
  }) async {
    try {
      return await delegate.create(
        request,
        onPhase: onPhase,
        isCancelled: isCancelled,
        expectedDestination: expectedDestination,
      );
    } finally {
      completed.complete();
    }
  }
}
