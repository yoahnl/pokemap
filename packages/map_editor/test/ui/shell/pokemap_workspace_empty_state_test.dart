import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/shared/map_workspace_empty_state.dart';
import 'package:map_editor/src/ui/panels/map_inspector_empty_state.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';
import 'package:map_core/map_core.dart';

import '../../shell_chrome_test_harness.dart';

void main() {
  group('PokeMap Workspace & Inspector Empty States Migration', () {
    testWidgets('Renders empty states with correct branding and actions when project is loaded but no map is active',
        (tester) async {
      final project = buildShellChromeProject(
        name: 'Empty State Project',
        maps: [
          buildShellChromeMap(id: 'map_1', name: 'Starting Town'),
          buildShellChromeMap(id: 'map_2', name: 'Route 101'),
        ].map((m) => ProjectMapEntry(
          id: m.id,
          name: m.name,
          relativePath: 'maps/${m.id}.json',
          role: MapRole.exterior,
        )).toList(),
      );

      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/theme_6_test_project',
          project: project,
          workspaceMode: EditorWorkspaceMode.map,
          activeMap: null,
        ),
      );

      // 1. Verify workspace central empty state is displayed
      expect(find.byType(MapWorkspaceEmptyState), findsOneWidget);
      expect(find.text('Aucune carte ouverte'), findsOneWidget);
      expect(find.text('Ouvrez une carte existante ou créez-en une nouvelle pour commencer à éditer votre monde.'), findsOneWidget);
      
      // Verify actions
      expect(find.widgetWithText(PokeMapButton, 'Créer une carte'), findsOneWidget);
      expect(find.widgetWithText(PokeMapButton, 'Ouvrir une carte'), findsOneWidget);
      expect(find.text('Sélectionnez une carte existante ou créez-en une nouvelle depuis ce projet.'), findsOneWidget);

      // Verify that old/forbidden texts do not exist inside empty states
      expect(find.text('No Map Loaded'), findsNothing);
      expect(find.textContaining('Tanset'), findsNothing);
      expect(find.descendant(of: find.byType(MapWorkspaceEmptyState), matching: find.textContaining('glissez')), findsNothing);
      expect(find.descendant(of: find.byType(MapWorkspaceEmptyState), matching: find.textContaining('glisser')), findsNothing);
      expect(find.descendant(of: find.byType(MapWorkspaceEmptyState), matching: find.textContaining('drag')), findsNothing);
      expect(find.descendant(of: find.byType(MapWorkspaceEmptyState), matching: find.textContaining('drop')), findsNothing);
      expect(find.descendant(of: find.byType(MapInspectorEmptyState), matching: find.textContaining('glissez')), findsNothing);
      expect(find.descendant(of: find.byType(MapInspectorEmptyState), matching: find.textContaining('glisser')), findsNothing);
      expect(find.descendant(of: find.byType(MapInspectorEmptyState), matching: find.textContaining('drag')), findsNothing);
      expect(find.descendant(of: find.byType(MapInspectorEmptyState), matching: find.textContaining('drop')), findsNothing);

      // Verify listed existing maps inside workspace empty state
      expect(find.descendant(of: find.byType(MapWorkspaceEmptyState), matching: find.text('Starting Town')), findsOneWidget);
      expect(find.descendant(of: find.byType(MapWorkspaceEmptyState), matching: find.text('Route 101')), findsOneWidget);

      // 2. Verify right inspector empty state is displayed
      expect(find.byType(MapInspectorEmptyState), findsOneWidget);
      expect(find.text('Ouvrez une carte pour voir ses calques et systèmes'), findsOneWidget);
      expect(find.text('Une fois une carte ouverte, vous pourrez :'), findsOneWidget);
      
      // Verify capabilities are present
      expect(find.text('Gérer les calques de tuiles'), findsOneWidget);
      expect(find.text('Placer des objets et PNJ'), findsOneWidget);
      expect(find.text('Définir les collisions'), findsOneWidget);
      expect(find.text('Créer des événements'), findsOneWidget);
      expect(find.text('Ajuster l\'ambiance'), findsOneWidget);

      // Verify Récents and Astuces sections
      expect(find.text('RÉCENTS'), findsOneWidget);
      expect(find.text('Aucune carte récente.\nOuvrez une carte pour les voir ici.'), findsOneWidget);
      expect(find.text('ASTUCES'), findsOneWidget);
    });

    testWidgets('Renders empty state when no project is loaded',
        (tester) async {
      await pumpEditorShellPage(
        tester,
        initialState: const EditorState(
          projectRootPath: null,
          project: null,
          workspaceMode: EditorWorkspaceMode.map,
          activeMap: null,
        ),
      );

      // Verify workspace central empty state is displayed for no project
      expect(find.byType(MapWorkspaceEmptyState), findsOneWidget);
      expect(find.text('Aucun projet ouvert'), findsOneWidget);
      expect(find.text('Ouvrez un projet existant ou créez-en un nouveau pour commencer à travailler.'), findsOneWidget);
      
      // Verify actions
      expect(find.widgetWithText(PokeMapButton, 'Créer un projet'), findsOneWidget);
      expect(find.widgetWithText(PokeMapButton, 'Ouvrir un projet'), findsOneWidget);
    });
  });
}
