import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  test('a removed cached document cannot be activated or saved', () async {
    final port = WorkspaceMemoryPort();
    final controller = MapWorkspaceController(workspaceSession, port);
    addTearDown(controller.dispose);
    await controller.initialize();
    final document = controller.active!;
    document.commit(document.current.copyWith(name: 'Brouillon conservé'));
    controller.project = controller.project!.copyWith(
      maps: [workspaceEntries.last],
    );
    await controller.activate(workspaceEntries.first);
    expect(controller.active, isNot(same(document)));
    expect(await controller.save(document), isFalse);
    expect(port.writes, 0);
  });
}
