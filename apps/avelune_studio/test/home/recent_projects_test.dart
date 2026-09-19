import 'dart:async';
import 'dart:io';

import 'package:avelune_studio/features/home/application/recent_projects_controller.dart';
import 'package:avelune_studio/features/home/data/local_recent_projects_adapter.dart';
import 'package:avelune_studio/features/home/data/memory_recent_projects_adapter.dart';
import 'package:avelune_studio/features/home/domain/recent_studio_project.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectSession project(String path, {String name = 'Aventure'}) =>
    ProjectSession(sessionId: path, name: name, directoryPath: path);

void main() {
  test(
    'keeps five most recently opened projects and updates duplicates',
    () async {
      var day = 1;
      final controller = RecentProjectsController(
        MemoryRecentProjectsAdapter(),
        clock: () => DateTime.utc(2026, 9, day++),
      );
      addTearDown(controller.dispose);
      for (var index = 0; index < 7; index++) {
        await controller.remember(project('/project-$index'));
      }
      expect(controller.entries.map((entry) => entry.directoryPath), [
        '/project-6',
        '/project-5',
        '/project-4',
        '/project-3',
        '/project-2',
      ]);
      await controller.remember(project('/project-3', name: 'Nouveau nom'));
      expect(controller.entries.first.name, 'Nouveau nom');
      expect(controller.entries, hasLength(5));
      expect(() => controller.entries.clear(), throwsUnsupportedError);
    },
  );

  test(
    'persists exact paths and removal never touches project directories',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'studio-recents-test-',
      );
      addTearDown(() => root.delete(recursive: true));
      final personal = await Directory('${root.path}/ Projet été #1 ').create();
      final manifest = File('${personal.path}/project.json');
      await manifest.writeAsString('unchanged');
      final adapter = LocalRecentProjectsAdapter(
        '${root.path}/settings/recent.json',
      );
      final controller = RecentProjectsController(adapter);
      addTearDown(controller.dispose);
      await controller.remember(project(personal.path));
      final reopened = RecentProjectsController(adapter);
      addTearDown(reopened.dispose);
      await reopened.load();
      expect(reopened.entries.single.directoryPath, personal.path);
      await reopened.remove(personal.path);
      expect(await adapter.load(), isEmpty);
      expect(await manifest.readAsString(), 'unchanged');
      expect(await personal.exists(), isTrue);
      expect(await Directory('${root.path}/settings').list().length, 1);
    },
  );

  test(
    'load completes before queued opening and writes are serialized',
    () async {
      final port = _DelayedPort();
      final controller = RecentProjectsController(port);
      addTearDown(controller.dispose);
      final loaded = controller.load();
      final first = controller.remember(project('/first'));
      final second = controller.remember(project('/second'));
      port.loading.complete([
        RecentStudioProject(
          name: 'Ancien',
          directoryPath: '/old',
          lastOpenedAt: DateTime.utc(2020),
        ),
      ]);
      await Future.wait([loaded, first, second]);
      expect(port.maximumConcurrentWrites, 1);
      expect(
        port.saved.map((entry) => entry.directoryPath),
        containsAll(['/old', '/first', '/second']),
      );
    },
  );

  test(
    'reports corrupt storage without modifying it and can recover',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'studio-recents-test-',
      );
      addTearDown(() => root.delete(recursive: true));
      final storage = File('${root.path}/recent.json');
      await storage.writeAsString('{broken');
      final controller = RecentProjectsController(
        LocalRecentProjectsAdapter(storage.path),
      );
      addTearDown(controller.dispose);
      var notifications = 0;
      controller.addListener(() => notifications++);
      await controller.load();
      expect(controller.error, isNotNull);
      expect(controller.entries, isEmpty);
      expect(await storage.readAsString(), '{broken');
      await controller.remember(project('/valid'));
      expect(controller.error, isNull);
      expect(notifications, 2);
    },
  );

  test(
    'missing preferences start empty and disposed listeners stay silent',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'studio-recents-test-',
      );
      addTearDown(() => root.delete(recursive: true));
      final controller = RecentProjectsController(
        LocalRecentProjectsAdapter('${root.path}/absent.json'),
      );
      var notifications = 0;
      void listener() => notifications++;
      controller.addListener(listener);
      await controller.load();
      expect(controller.entries, isEmpty);
      expect(controller.error, isNull);
      controller.removeListener(listener);
      await controller.remember(project('/first'));
      controller.dispose();
      await controller.remember(project('/second'));
      expect(notifications, 1);
      expect(controller.entries.single.directoryPath, '/first');
    },
  );
}

class _DelayedPort implements RecentProjectsPort {
  final loading = Completer<List<RecentStudioProject>>();
  List<RecentStudioProject> saved = [];
  int concurrentWrites = 0;
  int maximumConcurrentWrites = 0;

  @override
  Future<List<RecentStudioProject>> load() => loading.future;

  @override
  Future<void> save(List<RecentStudioProject> entries) async {
    concurrentWrites++;
    if (concurrentWrites > maximumConcurrentWrites) {
      maximumConcurrentWrites = concurrentWrites;
    }
    await Future<void>.delayed(Duration.zero);
    saved = List.of(entries);
    concurrentWrites--;
  }
}
