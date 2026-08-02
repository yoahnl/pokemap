import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
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
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_smart_tile_paint_palette.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';
import 'package:map_editor/src/features/surface_painter/surface_palette_panel.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';
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
        layerId: 'smart-terrain',
        bodyKind: WorldMapSubtoolBodyKind.terrainPainter,
        bodyType: WorldMapSmartTilePaintPalette,
        resultingTool: EditorToolType.terrainPaint,
        resultingBrush: EditorBrush.none(),
      ),
      (
        subtool: WorldMapPaintSubtool.path,
        layerId: 'smart-path',
        bodyKind: WorldMapSubtoolBodyKind.pathPainter,
        bodyType: WorldMapSmartTilePaintPalette,
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
          find.byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                widget.properties.label ==
                    'Catalogue d’éléments à placer du calque actif',
          ),
          findsOneWidget,
        );
        expect(find.byType(MapPaletteAssetBrowserLauncher), findsOneWidget);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets(
    'Terrain always exposes the published preset palette without mutation',
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

      expect(find.byType(WorldMapSmartTilePaintPalette), findsOneWidget);
      expect(find.text('Peindre un terrain'), findsOneWidget);
      expect(find.text('Prairie'), findsOneWidget);
      expect(find.text('Brouillon'), findsNothing);
      expect(find.text('Chemin'), findsNothing);

      expect(harness.notifier.state, same(before));
      expect(harness.notifier.state.mapUndoStack, isEmpty);
      expect(harness.notifier.state.mapRedoStack, isEmpty);
      expect(harness.notifier.state.isDirty, isFalse);
    },
  );

  testWidgets(
    'terrain preset creation stays disabled and explained before STN-03',
    (tester) async {
      final harness = _PaintHarness('tile', map: _tileOnlyMap);
      addTearDown(harness.dispose);
      harness.showMissingLayer(WorldMapPaintSubtool.terrain);

      await harness.pump(tester);

      final prairie = find.byKey(
        const ValueKey<String>(
          'world-map-smart-tile-terrain-preset-prairie',
        ),
      );
      expect(prairie, findsOneWidget);
      expect(
        find.text(smartTileNativeAuthoringRequiresStn03Code),
        findsOneWidget,
      );

      await tester.tap(prairie);
      await tester.pump();

      expect(
        harness.notifier.state.activeMap!.layers.whereType<SmartTileLayer>(),
        isEmpty,
      );
      expect(harness.notifier.state.mapUndoStack, isEmpty);
      expect(harness.notifier.state.isDirty, isFalse);
    },
  );

  testWidgets('compact terrain palette stays scrollable without overflow',
      (tester) async {
    final harness = _PaintHarness(
      'tile',
      map: _tileOnlyMap,
      initialSession: const WorldMapWorkspaceSession(
        activeFamily: WorldMapToolFamily.paint,
        lastPaintSubtool: WorldMapPaintSubtool.terrain,
      ),
    );
    addTearDown(harness.dispose);

    await harness.pump(tester, height: 280);

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(
        const ValueKey<String>('world-map-smart-tile-terrain-presets'),
      ),
      findsOneWidget,
    );
    expect(find.byType(Scrollable), findsWidgets);
  });

  testWidgets('narrow terrain palette uses one readable column',
      (tester) async {
    final harness = _PaintHarness(
      'tile',
      map: _tileOnlyMap,
      initialSession: const WorldMapWorkspaceSession(
        activeFamily: WorldMapToolFamily.paint,
        lastPaintSubtool: WorldMapPaintSubtool.terrain,
      ),
    );
    addTearDown(harness.dispose);

    await harness.pump(tester, width: 220);

    expect(find.text('Prairie'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('choosing an existing cell preset reuses its layer',
      (tester) async {
    final harness = _PaintHarness(
      'tile',
      map: _map,
      initialSession: const WorldMapWorkspaceSession(
        activeFamily: WorldMapToolFamily.paint,
        lastPaintSubtool: WorldMapPaintSubtool.terrain,
      ),
    );
    addTearDown(harness.dispose);
    final beforeLayerCount = _map.layers.length;

    await harness.pump(tester);
    await tester.tap(
      find.byKey(
        const ValueKey<String>(
          'world-map-smart-tile-terrain-preset-prairie',
        ),
      ),
    );
    await tester.pump();

    expect(harness.notifier.state.activeLayerId, 'smart-terrain');
    expect(
      harness.notifier.state.activeMap!.layers,
      hasLength(beforeLayerCount),
    );
    expect(harness.notifier.state.mapUndoStack, isEmpty);
    expect(harness.notifier.state.activeTool, EditorToolType.terrainPaint);
    expect(harness.sessionState.activeFamily, WorldMapToolFamily.paint);
  });

  testWidgets('path palette filters terrain and draft presets', (tester) async {
    final harness = _PaintHarness('tile', map: _tileOnlyMap);
    addTearDown(harness.dispose);
    harness.showMissingLayer(WorldMapPaintSubtool.path);

    await harness.pump(tester);

    expect(find.text('Peindre un chemin'), findsOneWidget);
    expect(find.text('Chemin'), findsOneWidget);
    expect(find.text('Prairie'), findsNothing);
    expect(find.text('Brouillon'), findsNothing);
  });

  testWidgets(
    'missing-layer guidance explains the required type and offers a safe add CTA',
    (tester) async {
      final harness = _PaintHarness(
        'tile',
        map: _tileOnlyMap,
      );
      addTearDown(harness.dispose);
      harness.showMissingLayer(WorldMapPaintSubtool.collision);
      final beforeEditor = harness.notifier.state;
      final beforeSession = harness.sessionState;

      await harness.pump(tester);

      final guidance = find.byKey(
        const ValueKey<String>('world-map-paint-missing-layer-guidance'),
      );
      final addButton = find.byKey(
        const ValueKey<String>('world-map-paint-add-required-layer'),
      );
      expect(guidance, findsOneWidget);
      expect(find.text('Calque de collision requis'), findsOneWidget);
      expect(
        find.text(
          'L’outil Collision peint uniquement dans un calque de collision.',
        ),
        findsOneWidget,
      );
      expect(find.text('Ajouter un calque de collision'), findsOneWidget);
      expect(
        tester.getSemantics(guidance).label,
        contains(
          'Calque de collision requis. '
          'L’outil Collision peint uniquement dans un calque de collision.',
        ),
      );
      expect(
        tester.getSemantics(addButton).flagsCollection.isButton,
        isTrue,
      );
      expect(harness.notifier.state, same(beforeEditor));
      expect(harness.sessionState, same(beforeSession));
      expect(harness.notifier.state.mapUndoStack, isEmpty);
      expect(harness.notifier.state.mapRedoStack, isEmpty);
      expect(harness.notifier.state.isDirty, isFalse);

      await tester.tap(addButton);
      await tester.pump();

      expect(
        harness.notifier.state.activeMap!.layers.whereType<CollisionLayer>(),
        hasLength(1),
      );
      expect(harness.notifier.state.activeTool, EditorToolType.collisionPaint);
      expect(harness.sessionState.activeFamily, WorldMapToolFamily.paint);
      expect(harness.paintInspectionIntent, isNull);
      expect(harness.notifier.state.mapUndoStack, hasLength(1));
      expect(harness.notifier.state.isDirty, isTrue);
    },
  );

  testWidgets(
    'stale add callback cannot mutate a homonymous map in another document',
    (tester) async {
      final harness = _PaintHarness(
        'tile',
        map: _tileOnlyMap,
        projectRootPath: '/projects/alpha',
        activeMapPath: '/projects/alpha/maps/shared.json',
      );
      addTearDown(harness.dispose);
      harness.showMissingLayer(WorldMapPaintSubtool.collision);
      await harness.pump(tester);
      final staleCallback = tester
          .widget<PokeMapButton>(
            find.byKey(
              const ValueKey<String>('world-map-paint-add-required-layer'),
            ),
          )
          .onPressed!;
      final nextMap = _tileOnlyMap.copyWith(name: 'Document homonyme B');
      harness.notifier.state = harness.notifier.state.copyWith(
        projectRootPath: '/projects/beta',
        activeMapPath: '/projects/beta/maps/shared.json',
        activeMap: nextMap,
        activeLayerId: 'tile',
        activeTool: EditorToolType.selection,
        savedMapSnapshot: nextMap,
      );
      await tester.pump();
      final before = harness.notifier.state;

      staleCallback();
      await tester.pump();

      expect(harness.notifier.state, same(before));
      expect(
        harness.notifier.state.activeMap!.layers.whereType<CollisionLayer>(),
        isEmpty,
      );
      expect(harness.notifier.state.mapUndoStack, isEmpty);
      expect(harness.notifier.state.isDirty, isFalse);
      expect(harness.paintInspectionIntent, isNull);
    },
  );

  testWidgets(
    'add callback rechecks missing routing before creating a layer',
    (tester) async {
      final harness = _PaintHarness('tile', map: _tileOnlyMap);
      addTearDown(harness.dispose);
      harness.showMissingLayer(WorldMapPaintSubtool.surface);
      await harness.pump(tester);
      final staleCallback = tester
          .widget<PokeMapButton>(
            find.byKey(
              const ValueKey<String>('world-map-paint-add-required-layer'),
            ),
          )
          .onPressed!;
      final updatedMap = _tileOnlyMap.copyWith(
        layers: <MapLayer>[
          ..._tileOnlyMap.layers,
          const SurfaceLayer(
            id: 'surface-existing',
            name: 'Surface existante',
          ),
        ],
      );
      harness.notifier.state = harness.notifier.state.copyWith(
        activeMap: updatedMap,
        activeLayerId: 'tile',
        activeTool: EditorToolType.selection,
        savedMapSnapshot: updatedMap,
      );
      await tester.pump();
      final before = harness.notifier.state;

      staleCallback();
      await tester.pump();

      expect(harness.notifier.state, same(before));
      expect(
        harness.notifier.state.activeMap!.layers.whereType<SurfaceLayer>(),
        hasLength(1),
      );
      expect(harness.notifier.state.activeLayerId, 'tile');
      expect(harness.notifier.state.activeTool, EditorToolType.selection);
      expect(harness.notifier.state.mapUndoStack, isEmpty);
      expect(harness.notifier.state.mapRedoStack, isEmpty);
      expect(harness.notifier.state.isDirty, isFalse);
      expect(harness.paintInspectionIntent, isNull);
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
        find.text('Sélectionnez une surface disponible avant de peindre.'),
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
    'Terrain and Path cell Smart Tile actions keep typed session coherent',
    (tester) async {
      final terrainHarness = _PaintHarness(
        'smart-terrain',
        initialSession: const WorldMapWorkspaceSession(
          activeFamily: WorldMapToolFamily.erase,
          lastPaintSubtool: WorldMapPaintSubtool.terrain,
        ),
      );
      addTearDown(terrainHarness.dispose);
      await terrainHarness.pump(tester);
      expect(
        find.text(smartTileWangPaintCompilerRequiredCode),
        findsNothing,
      );
      await tester.tap(
        find.byKey(
          const ValueKey<String>('world-map-smart-tile-terrain-paint'),
        ),
      );
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
        'smart-path',
        initialSession: const WorldMapWorkspaceSession(
          activeFamily: WorldMapToolFamily.erase,
          lastPaintSubtool: WorldMapPaintSubtool.path,
        ),
      );
      addTearDown(pathHarness.dispose);
      await pathHarness.pump(tester);
      expect(
        find.text(smartTileWangPaintCompilerRequiredCode),
        findsNothing,
      );
      await tester.tap(
        find.byKey(
          const ValueKey<String>('world-map-smart-tile-path-paint'),
        ),
      );
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

      await tester.tap(
        find.byKey(
          const ValueKey<String>('world-map-smart-tile-path-erase'),
        ),
      );
      await tester.pump();

      expect(pathHarness.notifier.state.activeTool, EditorToolType.eraser);
      expect(
        pathHarness.sessionState.activeFamily,
        WorldMapToolFamily.erase,
      );
      expect(
        pathHarness.paintInspectionIntent?.subtool,
        WorldMapPaintSubtool.path,
      );
    },
  );

  testWidgets('Wang Smart Tile actions stay disabled before STN-05',
      (tester) async {
    final harness = _PaintHarness(
      'smart-terrain',
      map: _mapWithWangTerrain,
      initialSession: const WorldMapWorkspaceSession(
        activeFamily: WorldMapToolFamily.erase,
        lastPaintSubtool: WorldMapPaintSubtool.terrain,
      ),
    );
    addTearDown(harness.dispose);
    final editorBefore = harness.notifier.state;
    final sessionBefore = harness.sessionState;

    await harness.pump(tester);
    expect(
      find.text(smartTileWangPaintCompilerRequiredCode),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(
        const ValueKey<String>('world-map-smart-tile-terrain-paint'),
      ),
    );
    await tester.pump();

    expect(harness.notifier.state, same(editorBefore));
    expect(harness.sessionState, same(sessionBefore));
  });

  testWidgets(
    'ignores viewport and status rebuilds but reacts to paint input changes',
    (tester) async {
      var rebuilds = 0;
      final harness = _PaintHarness(
        'collision',
        initialSession: const WorldMapWorkspaceSession(
          activeFamily: WorldMapToolFamily.paint,
          lastPaintSubtool: WorldMapPaintSubtool.collision,
        ),
      );
      addTearDown(harness.dispose);
      await harness.pump(
        tester,
        child: _CountingWorldMapPaintInspector(
          onBuild: () => rebuilds += 1,
        ),
      );
      expect(find.byType(WorldMapCollisionInspector), findsOneWidget);

      rebuilds = 0;
      harness.notifier.state = harness.notifier.state.copyWith(
        zoom: 2,
        panOffset: const Offset(12, 8),
        statusMessage: 'viewport-only',
      );
      await tester.pump();

      expect(rebuilds, 0);
      expect(find.byType(WorldMapCollisionInspector), findsOneWidget);

      harness.notifier.state = harness.notifier.state.copyWith(
        activeLayerId: 'tile',
      );
      await tester.pump();

      expect(rebuilds, greaterThan(0));
      expect(
        find.byKey(
          const ValueKey<String>('world-map-inspector-disabled-guidance'),
        ),
        findsOneWidget,
      );
    },
  );
}

int _mountedPaintBodyCount() {
  return <Type>[
    MapLayerAssetPalette,
    WorldMapSmartTilePaintPalette,
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
    String projectRootPath = '/virtual/project',
    String? activeMapPath,
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
      projectRootPath: projectRootPath,
      project: _project,
      workspaceMode: EditorWorkspaceMode.map,
      activeMap: this.map,
      activeMapPath: activeMapPath,
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

  void showLayerChoice(
    WorldMapPaintSubtool subtool,
    List<String> compatibleLayerIds,
  ) {
    container
        .read(worldMapPaintInspectionIntentProvider.notifier)
        .showLayerChoice(
          mapId: map.id,
          subtool: subtool,
          compatibleLayerIds: compatibleLayerIds,
        );
  }

  void showMissingLayer(WorldMapPaintSubtool subtool) {
    container
        .read(worldMapPaintInspectionIntentProvider.notifier)
        .showMissingLayer(
          mapId: map.id,
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

  Future<void> pump(
    WidgetTester tester, {
    Widget child = const WorldMapPaintInspector(),
    double width = 440,
    double height = 720,
  }) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        key: ValueKey<Object>(container),
        container: container,
        child: MaterialApp(
          theme: PokeMapTheme.light(),
          home: Scaffold(
            body: SizedBox(
              width: width,
              height: height,
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

class _CountingWorldMapPaintInspector extends WorldMapPaintInspector {
  const _CountingWorldMapPaintInspector({required this.onBuild});

  final VoidCallback onBuild;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    onBuild();
    return super.build(context, ref);
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
  smartTileCatalog: ProjectSmartTileCatalog(
    materials: const <ProjectSmartTileMaterial>[
      ProjectSmartTileMaterial(
        id: 'grass',
        name: 'Herbe',
        connectionGroupId: 'grass',
      ),
    ],
    presets: const <ProjectSmartTilePreset>[
      ProjectSmartTilePreset(
        id: 'prairie',
        name: 'Prairie',
        usage: SmartTileUsage.terrain,
        topology: SmartTileTopology.cardinal4,
        coveragePolicy: SmartTileCoveragePolicy.complete,
        coverageProfile: SmartTileCoverageProfile(
          mode: SmartTileCoverageMode.template,
        ),
        transformPolicy: SmartTileTransformPolicy(),
        status: SmartTilePresetStatus.published,
        defaultMaterialId: 'grass',
        allowedMaterialIds: <String>['grass'],
      ),
      ProjectSmartTilePreset(
        id: 'draft-terrain',
        name: 'Brouillon',
        usage: SmartTileUsage.terrain,
        topology: SmartTileTopology.cardinal4,
        coveragePolicy: SmartTileCoveragePolicy.complete,
        coverageProfile: SmartTileCoverageProfile(
          mode: SmartTileCoverageMode.template,
        ),
        transformPolicy: SmartTileTransformPolicy(),
        defaultMaterialId: 'grass',
        allowedMaterialIds: <String>['grass'],
      ),
      ProjectSmartTilePreset(
        id: 'path',
        name: 'Chemin',
        usage: SmartTileUsage.path,
        topology: SmartTileTopology.cardinal4,
        coveragePolicy: SmartTileCoveragePolicy.complete,
        coverageProfile: SmartTileCoverageProfile(
          mode: SmartTileCoverageMode.template,
        ),
        transformPolicy: SmartTileTransformPolicy(),
        status: SmartTilePresetStatus.published,
        defaultMaterialId: 'grass',
        allowedMaterialIds: <String>['grass'],
      ),
    ],
  ),
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
  version: ProjectVersion.v5,
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
    const SmartTileLayer(
      id: 'smart-terrain',
      name: 'Prairie',
      presetId: 'prairie',
      usage: SmartTileUsage.terrain,
      field: SmartTileField.cell(
        semanticCells: <int>[
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
    ),
    const SmartTileLayer(
      id: 'smart-path',
      name: 'Chemin',
      presetId: 'path',
      usage: SmartTileUsage.path,
      field: SmartTileField.cell(
        semanticCells: <int>[
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

final _mapWithWangTerrain = _map.copyWith(
  layers: _map.layers
      .map(
        (layer) => layer.id == 'smart-terrain'
            ? const SmartTileLayer(
                id: 'smart-terrain',
                name: 'Prairie Wang',
                presetId: 'prairie',
                usage: SmartTileUsage.terrain,
                field: SmartTileField.edge(
                  semanticCells: <int>[
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
                  horizontalEdges: <int>[],
                  verticalEdges: <int>[],
                ),
              )
            : layer,
      )
      .toList(growable: false),
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

final _tileOnlyMap = _map.copyWith(
  id: 'tile-only',
  name: 'Éléments uniquement',
  layers: <MapLayer>[
    _map.layers.whereType<TileLayer>().single,
  ],
);
