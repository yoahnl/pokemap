import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> waitForOrder(MapWorkspaceController workspace) async {
  final deadline = DateTime.now().add(const Duration(seconds: 10));
  while (workspace.active!.saving && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  expect(workspace.active!.saving, isFalse);
}
