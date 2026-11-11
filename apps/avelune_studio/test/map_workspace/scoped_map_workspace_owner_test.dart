import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_workflow.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/scoped_map_workspace_port.dart';

void main() {
  test(
    'scoped map test opens the runtime without loading all workshops',
    () async {
      final port = ScopedTestMapPort();
      final controller = MapWorkspaceController(scopedMapSession, port);
      addTearDown(controller.dispose);
      await controller.initialize();
      final launches = <String>[];
      final workflow = WorkspaceWorkflow(
        controller: controller,
        isActive: () => true,
        changed: () {},
        resources: () => null,
        narrative: () => null,
        confirmClose: () async => WorkspaceCloseChoice.cancel,
        flushFocus: () {},
        launchMap: (entry, revision) async {
          launches.add('${entry.id}@$revision');
          expect(port.fullReads, 0);
          expect(port.workshops, isEmpty);
          expect(controller.hasCompleteProject, isFalse);
        },
        launchGame: () async => launches.add('game'),
      );
      final document = controller.active;
      final reads = List.of(port.selections);

      await workflow.test();

      expect(launches, ['first@map-1']);
      expect(workflow.testing, isFalse);
      expect(port.fullReads, 0);
      expect(port.workshops, isEmpty);
      expect(port.selections, reads);
      expect(controller.hasCompleteProject, isFalse);
      expect(controller.active, same(document));
      expect(controller.active!.dirty, isFalse);
    },
  );
}
