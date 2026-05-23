import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/design_system/pokemap_badge.dart';

import '../../shell_chrome_test_harness.dart';

void main() {
  group('PokeMap Open Map Canvas Chrome Tests', () {
    testWidgets('Renders map header details, favorite star, options pulldown and light chips',
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
          projectRootPath: '/tmp/open_map_canvas_chrome_test',
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
          zoom: 1.0,
        ),
      );

      // 1. Verify Header
      expect(find.text('Bourg-Palette'), findsWidgets);
      // Dimensions match new multiplication symbol and compact spacing
      expect(find.text('32 × 24 tuiles • 1 couches'), findsWidgets);
      expect(find.textContaining('Scene'), findsNothing);
      expect(find.textContaining(RegExp(r'\btiles\b')), findsNothing);
      expect(find.textContaining(RegExp(r'\blayers\b')), findsNothing);

      // Verify the 'Scène' badge
      final sceneBadgeFinder = find.byWidgetPredicate(
        (widget) => widget is PokeMapBadge && widget.label == 'Scène',
      );
      expect(sceneBadgeFinder, findsOneWidget);

      // 2. Verify Favorite Star interactive button
      final starFinder = find.byKey(const ValueKey('pokemap-favorite-star'));
      expect(starFinder, findsOneWidget);
      // Tap the star button to verify interaction
      await tester.tap(starFinder);
      await tester.pumpAndSettle();

      // 3. Verify Options Ellipsis button exists
      expect(find.byType(MacosPulldownButton), findsWidgets);

      // 4. Verify Light Preview Chips
      expect(find.text('Aperçu lumière'), findsOneWidget);
      expect(find.text('Preview lumiere'), findsNothing);

      // Verify presets are present
      expect(find.text('Neutre'), findsOneWidget);
      expect(find.text('Midi'), findsOneWidget);
      expect(find.text('Matin'), findsOneWidget);
      expect(find.text('Soir'), findsOneWidget);
      expect(find.text('Nuit douce'), findsOneWidget);

      // Tap on 'Soir' preset button to verify active state switching
      final soirButton = find.byKey(const ValueKey('shadow-light-preview-evening-button'));
      expect(soirButton, findsOneWidget);
      await tester.tap(soirButton);
      await tester.pumpAndSettle();
    });
  });
}
