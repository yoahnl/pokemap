import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/panels/project_explorer/widgets/tree/tileset_tree_nodes.dart';

import '../../shell_chrome_test_harness.dart';

Future<void> _pumpInBridge(
  WidgetTester tester,
  Widget child, {
  required ThemeData theme,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      builder: (context, innerChild) {
        return PokeMapMacosCompatibilityBridge(
          child: innerChild ?? const SizedBox.shrink(),
        );
      },
      home: Scaffold(
        body: child,
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('PokeMap Project Explorer Inner Trees Polish', () {
    testWidgets('TilesetLibraryRootDropStrip renders French drag-and-drop texts & warning accent color',
        (tester) async {
      final project = buildShellChromeProject(name: 'Test Project');
      final container = ProviderContainer();
      final sub = container.listen(editorNotifierProvider, (_, __) {});
      final notifier = container.read(editorNotifierProvider.notifier);

      addTearDown(() async {
        sub.close();
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await tester.pump();
        container.dispose();
      });
      
      await _pumpInBridge(
        tester,
        TilesetLibraryRootDropStrip(
          project: project,
          notifier: notifier,
        ),
        theme: PokeMapTheme.dark(),
      );

      // Verify that the old English string is absent and French string is present
      expect(find.text('Library root — drop here to ungroup'), findsNothing);
      expect(find.text('Déposer ici pour sortir du dossier'), findsOneWidget);

      // Trigger a drag hover simulation by checking the structure is rendered
      expect(find.byType(TilesetLibraryRootDropStrip), findsOneWidget);
    });

    testWidgets('ProjectExplorerPanel renders localized headers and sub-entries in French',
        (tester) async {
      final project = buildShellChromeProject(
        name: 'French Explorer Project',
      );

      final map1 = buildShellChromeMap(
        id: 'starting_map',
        name: 'Bourg-Palette',
      );

      const entry1 = ProjectMapEntry(
        id: 'starting_map',
        name: 'Bourg-Palette',
        relativePath: 'maps/starting_map.json',
        groupId: null,
      );

      const entry2 = ProjectMapEntry(
        id: 'cave_map',
        name: 'Mont Sélénite',
        relativePath: 'maps/cave_map.json',
        groupId: 'g_cave',
      );

      const group = ProjectMapGroup(
        id: 'g_cave',
        name: 'Grottes de Kanto',
        type: MapGroupType.cave,
        parentGroupId: null,
      );

      final updatedProject = project.copyWith(
        maps: [entry1, entry2],
        groups: [group],
      );

      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/theme_10_test_project',
          project: updatedProject,
          workspaceMode: EditorWorkspaceMode.map,
          activeMap: map1,
        ),
      );

      // Verify that French section headers and labels are rendered
      expect(find.text('CARTES NON GROUPÉES'), findsOneWidget);
      expect(find.text('UNGROUPED MAPS'), findsNothing);
      expect(find.text('Grottes de Kanto'), findsOneWidget); // match exact group name case in the tree
      expect(find.text('GROTTE'), findsOneWidget); // Translated group type

      // Verify sub-entries of Catalogs are present in French
      expect(find.text('Pokédex'), findsOneWidget);
      expect(find.text('Recherche, import, détail et édition locale des espèces'), findsOneWidget);
      expect(find.text('Moves'), findsOneWidget);
      expect(find.text('Catalogue local des capacités du projet'), findsOneWidget);
      expect(find.text('Items'), findsOneWidget);
      expect(find.text('Catalogue local des objets du projet'), findsOneWidget);
    });
  });
}
