import 'dart:async';

import 'package:avelune_studio/src/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/src/features/map_workspace/application/map_workspace_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'm1_controller_fixture.dart';

void main() {
  late M1ControlledPort port;
  late MapWorkspaceController controller;
  setUp(() {
    port = M1ControlledPort();
    controller = MapWorkspaceController(m1Session, port);
  });
  tearDown(() => controller.dispose());

  test(
    'warm map activation keeps edits and loads project and maps only once',
    () async {
      await controller.initialize();
      final first = controller.active!;
      first.commit(first.current.copyWith(name: 'Dirty A'));
      await controller.activate(m1Second);
      final second = controller.active!;
      await controller.activate(m1First);
      expect(controller.active, same(first));
      expect(first.current.name, 'Dirty A');
      expect(controller.dirty, isTrue);
      await controller.activate(m1Second);
      expect(controller.active, same(second));
      expect(port.projectLoads, 1);
      expect(port.mapLoads, {'a': 1, 'b': 1});
    },
  );

  test('late activation cannot replace the latest choice', () async {
    port.pendingLoads['a'] = Completer<MapWorkspaceDocument>();
    final first = controller.activate(m1First);
    await controller.activate(m1Second);
    expect(controller.active!.base.mapId, 'b');
    port.pendingLoads['a']!.complete(m1Document('a'));
    await first;
    expect(controller.active!.base.mapId, 'b');
    expect(controller.loading, isFalse);
    expect(controller.documents.keys, containsAll(['a', 'b']));
  });

  test('simultaneous requests for one map share the same load', () async {
    port.pendingLoads['a'] = Completer<MapWorkspaceDocument>();
    final first = controller.activate(m1First);
    final second = controller.activate(m1First);
    expect(port.mapLoads['a'], 1);
    port.pendingLoads['a']!.complete(m1Document('a'));
    await Future.wait([first, second]);
    expect(controller.documents.length, 1);
  });

  test('obsolete load failure does not replace current success', () async {
    port.pendingLoads['a'] = Completer<MapWorkspaceDocument>();
    final first = controller.activate(m1First);
    await controller.activate(m1Second);
    port.pendingLoads['a']!.completeError(
      const MapWorkspaceFailure(
        MapWorkspaceProblem.invalidDocument,
        'Broken A',
      ),
    );
    await first;
    expect(controller.error, isNull);
    expect(controller.active!.base.mapId, 'b');
  });

  test('disposed project initialization cannot trigger a map load', () async {
    port.pendingProject = Completer<ProjectManifest>();
    final pending = controller.initialize();
    controller.dispose();
    port.pendingProject!.complete(port.project);
    await pending;
    expect(controller.project, isNull);
    expect(port.mapLoads, isEmpty);
  });

  test('disposed map completion cannot publish or retain a document', () async {
    var notifications = 0;
    controller.addListener(() => notifications++);
    port.pendingLoads['a'] = Completer<MapWorkspaceDocument>();
    final pending = controller.activate(m1First);
    controller.dispose();
    final before = notifications;
    port.pendingLoads['a']!.complete(m1Document('a'));
    await pending;
    expect(controller.active, isNull);
    expect(controller.documents, isEmpty);
    expect(notifications, before);
  });

  test(
    'save uses its snapshot and retains edits made during the write',
    () async {
      await controller.initialize();
      final document = controller.active!;
      document.commit(document.current.copyWith(name: 'Snapshot'));
      final pending = controller.save(document);
      document.commit(document.current.copyWith(name: 'Newer work'));
      expect(await controller.save(document), isFalse);
      expect(port.saves.length, 1);
      port.saves.single.result.complete('saved-1');
      expect(await pending, isTrue);
      expect(document.saved.name, 'Snapshot');
      expect(document.current.name, 'Newer work');
      expect(document.base.revision, 'saved-1');
      expect(document.dirty, isTrue);
      final retry = controller.save(document);
      expect(port.saves.last.base.revision, 'saved-1');
      port.saves.last.result.complete('saved-2');
      expect(await retry, isTrue);
      expect(document.dirty, isFalse);
    },
  );

  for (final problem in [
    MapWorkspaceProblem.conflict,
    MapWorkspaceProblem.writeFailed,
  ]) {
    test(
      '${problem.name} keeps current, base revision and dirty for retry',
      () async {
        await controller.initialize();
        final document = controller.active!;
        final before = document.base;
        document.commit(document.current.copyWith(name: 'Keep me'));
        final pending = controller.save(document);
        port.saves.single.result.completeError(
          MapWorkspaceFailure(problem, 'Expected failure'),
        );
        expect(await pending, isFalse);
        expect(document.base, same(before));
        expect(document.current.name, 'Keep me');
        expect(document.dirty, isTrue);
        expect(document.saving, isFalse);
        expect(document.error, 'Expected failure');
      },
    );
  }

  test('saveAll refuses closing if a document changed during save', () async {
    await controller.initialize();
    final document = controller.active!;
    document.commit(document.current.copyWith(name: 'Snapshot'));
    final pending = controller.saveAll();
    document.commit(document.current.copyWith(name: 'Keep newer work'));
    port.saves.single.result.complete('saved-1');
    expect(await pending, isFalse);
    expect(controller.dirty, isTrue);
  });

  test(
    'saveAll stops on failure and leaves every later document dirty',
    () async {
      await controller.initialize();
      final first = controller.active!;
      first.commit(first.current.copyWith(name: 'Dirty A'));
      await controller.activate(m1Second);
      final second = controller.active!;
      second.commit(second.current.copyWith(name: 'Dirty B'));
      final pending = controller.saveAll();
      port.saves.single.result.completeError(
        const MapWorkspaceFailure(MapWorkspaceProblem.conflict, 'Conflict'),
      );
      expect(await pending, isFalse);
      expect(port.saves.length, 1);
      expect(first.dirty, isTrue);
      expect(second.dirty, isTrue);
    },
  );

  test('disposed save completion cannot accept a new baseline', () async {
    await controller.initialize();
    final document = controller.active!;
    document.commit(document.current.copyWith(name: 'Snapshot'));
    final pending = controller.save(document);
    controller.dispose();
    port.saves.single.result.complete('saved-1');
    expect(await pending, isFalse);
    expect(document.base.revision, 'revision-a');
    expect(document.dirty, isTrue);
  });

  test('a disposed empty controller cannot authorize saveAll close', () async {
    controller.dispose();
    expect(await controller.saveAll(), isFalse);
  });

  test('failed navigation preserves the previous dirty document', () async {
    await controller.initialize();
    final current = controller.active!;
    current.commit(current.current.copyWith(name: 'Keep edits'));
    port.pendingLoads['b'] = Completer<MapWorkspaceDocument>();
    final pending = controller.activate(m1Second);
    port.pendingLoads['b']!.completeError(
      const MapWorkspaceFailure(
        MapWorkspaceProblem.invalidDocument,
        'Invalid B',
      ),
    );
    await pending;
    expect(controller.active, same(current));
    expect(current.current.name, 'Keep edits');
    expect(controller.dirty, isTrue);
    expect(controller.loading, isFalse);
    expect(controller.error, 'Invalid B');
  });

  test(
    'saveAll succeeds only after all dirty documents finish sequentially',
    () async {
      await controller.initialize();
      expect(await controller.save(controller.active!), isTrue);
      expect(port.saves, isEmpty);
      controller.active!.commit(
        controller.active!.current.copyWith(name: 'Dirty A'),
      );
      await controller.activate(m1Second);
      controller.active!.commit(
        controller.active!.current.copyWith(name: 'Dirty B'),
      );
      final pending = controller.saveAll();
      expect(port.saves.length, 1);
      port.saves.first.result.complete('saved-a');
      await Future<void>.delayed(Duration.zero);
      expect(port.saves.length, 2);
      expect(controller.saving, isTrue);
      port.saves.last.result.complete('saved-b');
      expect(await pending, isTrue);
      expect(controller.saving, isFalse);
      expect(controller.dirty, isFalse);
    },
  );
}
