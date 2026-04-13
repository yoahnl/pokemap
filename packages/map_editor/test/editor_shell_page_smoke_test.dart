import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

import 'shell_chrome_test_harness.dart';

void main() {
  group('EditorShellPage smoke', () {
    testWidgets('renders map workspace chrome and toggles the right panel',
        (tester) async {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/editor_shell_smoke',
          project: buildShellChromeProject(),
        ),
      );

      expect(find.text('Map Workspace'), findsOneWidget);
      expect(
        find.text('Open a map to start building your world.'),
        findsOneWidget,
      );
      expect(find.text('Ready'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is MacosIconButton &&
              widget.semanticLabel == 'Hide right panel',
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.byWidgetPredicate(
          (widget) =>
              widget is MacosIconButton &&
              widget.semanticLabel == 'Hide right panel',
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is MacosIconButton &&
              widget.semanticLabel == 'Show right panel',
        ),
        findsOneWidget,
      );
    });

    testWidgets('updates the workspace header for tileset mode',
        (tester) async {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/editor_shell_tileset',
          project: buildShellChromeProject(
            tilesets: const <ProjectTilesetEntry>[
              ProjectTilesetEntry(
                id: 'indoor',
                name: 'Indoor',
                relativePath: 'tilesets/indoor.json',
              ),
            ],
          ),
          workspaceMode: EditorWorkspaceMode.tileset,
          selectedTilesetEditorId: 'indoor',
        ),
      );

      expect(find.text('Indoor'), findsAtLeastNWidgets(1));
      expect(
        find.text(
          'Visual library editing for tiles, elements and groups.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders the trainer studio workspace chrome', (tester) async {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/editor_shell_trainer',
          project: buildShellChromeProject(),
          workspaceMode: EditorWorkspaceMode.trainer,
        ),
      );

      expect(find.text('Trainer Studio'), findsWidgets);
      expect(
        find.textContaining('battle-ready rosters'),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('trainer-library-new-trainer-button')),
        findsOneWidget,
      );
    });

    testWidgets('renders shell chrome with an error state already present',
        (tester) async {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/editor_shell_error',
          project: buildShellChromeProject(),
          errorMessage: 'Shell render failure',
        ),
      );

      expect(find.text('Shell render failure'), findsOneWidget);
    });
  });
}
