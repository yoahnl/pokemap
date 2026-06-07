import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/ui/shared/pokemap_macos_ui_shim.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/shared/top_toolbar/widgets/toolbar_capsules.dart';

import '../../shell_chrome_test_harness.dart';

void main() {
  group('PokeMap Topbar Command Groups Tests', () {
    testWidgets('Renders all 6 functional command groups and PokeMap brand logo',
        (tester) async {
      final container = await pumpTopToolbarHarness(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/topbar_command_groups_test',
          project: buildShellChromeProject(
            name: 'Selbrume Demo',
            tilesets: [
              const ProjectTilesetEntry(
                id: 'ts_1',
                name: 'Tileset 1',
                relativePath: 'tilesets/ts_1.json',
              ),
            ],
          ),
          activeMap: buildShellChromeMap(),
          workspaceMode: EditorWorkspaceMode.map,
        ),
        surfaceSize: const Size(1800, 220),
      );

      // Verify Brand elements
      expect(find.text('PokeMap'), findsOneWidget);
      expect(find.text('RPG Map Editor'), findsOneWidget);
      expect(find.text('Selbrume Demo  •  World Editor'), findsOneWidget);

      // Verify the 6 named capsule groups
      expect(find.text('Fichier'), findsOneWidget);
      expect(find.text('Carte'), findsOneWidget);
      expect(find.text('Affichage'), findsOneWidget);
      expect(find.text('Outils'), findsOneWidget);
      expect(find.text('Calques'), findsOneWidget);
      expect(find.text('Aperçu'), findsOneWidget);

      // Verify they are rendered inside ToolbarCapsuleGroup widgets
      final capsuleGroups = find.byType(ToolbarCapsuleGroup);
      expect(capsuleGroups, findsAtLeastNWidgets(1));

      // Verify buttons are clickable (e.g. Switch to tileset workspace)
      final tilesetButton = find.byWidgetPredicate(
        (widget) => widget is MacosTooltip && widget.message == 'Switch to tileset workspace',
      );
      expect(tilesetButton, findsOneWidget);
      await tester.tap(tilesetButton);
      await tester.pumpAndSettle();

      expect(container.read(editorNotifierProvider).workspaceMode, EditorWorkspaceMode.tileset);
    });
  });
}
