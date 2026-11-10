import 'dart:async';

import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/project_session/application/project_session_controller.dart';
import 'package:avelune_studio/features/project_session/application/project_session_open_controller.dart';
import 'package:avelune_studio/features/project_session/application/project_open_message.dart';
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
    test('submits $description exactly without invoking the picker', () async {
      final port = ControlledProjectSessionPort();
      final session = ProjectSessionController(port);
      var selections = 0;
      final opening = ProjectSessionOpenController(
        session: session,
        chooseDirectory: () async {
          selections++;
          return '/alternative';
        },
      );
      opening.path = path;
      final pending = opening.open();
      expect(port.requests, [path]);
      expect(selections, 0);
      opening.dispose();
      await session.dispose();
      port.pending.single.complete(exampleA);
      expect(await pending, isFalse);
      expect(port.released, [exampleA]);
    });
  }

  test(
    'passes the native trailing space unchanged and retains the refused path',
    () async {
      final port = ControlledProjectSessionPort();
      final session = ProjectSessionController(port);
      final selection = Completer<String?>();
      final opening = ProjectSessionOpenController(
        session: session,
        chooseDirectory: () => selection.future,
      );
      addTearDown(() async {
        opening.dispose();
        await session.dispose();
      });
      opening.path = '/brouillon';
      final pending = opening.open(browse: true);
      expect(opening.picking, isTrue);
      expect(port.requests, isEmpty);
      selection.complete('/projets/MonJeu ');
      await Future<void>.delayed(Duration.zero);
      expect(port.requests, ['/projets/MonJeu ']);
      port.pending.single.completeError(
        const ProjectOpenFailure(ProjectOpenProblem.pathNotPreserved),
      );
      expect(await pending, isFalse);
      expect(projectOpenMessage(session.state.problem), _refusalMessage);
      expect(opening.path, '/projets/MonJeu ');
      expect(session.state.project, isNull);
    },
  );

  test('an actually empty path opens the picker without reading', () async {
    final port = ControlledProjectSessionPort();
    final session = ProjectSessionController(port);
    var selections = 0;
    final opening = ProjectSessionOpenController(
      session: session,
      chooseDirectory: () async {
        selections++;
        return null;
      },
    );
    addTearDown(() async {
      opening.dispose();
      await session.dispose();
    });
    expect(await opening.open(), isFalse);
    expect(selections, 1);
    expect(port.requests, isEmpty);
    expect(opening.path, '');
  });

  test(
    'cancelling the picker preserves the failed session and entered path',
    () async {
      final port = ControlledProjectSessionPort();
      final session = ProjectSessionController(port);
      final pending = session.open('/refus ');
      port.pending.single.completeError(
        const ProjectOpenFailure(ProjectOpenProblem.pathNotPreserved),
      );
      await pending;
      final opening = ProjectSessionOpenController(
        session: session,
        chooseDirectory: () async => null,
      );
      addTearDown(() async {
        opening.dispose();
        await session.dispose();
      });
      final before = session.state;
      opening.path = ' /brouillon ';
      expect(await opening.open(browse: true), isFalse);
      expect(session.state, same(before));
      expect(port.requests, ['/refus ']);
      expect(port.released, isEmpty);
      expect(opening.path, ' /brouillon ');
      expect(projectOpenMessage(session.state.problem), _refusalMessage);
    },
  );

  test(
    'typed French refusal accepts correction then closes the real session',
    () async {
      final port = ControlledProjectSessionPort();
      final session = ProjectSessionController(port);
      var selections = 0;
      final opening = ProjectSessionOpenController(
        session: session,
        chooseDirectory: () async {
          selections++;
          return '/alternative';
        },
      );
      addTearDown(() async {
        opening.dispose();
        await session.dispose();
      });
      final refused = opening.open(directoryPath: '/projets/MonJeu ');
      port.pending.single.completeError(
        const ProjectOpenFailure(ProjectOpenProblem.pathNotPreserved),
      );
      expect(await refused, isFalse);
      expect(session.state.project, isNull);
      expect(session.state.problem, ProjectOpenProblem.pathNotPreserved);
      expect(projectOpenMessage(session.state.problem), _refusalMessage);
      expect(opening.path, '/projets/MonJeu ');
      expect(port.released, isEmpty);
      final corrected = opening.open(directoryPath: exampleA.directoryPath);
      expect(port.requests, ['/projets/MonJeu ', exampleA.directoryPath]);
      port.pending.last.complete(exampleA);
      expect(await corrected, isTrue);
      expect(session.state.project, same(exampleA));
      expect(session.state.problem, isNull);
      expect(selections, 0);
      expect(await opening.close(), isTrue);
      expect(port.released, [exampleA]);
      expect(opening.path, exampleA.directoryPath);
    },
  );

  test('a native result after disposal never opens a project', () async {
    final port = ControlledProjectSessionPort();
    final session = ProjectSessionController(port);
    final selection = Completer<String?>();
    final opening = ProjectSessionOpenController(
      session: session,
      chooseDirectory: () => selection.future,
    );
    final pending = opening.open(browse: true);
    opening.dispose();
    await session.dispose();
    selection.complete('/projets/MonJeu ');
    expect(await pending, isFalse);
    expect(port.requests, isEmpty);
    expect(port.released, isEmpty);
  });
}

const _refusalMessage =
    'Ce chemin ne peut pas être ouvert sans modifier le dossier visé. '
    'Aucun projet n’a été ouvert. Vérifiez les espaces en bordure du chemin '
    'ou choisissez un autre dossier.';
