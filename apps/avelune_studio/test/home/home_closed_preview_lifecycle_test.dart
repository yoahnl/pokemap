import 'dart:async';
import 'dart:io';

import 'package:avelune_studio/features/home/application/recent_projects_controller.dart';
import 'package:avelune_studio/features/home/data/memory_recent_projects_adapter.dart';
import 'package:avelune_studio/features/project_session/application/project_session_controller.dart';
import 'package:avelune_studio/features/project_session/application/project_session_open_controller.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../tool/create_example_project.dart';
import '../support/controlled_project_session_port.dart';

void main() {
  test(
    'closed on-disk project reopens with a fresh session and intact maps',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'home-reopen-project-',
      );
      final session = ProjectSessionController(LocalProjectSessionAdapter());
      final recents = RecentProjectsController(MemoryRecentProjectsAdapter());
      final opening = ProjectSessionOpenController(
        session: session,
        chooseDirectory: () async => root.path,
        recentProjects: recents,
      );
      addTearDown(() async {
        opening.dispose();
        recents.dispose();
        await session.dispose();
        await root.delete(recursive: true);
      });
      await writeExampleProject(root);
      await recents.load();
      expect(await opening.open(browse: true), isTrue);
      final first = session.state.project!;
      final mapFiles = await Directory('${root.path}/maps')
          .list()
          .where((entity) => entity is File)
          .cast<File>()
          .toList();
      final originals = {
        for (final map in mapFiles) map.path: await map.readAsBytes(),
      };
      expect(await opening.close(), isTrue);
      expect(session.state.project, isNull);
      expect(await opening.open(directoryPath: first.directoryPath), isTrue);
      final second = session.state.project!;
      expect(second.sessionId, isNot(first.sessionId));
      expect(second.directoryPath, first.directoryPath);
      for (final entry in originals.entries) {
        expect(await File(entry.key).readAsBytes(), entry.value);
      }
      await recents.load();
      expect(recents.entries, hasLength(1));
      expect(recents.entries.single.directoryPath, second.directoryPath);
    },
  );

  test('disposed picker cannot replace the new session owner', () async {
    final oldPort = ControlledProjectSessionPort();
    final nextPort = ControlledProjectSessionPort();
    final oldSession = ProjectSessionController(oldPort);
    final nextSession = ProjectSessionController(nextPort);
    final delayed = Completer<String?>();
    final oldOpening = ProjectSessionOpenController(
      session: oldSession,
      chooseDirectory: () => delayed.future,
    );
    final nextOpening = ProjectSessionOpenController(
      session: nextSession,
      chooseDirectory: () async => exampleB.directoryPath,
    );
    addTearDown(() async {
      oldOpening.dispose();
      nextOpening.dispose();
      await oldSession.dispose();
      await nextSession.dispose();
    });
    final lateChoice = oldOpening.open(browse: true);
    oldOpening.dispose();
    final next = nextOpening.open(browse: true);
    await Future<void>.delayed(Duration.zero);
    nextPort.pending.single.complete(exampleB);
    expect(await next, isTrue);
    delayed.complete(exampleA.directoryPath);
    expect(await lateChoice, isFalse);
    expect(oldPort.requests, isEmpty);
    expect(nextSession.state.project, same(exampleB));
    expect(nextPort.released, isEmpty);
  });
}
