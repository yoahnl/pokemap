import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';
import 'package:map_editor/src/ui/shared/inspector_section_card.dart';

import '../../shell_chrome_test_harness.dart';

// Minimal bridge harness to test widgets in isolation
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
  group('PokeMap Inspector Shell Migration', () {
    testWidgets('InspectorSectionCard uses PokeMap design tokens and custom border radius',
        (tester) async {
      await _pumpInBridge(
        tester,
        InspectorSectionCard(
          title: 'Calques',
          subtitle: 'Gérer les calques de la carte',
          icon: CupertinoIcons.layers,
          expanded: true,
          onToggle: () {},
          expandedHeight: 100,
          child: const Text('Contenu de test'),
        ),
        theme: PokeMapTheme.dark(),
      );

      // Verify title and subtitle are rendered correctly
      expect(find.text('Calques'), findsOneWidget);
      expect(find.text('Gérer les calques de la carte'), findsOneWidget);

      // Verify container decoration uses PokeMap surfaceBase and borderSubtle colors
      final containerFinder = find.byType(Container).first;
      final Container containerWidget = tester.widget<Container>(containerFinder);
      final BoxDecoration? deco = containerWidget.decoration as BoxDecoration?;
      expect(deco?.color, equals(PokeMapColorTokens.dark.surfaceBase));
      expect(deco?.border?.top.color, equals(PokeMapColorTokens.dark.borderSubtle));
      expect(deco?.borderRadius, equals(BorderRadius.circular(12)));
    });

    testWidgets('Full MapInspectorPanel renders localized sections and active overview card',
        (tester) async {
      final project = buildShellChromeProject(
        name: 'Inspector Shell Project',
      );

      final map = buildShellChromeMap(
        id: 'starting_map',
        name: 'Bourg-Palette',
        width: 15,
        height: 10,
        layers: const [
          TileLayer(id: 'layer_tiles_1', name: 'Sol principal', isVisible: true),
          TerrainLayer(id: 'layer_terrain_1', name: 'Herbe base', isVisible: true),
        ],
      );

      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/theme_9_test_project',
          project: project,
          workspaceMode: EditorWorkspaceMode.map,
          activeMap: map,
          activeLayerId: 'layer_tiles_1',
        ),
      );

      // Verify Map Overview Card renders Bourg-Palette in French
      expect(find.text('Bourg-Palette'), findsNWidgets(2));
      expect(find.text('15 x 10 tuiles  •  2 couches'), findsNWidgets(2));
      expect(find.text('Calque de tuiles actif'), findsOneWidget);

      // Verify French section headers are present
      expect(find.text('Propriétés de carte'), findsOneWidget);
      expect(find.text('Calques'), findsOneWidget);
      expect(find.text('Tuiles & éléments'), findsOneWidget);

      // Verify that old English names do not exist
      expect(find.text('Layers'), findsNothing);
      expect(find.text('Base Ground'), findsNothing);
      expect(find.text('Map Entities'), findsNothing);
    });

    testWidgets('LayersPanel renders localized options and action buttons',
        (tester) async {
      final project = buildShellChromeProject(
        name: 'Layers Panel Project',
      );

      final map = buildShellChromeMap(
        id: 'starting_map',
        name: 'Bourg-Palette',
        layers: const [
          TileLayer(id: 'layer_tiles_1', name: 'Sol principal', isVisible: true),
          TerrainLayer(id: 'layer_terrain_1', name: 'Herbe base', isVisible: false),
        ],
      );

      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/theme_9_test_project',
          project: project,
          workspaceMode: EditorWorkspaceMode.map,
          activeMap: map,
          activeLayerId: 'layer_tiles_1',
        ),
      );

      // Verify layers panel titles
      expect(find.text('Actions du calque'), findsWidgets);
      
      // Verify layer rows are shown with correct styles and statuses
      expect(find.text('Sol principal'), findsOneWidget);
      expect(find.text('Herbe base'), findsOneWidget);
      expect(find.text('tuiles • layer_tiles_1'), findsOneWidget);
      expect(find.text('terrain • layer_terrain_1'), findsOneWidget);

      // Verify action buttons are rendered using PokeMapIconButton
      expect(find.byType(PokeMapIconButton), findsWidgets);
    });
  });
}
