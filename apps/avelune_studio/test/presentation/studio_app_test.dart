import 'dart:async';

import 'package:avelune_studio/src/bootstrap/studio_app.dart';
import 'package:avelune_studio/src/features/project_session/application/project_session.dart';
import 'package:avelune_studio/src/features/project_session/application/project_session_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('releases the path field while the native picker owns input', (
    tester,
  ) async {
    final port = _Port();
    final picked = Completer<String?>();
    await tester.pumpWidget(
      StudioApp(
        createSession: () => ProjectSessionController(port),
        chooseDirectory: () => picked.future,
      ),
    );
    await tester.enterText(find.byType(TextField), '/brouillon');
    await tester.tap(find.text('Parcourir'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    picked.complete(null);
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('/brouillon'), findsOneWidget);
    expect(port.opened, isEmpty);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('shows the real opening action without loading at startup', (
    tester,
  ) async {
    final port = _Port();
    await tester.pumpWidget(_app(port));
    expect(find.text('Avelune Studio'), findsOneWidget);
    expect(find.text('Ouvrir un projet'), findsOneWidget);
    expect(port.opened, isEmpty);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('opens from the native selection, displays identity and closes', (
    tester,
  ) async {
    final port = _Port();
    await tester.pumpWidget(_app(port));
    await tester.tap(find.text('Ouvrir un projet'));
    await tester.pump();
    expect(find.text('Lecture du projet…'), findsOneWidget);
    expect(port.opened, ['/exemple']);
    port.pending.complete(_project);
    await tester.pumpAndSettle();
    expect(find.text('Projet Exemple réellement lu'), findsOneWidget);
    expect(find.text('/exemple'), findsWidgets);
    expect(find.text('Projet ouvert — lecture seule'), findsOneWidget);
    await tester.tap(find.text('Fermer le projet'));
    await tester.pumpAndSettle();
    expect(find.text('Projet Exemple réellement lu'), findsNothing);
    expect(port.closed, [_project]);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('shows an actionable failure and retries the entered directory', (
    tester,
  ) async {
    final port = _Port();
    await tester.pumpWidget(_app(port));
    await tester.enterText(find.byType(TextField), '/invalide');
    await tester.tap(find.text('Ouvrir un projet'));
    await tester.pump();
    port.pending.completeError(
      const ProjectOpenFailure(ProjectOpenProblem.manifestInvalid),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('manifeste'), findsWidgets);
    expect(find.text('Projet ouvert — lecture seule'), findsNothing);
    port.pending = Completer<ProjectSession>();
    await tester.enterText(find.byType(TextField), '/corrige');
    await tester.tap(find.text('Ouvrir un projet'));
    await tester.pump();
    port.pending.complete(_project);
    await tester.pumpAndSettle();
    expect(port.opened, ['/invalide', '/corrige']);
    expect(find.text('Projet Exemple réellement lu'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'rebuilds and resizes without recreating or reloading a session',
    (tester) async {
      var created = 0;
      final port = _Port();
      ProjectSessionController create() {
        created++;
        return ProjectSessionController(port);
      }

      Widget app() => StudioApp(
        createSession: create,
        chooseDirectory: () async => '/exemple',
      );
      await tester.pumpWidget(app());
      await tester.tap(find.text('Ouvrir un projet'));
      await tester.pump();
      port.pending.complete(_project);
      await tester.pumpAndSettle();
      await tester.pumpWidget(app());
      await tester.binding.setSurfaceSize(const Size(480, 360));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(created, 1);
      expect(port.opened, ['/exemple']);
      expect(port.closed, isEmpty);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(port.closed, [_project]);
      await tester.binding.setSurfaceSize(null);
    },
  );

  testWidgets('supports keyboard submission and focus traversal', (
    tester,
  ) async {
    final port = _Port();
    await tester.pumpWidget(_app(port));
    await tester.enterText(find.byType(TextField), '/clavier');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(port.opened, ['/clavier']);
    port.pending.complete(_project);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    expect(FocusManager.instance.primaryFocus, isNotNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('cancels a pending read and disposes its late result', (
    tester,
  ) async {
    final port = _Port();
    await tester.pumpWidget(_app(port));
    await tester.tap(find.text('Ouvrir un projet'));
    await tester.pump();
    await tester.tap(find.text('Annuler l’ouverture'));
    await tester.pump();
    port.pending.complete(_project);
    await tester.pumpAndSettle();
    expect(find.text('Projet Exemple réellement lu'), findsNothing);
    expect(port.closed, [_project]);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('does not open a directory picker result after disposal', (
    tester,
  ) async {
    final port = _Port();
    final picked = Completer<String?>();
    await tester.pumpWidget(
      StudioApp(
        createSession: () => ProjectSessionController(port),
        chooseDirectory: () => picked.future,
      ),
    );
    await tester.tap(find.text('Ouvrir un projet'));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    picked.complete('/tardif');
    await tester.pumpAndSettle();
    expect(port.opened, isEmpty);
    expect(tester.takeException(), isNull);
  });
}

const _project = ProjectSession(
  sessionId: 'session-exemple',
  name: 'Projet Exemple réellement lu',
  directoryPath: '/exemple',
);

Widget _app(_Port port) => StudioApp(
  createSession: () => ProjectSessionController(port),
  chooseDirectory: () async => '/exemple',
);

class _Port implements ProjectSessionPort {
  var pending = Completer<ProjectSession>();
  final opened = <String>[];
  final closed = <ProjectSession>[];

  @override
  Future<ProjectSession> open(String directoryPath) {
    opened.add(directoryPath);
    return pending.future;
  }

  @override
  Future<void> close(ProjectSession session) async {
    closed.add(session);
  }
}
