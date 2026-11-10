import 'dart:async';

import 'package:avelune_studio/features/project_session/application/project_session_controller.dart';
import 'package:avelune_studio/features/project_session/application/project_session_open_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/controlled_project_session_port.dart';

void main() {
  test(
    'changed session refuses a created project and releases creation access',
    () async {
      final port = ControlledProjectSessionPort();
      final session = ProjectSessionController(port);
      final controller = ProjectSessionOpenController(
        session: session,
        chooseDirectory: () async => null,
      );
      final shown = Completer<void>();
      final closed = Completer<void>();
      final visibility = <bool>[];
      var releases = 0;
      late Future<bool> Function(String) openCreated;
      addTearDown(controller.dispose);
      addTearDown(session.dispose);
      final creation = controller.runCreation(
        present: (open) async {
          openCreated = open;
          shown.complete();
          await closed.future;
        },
        releaseParent: () async {
          releases++;
        },
        onVisibilityChanged: visibility.add,
      );
      await shown.future;
      expect(controller.creating, isTrue);
      final replacing = session.open(exampleB.directoryPath);
      port.pending.single.complete(exampleB);
      await replacing;
      expect(await openCreated('/created'), isFalse);
      expect(port.requests, [exampleB.directoryPath]);
      expect(session.state.project, same(exampleB));
      closed.complete();
      await creation;
      expect(releases, 1);
      expect(visibility, [true, false]);
      expect(controller.creating, isFalse);
    },
  );

  test(
    'disposed owner rejects late receipt and still releases its parent',
    () async {
      final port = ControlledProjectSessionPort();
      final session = ProjectSessionController(port);
      final controller = ProjectSessionOpenController(
        session: session,
        chooseDirectory: () async => null,
      );
      final shown = Completer<void>();
      final closed = Completer<void>();
      late Future<bool> Function(String) openCreated;
      var releases = 0;
      final visibility = <bool>[];
      addTearDown(session.dispose);
      final creation = controller.runCreation(
        present: (open) async {
          openCreated = open;
          shown.complete();
          await closed.future;
        },
        releaseParent: () async {
          releases++;
        },
        onVisibilityChanged: visibility.add,
      );
      await shown.future;
      controller.dispose();
      expect(await openCreated('/late'), isFalse);
      closed.complete();
      await creation;
      expect(port.requests, isEmpty);
      expect(releases, 1);
      expect(visibility, [true, false]);
    },
  );

  test(
    'creation failure releases visibility and access without opening a project',
    () async {
      final port = ControlledProjectSessionPort();
      final session = ProjectSessionController(port);
      final controller = ProjectSessionOpenController(
        session: session,
        chooseDirectory: () async => null,
      );
      final visibility = <bool>[];
      var releases = 0;
      addTearDown(controller.dispose);
      addTearDown(session.dispose);
      await expectLater(
        controller.runCreation(
          present: (_) async => throw StateError('creator.failed'),
          releaseParent: () async {
            releases++;
          },
          onVisibilityChanged: visibility.add,
        ),
        throwsStateError,
      );
      expect(releases, 1);
      expect(visibility, [true, false]);
      expect(controller.creating, isFalse);
      expect(port.requests, isEmpty);
    },
  );

  test(
    'a parent release failure still clears the creator visibility guard',
    () async {
      final port = ControlledProjectSessionPort();
      final session = ProjectSessionController(port);
      final controller = ProjectSessionOpenController(
        session: session,
        chooseDirectory: () async => null,
      );
      final visibility = <bool>[];
      addTearDown(controller.dispose);
      addTearDown(session.dispose);
      await expectLater(
        controller.runCreation(
          present: (_) async {},
          releaseParent: () async => throw StateError('release.failed'),
          onVisibilityChanged: visibility.add,
        ),
        throwsStateError,
      );
      expect(visibility, [true, false]);
      expect(controller.creating, isFalse);
      expect(port.requests, isEmpty);
    },
  );

  test(
    'a pending creation blocks duplicate launch and opens its receipt once',
    () async {
      final port = ControlledProjectSessionPort();
      final session = ProjectSessionController(port);
      final controller = ProjectSessionOpenController(
        session: session,
        chooseDirectory: () async => null,
      );
      final shown = Completer<void>();
      final closed = Completer<void>();
      late Future<bool> Function(String) openCreated;
      var presentations = 0;
      addTearDown(controller.dispose);
      addTearDown(session.dispose);
      final creation = controller.runCreation(
        present: (open) async {
          presentations++;
          openCreated = open;
          shown.complete();
          await closed.future;
        },
      );
      await shown.future;
      await controller.runCreation(
        present: (_) async {
          presentations++;
        },
      );
      expect(presentations, 1);
      final opening = openCreated(exampleA.directoryPath);
      expect(port.requests, [exampleA.directoryPath]);
      port.pending.single.complete(exampleA);
      expect(await opening, isTrue);
      expect(session.state.project, same(exampleA));
      expect(await openCreated('/second'), isFalse);
      expect(port.requests, [exampleA.directoryPath]);
      closed.complete();
      await creation;
      expect(controller.creating, isFalse);
    },
  );
}
