import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

import 'shell_chrome_test_harness.dart';

void main() {
  group('TopToolbar', () {
    testWidgets('shows the app brand and project workspace label',
        (tester) async {
      await pumpTopToolbarHarness(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/top_toolbar_project',
          project: buildShellChromeProject(name: 'Pokemon Map'),
          workspaceMode: EditorWorkspaceMode.pokedex,
        ),
      );

      expect(find.text('RPG Map Editor'), findsOneWidget);
      expect(find.text('Pokemon Map  •  Pokédex'), findsOneWidget);
    });

    testWidgets('falls back to the workspace label when no project is loaded',
        (tester) async {
      await pumpTopToolbarHarness(
        tester,
        initialState: const EditorState(),
      );

      expect(find.text('RPG Map Editor'), findsOneWidget);
      expect(find.text('World Editor'), findsOneWidget);
    });

    testWidgets('shows the toolbar status chip when a status is present',
        (tester) async {
      await pumpTopToolbarHarness(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/top_toolbar_status',
          project: buildShellChromeProject(),
          statusMessage: 'Map saved',
        ),
      );

      expect(find.text('Map saved'), findsOneWidget);
    });
  });
}
