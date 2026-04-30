import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

import 'shell_chrome_test_harness.dart';

void main() {
  testWidgets('removed surface authoring workspace is not exposed in shell UI',
      (tester) async {
    await pumpEditorShellPage(
      tester,
      initialState: EditorState(
        projectRootPath: '/tmp/removed_surface_authoring_workspace',
        project: buildShellChromeProject(),
      ),
    );

    expect(find.text(_removedWorkspaceLabel()), findsNothing);
    expect(
        find.byTooltip('Switch to ${_removedWorkspaceLabel()}'), findsNothing);
    expect(
        find.byKey(const Key('surface-studio-workspace-entry')), findsNothing);
  });
}

String _removedWorkspaceLabel() => 'Surface ' 'Studio';
