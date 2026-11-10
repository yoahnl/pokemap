import 'dart:async';

import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/project_session/application/project_session_controller.dart';
import 'package:avelune_studio/features/project_session/application/project_session_state.dart';
import 'package:avelune_studio/features/project_session/application/project_session_open_controller.dart';
import 'package:avelune_studio/features/project_session/application/project_open_message.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:avelune_studio/app/studio_app.dart';
import 'package:avelune_studio/app/di/providers.dart';

import '../support/test_studio_app.dart';

import '../support/controlled_project_session_port.dart';

void main() {
  test(
    'pending picker retains entered path and blocks duplicate selection',
    () async {
      final port = ControlledProjectSessionPort();
      final session = ProjectSessionController(port);
      final picked = Completer<String?>();
      var selections = 0;
      final opening = ProjectSessionOpenController(
        session: session,
        chooseDirectory: () {
          selections++;
          return picked.future;
        },
      );
      addTearDown(() async {
        opening.dispose();
        await session.dispose();
      });
      opening.path = '/brouillon';
      final pending = opening.open(browse: true);
      expect(opening.picking, isTrue);
      expect(await opening.open(browse: true), isFalse);
      expect(selections, 1);
      picked.complete(null);
      expect(await pending, isFalse);
      expect(opening.path, '/brouillon');
      expect(opening.picking, isFalse);
      expect(port.requests, isEmpty);
    },
  );

  test('opening coordinator does not load a project on construction', () async {
    final port = ControlledProjectSessionPort();
    final session = ProjectSessionController(port);
    final opening = ProjectSessionOpenController(
      session: session,
      chooseDirectory: () async => null,
    );
    opening.dispose();
    await session.dispose();
    expect(port.requests, isEmpty);
    expect(port.released, isEmpty);
  });

  test(
    'native selection opens identity then releases its real session',
    () async {
      final port = ControlledProjectSessionPort();
      final session = ProjectSessionController(port);
      final opening = ProjectSessionOpenController(
        session: session,
        chooseDirectory: () async => exampleA.directoryPath,
      );
      addTearDown(() async {
        opening.dispose();
        await session.dispose();
      });
      final pending = opening.open(browse: true);
      await Future<void>.delayed(Duration.zero);
      expect(session.state.status, ProjectSessionStatus.opening);
      expect(port.requests, [exampleA.directoryPath]);
      port.pending.single.complete(exampleA);
      expect(await pending, isTrue);
      expect(session.state.project, same(exampleA));
      expect(opening.path, exampleA.directoryPath);
      expect(await opening.close(), isTrue);
      expect(session.state.project, isNull);
      expect(port.released, [exampleA]);
    },
  );

  test(
    'invalid manifest has an actionable message and corrected path can retry',
    () async {
      final port = ControlledProjectSessionPort();
      final session = ProjectSessionController(port);
      final opening = ProjectSessionOpenController(
        session: session,
        chooseDirectory: () async => null,
      );
      addTearDown(() async {
        opening.dispose();
        await session.dispose();
      });
      final failed = opening.open(directoryPath: '/invalide');
      port.pending.single.completeError(
        const ProjectOpenFailure(ProjectOpenProblem.manifestInvalid),
      );
      expect(await failed, isFalse);
      expect(projectOpenMessage(session.state.problem), contains('manifeste'));
      expect(session.state.project, isNull);
      final retry = opening.open(directoryPath: '/corrige');
      port.pending.last.complete(exampleA);
      expect(await retry, isTrue);
      expect(port.requests, ['/invalide', '/corrige']);
      expect(session.state.project, same(exampleA));
    },
  );

  test(
    'cancelling pending read releases its late result without opening it',
    () async {
      final port = ControlledProjectSessionPort();
      final session = ProjectSessionController(port);
      final opening = ProjectSessionOpenController(
        session: session,
        chooseDirectory: () async => null,
      );
      addTearDown(() async {
        opening.dispose();
        await session.dispose();
      });
      final pending = opening.open(directoryPath: '/exemple');
      opening.cancel();
      port.pending.single.complete(exampleA);
      expect(await pending, isFalse);
      expect(session.state.project, isNull);
      expect(port.released, [exampleA]);
    },
  );

  testWidgets(
    'neutral host rebuild and resize retain the opened session scope',
    (tester) async {
      var created = 0;
      final port = ControlledProjectSessionPort();
      ProjectSessionController create() {
        created++;
        return ProjectSessionController(port);
      }

      Widget app() => TestStudioApp(
        createSession: create,
        chooseDirectory: () async => null,
      );
      await tester.pumpWidget(app());
      final container = ProviderScope.containerOf(
        tester.element(find.byType(StudioApp)),
        listen: false,
      );
      final session = container.read(projectSessionControllerProvider);
      final pending = session.open(exampleA.directoryPath);
      port.pending.single.complete(exampleA);
      await pending;
      await tester.pumpWidget(app());
      await tester.binding.setSurfaceSize(const Size(480, 360));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpAndSettle();
      expect(container.read(projectSessionControllerProvider), same(session));
      expect(session.state.project, same(exampleA));
      expect(created, 1);
      expect(port.requests, [exampleA.directoryPath]);
      expect(port.released, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(session.disposed, isTrue);
      expect(port.released, [exampleA]);
    },
  );

  test('disposed coordinator ignores a late directory result', () async {
    final port = ControlledProjectSessionPort();
    final session = ProjectSessionController(port);
    final picked = Completer<String?>();
    final opening = ProjectSessionOpenController(
      session: session,
      chooseDirectory: () => picked.future,
    );
    final pending = opening.open(browse: true);
    opening.dispose();
    picked.complete('/tardif');
    expect(await pending, isFalse);
    expect(port.requests, isEmpty);
    await session.dispose();
  });
}
