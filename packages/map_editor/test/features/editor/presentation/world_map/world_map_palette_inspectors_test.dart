import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/application/world_map_tool_activation.dart';
import 'package:map_editor/src/features/editor/application/world_map_tool_family.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_paint_inspector.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_place_inspector.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_workspace_session.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/panels/tileset_palette/widgets/browser/map_palette_asset_browser.dart';
import 'package:map_editor/src/ui/panels/tileset_palette/widgets/palette/map_layer_asset_palette.dart';

void main() {
  testWidgets(
    'Paint Tile embeds the tile palette and source chooser',
    (tester) async {
      final harness = _InspectorHarness();
      addTearDown(harness.dispose);
      harness.session.activateTool(
        harness.notifier,
        const ActivateWorldMapPaint(WorldMapPaintSubtool.tile),
      );

      await harness.pump(tester, const WorldMapPaintInspector());

      final palette = tester.widget<MapLayerAssetPalette>(
        find.byType(MapLayerAssetPalette),
      );
      expect(palette.mode, MapLayerAssetPaletteMode.tiles);
      expect(find.byType(MapPaletteAssetBrowserLauncher), findsOneWidget);
      expect(find.text('Changer de source'), findsOneWidget);
    },
  );

  testWidgets(
    'Paint non-tile subtools show non-mutating guidance without an asset palette',
    (tester) async {
      final harness = _InspectorHarness(
        initialSession: const WorldMapWorkspaceSession(
          activeFamily: WorldMapToolFamily.paint,
          lastPaintSubtool: WorldMapPaintSubtool.terrain,
        ),
      );
      addTearDown(harness.dispose);
      final before = harness.notifier.state;

      await harness.pump(tester, const WorldMapPaintInspector());

      expect(find.byType(MapLayerAssetPalette), findsNothing);
      expect(find.textContaining('Terrain'), findsWidgets);
      expect(harness.notifier.state, before);
    },
  );

  testWidgets(
    'Place Object embeds the element palette and source chooser',
    (tester) async {
      final harness = _InspectorHarness();
      addTearDown(harness.dispose);
      harness.session.activateTool(
        harness.notifier,
        const ActivateWorldMapPlacement(WorldMapPlacementSubtool.object),
      );

      await harness.pump(tester, const WorldMapPlaceInspector());

      final palette = tester.widget<MapLayerAssetPalette>(
        find.byType(MapLayerAssetPalette),
      );
      expect(palette.mode, MapLayerAssetPaletteMode.elements);
      expect(find.byType(MapPaletteAssetBrowserLauncher), findsOneWidget);
      expect(find.text('Changer de source'), findsOneWidget);
    },
  );

  testWidgets(
    'Place non-object subtools show non-mutating guidance without an asset palette',
    (tester) async {
      final harness = _InspectorHarness(
        initialSession: const WorldMapWorkspaceSession(
          activeFamily: WorldMapToolFamily.place,
          lastPlacementSubtool: WorldMapPlacementSubtool.entity,
        ),
      );
      addTearDown(harness.dispose);
      final before = harness.notifier.state;

      await harness.pump(tester, const WorldMapPlaceInspector());

      expect(find.byType(MapLayerAssetPalette), findsNothing);
      expect(find.textContaining('Entity'), findsWidgets);
      expect(harness.notifier.state, before);
    },
  );
}

class _InspectorHarness {
  _InspectorHarness({
    WorldMapWorkspaceSession initialSession = const WorldMapWorkspaceSession(),
  }) : container = ProviderContainer(
          overrides: <Override>[
            worldMapWorkspaceSessionProvider.overrideWith(
              () => _TestWorldMapWorkspaceSessionController(initialSession),
            ),
          ],
        ) {
    keepAlive = container.listen(editorNotifierProvider, (_, __) {});
    notifier.state = const EditorState(
      projectRootPath: '/virtual/project',
      project: _project,
      workspaceMode: EditorWorkspaceMode.map,
      activeMap: _map,
      activeLayerId: 'ground',
    );
  }

  final ProviderContainer container;
  late final ProviderSubscription<EditorState> keepAlive;

  EditorNotifier get notifier =>
      container.read(editorNotifierProvider.notifier);

  WorldMapWorkspaceSessionController get session =>
      container.read(worldMapWorkspaceSessionProvider.notifier);

  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: PokeMapTheme.light(),
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: child,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  void dispose() {
    keepAlive.close();
    container.dispose();
  }
}

class _TestWorldMapWorkspaceSessionController
    extends WorldMapWorkspaceSessionController {
  _TestWorldMapWorkspaceSessionController(this.initialSession);

  final WorldMapWorkspaceSession initialSession;

  @override
  WorldMapWorkspaceSession build() => initialSession;
}

const _project = ProjectManifest(
  name: 'Inspecteurs palette',
  maps: <ProjectMapEntry>[
    ProjectMapEntry(
      id: 'town',
      name: 'Ville',
      relativePath: 'maps/town.json',
    ),
  ],
  tilesets: <ProjectTilesetEntry>[
    ProjectTilesetEntry(
      id: 'world',
      name: 'Monde',
      relativePath: 'tilesets/world.png',
    ),
  ],
  settings: ProjectSettings(tileWidth: 1, tileHeight: 1),
);

const _map = MapData(
  id: 'town',
  name: 'Ville',
  size: GridSize(width: 1, height: 1),
  layers: <MapLayer>[
    TileLayer(
      id: 'ground',
      name: 'Sol',
      tilesetId: 'world',
      tiles: <int>[0],
    ),
  ],
);
