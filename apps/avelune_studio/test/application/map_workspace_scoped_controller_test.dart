import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/scoped_map_workspace_port.dart';

void main() {
  test('working initialization and map activation retain only the active selection', () async {
    final port = ScopedTestMapPort();
    final controller = MapWorkspaceController(scopedMapSession, port);
    addTearDown(controller.dispose);
    await controller.initialize();
    expect(port.fullReads, 0);
    expect(controller.projectScope, MapWorkspaceProjectScope.mapSelection);
    expect(controller.project!.tilesets.map((e) => e.id), ['first']);
    await controller.activate(secondScopedMap);
    expect(controller.project!.tilesets.map((e) => e.id), ['second']);
    await controller.activate(firstScopedMap);
    expect(controller.project!.tilesets.map((e) => e.id), ['first']);
    expect(port.selections, ['first', 'second']);
    expect(controller.hasCompleteProject, isFalse);
  });

  test('complete workshops are an explicit materialization which retains map drafts', () async {
    final port = ScopedTestMapPort();
    final controller = MapWorkspaceController(scopedMapSession, port);
    addTearDown(controller.dispose);
    await controller.initialize();
    final active = controller.active!;
    active.current = active.current.copyWith(name: 'Brouillon conservé');
    await controller.materializeProject();
    expect(port.fullReads, 1);
    expect(controller.hasCompleteProject, isTrue);
    expect(controller.project!.tilesets, hasLength(2));
    expect(controller.active, same(active));
    expect(controller.active!.current.name, 'Brouillon conservé');
  });
}
