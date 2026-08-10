import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show Key;
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/canvas/encounter_studio_panel.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';
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

  testWidgets('opens the exact table requested by a World Map deep link', (
    tester,
  ) async {
    await pumpEditorCanvasHostHarness(
      tester,
      surfaceSize: const Size(1280, 900),
      initialState: EditorState(
        projectRootPath: '/tmp/encounter-studio-deep-link',
        project: buildShellChromeProject(
          encounterTables: const <ProjectEncounterTable>[
            ProjectEncounterTable(
              id: 'route_1_grass',
              name: 'Route 1 — Hautes herbes',
              encounterKind: EncounterKind.walk,
            ),
            ProjectEncounterTable(
              id: 'route_1_surf',
              name: 'Route 1 — Surf',
              encounterKind: EncounterKind.surf,
            ),
          ],
        ),
        workspaceMode: EditorWorkspaceMode.encounter,
        encounterStudioTableId: 'route_1_surf',
      ),
    );

    final selectedCard = tester.widget<PokeMapCard>(
      find.byKey(const Key('encounter-tables-table-toggle-route_1_surf')),
    );
    expect(selectedCard.selected, isTrue);
    expect(
      find.byKey(const Key('encounter-tables-edit-name-field-route_1_surf')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('encounter-tables-edit-name-field-route_1_grass')),
      findsNothing,
    );
  });
}
