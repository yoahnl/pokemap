import 'dart:async';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_workflow.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/ui06_scene_fixture.dart';

void main() {
  test('full project launch and map launch retain separate routes', () async {
    final fixture = await Ui06SceneFixture.create();
    addTearDown(fixture.dispose);
    final maps = MapWorkspaceController(fixture.session, fixture.maps);
    addTearDown(maps.dispose);
    await maps.initialize();
    var mapLaunches = 0, projectLaunches = 0;
    Completer<void>? started, returned;
    final actions = WorkspaceWorkflow(
      controller: maps,
      isActive: () => true,
      changed: () {},
      resources: () => null,
      narrative: () => null,
      confirmClose: () async => WorkspaceCloseChoice.cancel,
      flushFocus: () {},
      launchMap: (entry, revision) async {
        expect(entry.id, maps.active!.current.id);
        expect(revision, maps.active!.base.revision);
        mapLaunches++;
        started!.complete();
        await returned!.future;
      },
      launchGame: () async {
        projectLaunches++;
        started!.complete();
        await returned!.future;
      },
    );
    for (final fullProject in [true, false]) {
      started = Completer<void>();
      returned = Completer<void>();
      final running = actions.test(fullProject: fullProject);
      await started.future.timeout(const Duration(seconds: 5));
      expect(actions.testing, isTrue);
      returned.complete();
      await running;
      expect(actions.testing, isFalse);
    }
    expect(projectLaunches, 1);
    expect(mapLaunches, 1);
  });
}
