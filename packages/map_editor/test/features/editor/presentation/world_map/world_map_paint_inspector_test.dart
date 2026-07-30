import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/border_map_editing/presentation/border_layer_inspector_panel.dart';
import 'package:map_editor/src/features/border_map_editing/state/border_map_editing_providers.dart';
import 'package:map_editor/src/features/editor/application/world_map_subtool_body_projector.dart';
import 'package:map_editor/src/features/editor/application/world_map_tool_activation.dart';
import 'package:map_editor/src/features/editor/application/world_map_tool_family.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_collision_inspector.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_paint_inspection_intent.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_paint_inspector.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_workspace_session.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';
import 'package:map_editor/src/features/surface_painter/surface_palette_panel.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';
import 'package:map_editor/src/ui/panels/terrain_map_panel.dart';
import 'package:map_editor/src/ui/panels/tileset_palette/widgets/browser/map_palette_asset_browser.dart';
import 'package:map_editor/src/ui/panels/tileset_palette/widgets/palette/map_layer_asset_palette.dart';

void main() {
  testWidgets('projects all six Paint subtools to their real body',
      (tester) async {
    const tileBrush = EditorBrush.tile(tileId: 1, tilesetId: 'world');
    const cases = <({
      WorldMapPaintSubtool subtool,
      String layerId,
      WorldMapSubtoolBodyKind bodyKind,
      Type bodyType,
      EditorToolType resultingTool,
      EditorBrush resultingBrush,
    })>[
      (
        subtool: WorldMapPaintSubtool.tile,
        layerId: 'tile',
        bodyKind: WorldMapSubtoolBodyKind.tilesPalette,
        bodyType: MapLayerAssetPalette,
        resultingTool: EditorToolType.tilePaint,
        resultingBrush: tileBrush,
      ),
      (
        subtool: WorldMapPaintSubtool.terrain,
        layerId: 'terrain',
        bodyKind: WorldMapSubtoolBodyKind.terrainPainter,
        bodyType: TerrainMapPanel,
        resultingTool: EditorToolType.terrainPaint,
        resultingBrush: EditorBrush.none(),
      ),
      (
        subtool: WorldMapPaintSubtool.path,
        layerId: 'path',
        bodyKind: WorldMapSubtoolBodyKind.pathPainter,
        bodyType: TerrainMapPanel,
        resultingTool: EditorToolType.terrainPaint,
        resultingBrush: EditorBrush.none(),
      ),
      (
        subtool: WorldMapPaintSubtool.surface,
        layerId: 'surface',
        bodyKind: WorldMapSubtoolBodyKind.surfacePainter,
        bodyType: SurfacePainterPanel,
        resultingTool: EditorToolType.surfacePaint,
        resultingBrush: EditorBrush.none(),
      ),
      (
        subtool: WorldMapPaintSubtool.border,
        layerId: 'border',
        bodyKind: WorldMapSubtoolBodyKind.borderInspector,
        bodyType: BorderLayerInspectorPanel,
        resultingTool: EditorToolType.borderPaint,
        resultingBrush: EditorBrush.none(),
      ),
      (
        subtool: WorldMapPaintSubtool.collision,
        layerId: 'collision',
        bodyKind: WorldMapSubtoolBodyKind.collisionInspector,
        bodyType: WorldMapCollisionInspector,
        resultingTool: EditorToolType.collisionPaint,
        resultingBrush: EditorBrush.none(),
      ),
    ];

    for (final testCase in cases) {
      final harness = _PaintHarness(testCase.layerId);
      addTearDown(harness.dispose);
      if (testCase.subtool == WorldMapPaintSubtool.border) {
        harness.selectBorderFeature();
      }
      final result = harness.session.activateTool(
        harness.notifier,
        ActivateWorldMapPaint(testCase.subtool),
      );
      expect(result.accepted, isTrue, reason: testCase.subtool.name);
      expect(
        result.resultingTool,
        testCase.resultingTool,
        reason: testCase.subtool.name,
      );

      await harness.pump(tester);

      expect(find.byType(testCase.bodyType), findsOneWidget);
      expect(
        find.byKey(
          ValueKey<String>(
            'world-map-paint-body-${testCase.bodyKind.name}',
          ),
        ),
        findsOneWidget,
      );
      expect(
        harness.notifier.state.activeTool,
        testCase.resultingTool,
      );
      expect(
        harness.notifier.state.activeBrush,
        testCase.resultingBrush,
      );
      if (testCase.subtool == WorldMapPaintSubtool.tile) {
        expect(
          tester
              .widget<MapLayerAssetPalette>(
                find.byType(MapLayerAssetPalette),
              )
              .mode,
          MapLayerAssetPaletteMode.tiles,
        );
        expect(find.byType(MapPaletteAssetBrowserLauncher), findsOneWidget);
      }
      if (testCase.subtool == WorldMapPaintSubtool.terrain) {
        expect(
          tester.widget<TerrainMapPanel>(find.byType(TerrainMapPanel)).mode,
          TerrainMapPanelMode.groundOnly,
        );
      }
      if (testCase.subtool == WorldMapPaintSubtool.path) {
        expect(
          tester.widget<TerrainMapPanel>(find.byType(TerrainMapPanel)).mode,
          TerrainMapPanelMode.surfaceOnly,
        );
      }

      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets(
    'disabled Paint guidance is focusable semantic and keyboard read-only',
    (tester) async {
      final harness = _PaintHarness(
        'tile',
        initialSession: const WorldMapWorkspaceSession(
          activeFamily: WorldMapToolFamily.paint,
          lastPaintSubtool: WorldMapPaintSubtool.terrain,
        ),
      );
      addTearDown(harness.dispose);
      final before = harness.notifier.state;

      await harness.pump(tester);

      const reason = 'Paint/terrain requires an active terrain layer.';
      final guidance = find.byKey(
        const ValueKey<String>('world-map-inspector-disabled-guidance'),
      );
      expect(guidance, findsOneWidget);
      expect(find.text(reason), findsOneWidget);
      expect(
        tester.widget<Focus>(guidance).canRequestFocus,
        isTrue,
      );
      expect(
        tester.getSemantics(guidance).flagsCollection.isFocused,
        isNot(Tristate.none),
      );
      expect(
        find.descendant(
          of: guidance,
          matching: find.byType(PokeMapButton),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: guidance,
          matching: find.byType(PokeMapIconButton),
        ),
        findsNothing,
      );

      Focus.of(tester.element(find.text(reason))).requestFocus();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(harness.notifier.state, same(before));
      expect(harness.notifier.state.mapUndoStack, isEmpty);
      expect(harness.notifier.state.mapRedoStack, isEmpty);
      expect(harness.notifier.state.isDirty, isFalse);
    },
  );

  testWidgets(
    'Surface setup is one real body and arms only from its explicit buttons',
    (tester) async {
      final harness = _PaintHarness(
        'surface',
        selectedSurfacePresetId: null,
      );
      addTearDown(harness.dispose);
      harness.showSetup(WorldMapPaintSubtool.surface);
      final beforeEditor = harness.notifier.state;
      final beforeSession = harness.sessionState;

      await harness.pump(tester);

      expect(find.byType(SurfacePainterPanel), findsOneWidget);
      expect(_mountedPaintBodyCount(), 1);
      expect(
        find.text('Select an available surface before painting.'),
        findsOneWidget,
      );
      expect(harness.notifier.state, same(beforeEditor));
      expect(harness.sessionState, same(beforeSession));

      await tester.tap(
        find.byKey(const ValueKey<String>('surface-palette-preset-water')),
      );
      await tester.pump();

      expect(harness.notifier.state.selectedSurfacePresetId, 'water');
      expect(
        harness.notifier.state.activeTool,
        EditorToolType.selection,
      );
      expect(harness.notifier.state.activeBrush, beforeEditor.activeBrush);
      expect(harness.notifier.state.mapUndoStack, isEmpty);
      expect(harness.notifier.state.mapRedoStack, isEmpty);
      expect(harness.sessionState, same(beforeSession));
      expect(harness.paintInspectionIntent, isNotNull);

      await tester.tap(find.text('Peindre Surface'));
      await tester.pump();

      expect(
        harness.notifier.state.activeTool,
        EditorToolType.surfacePaint,
      );
      expect(
        harness.sessionState.activeFamily,
        WorldMapToolFamily.paint,
      );
      expect(harness.paintInspectionIntent, isNull);

      await tester.tap(find.text('Effacer Surface'));
      await tester.pump();

      expect(harness.notifier.state.activeTool, EditorToolType.eraser);
      expect(
        harness.sessionState.activeFamily,
        WorldMapToolFamily.erase,
      );
    },
  );

  testWidgets(
    'Border setup stays inert until explicit transactional Paint and Erase',
    (tester) async {
      final harness = _PaintHarness('border');
      addTearDown(harness.dispose);
      harness.clearBorderSelection();
      harness.showSetup(WorldMapPaintSubtool.border);
      final beforeEditor = harness.notifier.state;
      final beforeSession = harness.sessionState;

      await harness.pump(tester);

      expect(find.byType(BorderLayerInspectorPanel), findsOneWidget);
      expect(_mountedPaintBodyCount(), 1);
      expect(
        tester
            .widgetList<PokeMapDiagnosticCallout>(
              find.byType(PokeMapDiagnosticCallout),
            )
            .map((callout) => callout.message),
        contains('Sélectionnez ou créez une bordure dans ce calque.'),
      );
      expect(harness.notifier.state, same(beforeEditor));
      expect(harness.sessionState, same(beforeSession));

      final borderFeature = find.byKey(
        const ValueKey<String>('border-feature-coast'),
      );
      await tester.ensureVisible(borderFeature);
      await tester.tap(borderFeature);
      await tester.pump();

      expect(harness.notifier.state.activeTool, EditorToolType.selection);
      expect(harness.notifier.state.activeBrush, beforeEditor.activeBrush);
      expect(harness.notifier.state.mapUndoStack, isEmpty);
      expect(harness.notifier.state.mapRedoStack, isEmpty);
      expect(harness.sessionState, same(beforeSession));
      expect(harness.paintInspectionIntent, isNotNull);

      final paintButton = find.byKey(
        const ValueKey<String>('border-inspector-paint-button'),
      );
      await tester.ensureVisible(paintButton);
      await tester.tap(paintButton);
      await tester.pump();

      expect(harness.notifier.state.activeTool, EditorToolType.borderPaint);
      expect(
        harness.sessionState.activeFamily,
        WorldMapToolFamily.paint,
      );
      expect(harness.paintInspectionIntent, isNull);

      final eraseButton = find.byKey(
        const ValueKey<String>('border-inspector-erase-button'),
      );
      await tester.ensureVisible(eraseButton);
      await tester.tap(eraseButton);
      await tester.pump();

      expect(harness.notifier.state.activeTool, EditorToolType.borderErase);
      expect(
        harness.sessionState.activeFamily,
        WorldMapToolFamily.erase,
      );
    },
  );

  testWidgets('empty Border setup exposes creation without arming the tool',
      (tester) async {
    final harness = _PaintHarness(
      'border',
      map: _mapWithEmptyBorder,
    );
    addTearDown(harness.dispose);
    harness.showSetup(WorldMapPaintSubtool.border);
    final beforeEditor = harness.notifier.state;
    final beforeSession = harness.sessionState;

    await harness.pump(tester);

    expect(find.byType(BorderLayerInspectorPanel), findsOneWidget);
    expect(_mountedPaintBodyCount(), 1);
    expect(
      find.byKey(const ValueKey<String>('border-create-feature-button')),
      findsOneWidget,
    );
    expect(harness.notifier.state, same(beforeEditor));
    expect(harness.sessionState, same(beforeSession));
  });

  testWidgets(
    'Terrain and Path embedded actions keep editor and typed session coherent',
    (tester) async {
      final terrainHarness = _PaintHarness(
        'terrain',
        initialSession: const WorldMapWorkspaceSession(
          activeFamily: WorldMapToolFamily.erase,
          lastPaintSubtool: WorldMapPaintSubtool.terrain,
        ),
      );
      addTearDown(terrainHarness.dispose);

      await terrainHarness.pump(tester);
      await tester.tap(find.text('Peindre le fond'));
      await tester.pump();

      expect(
        terrainHarness.notifier.state.activeTool,
        EditorToolType.terrainPaint,
      );
      expect(
        terrainHarness.sessionState.activeFamily,
        WorldMapToolFamily.paint,
      );
      expect(
        terrainHarness.sessionState.lastPaintSubtool,
        WorldMapPaintSubtool.terrain,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      final pathHarness = _PaintHarness(
        'path',
        initialSession: const WorldMapWorkspaceSession(
          activeFamily: WorldMapToolFamily.erase,
          lastPaintSubtool: WorldMapPaintSubtool.path,
        ),
      );
      addTearDown(pathHarness.dispose);

      await pathHarness.pump(tester);
      await tester.tap(find.text('Peindre le path'));
      await tester.pump();

      expect(
        pathHarness.notifier.state.activeTool,
        EditorToolType.terrainPaint,
      );
      expect(
        pathHarness.sessionState.activeFamily,
        WorldMapToolFamily.paint,
      );
      expect(
        pathHarness.sessionState.lastPaintSubtool,
        WorldMapPaintSubtool.path,
      );

      await tester.tap(find.text('Gommer'));
      await tester.pump();

      expect(pathHarness.notifier.state.activeTool, EditorToolType.eraser);
      expect(
        pathHarness.sessionState.activeFamily,
        WorldMapToolFamily.erase,
      );
    },
  );
}

int _mountedPaintBodyCount() {
  return <Type>[
    MapLayerAssetPalette,
    TerrainMapPanel,
    SurfacePainterPanel,
    BorderLayerInspectorPanel,
    WorldMapCollisionInspector,
  ].map((type) => find.byType(type).evaluate().length).reduce((a, b) => a + b);
}

class _PaintHarness {
  _PaintHarness(
    String activeLayerId, {
    WorldMapWorkspaceSession initialSession = const WorldMapWorkspaceSession(),
    MapData? map,
    String? selectedSurfacePresetId = 'water',
  })  : map = map ?? _map,
        activeLayerId = activeLayerId,
        container = ProviderContainer(
          overrides: <Override>[
            worldMapWorkspaceSessionProvider.overrideWith(
              () => _TestSessionController(initialSession),
            ),
          ],
        ) {
    keepAlive = container.listen(editorNotifierProvider, (_, __) {});
    notifier.state = EditorState(
      projectRootPath: '/virtual/project',
      project: _project,
      workspaceMode: EditorWorkspaceMode.map,
      activeMap: this.map,
      activeLayerId: activeLayerId,
      activeBrush: const EditorBrush.tile(tileId: 1, tilesetId: 'world'),
      selectedTerrainType: TerrainType.grass,
      selectedTerrainPresetId: 'grass',
      selectedSurfacePresetId: selectedSurfacePresetId,
      savedMapSnapshot: this.map,
    );
  }

  final MapData map;
  final String activeLayerId;
  final ProviderContainer container;
  late final ProviderSubscription<EditorState> keepAlive;

  EditorNotifier get notifier =>
      container.read(editorNotifierProvider.notifier);

  WorldMapWorkspaceSessionController get session =>
      container.read(worldMapWorkspaceSessionProvider.notifier);

  WorldMapWorkspaceSession get sessionState =>
      container.read(worldMapWorkspaceSessionProvider);

  WorldMapPaintInspectionIntent? get paintInspectionIntent =>
      container.read(worldMapPaintInspectionIntentProvider);

  void showSetup(WorldMapPaintSubtool subtool) {
    container.read(worldMapPaintInspectionIntentProvider.notifier).showSetup(
          mapId: map.id,
          layerId: activeLayerId,
          subtool: subtool,
        );
  }

  void selectBorderFeature() {
    container
        .read(activeBorderFeatureControllerProvider.notifier)
        .selectFeature(
          map: map,
          layerId: 'border',
          featureId: 'coast',
        );
  }

  void clearBorderSelection() {
    container.read(activeBorderFeatureControllerProvider.notifier).clear();
  }

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        key: ValueKey<Object>(container),
        container: container,
        child: MaterialApp(
          theme: PokeMapTheme.light(),
          home: const Scaffold(
            body: SizedBox(
              width: 440,
              height: 720,
              child: WorldMapPaintInspector(),
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

class _TestSessionController extends WorldMapWorkspaceSessionController {
  _TestSessionController(this.initialSession);

  final WorldMapWorkspaceSession initialSession;

  @override
  WorldMapWorkspaceSession build() => initialSession;
}

final _project = ProjectManifest(
  name: 'Paint inspector',
  maps: const <ProjectMapEntry>[],
  tilesets: const <ProjectTilesetEntry>[
    ProjectTilesetEntry(
      id: 'world',
      name: 'World',
      relativePath: 'tilesets/world.png',
    ),
  ],
  terrainPresets: const <ProjectTerrainPreset>[
    ProjectTerrainPreset(
      id: 'grass',
      name: 'Grass',
      terrainType: TerrainType.grass,
    ),
  ],
  surfaceCatalog: ProjectSurfaceCatalog(
    presets: <ProjectSurfacePreset>[
      ProjectSurfacePreset(
        id: 'water',
        name: 'Water',
        variantAnimations: SurfaceVariantAnimationRefSet(
          refs: <SurfaceVariantAnimationRef>[
            SurfaceVariantAnimationRef(
              role: SurfaceVariantRole.isolated,
              animationId: 'water-idle',
            ),
          ],
        ),
      ),
    ],
  ),
  borderCatalog: ProjectBorderCatalog(
    records: <BorderBlueprintRecord>[
      BorderBlueprintRecord(
        id: 'coast-blueprint',
        draft: BorderBlueprintDraft(
          baseRevision: 1,
          definition: BorderBlueprintDraftDefinition(
            name: 'Coast',
            previewSeed: BorderSignedInt64.zero,
            template: BorderBlueprintTemplate.organicEdge,
            primitives: const <BorderPrimitiveDraft>[],
            defaults: _borderParams,
            sortOrder: 0,
          ),
        ),
        latestPublished: BorderBlueprintRevision(
          revision: 1,
          definition: BorderBlueprintPublishedDefinition(
            name: 'Coast',
            previewSeed: BorderSignedInt64.zero,
            template: BorderBlueprintTemplate.organicEdge,
            primitives: const <BorderPublishedPrimitive>[],
            defaults: _borderParams,
            sortOrder: 0,
          ),
        ),
      ),
    ],
  ),
);

final _borderParams = BorderGenerationParams(
  irregularityPermille: 0,
  detailDensityPermille: 0,
  variationPermille: 0,
  maxOverlapPx: 0,
  gapTolerancePx: 0,
  depthRows: 1,
);

final _map = MapData(
  id: 'map',
  name: 'Map',
  version: ProjectVersion.v2,
  size: const GridSize(width: 4, height: 4),
  layers: <MapLayer>[
    const TileLayer(
      id: 'tile',
      name: 'Tile',
      tilesetId: 'world',
      tiles: <int>[
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
      ],
    ),
    const TerrainLayer(
      id: 'terrain',
      name: 'Terrain',
      terrains: <TerrainType>[],
    ),
    const PathLayer(
      id: 'path',
      name: 'Path',
      cells: <bool>[],
    ),
    const SurfaceLayer(id: 'surface', name: 'Surface'),
    const CollisionLayer(
      id: 'collision',
      name: 'Collision',
      collisions: <bool>[],
    ),
    MapLayer.border(
      id: 'border',
      name: 'Border',
      content: BorderLayerContent(
        features: <BorderFeature>[
          BorderFeature(
            id: 'coast',
            name: 'Coast',
            blueprintId: 'coast-blueprint',
            seed: BorderSignedInt64.zero,
            geometry: BorderRegionGeometry(
              width: 4,
              height: 4,
              cells: const <bool>[
                false,
                false,
                false,
                false,
                false,
                false,
                false,
                false,
                false,
                false,
                false,
                false,
                false,
                false,
                false,
                false,
              ],
            ),
            overrides: const <BorderSlotOverride>[],
            keepOutRegions: const <BorderKeepOutRegion>[],
          ),
        ],
      ),
    ),
  ],
);

final _mapWithEmptyBorder = _map.copyWith(
  layers: <MapLayer>[
    for (final layer in _map.layers)
      if (layer.id == 'border')
        const BorderLayer(id: 'border', name: 'Border')
      else
        layer,
  ],
);
