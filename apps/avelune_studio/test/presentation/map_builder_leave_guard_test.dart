import 'dart:ui' show AppExitResponse;

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/app/di/map_workspace_providers.dart';
import 'package:avelune_studio/app/di/project_session_providers.dart';
import 'package:avelune_studio/app/studio_app.dart';
import 'package:avelune_studio/features/project_session/application/project_session_controller.dart';
import 'package:avelune_studio/features/project_session/application/project_session_open_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/controlled_project_session_port.dart';
import '../support/map_workspace_fixture.dart';
import 'map_builder_leave_guard_harness.dart';

void main() {
  testWidgets('unsaved behaviours show in the header of every space', (
    tester,
  ) async {
    await open(tester);
    await editBehaviour(tester);
    expect(find.text('Non enregistré'), findsOneWidget);

    for (final space in ['construction', 'gameplay', 'ambiance', 'story']) {
      await tester.tap(find.byKey(ValueKey('map-space-$space')));
      await settle(tester);
      expect(find.text('Non enregistré'), findsOneWidget, reason: space);
      expect(
        tester
            .widget<StudioButton>(find.byKey(const ValueKey('studio-save')))
            .onPressed,
        isNotNull,
        reason: space,
      );
    }
  });

  testWidgets('the home entry asks first and Annuler keeps everything', (
    tester,
  ) async {
    await open(tester);
    editMap();
    await tester.pump();

    await goHome(tester);
    expect(find.text('Enregistrer les modifications ?'), findsOneWidget);
    await choose(tester, 'cancel');

    expect(find.byKey(const ValueKey('map-builder')), findsOneWidget);
    expect(sessions.released, isEmpty);
    expect(memory.writes, 0);
    expect(controller().active!.current.name, 'Clairière modifiée');
    expect(find.text('Non enregistré'), findsOneWidget);
  });

  testWidgets('Ne pas enregistrer leaves the project without saving', (
    tester,
  ) async {
    await open(tester);
    editMap();
    await tester.pump();

    await goHome(tester);
    await choose(tester, 'discard');

    expect(sessions.released, [exampleA]);
    expect(find.byKey(const ValueKey('studio-home')), findsOneWidget);
    expect(memory.writes, 0);
    expect(events.published, isEmpty);
  });

  testWidgets('Enregistrer saves the map, then the behaviours, then leaves', (
    tester,
  ) async {
    await open(tester);
    await editBehaviour(tester);
    editMap();
    await tester.pump();

    await goHome(tester);
    await choose(tester, 'save');

    expect(memory.writes, 1);
    expect(events.published, [
      (id: leaveGuardMeeting.id, name: 'meeting', mapWrites: 1),
    ]);
    expect(sessions.released, [exampleA]);
    expect(find.byKey(const ValueKey('studio-home')), findsOneWidget);
  });

  testWidgets('a refused save keeps the project open', (tester) async {
    await open(tester);
    editMap();
    memory.failSave = true;
    await tester.pump();

    await goHome(tester);
    await choose(tester, 'save');

    expect(find.byKey(const ValueKey('map-builder')), findsOneWidget);
    expect(sessions.released, isEmpty);
    expect(find.text('Échec de l’enregistrement'), findsOneWidget);
  });

  testWidgets('a clean project leaves without asking', (tester) async {
    await open(tester);
    await goHome(tester);

    expect(find.byKey(const ValueKey('studio-save-choice')), findsNothing);
    expect(sessions.released, [exampleA]);
  });

  testWidgets('saving while typing commits the field first', (tester) async {
    await open(tester);
    await openMeeting(tester);
    await tester.enterText(nameField(), 'Rencontre');
    await tester.pump();

    await pressWithControl(tester, LogicalKeyboardKey.keyS);

    expect(events.published, [
      (id: leaveGuardMeeting.id, name: 'Rencontre', mapWrites: 0),
    ]);
    expect(find.text('Enregistré'), findsOneWidget);
  });

  testWidgets('the save button commits the field being typed', (tester) async {
    await open(tester);
    editMap();
    await openMeeting(tester);
    await tester.enterText(nameField(), 'Rencontre');
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('studio-save')));
    await settle(tester);

    expect(memory.writes, 1);
    expect(events.published, [
      (id: leaveGuardMeeting.id, name: 'Rencontre', mapWrites: 1),
    ]);
    expect(find.text('Enregistré'), findsOneWidget);
  });

  testWidgets('leaving while typing keeps the typed text', (tester) async {
    await open(tester);
    await openMeeting(tester);
    await tester.enterText(nameField(), 'Rencontre');
    await tester.pump();

    await goHome(tester);
    await choose(tester, 'save');

    expect(events.published, [
      (id: leaveGuardMeeting.id, name: 'Rencontre', mapWrites: 0),
    ]);
    expect(sessions.released, [exampleA]);
  });

  testWidgets('undo inside a text field never undoes the map', (tester) async {
    await open(tester);
    editMap();
    await openMeeting(tester);
    await tester.enterText(nameField(), 'Rencontre');
    await tester.pump();

    await pressWithControl(tester, LogicalKeyboardKey.keyZ);

    expect(controller().active!.current.name, 'Clairière modifiée');
    expect(events.published, isEmpty);
  });

  testWidgets('a project switch asks the same guard first', (tester) async {
    await open(tester);
    editMap();
    await tester.pump();
    final switching = ProjectSessionOpenController(
      session: container.read(projectSessionControllerProvider),
      chooseDirectory: () async => exampleB.directoryPath,
      allowSwitch: container.read(studioExitGuardProvider).confirmLeave,
    );
    addTearDown(switching.dispose);

    final opened = switching.open(browse: true);
    await settle(tester);
    await choose(tester, 'cancel');

    expect(await opened, isFalse);
    expect(sessions.requests, [exampleA.directoryPath]);
    expect(find.byKey(const ValueKey('map-builder')), findsOneWidget);
    expect(controller().active!.current.name, 'Clairière modifiée');
  });

  testWidgets('quitting asks first and Annuler keeps the app open', (
    tester,
  ) async {
    sizeView(tester);
    final port = ControlledProjectSessionPort();
    final session = ProjectSessionController(port);
    addTearDown(session.dispose);
    final opening = session.open(exampleA.directoryPath);
    port.pending.single.complete(exampleA);
    await opening;
    memory = leaveGuardMemory();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectSessionControllerProvider.overrideWith((ref) => session),
          mapWorkspacePortProvider(exampleA).overrideWithValue(memory),
          workspaceVisualsLoaderProvider.overrideWithValue(
            (session, manifest) async => WorkspaceTestVisuals(),
          ),
        ],
        child: const StudioApp(),
      ),
    );
    await settle(tester);
    container = ProviderScope.containerOf(
      tester.element(find.byType(StudioApp)),
      listen: false,
    );
    editMap();
    await tester.pump();

    final cancelled = tester.binding.handleRequestAppExit();
    await settle(tester);
    await choose(tester, 'cancel');
    expect(await cancelled, AppExitResponse.cancel);
    expect(session.disposed, isFalse);
    expect(port.released, isEmpty);
    expect(find.byKey(const ValueKey('map-builder')), findsOneWidget);
    expect(controller().dirty, isTrue);

    final left = tester.binding.handleRequestAppExit();
    await settle(tester);
    await choose(tester, 'discard');
    expect(await left, AppExitResponse.exit);
    expect(memory.writes, 0);
    expect(session.disposed, isTrue);
    await tester.pumpWidget(const SizedBox());
  });
}
