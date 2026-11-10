import 'dart:async';

import 'package:avelune_studio/features/home/application/recent_projects_controller.dart';
import 'package:avelune_studio/features/home/data/memory_recent_projects_adapter.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/project_session/application/project_session_controller.dart';
import 'package:avelune_studio/features/project_session/application/project_session_open_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/controlled_project_session_port.dart';
import '../support/map_workspace_fixture.dart';

void main() {
  test(
    'cancelled project switch preserves document, history and session',
    () async {
      final port = ControlledProjectSessionPort();
      final session = ProjectSessionController(port);
      final recent = RecentProjectsController(MemoryRecentProjectsAdapter());
      final maps = WorkspaceMemoryPort();
      final workspace = MapWorkspaceController(workspaceSession, maps);
      var allowed = true;
      var selected = '/fixture';
      final opening = ProjectSessionOpenController(
        session: session,
        chooseDirectory: () async => selected,
        recentProjects: recent,
        allowSwitch: () async => allowed,
      );
      addTearDown(() async {
        opening.dispose();
        recent.dispose();
        workspace.dispose();
        await session.dispose();
      });
      expect(maps.reads, 0);
      final first = opening.open(browse: true);
      await Future<void>.delayed(Duration.zero);
      port.pending.single.complete(workspaceSession);
      expect(await first, isTrue);
      await workspace.initialize();
      final document = workspace.active!;
      document.commit(
        document.current.copyWith(name: 'Modification conservée'),
      );
      final reads = maps.reads;
      allowed = false;
      selected = '/other';
      expect(await opening.open(browse: true), isFalse);
      expect(port.requests, ['/fixture']);
      expect(port.released, isEmpty);
      expect(session.state.project, same(workspaceSession));
      expect(workspace.active, same(document));
      expect(document.dirty, isTrue);
      expect(document.current.name, 'Modification conservée');
      expect(workspace.documents.keys, ['a']);
      expect(maps.reads, reads);
      expect(maps.writes, 0);
      await workspace.activate(workspace.project!.maps.first);
      expect(workspace.active, same(document));
      workspace.restore(redo: false);
      expect(document.current.name, 'a');
      expect(maps.reads, reads);
      expect(maps.writes, 0);
    },
  );

  test(
    'cancelled picker cannot open a project after its choice arrives',
    () async {
      final port = ControlledProjectSessionPort();
      final session = ProjectSessionController(port);
      final choice = Completer<String?>();
      final opening = ProjectSessionOpenController(
        session: session,
        chooseDirectory: () => choice.future,
      );
      addTearDown(opening.dispose);
      addTearDown(session.dispose);
      final pending = opening.open(browse: true);
      expect(opening.picking, isTrue);
      opening.cancel();
      choice.complete('/late');
      expect(await pending, isFalse);
      expect(port.requests, isEmpty);
      expect(opening.picking, isFalse);
      expect(session.state.project, isNull);
    },
  );

  test(
    'picker failure preserves the active project and releases busy state',
    () async {
      final port = ControlledProjectSessionPort();
      final session = ProjectSessionController(port);
      final first = session.open(exampleA.directoryPath);
      port.pending.single.complete(exampleA);
      await first;
      final opening = ProjectSessionOpenController(
        session: session,
        chooseDirectory: () async => throw StateError('picker.unavailable'),
      );
      addTearDown(opening.dispose);
      addTearDown(session.dispose);
      expect(await opening.open(browse: true), isFalse);
      expect(opening.error, contains('sélecteur de dossier'));
      expect(opening.picking, isFalse);
      expect(session.state.project, same(exampleA));
      expect(port.released, isEmpty);
    },
  );
}
