import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/shared/top_toolbar/widgets/toolbar_capsules.dart';
import 'package:map_editor/src/ui/shared/pokemap_macos_ui_shim.dart';

import '../../shell_chrome_test_harness.dart';

void main() {
  group('PokeMap Topbar Migration', () {
    testWidgets('TopToolbar renders brand and custom themed elements under Dark Theme',
        (tester) async {
      await pumpTopToolbarHarness(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/topbar_migration_test',
          project: buildShellChromeProject(name: 'Theme 5 Test'),
          workspaceMode: EditorWorkspaceMode.map,
        ),
      );

      // Verify Brand title is rendered with appropriate style
      expect(find.text('RPG Map Editor'), findsOneWidget);
      expect(find.text('Theme 5 Test  •  World Editor'), findsOneWidget);

      // Verify the brand icon is rendered using MacosIcon
      expect(find.byType(MacosIcon), findsWidgets);

      // Verify top level ToolBar container exists
      final toolbarFinder = find.byType(ToolBar);
      expect(toolbarFinder, findsOneWidget);

      // Verify the ToolBar uses the design system divider color and decoration background
      final ToolBar toolbarWidget = tester.widget<ToolBar>(toolbarFinder);
      expect(toolbarWidget.dividerColor, equals(PokeMapColorTokens.dark.divider));
      
      final toolbarDeco = toolbarWidget.decoration;
      expect(toolbarDeco?.color, equals(PokeMapColorTokens.dark.backgroundShell));

      // Verify custom themed capsules exist
      expect(find.byType(ToolbarCapsuleGroup), findsWidgets);
    });

    testWidgets('TopToolbar renders status message with brandPrimaryColors soft tint',
        (tester) async {
      await pumpTopToolbarHarness(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/topbar_status_test',
          project: buildShellChromeProject(name: 'Status Test'),
          workspaceMode: EditorWorkspaceMode.map,
          statusMessage: 'Prêt',
        ),
      );

      // Verify status message text
      expect(find.text('Prêt'), findsOneWidget);

      // Verify status message is wrapped in themed Container
      final statusContainerFinder = find.ancestor(
        of: find.text('Prêt'),
        matching: find.byType(Container),
      ).first;
      final Container statusContainer = tester.widget<Container>(statusContainerFinder);
      final statusDeco = statusContainer.decoration as BoxDecoration?;
      expect(statusDeco?.color, equals(PokeMapColorTokens.dark.brandPrimarySoft));
      
      final statusBorder = statusDeco?.border as Border?;
      expect(statusBorder?.top.color, equals(PokeMapColorTokens.dark.brandPrimaryBorder));
    });
  });
}
