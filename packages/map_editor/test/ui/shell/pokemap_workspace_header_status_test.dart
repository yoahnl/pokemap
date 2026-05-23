import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/design_system/pokemap_badge.dart';
import 'package:map_editor/src/ui/editor_shell_page.dart';

import '../../shell_chrome_test_harness.dart';

void main() {
  group('PokeMap Workspace Header & Status Bar Polish Tests', () {
    testWidgets(
        'Renders default French workspace header and status bar when no map is active',
        (tester) async {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/workspace_header_test',
          project: buildShellChromeProject(),
          workspaceMode: EditorWorkspaceMode.map,
          activeMap: null,
          zoom: 1.0,
        ),
      );

      // 1. Verify workspace header
      expect(find.text('Espace carte'), findsWidgets);
      expect(
        find.text('Ouvrez une carte pour commencer à construire votre monde.'),
        findsWidgets,
      );
      expect(find.text('Map Workspace'), findsNothing);
      expect(
        find.text('Open a map to start building your world.'),
        findsNothing,
      );

      // 2. Verify Scène badge
      final sceneBadgeFinder = find.descendant(
        of: find.byType(EditorShellPage),
        matching: find.byWidgetPredicate(
          (widget) => widget is PokeMapBadge && widget.label == 'Scène',
        ),
      );
      expect(sceneBadgeFinder, findsWidgets);
      expect(find.text('Scene'), findsNothing);

      // 3. Verify status bar defaults
      expect(find.text('Prêt'), findsWidgets);
      expect(find.text('Ready'), findsNothing);
      expect(find.text('Zoom 100 %'), findsWidgets);
      expect(find.text('Zoom 100%'), findsNothing); // Zoom should have French spacing
    });

    testWidgets(
        'Renders active map information in French in both header and status bar',
        (tester) async {
      final map = buildShellChromeMap(
        id: 'starter_town',
        name: 'Bourg-Palette',
        width: 32,
        height: 24,
        layers: [
          const TileLayer(
            id: 'ground',
            name: 'Ground',
            tilesetId: 'world',
            tiles: [],
          ),
        ],
      );

      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/workspace_header_test',
          project: buildShellChromeProject(maps: [
            const ProjectMapEntry(
              id: 'starter_town',
              name: 'Bourg-Palette',
              relativePath: 'maps/starter_town.json',
              role: MapRole.exterior,
            ),
          ]),
          workspaceMode: EditorWorkspaceMode.map,
          activeMap: map,
          zoom: 1.25,
        ),
      );

      // 1. Verify header updates with map name and French size details
      expect(find.text('Bourg-Palette'), findsWidgets);
      expect(find.text('32 × 24 tuiles • 1 couches'), findsWidgets);
      expect(find.textContaining(RegExp(r'\btiles\b')), findsNothing);
      expect(find.textContaining(RegExp(r'\blayers\b')), findsNothing);

      // 2. Verify status bar updates with map id chip and Zoom chip
      expect(find.text('Carte starter_town'), findsWidgets);
      expect(find.text('Map starter_town'), findsNothing);
      expect(find.text('32 x 24'), findsWidgets);
      expect(find.text('Zoom 125 %'), findsWidgets);
    });

    testWidgets(
        'Renders French status message when project is loaded',
        (tester) async {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/workspace_header_test',
          project: buildShellChromeProject(name: 'Selbrume'),
          workspaceMode: EditorWorkspaceMode.map,
          statusMessage: 'Projet « Selbrume » chargé',
        ),
      );

      expect(find.text('Projet « Selbrume » chargé'), findsWidgets);
      expect(find.text('Project "Selbrume" loaded'), findsNothing);
    });
  });
}
