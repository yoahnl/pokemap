import 'dart:async';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_map_catalog_actions.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  test(
    'catalogue operation refuses overlap and releases its guard after failure',
    () async {
      final controller = MapWorkspaceController(
        workspaceSession,
        WorkspaceMemoryPort(),
      );
      addTearDown(controller.dispose);
      final gate = Completer<void>();
      var operations = 0;
      final first = runWorkspaceMapCatalogOperation(controller, () async {
        operations++;
        await gate.future;
        throw StateError('operation refused');
      });
      final failure = expectLater(first, throwsStateError);
      await runWorkspaceMapCatalogOperation(
        controller,
        () async => operations++,
      );
      expect(operations, 1);
      gate.complete();
      await failure;
      await runWorkspaceMapCatalogOperation(
        controller,
        () async => operations++,
      );
      expect(operations, 2);
    },
  );
}
