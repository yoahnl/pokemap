import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

import '../shell_chrome_test_harness.dart';

void main() {
  group('Environment Studio — entrée workspace', () {
    testWidgets(
        'EditorCanvasHost affiche le shell quand le mode est environmentStudio',
        (tester) async {
      await pumpEditorCanvasHostHarness(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/env_studio_canvas',
          project: buildShellChromeProject(),
          workspaceMode: EditorWorkspaceMode.environmentStudio,
        ),
      );

      expect(find.byKey(const Key('environment-studio-shell')), findsOneWidget);
    });

    testWidgets('affiche le message projet absent sans manifest',
        (tester) async {
      await pumpEditorCanvasHostHarness(
        tester,
        initialState: const EditorState(
          workspaceMode: EditorWorkspaceMode.environmentStudio,
        ),
      );

      expect(
        find.byKey(const Key('environment-studio-missing-project')),
        findsOneWidget,
      );
    });

    testWidgets(
        'le project explorer ouvre Environment Studio au tap (clé dédiée)',
        (tester) async {
      final container = await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/env_studio_explorer',
          project: buildShellChromeProject(),
        ),
      );

      expect(
        find.byKey(const Key('project-explorer-environment-studio-entry')),
        findsOneWidget,
      );
      expect(find.textContaining('shell read-only'), findsNothing);
      expect(find.textContaining('lecture seule'), findsNothing);

      await tester.ensureVisible(
        find.byKey(const Key('project-explorer-environment-studio-entry')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('project-explorer-environment-studio-entry')),
      );
      await tester.pumpAndSettle();

      expect(
        container.read(editorNotifierProvider).workspaceMode,
        EditorWorkspaceMode.environmentStudio,
      );
      expect(find.byKey(const Key('environment-studio-title')), findsOneWidget);
    });
  });
}
