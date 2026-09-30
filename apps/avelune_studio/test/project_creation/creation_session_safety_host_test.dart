import 'dart:async';
import 'dart:io';

import 'package:avelune_studio/features/project_session/application/project_session_controller.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/presentation/features/narrative/narrative_story_pane.dart';
import 'package:avelune_studio/presentation/features/project_creation/project_creation_dialog.dart';
import 'package:avelune_studio/presentation/shared/widgets/layout/studio_primary_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_local.dart';

import '../support/m2_ui_fixture.dart' show pumpIo;
import '../support/project_creation_workspace_fixture.dart';

void main() {
  Future<ProjectCreationWorkspaceFixture> fixture(WidgetTester tester) async {
    final parent = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('creation-session-'),
    ))!;
    final fixture = ProjectCreationWorkspaceFixture(
      tester,
      parent,
      File('${parent.path}/demo.avelunegame'),
    );
    addTearDown(() async {
      await fixture.dispose();
      await tester.runAsync(() => parent.delete(recursive: true));
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
    final before = (await tester.runAsync(manifestFile.readAsBytes))!;
    await tester.tap(
      find.descendant(
        of: find.byType(StudioPrimaryNavigation),
        matching: find.byTooltip('Histoire'),
      ),
    );
    await pumpIo(tester, frames: 12);
    final owner = tester
        .widget<NarrativeStoryPane>(find.byType(NarrativeStoryPane))
        .controller;
    owner.addStory('Histoire en cours', ['Une étape encore non publiée']);
    final draft = owner.pendingStories.values.single;
    await pumpIo(tester, frames: 4);
    expect(owner.dirty, isTrue);
    expect(host.maps.dirty, isFalse);
    await tester.tap(find.text('Accueil'));
    await pumpIo(tester, frames: 12);
    await host.submitCreation(16, name: 'Projet B');
    expect(find.text('Conserver vos modifications ?'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Annuler'),
      ),
    );
    await pumpIo(tester, frames: 12);
    expect(host.session.state.project, same(session));
    expect(owner.pendingStories.values.single, same(draft));
    expect(owner.dirty, isTrue);
    expect(
      await tester.runAsync(manifestFile.readAsBytes),
      orderedEquals(before),
    );
    await tester.tap(find.byKey(const ValueKey('creation-close')));
    await pumpIo(tester, frames: 8);
    await tester.tap(find.text('Reprendre mon projet'));
    await pumpIo(tester, frames: 12);
    await tester.tap(
      find.descendant(
        of: find.byType(StudioPrimaryNavigation),
        matching: find.byTooltip('Histoire'),
      ),
    );
    await pumpIo(tester, frames: 12);
    expect(
      tester
          .widget<NarrativeStoryPane>(find.byType(NarrativeStoryPane))
          .controller,
      same(owner),
    );
    expect(owner.pendingStories[draft.id], same(draft));
    expect(owner.dirty, isTrue);
    expect(
      await tester.runAsync(manifestFile.readAsBytes),
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
      final targetPath = (await tester.runAsync(() async {
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
      await host.submitCreation(48, name: 'Ancienne création', confirm: false);
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const ValueKey('create-project-confirm')));
        await reached.future;
        expect(host.parent.listSync().whereType<Directory>().length, 1);
        await host.mount(
          creationPort: service,
          sessionController: replacement,
          settle: false,
          bridgeCreate: false,
        );
        expect(host.session.state.project, isNull);
      });
      await tester.runAsync(() => replacement.open(targetPath));
      await pumpIo(tester, frames: 12);
      final target = replacement.state.project!;
      expect(host.maps.project!.name, 'Projet B');
      release.complete();
      await tester.runAsync(() => service.completed.future);
      await tester.pumpAndSettle();
      expect(reached.isCompleted, isTrue);
      expect(host.session.state.project, same(target));
      expect(previous.state.project, isNull);
      expect(find.byType(ProjectCreationDialog), findsOneWidget);
      expect(find.textContaining('Projet créé et conservé'), findsOneWidget);
      expect(host.parent.listSync().whereType<Directory>().length, 2);
      expect(
        (await host.recents.load()).any(
          (entry) => entry.name == 'Ancienne création',
        ),
        isFalse,
      );
      await tester.tap(find.byKey(const ValueKey('creation-close')));
      await pumpIo(tester, frames: 8);
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
