import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/editor/application/project_session_controller.dart';
import 'package:map_editor/src/features/editor/application/project_session_models.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_selectors.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

import 'shell_chrome_test_harness.dart';

void main() {
  testWidgets('Character Studio is a first-class canvas workspace', (
    tester,
  ) async {
    await pumpEditorCanvasHostHarness(
      tester,
      initialState: EditorState(
        projectRootPath: '/tmp/character-studio-routing',
        project: buildShellChromeProject(),
        workspaceMode: EditorWorkspaceMode.characterStudio,
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('character-studio-workspace')),
      findsOneWidget,
    );
  });

  testWidgets('Character Studio Explorer card opens and remains selected', (
    tester,
  ) async {
    final container = await pumpEditorShellPage(
      tester,
      initialState: EditorState(
        projectRootPath: '/tmp/character-studio-explorer',
        project: buildShellChromeProject(),
      ),
      surfaceSize: const Size(1672, 980),
    );
    final card = find.byKey(
      const ValueKey<String>('character-studio-module-card'),
    );

    expect(card, findsOneWidget);
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    await tester.tap(card);
    await tester.pumpAndSettle();

    expect(
      container.read(editorNotifierProvider).workspaceMode,
      EditorWorkspaceMode.characterStudio,
    );
    expect(
      find.byKey(const ValueKey<String>('character-studio-workspace')),
      findsOneWidget,
    );
    expect(
      container.read(editorShellSnapshotProvider).workspaceTitle,
      'Character Studio',
    );
    expect(
      container.read(editorShellSnapshotProvider).workspaceSubtitle,
      'Personnages, portraits et animations du projet.',
    );
  });

  test('reopening a project from Character Studio restores a valid mode', () {
    const controller = ProjectSessionController();
    final reopened = controller.openProjectSession(
      current: EditorState(
        projectRootPath: '/tmp/old-project',
        project: buildShellChromeProject(name: 'Old'),
        workspaceMode: EditorWorkspaceMode.characterStudio,
      ),
      session: ProjectSessionLoadResult(
        projectRootPath: '/tmp/new-project',
        project: buildShellChromeProject(name: 'New'),
      ),
      statusMessage: 'Projet ouvert',
    );

    expect(reopened.workspaceMode, EditorWorkspaceMode.map);
  });
}
