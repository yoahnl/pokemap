import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/design_system/pokemap_icon_button.dart';

import '../shell_chrome_test_harness.dart';

void main() {
  testWidgets('World Explorer opens Personalization Studio from a real project',
      (tester) async {
    final container = await pumpEditorShellPage(
      tester,
      initialState: EditorState(
        projectRootPath: '/tmp/personalization-studio-project',
        project: buildShellChromeProject(),
        workspaceMode: EditorWorkspaceMode.map,
      ),
      surfaceSize: const Size(1600, 1000),
    );

    final entry = find.byKey(
      const ValueKey<String>('personalization-studio-module-card'),
    );
    expect(entry, findsOneWidget);
    expect(find.text('Personalization Studio'), findsWidgets);

    await tester.ensureVisible(entry);
    await tester.tap(entry);
    await tester.pumpAndSettle();

    expect(
      container.read(editorNotifierProvider).workspaceMode,
      EditorWorkspaceMode.personalizationStudio,
    );
    expect(
      find.byKey(const Key('personalization-studio-title')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('project-explorer-toggle')),
    );
    await tester.pumpAndSettle();

    final reopen = find.byKey(
      const ValueKey<String>('project-explorer-reopen-toggle'),
    );
    final accessibleButton = find.descendant(
      of: reopen,
      matching: find.byType(PokeMapIconButton),
    );
    expect(accessibleButton, findsOneWidget);
    expect(
      find.bySemanticsLabel('Rouvrir l’explorateur global'),
      findsOneWidget,
    );
  });
}
