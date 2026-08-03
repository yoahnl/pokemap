import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/adaptive_map_inspector.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_layers_inspector.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_workspace_session.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';
import 'package:map_editor/src/ui/panels/map_inspector_panel.dart';
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
    testWidgets(
        'InspectorSectionCard uses PokeMap design tokens and custom border radius',
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
      final Container containerWidget =
          tester.widget<Container>(containerFinder);
      final BoxDecoration? deco = containerWidget.decoration as BoxDecoration?;
      expect(deco?.color, equals(PokeMapColorTokens.dark.surfaceBase));
      expect(deco?.border?.top.color,
          equals(PokeMapColorTokens.dark.borderSubtle));
      expect(deco?.borderRadius, equals(BorderRadius.circular(12)));
    });

    testWidgets(
        'AdaptiveMapInspector replaces the legacy full map inspector panel',
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
          TileLayer(
              id: 'layer_tiles_1', name: 'Sol principal', isVisible: true),
          SmartTileLayer(
            id: 'layer_terrain_1',
            name: 'Herbe base',
            isVisible: true,
            presetId: 'grass',
            usage: SmartTileUsage.terrain,
            field: SmartTileField.cell(),
          ),
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

      expect(find.byType(AdaptiveMapInspector), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('adaptive-map-inspector')),
        findsOneWidget,
      );
      expect(find.byType(MapInspectorPanel), findsNothing);
      expect(
        find.byKey(
          const ValueKey<String>('world-map-inspector-body-empty'),
        ),
        findsOneWidget,
      );
      expect(find.text('Aucune sélection'), findsWidgets);
      expect(find.text('Propriétés de carte'), findsNothing);
      expect(find.text('Tuiles & éléments'), findsNothing);
    });

    testWidgets('adaptive layers inspector renders localized rows and actions',
        (tester) async {
      final project = buildShellChromeProject(
        name: 'Layers Panel Project',
      );

      final map = buildShellChromeMap(
        id: 'starting_map',
        name: 'Bourg-Palette',
        layers: const [
          TileLayer(
              id: 'layer_tiles_1', name: 'Sol principal', isVisible: true),
          SmartTileLayer(
            id: 'layer_terrain_1',
            name: 'Herbe base',
            isVisible: false,
            presetId: 'grass',
            usage: SmartTileUsage.terrain,
            field: SmartTileField.cell(),
          ),
        ],
      );

      final container = await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/theme_9_test_project',
          project: project,
          workspaceMode: EditorWorkspaceMode.map,
          activeMap: map,
          activeLayerId: 'layer_tiles_1',
        ),
      );

      final result = container
          .read(worldMapWorkspaceSessionProvider.notifier)
          .activateLayers(container.read(editorNotifierProvider.notifier));
      expect(result.accepted, isTrue);
      await tester.pump();

      expect(find.byType(WorldMapLayersInspector), findsOneWidget);
      expect(
        find.byKey(
          const ValueKey<String>('world-map-layer-row-layer_tiles_1'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('world-map-layer-row-layer_terrain_1'),
        ),
        findsOneWidget,
      );
      expect(find.text('Sol principal'), findsOneWidget);
      expect(find.text('Herbe base'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('world-map-layer-add')),
        findsOneWidget,
      );
      expect(find.byType(PokeMapIconButton), findsWidgets);
    });
  });
}
