import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/canvas/encounter_studio_panel.dart';
import 'package:map_editor/src/ui/panels/encounter_tables_panel.dart';
import 'package:map_editor/src/ui/panels/trainer_library_panel.dart';

import 'shell_chrome_test_harness.dart';

void main() {
  testWidgets('opens wild encounters by default and switches to trainers', (
    tester,
  ) async {
    final container = await pumpEditorCanvasHostHarness(
      tester,
      initialState: EditorState(
        projectRootPath: '/tmp/encounter-studio-workspace',
        project: buildShellChromeProject(),
        workspaceMode: EditorWorkspaceMode.encounter,
      ),
    );

    expect(find.byKey(encounterStudioPanelKey), findsOneWidget);
    expect(find.byType(EncounterTablesPanel), findsOneWidget);
    expect(find.byType(TrainerLibraryPanel), findsNothing);

    await tester.tap(find.byKey(encounterStudioTrainersTabKey));
    await tester.pumpAndSettle();

    expect(
      container.read(editorNotifierProvider).encounterStudioSection,
      EncounterStudioSection.trainers,
    );
    expect(find.byType(EncounterTablesPanel), findsNothing);
    expect(find.byType(TrainerLibraryPanel), findsOneWidget);
  });

  testWidgets('restores the active section and supports keyboard activation', (
    tester,
  ) async {
    final container = await pumpEditorCanvasHostHarness(
      tester,
      initialState: EditorState(
        projectRootPath: '/tmp/encounter-studio-keyboard',
        project: buildShellChromeProject(),
        workspaceMode: EditorWorkspaceMode.encounter,
        encounterStudioSection: EncounterStudioSection.trainers,
      ),
    );

    expect(find.byType(TrainerLibraryPanel), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(
      container.read(editorNotifierProvider).encounterStudioSection,
      EncounterStudioSection.wildEncounters,
    );
    expect(find.byType(EncounterTablesPanel), findsOneWidget);
  });
}
