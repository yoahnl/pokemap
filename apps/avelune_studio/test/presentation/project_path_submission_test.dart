import 'dart:async';

import '../support/test_studio_app.dart';
import '../support/open_project_path.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/project_session/application/project_session_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/controlled_project_session_port.dart';

void main() {
  for (final (description, path) in [
    ('trailing space', '/projets/MonJeu '),
    ('surrounding spaces', '  /projets/MonJeu  '),
    ('whitespace only', '   '),
    ('quoted path', '"/projets/Mon Jeu"'),
    ('unicode characters', '/projets/E\u0301té\u00a0Mon Jeu'),
    ('tilde', '~/projets/MonJeu'),
  ]) {
    testWidgets('submits $description exactly without invoking the picker', (
      tester,
    ) async {
      final port = ControlledProjectSessionPort();
      var selections = 0;
      await tester.pumpWidget(
        TestStudioApp(
          createSession: () => ProjectSessionController(port),
          chooseDirectory: () async {
            selections++;
            return '/alternative';
          },
        ),
      );
      await enterProjectPath(tester, path);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(port.requests, [path]);
      expect(selections, 0);
      await tester.pumpWidget(const SizedBox());
      port.pending.single.complete(exampleA);
      await tester.pumpAndSettle();
      expect(port.released, [exampleA]);
    });
  }

  testWidgets('passes the native trailing space unchanged to the session', (
    tester,
  ) async {
    final port = ControlledProjectSessionPort();
    final selection = Completer<String?>();
    await tester.pumpWidget(
      TestStudioApp(
        createSession: () => ProjectSessionController(port),
        chooseDirectory: () => selection.future,
      ),
    );
    await enterProjectPath(tester, '/brouillon');
    await tapVisible(tester, find.byKey(const ValueKey('open-project-picker')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(studioProjectPathField(), findsNothing);
    expect(port.requests, isEmpty);
    selection.complete('/projets/MonJeu ');
    await tester.pump();
    expect(port.requests, ['/projets/MonJeu ']);
    port.pending.single.completeError(
      const ProjectOpenFailure(ProjectOpenProblem.pathNotPreserved),
    );
    await tester.pumpAndSettle();
    expect(find.text(_refusalMessage), findsOneWidget);
    expect(find.text('Projet ouvert — lecture seule'), findsNothing);
    await revealProjectPath(tester);
    expect(_enteredPath(tester), '/projets/MonJeu ');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('an actually empty field opens the picker without reading', (
    tester,
  ) async {
    final port = ControlledProjectSessionPort();
    var selections = 0;
    await tester.pumpWidget(
      TestStudioApp(
        createSession: () => ProjectSessionController(port),
        chooseDirectory: () async {
          selections++;
          return null;
        },
      ),
    );
    await tapVisible(tester, find.byKey(const ValueKey('open-project-picker')));
    await tester.pumpAndSettle();
    expect(selections, 1);
    expect(port.requests, isEmpty);
    await revealProjectPath(tester);
    expect(_enteredPath(tester), '');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('cancelling the picker preserves the session and entered text', (
    tester,
  ) async {
    final port = ControlledProjectSessionPort();
    final session = ProjectSessionController(port);
    final opening = session.open('/refus ');
    port.pending.single.completeError(
      const ProjectOpenFailure(ProjectOpenProblem.pathNotPreserved),
    );
    await opening;
    await tester.pumpWidget(
      TestStudioApp(
        createSession: () => session,
        chooseDirectory: () async => null,
      ),
    );
    await tester.pumpAndSettle();
    final before = session.state;
    await enterProjectPath(tester, ' /brouillon ');
    await tapVisible(tester, find.byKey(const ValueKey('open-project-picker')));
    await tester.pumpAndSettle();
    expect(identical(session.state, before), isTrue);
    expect(port.requests, ['/refus ']);
    expect(port.released, isEmpty);
    await revealProjectPath(tester);
    expect(_enteredPath(tester), ' /brouillon ');
    expect(find.text(_refusalMessage), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'shows the typed refusal in French and accepts a corrected path',
    (tester) async {
      final port = ControlledProjectSessionPort();
      final session = ProjectSessionController(port);
      var selections = 0;
      await tester.pumpWidget(
        TestStudioApp(
          createSession: () => session,
          chooseDirectory: () async {
            selections++;
            return '/alternative';
          },
        ),
      );
      await enterProjectPath(tester, '/projets/MonJeu ');
      await tapVisible(tester, find.byKey(const ValueKey('open-project-path')));
      await tester.pump();
      port.pending.single.completeError(
        const ProjectOpenFailure(ProjectOpenProblem.pathNotPreserved),
      );
      await tester.pumpAndSettle();
      expect(find.text(_refusalMessage), findsOneWidget);
      expect(find.text('Projet ouvert — lecture seule'), findsNothing);
      expect(find.text(exampleA.name), findsNothing);
      expect(find.textContaining('ProjectOpenFailure'), findsNothing);
      expect(find.textContaining('Instance of'), findsNothing);
      expect(session.state.project, isNull);
      expect(session.state.problem, ProjectOpenProblem.pathNotPreserved);
      await revealProjectPath(tester);
      expect(_enteredPath(tester), '/projets/MonJeu ');
      expect(port.requests, ['/projets/MonJeu ']);
      expect(port.released, isEmpty);
      await enterProjectPath(tester, exampleA.directoryPath);
      await tapVisible(tester, find.byKey(const ValueKey('open-project-path')));
      await tester.pump();
      expect(port.requests, ['/projets/MonJeu ', exampleA.directoryPath]);
      port.pending.last.complete(exampleA);
      await tester.pumpAndSettle();
      expect(find.text('Projet ouvert — lecture seule'), findsOneWidget);
      expect(find.text(exampleA.name), findsWidgets);
      expect(find.text(_refusalMessage), findsNothing);
      expect(selections, 0);
      expect(tester.takeException(), isNull);
      await tapVisible(tester, find.byKey(const ValueKey('Fermer le projet')));
      await tester.pumpAndSettle();
      expect(port.released, [exampleA]);
      await revealProjectPath(tester);
      expect(_enteredPath(tester), exampleA.directoryPath);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('a native result after disposal never opens a project', (
    tester,
  ) async {
    final port = ControlledProjectSessionPort();
    final selection = Completer<String?>();
    await tester.pumpWidget(
      TestStudioApp(
        createSession: () => ProjectSessionController(port),
        chooseDirectory: () => selection.future,
      ),
    );
    await tapVisible(tester, find.byKey(const ValueKey('open-project-picker')));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    selection.complete('/projets/MonJeu ');
    await tester.pumpAndSettle();
    expect(port.requests, isEmpty);
    expect(port.released, isEmpty);
    expect(tester.takeException(), isNull);
  });
}

String _enteredPath(WidgetTester tester) =>
    tester.widget<TextField>(studioProjectPathField()).controller!.text;

const _refusalMessage =
    'Ce chemin ne peut pas être ouvert sans modifier le dossier visé. '
    'Aucun projet n’a été ouvert. Vérifiez les espaces en bordure du chemin '
    'ou choisissez un autre dossier.';
