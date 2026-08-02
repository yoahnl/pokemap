import 'dart:ui' show SemanticsAction;

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/terrain_selection_mode.dart';
import 'package:map_editor/src/features/editor/application/map_layer_deletion_impact.dart';
import 'package:map_editor/src/features/editor/application/map_context_target.dart';
import 'package:map_editor/src/features/editor/application/world_map_tool_activation.dart';
import 'package:map_editor/src/features/editor/application/world_map_tool_family.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_layer_mutation_dialogs.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_layers_inspector.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_paint_inspection_intent.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_workspace_session.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/map_canvas.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets('shows one canonical top-first list and activates a layer',
      (tester) async {
    final harness = _Harness(_threeLayerMap(), activeLayerId: 'middle');
    addTearDown(harness.dispose);
    await harness.pump(tester);

    expect(find.byType(CustomScrollView), findsOneWidget);
    final top = tester.getTopLeft(
      find.byKey(const ValueKey<String>('world-map-layer-row-top')),
    );
    final middle = tester.getTopLeft(
      find.byKey(const ValueKey<String>('world-map-layer-row-middle')),
    );
    final bottom = tester.getTopLeft(
      find.byKey(const ValueKey<String>('world-map-layer-row-bottom')),
    );
    expect(top.dy, lessThan(middle.dy));
    expect(middle.dy, lessThan(bottom.dy));
    expect(
      find.byKey(const ValueKey<String>('world-map-layer-active-middle')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('world-map-layer-activate-top')),
    );
    await tester.pump();
    expect(harness.notifier.state.activeLayerId, 'top');
  });

  testWidgets(
    'layer row opens the canonical paint tool directly from Layers',
    (tester) async {
      final harness = _Harness(
        const MapData(
          id: 'map',
          name: 'Map',
          version: ProjectVersion.v5,
          size: GridSize(width: 1, height: 1),
          layers: <MapLayer>[
            TileLayer(id: 'tiles', name: 'Tuiles', tiles: <int>[0]),
            SmartTileLayer(
              id: 'terrain',
              name: 'Terrain',
              presetId: 'grass',
              usage: SmartTileUsage.terrain,
              field: SmartTileField.cell(semanticCells: _oneCell),
            ),
            SmartTileLayer(
              id: 'path',
              name: 'Chemin',
              presetId: 'road',
              usage: SmartTileUsage.path,
              field: SmartTileField.cell(semanticCells: _oneCell),
            ),
            CollisionLayer(
              id: 'collision',
              name: 'Collision',
              collisions: <bool>[false],
            ),
          ],
        ),
        activeLayerId: 'tiles',
      );
      addTearDown(harness.dispose);
      await harness.pump(tester, size: const Size(380, 920));

      for (final testCase in <({
        String layerId,
        EditorToolType tool,
        WorldMapPaintSubtool subtool,
        TerrainSelectionMode? terrainMode,
      })>[
        (
          layerId: 'tiles',
          tool: EditorToolType.tilePaint,
          subtool: WorldMapPaintSubtool.tile,
          terrainMode: null,
        ),
        (
          layerId: 'terrain',
          tool: EditorToolType.terrainPaint,
          subtool: WorldMapPaintSubtool.terrain,
          terrainMode: TerrainSelectionMode.terrain,
        ),
        (
          layerId: 'path',
          tool: EditorToolType.terrainPaint,
          subtool: WorldMapPaintSubtool.path,
          terrainMode: TerrainSelectionMode.path,
        ),
        (
          layerId: 'collision',
          tool: EditorToolType.collisionPaint,
          subtool: WorldMapPaintSubtool.collision,
          terrainMode: null,
        ),
      ]) {
        expect(
            harness.session.activateLayers(harness.notifier).accepted, isTrue);
        harness.session.pinInspector(WorldMapInspectorKind.layers);
        await tester.pump();

        await tester.tap(
          find.byKey(
            ValueKey<String>(
              'world-map-layer-activate-${testCase.layerId}',
            ),
          ),
        );
        await tester.pump();

        expect(
          harness.notifier.state.activeLayerId,
          testCase.layerId,
          reason: testCase.layerId,
        );
        expect(
          harness.notifier.state.activeTool,
          testCase.tool,
          reason: testCase.layerId,
        );
        if (testCase.terrainMode case final terrainMode?) {
          expect(
            harness.notifier.state.terrainSelectionMode,
            terrainMode,
            reason: testCase.layerId,
          );
        }
        expect(
          harness.sessionState.activeFamily,
          WorldMapToolFamily.paint,
          reason: testCase.layerId,
        );
        expect(
          harness.sessionState.lastPaintSubtool,
          testCase.subtool,
          reason: testCase.layerId,
        );
        expect(harness.sessionState.pinnedInspectorKind, isNull);
        expect(harness.sessionState.inspectorVisible, isTrue);
        expect(
          harness.container.read(worldMapPaintInspectionIntentProvider),
          isNull,
        );
      }
    },
  );

  testWidgets(
    'surface and border rows open their Paint setup instead of trapping the user in Layers',
    (tester) async {
      final harness = _Harness(
        const MapData(
          id: 'map',
          name: 'Map',
          version: ProjectVersion.v4,
          size: GridSize(width: 1, height: 1),
          layers: <MapLayer>[
            SurfaceLayer(id: 'surface', name: 'Surface'),
            BorderLayer(id: 'border', name: 'Bordures'),
          ],
        ),
        activeLayerId: 'surface',
      );
      addTearDown(harness.dispose);
      await harness.pump(tester);

      for (final testCase in <({
        String layerId,
        WorldMapPaintSubtool subtool,
      })>[
        (layerId: 'surface', subtool: WorldMapPaintSubtool.surface),
        (layerId: 'border', subtool: WorldMapPaintSubtool.border),
      ]) {
        expect(
            harness.session.activateLayers(harness.notifier).accepted, isTrue);
        harness.session.pinInspector(WorldMapInspectorKind.layers);
        harness.container
            .read(worldMapPaintInspectionIntentProvider.notifier)
            .clear();
        await tester.pump();

        await tester.tap(
          find.byKey(
            ValueKey<String>(
              'world-map-layer-activate-${testCase.layerId}',
            ),
          ),
        );
        await tester.pump();

        final intent = harness.container.read(
          worldMapPaintInspectionIntentProvider,
        );
        expect(harness.notifier.state.activeLayerId, testCase.layerId);
        expect(intent?.kind, WorldMapPaintInspectionIntentKind.setup);
        expect(intent?.layerId, testCase.layerId);
        expect(intent?.subtool, testCase.subtool);
        expect(harness.sessionState.pinnedInspectorKind, isNull);
        expect(harness.sessionState.inspectorVisible, isTrue);
      }
    },
  );

  testWidgets('compact inspector keeps layer rows reachable by local scroll',
      (tester) async {
    final harness = _Harness(_threeLayerMap(), activeLayerId: 'middle');
    addTearDown(harness.dispose);
    await harness.pump(tester, size: const Size(380, 260));

    final scrollable = find
        .descendant(
          of: find.byKey(const ValueKey<String>('world-map-layer-list')),
          matching: find.byType(Scrollable),
        )
        .first;
    final before = tester.state<ScrollableState>(scrollable).position;
    expect(before.maxScrollExtent, greaterThan(0));

    await tester.drag(scrollable, const Offset(0, -600));
    await tester.pumpAndSettle();

    final after = tester.state<ScrollableState>(scrollable).position;
    expect(after.pixels, greaterThan(0));
    expect(
      find.byKey(const ValueKey<String>('world-map-layer-row-bottom')),
      findsOneWidget,
    );
  });

  testWidgets('labels the projected row count as layer groups', (tester) async {
    final harness = _Harness(
      _threeLayerMap().copyWith(
        layers: [
          _tile('top', 'Top').copyWith(isVisible: false),
          _tile('middle', 'Middle'),
          _tile('bottom', 'Bottom'),
        ],
      ),
      activeLayerId: 'middle',
    );
    addTearDown(harness.dispose);
    await harness.pump(tester);

    expect(find.text('3 groupes de calques'), findsOneWidget);
    expect(find.textContaining('calque(s) visible(s)'), findsNothing);
  });

  testWidgets('shows compact rows with an explicit color-coded layer type',
      (tester) async {
    final harness = _Harness(
      const MapData(
        id: 'map',
        name: 'Map',
        version: ProjectVersion.v5,
        size: GridSize(width: 1, height: 1),
        layers: <MapLayer>[
          TileLayer(id: 'tiles', name: 'Sol', tiles: <int>[0]),
          SmartTileLayer(
            id: 'terrain',
            name: 'Herbe',
            presetId: 'grass',
            usage: SmartTileUsage.terrain,
            field: SmartTileField.cell(semanticCells: _oneCell),
          ),
          SmartTileLayer(
            id: 'path',
            name: 'Sentier',
            presetId: 'path',
            usage: SmartTileUsage.path,
            field: SmartTileField.cell(semanticCells: _oneCell),
          ),
        ],
      ),
      activeLayerId: 'tiles',
    );
    addTearDown(harness.dispose);
    await harness.pump(tester);

    expect(
      find.byKey(const ValueKey<String>('world-map-layer-type-tiles')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('world-map-layer-type-terrain')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('world-map-layer-type-path')),
      findsOneWidget,
    );
    expect(find.text('Tuiles'), findsOneWidget);
    expect(find.text('Terrain'), findsOneWidget);
    expect(find.text('Chemin'), findsOneWidget);

    expect(
      tester
          .widget<PokeMapPanel>(
            find.byKey(
              const ValueKey<String>('world-map-layer-card-tiles'),
            ),
          )
          .accentTone,
      PokeMapTone.brand,
    );
    expect(
      tester
          .widget<PokeMapPanel>(
            find.byKey(
              const ValueKey<String>('world-map-layer-card-terrain'),
            ),
          )
          .accentTone,
      PokeMapTone.success,
    );
    expect(
      tester
          .widget<PokeMapPanel>(
            find.byKey(
              const ValueKey<String>('world-map-layer-card-path'),
            ),
          )
          .accentTone,
      PokeMapTone.warning,
    );
    expect(
      tester
          .getSize(
            find.byKey(const ValueKey<String>('world-map-layer-row-tiles')),
          )
          .height,
      lessThan(120),
    );
  });

  testWidgets('filters layers by name and explicit type then resets',
      (tester) async {
    final harness = _Harness(
      const MapData(
        id: 'map',
        name: 'Map',
        version: ProjectVersion.v5,
        size: GridSize(width: 1, height: 1),
        layers: <MapLayer>[
          TileLayer(id: 'tiles', name: 'Sol principal', tiles: <int>[0]),
          SmartTileLayer(
            id: 'terrain',
            name: 'Herbe sombre',
            presetId: 'grass',
            usage: SmartTileUsage.terrain,
            field: SmartTileField.cell(semanticCells: _oneCell),
          ),
          CollisionLayer(
            id: 'collision',
            name: 'Blocages',
            collisions: <bool>[false],
          ),
          ObjectLayer(id: 'objects', name: 'Décor'),
        ],
      ),
      activeLayerId: 'tiles',
    );
    addTearDown(harness.dispose);
    await harness.pump(tester, size: const Size(540, 760));

    final search = find.descendant(
      of: find.byKey(const ValueKey<String>('world-map-layer-search')),
      matching: find.byType(TextField),
    );
    expect(search, findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('world-map-layer-type-filter')),
      findsOneWidget,
    );

    await tester.enterText(search, 'bloc');
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('world-map-layer-row-collision')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('world-map-layer-row-tiles')),
      findsNothing,
    );
    expect(find.text('1 calque affiché sur 4'), findsOneWidget);

    await tester.enterText(search, '');
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey<String>('world-map-layer-type-filter')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Terrain').last);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('world-map-layer-row-terrain')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('world-map-layer-row-collision')),
      findsNothing,
    );

    await tester.enterText(search, 'introuvable');
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('world-map-layer-filter-empty')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('world-map-layer-filter-reset')),
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('world-map-layer-row-tiles')),
      findsOneWidget,
    );
    expect(find.text('4 groupes de calques'), findsOneWidget);
  });

  testWidgets(
    'layer row preserves a compatible Paint subtool through the session controller',
    (tester) async {
      final harness = _Harness(
        const MapData(
          id: 'map',
          name: 'Map',
          version: ProjectVersion.v5,
          size: GridSize(width: 1, height: 1),
          layers: <MapLayer>[
            SmartTileLayer(
              id: 'path-a',
              name: 'Chemin A',
              presetId: 'path-a',
              usage: SmartTileUsage.path,
              field: SmartTileField.cell(semanticCells: _oneCell),
            ),
            SmartTileLayer(
              id: 'path-b',
              name: 'Chemin B',
              presetId: 'path-b',
              usage: SmartTileUsage.path,
              field: SmartTileField.cell(semanticCells: _oneCell),
            ),
          ],
        ),
        activeLayerId: 'path-a',
      );
      addTearDown(harness.dispose);
      expect(
        harness.session
            .activateTool(
              harness.notifier,
              const ActivateWorldMapPaint(WorldMapPaintSubtool.path),
            )
            .accepted,
        isTrue,
      );
      await harness.pump(tester);

      await tester.tap(
        find.byKey(
          const ValueKey<String>('world-map-layer-activate-path-b'),
        ),
      );
      await tester.pump();

      expect(harness.notifier.state.activeLayerId, 'path-b');
      expect(harness.notifier.state.activeTool, EditorToolType.terrainPaint);
      expect(
        harness.sessionState.activeFamily,
        WorldMapToolFamily.paint,
      );
      expect(
        harness.sessionState.lastPaintSubtool,
        WorldMapPaintSubtool.path,
      );
      expect(harness.notifier.state.mapUndoStack, isEmpty);
      expect(harness.notifier.state.isDirty, isFalse);
    },
  );

  testWidgets(
    'compatible layer row becomes the remembered Paint destination',
    (tester) async {
      final harness = _Harness(
        const MapData(
          id: 'map',
          name: 'Map',
          version: ProjectVersion.v5,
          size: GridSize(width: 1, height: 1),
          layers: <MapLayer>[
            TileLayer(
              id: 'tile',
              name: 'Éléments',
              tilesetId: 'world',
              tiles: <int>[0],
            ),
            SmartTileLayer(
              id: 'path-a',
              name: 'Chemin A',
              presetId: 'path-a',
              usage: SmartTileUsage.path,
              field: SmartTileField.cell(semanticCells: _oneCell),
            ),
            SmartTileLayer(
              id: 'path-b',
              name: 'Chemin B',
              presetId: 'path-b',
              usage: SmartTileUsage.path,
              field: SmartTileField.cell(semanticCells: _oneCell),
            ),
          ],
        ),
        activeLayerId: 'tile',
      );
      addTearDown(harness.dispose);

      final firstRouting = harness.session.routePaintSubtool(
        harness.notifier,
        WorldMapPaintSubtool.path,
        chosenLayerId: 'path-a',
      );
      expect(firstRouting.outcome, WorldMapPaintRoutingOutcome.activated);
      await harness.pump(tester);

      await tester.tap(
        find.byKey(
          const ValueKey<String>('world-map-layer-activate-path-b'),
        ),
      );
      await tester.pump();
      expect(harness.notifier.state.activeLayerId, 'path-b');
      expect(harness.notifier.state.activeTool, EditorToolType.terrainPaint);

      await tester.tap(
        find.byKey(const ValueKey<String>('world-map-layer-activate-tile')),
      );
      await tester.pump();
      expect(harness.notifier.state.activeLayerId, 'tile');
      expect(harness.notifier.state.activeTool, EditorToolType.tilePaint);
      expect(
        harness.sessionState.activeFamily,
        WorldMapToolFamily.paint,
      );
      expect(
        harness.sessionState.lastPaintSubtool,
        WorldMapPaintSubtool.tile,
      );

      final replay = harness.session.routePaintSubtool(
        harness.notifier,
        WorldMapPaintSubtool.path,
      );

      expect(replay.outcome, WorldMapPaintRoutingOutcome.activated);
      expect(replay.layerId, 'path-b');
      expect(harness.notifier.state.activeLayerId, 'path-b');
      expect(harness.notifier.state.mapUndoStack, isEmpty);
      expect(harness.notifier.state.isDirty, isFalse);
    },
  );

  testWidgets(
    'layer row switches an incompatible Paint subtool to the canonical one',
    (tester) async {
      final harness = _Harness(
        const MapData(
          id: 'map',
          name: 'Map',
          version: ProjectVersion.v5,
          size: GridSize(width: 1, height: 1),
          layers: <MapLayer>[
            SmartTileLayer(
              id: 'path',
              name: 'Chemin',
              presetId: 'path',
              usage: SmartTileUsage.path,
              field: SmartTileField.cell(semanticCells: _oneCell),
            ),
            SmartTileLayer(
              id: 'terrain',
              name: 'Terrain',
              presetId: 'terrain',
              usage: SmartTileUsage.terrain,
              field: SmartTileField.cell(semanticCells: _oneCell),
            ),
          ],
        ),
        activeLayerId: 'path',
      );
      addTearDown(harness.dispose);
      expect(
        harness.session
            .activateTool(
              harness.notifier,
              const ActivateWorldMapPaint(WorldMapPaintSubtool.path),
            )
            .accepted,
        isTrue,
      );
      await harness.pump(tester);

      await tester.tap(
        find.byKey(
          const ValueKey<String>('world-map-layer-activate-terrain'),
        ),
      );
      await tester.pump();

      expect(harness.notifier.state.activeLayerId, 'terrain');
      expect(harness.notifier.state.activeTool, EditorToolType.terrainPaint);
      expect(
        harness.notifier.state.terrainSelectionMode,
        TerrainSelectionMode.terrain,
      );
      expect(
        harness.sessionState.activeFamily,
        WorldMapToolFamily.paint,
      );
      expect(
        harness.sessionState.lastPaintSubtool,
        WorldMapPaintSubtool.terrain,
      );
      expect(harness.notifier.state.mapUndoStack, isEmpty);
      expect(harness.notifier.state.isDirty, isFalse);
    },
  );

  testWidgets(
      'explains an active technical environment visually and semantically',
      (tester) async {
    final map = MapData(
      id: 'map',
      name: 'Map',
      size: const GridSize(width: 1, height: 1),
      layers: [
        _tile('decor', 'Décor'),
        EnvironmentLayer(
          id: 'env_decor',
          name: 'Environnement du décor',
          content: EnvironmentLayerContent(targetTileLayerId: 'decor'),
        ),
      ],
    );
    final harness = _Harness(map, activeLayerId: 'env_decor');
    addTearDown(harness.dispose);
    await harness.pump(tester);

    expect(find.text('Environnement technique sélectionné'), findsOneWidget);
    final semantics = tester.getSemantics(
      find.byKey(
        const ValueKey<String>('world-map-layer-semantics-decor'),
      ),
    );
    expect(
      semantics.label,
      contains('Environnement technique sélectionné'),
    );
  });

  testWidgets('edits visibility opacity rename and group order',
      (tester) async {
    final harness = _Harness(_threeLayerMap(), activeLayerId: 'middle');
    addTearDown(harness.dispose);
    await harness.pump(
      tester,
      onRenameRequested: ({
        required context,
        required layerId,
        required currentName,
      }) async {
        expect(layerId, 'middle');
        expect(currentName, 'Middle');
        return '  Milieu  ';
      },
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('world-map-layer-visibility-middle')),
    );
    await tester.pump();
    expect(_layer(harness, 'middle').isVisible, isFalse);

    final slider = tester.widget<PokeMapGuidedSlider>(
      find.byKey(const ValueKey<String>('world-map-layer-opacity-middle')),
    );
    slider.onChanged(40);
    await tester.pump();
    expect(_layer(harness, 'middle').opacity, 0.4);

    await tester.tap(
      find.byKey(const ValueKey<String>('world-map-layer-rename-middle')),
    );
    await tester.pumpAndSettle();
    expect(_layer(harness, 'middle').name, 'Milieu');

    await tester.tap(
      find.byKey(const ValueKey<String>('world-map-layer-move-up-middle')),
    );
    await tester.pump();
    expect(
      harness.notifier.state.activeMap!.layers.map((layer) => layer.id),
      const ['middle', 'top', 'bottom'],
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('world-map-layer-move-down-middle')),
    );
    await tester.pump();
    expect(
      harness.notifier.state.activeMap!.layers.map((layer) => layer.id),
      const ['top', 'middle', 'bottom'],
    );
  });

  testWidgets('coalesces one opacity drag into one undo entry', (tester) async {
    final harness = _Harness(_threeLayerMap(), activeLayerId: 'middle');
    addTearDown(harness.dispose);
    await harness.pump(tester);

    final control = find.byKey(
      const ValueKey<String>('world-map-layer-opacity-middle'),
    );
    await tester.ensureVisible(control);
    await tester.pump();
    final slider = find.descendant(
      of: control,
      matching: find.byType(CupertinoSlider),
    );
    final rect = tester.getRect(slider);
    final gesture = await tester.startGesture(
      Offset(rect.right - 22, rect.center.dy),
    );
    await gesture.moveTo(
      Offset(rect.left + rect.width * 0.8, rect.center.dy),
    );
    await tester.pump();
    await gesture.moveTo(
      Offset(rect.left + rect.width * 0.6, rect.center.dy),
    );
    await tester.pump();
    await gesture.moveTo(
      Offset(rect.left + rect.width * 0.4, rect.center.dy),
    );
    await tester.pump();

    expect(_layer(harness, 'middle').opacity, lessThan(1));

    await gesture.up();
    await tester.pump();

    expect(harness.notifier.state.mapStrokeStart, isNull);
    expect(harness.notifier.state.mapUndoStack, hasLength(1));

    harness.notifier.undoMap();
    expect(_layer(harness, 'middle').opacity, 1);
  });

  testWidgets('closes a semantic opacity increase as one undo entry',
      (tester) async {
    final harness = _Harness(
      _threeLayerMap().copyWith(
        layers: [
          _tile('top', 'Top'),
          _tile('middle', 'Middle').copyWith(opacity: 0.5),
          _tile('bottom', 'Bottom'),
        ],
      ),
      activeLayerId: 'middle',
    );
    addTearDown(harness.dispose);
    final semantics = tester.ensureSemantics();
    await harness.pump(tester);

    final control = find.byKey(
      const ValueKey<String>('world-map-layer-opacity-middle'),
    );
    await tester.ensureVisible(control);
    await tester.pump();
    final slider = find.descendant(
      of: control,
      matching: find.byType(CupertinoSlider),
    );
    final node = tester.getSemantics(slider);
    node.owner!.performAction(node.id, SemanticsAction.increase);
    await tester.pump();

    expect(_layer(harness, 'middle').opacity, greaterThan(0.5));
    expect(harness.notifier.state.mapStrokeStart, isNull);
    expect(harness.notifier.state.mapUndoStack, hasLength(1));

    harness.notifier.undoMap();
    expect(_layer(harness, 'middle').opacity, 0.5);
    semantics.dispose();
  });

  testWidgets('cancelled opacity drag closes before a distinct next gesture',
      (tester) async {
    final harness = _Harness(_threeLayerMap(), activeLayerId: 'middle');
    addTearDown(harness.dispose);
    await harness.pump(tester);

    final control = find.byKey(
      const ValueKey<String>('world-map-layer-opacity-middle'),
    );
    await tester.ensureVisible(control);
    await tester.pump();
    final slider = find.descendant(
      of: control,
      matching: find.byType(CupertinoSlider),
    );
    final rect = tester.getRect(slider);
    final firstGesture = await tester.startGesture(
      Offset(rect.right - 22, rect.center.dy),
    );
    await firstGesture.moveTo(
      Offset(rect.left + rect.width * 0.8, rect.center.dy),
    );
    await tester.pump();
    await firstGesture.moveTo(
      Offset(rect.left + rect.width * 0.6, rect.center.dy),
    );
    await tester.pump();
    await firstGesture.moveTo(
      Offset(rect.left + rect.width * 0.4, rect.center.dy),
    );
    await tester.pump();
    await firstGesture.cancel();
    await tester.pump();

    final opacityAfterCancel = _layer(harness, 'middle').opacity;
    expect(opacityAfterCancel, lessThan(1));
    expect(harness.notifier.state.mapStrokeStart, isNull);
    expect(harness.notifier.state.mapUndoStack, hasLength(1));

    final thumbX = rect.left + 22 + (rect.width - 44) * opacityAfterCancel;
    final secondGesture = await tester.startGesture(
      Offset(thumbX, rect.center.dy),
    );
    await secondGesture.moveBy(const Offset(-8, 0));
    await tester.pump();
    await secondGesture.moveBy(const Offset(-24, 0));
    await tester.pump();
    await secondGesture.moveBy(const Offset(-24, 0));
    await tester.pump();
    await secondGesture.up();
    await tester.pump();

    expect(harness.notifier.state.mapStrokeStart, isNull);
    expect(harness.notifier.state.mapUndoStack, hasLength(2));
  });

  testWidgets('dispatches every direct creation kind with real layer types',
      (tester) async {
    final harness = _Harness(_threeLayerMap(), activeLayerId: 'middle');
    addTearDown(harness.dispose);
    await harness.pump(tester);

    final add = tester.widget<PokeMapSplitButton<WorldMapLayerCreationKind>>(
      find.byKey(const ValueKey<String>('world-map-layer-add')),
    );
    expect(
        add.items.map((item) => item.value), WorldMapLayerCreationKind.values);
    for (final kind in WorldMapLayerCreationKind.values.where(
      (kind) =>
          kind != WorldMapLayerCreationKind.smartTerrain &&
          kind != WorldMapLayerCreationKind.smartPath,
    )) {
      add.onSelected(kind);
      await tester.pump();
    }

    final created = harness.notifier.state.activeMap!.layers;
    expect(created.whereType<TileLayer>(), isNotEmpty);
    expect(created.whereType<CollisionLayer>(), hasLength(1));
    expect(created.whereType<TerrainLayer>(), isEmpty);
    expect(created.whereType<PathLayer>(), isEmpty);
    expect(created.whereType<ObjectLayer>(), hasLength(1));
    expect(created.whereType<EnvironmentLayer>(), hasLength(1));
    expect(created.whereType<BorderLayer>(), hasLength(1));
    expect(created.whereType<SurfaceLayer>(), hasLength(1));
    final layerScroll = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byKey(const ValueKey<String>('world-map-layer-list')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    for (var pass = 0; pass < 4; pass += 1) {
      layerScroll.position.jumpTo(layerScroll.position.maxScrollExtent);
      await tester.pump();
    }
    expect(
      find.text(
        'Zone auteur pour environnements organiques : forêts, bosquets, '
        'prairies, côtes rocheuses.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('disables Smart Tile terrain creation with the STN-03 diagnostic',
      (tester) async {
    final harness = _Harness(
      _threeLayerMap(),
      activeLayerId: 'middle',
      project: _smartTileProject,
    );
    addTearDown(harness.dispose);
    await harness.pump(tester);

    final add = tester.widget<PokeMapSplitButton<WorldMapLayerCreationKind>>(
      find.byKey(const ValueKey<String>('world-map-layer-add')),
    );
    final smartTerrain = add.items.singleWhere(
      (item) => item.label == 'Terrain',
    );

    expect(smartTerrain.enabled, isFalse);
    expect(
      smartTerrain.disabledReason,
      smartTileNativeAuthoringRequiresStn03Code,
    );
    expect(harness.notifier.state.activeMap!.layers.whereType<SmartTileLayer>(),
        isEmpty);
  });

  testWidgets('disables Smart Tile path creation with the STN-03 diagnostic',
      (tester) async {
    final harness = _Harness(
      _threeLayerMap(),
      activeLayerId: 'middle',
      project: _smartTileProject,
    );
    addTearDown(harness.dispose);
    await harness.pump(tester);

    final add = tester.widget<PokeMapSplitButton<WorldMapLayerCreationKind>>(
      find.byKey(const ValueKey<String>('world-map-layer-add')),
    );
    final smartPath = add.items.singleWhere(
      (item) => item.label == 'Chemin',
    );

    expect(smartPath.enabled, isFalse);
    expect(
      smartPath.disabledReason,
      smartTileNativeAuthoringRequiresStn03Code,
    );
    expect(harness.notifier.state.activeMap!.layers.whereType<SmartTileLayer>(),
        isEmpty);
  });

  testWidgets('rename cancellation leaves map and history untouched',
      (tester) async {
    final harness = _Harness(_threeLayerMap(), activeLayerId: 'middle');
    addTearDown(harness.dispose);
    final before = harness.notifier.state.activeMap;
    await harness.pump(
      tester,
      onRenameRequested: ({
        required context,
        required layerId,
        required currentName,
      }) async =>
          null,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('world-map-layer-rename-middle')),
    );
    await tester.pumpAndSettle();

    expect(harness.notifier.state.activeMap, same(before));
    expect(harness.notifier.state.canUndoMap, isFalse);
  });

  testWidgets('rename confirmation cannot mutate a newly active map',
      (tester) async {
    final harness = _Harness(_threeLayerMap(), activeLayerId: 'middle');
    addTearDown(harness.dispose);
    await harness.pump(
      tester,
      onRenameRequested: ({
        required context,
        required layerId,
        required currentName,
      }) async {
        harness.notifier.state = harness.notifier.state.copyWith(
          activeMap: _threeLayerMap().copyWith(
            id: 'other_map',
            name: 'Other map',
          ),
        );
        return 'Wrong map rename';
      },
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('world-map-layer-rename-middle')),
    );
    await tester.pumpAndSettle();

    expect(harness.notifier.state.activeMap!.id, 'other_map');
    expect(_layer(harness, 'middle').name, 'Middle');
    expect(harness.notifier.state.canUndoMap, isFalse);
  });

  testWidgets('delete cancellation reports impact without losing placements',
      (tester) async {
    MapLayerDeletionImpact? receivedImpact;
    final map = _threeLayerMap().copyWith(
      placedElements: const [
        MapPlacedElement(
          id: 'tree',
          layerId: 'middle',
          elementId: 'tree',
          pos: GridPos(x: 0, y: 0),
        ),
      ],
    );
    final harness = _Harness(map, activeLayerId: 'middle');
    addTearDown(harness.dispose);
    await harness.pump(
      tester,
      onDeleteRequested: ({
        required context,
        required impact,
      }) async {
        receivedImpact = impact;
        return false;
      },
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('world-map-layer-delete-middle')),
    );
    await tester.pumpAndSettle();

    expect(receivedImpact?.placedElementCount, 1);
    expect(harness.notifier.state.activeMap!.placedElements, hasLength(1));
    expect(harness.notifier.state.activeMap!.layers, hasLength(3));
    expect(harness.notifier.state.canUndoMap, isFalse);
  });

  testWidgets('confirmed deletion removes the layer and its placements',
      (tester) async {
    final map = _threeLayerMap().copyWith(
      placedElements: const [
        MapPlacedElement(
          id: 'tree',
          layerId: 'middle',
          elementId: 'tree',
          pos: GridPos(x: 0, y: 0),
        ),
      ],
    );
    final harness = _Harness(map, activeLayerId: 'middle');
    addTearDown(harness.dispose);
    await harness.pump(
      tester,
      onDeleteRequested: ({
        required context,
        required impact,
      }) async =>
          true,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('world-map-layer-delete-middle')),
    );
    await tester.pumpAndSettle();

    expect(
      harness.notifier.state.activeMap!.layers
          .where((layer) => layer.id == 'middle'),
      isEmpty,
    );
    expect(harness.notifier.state.activeMap!.placedElements, isEmpty);
  });

  testWidgets('rechecks impact after confirmation and rejects stale deletion',
      (tester) async {
    final harness = _Harness(_threeLayerMap(), activeLayerId: 'middle');
    addTearDown(harness.dispose);
    await harness.pump(
      tester,
      onDeleteRequested: ({
        required context,
        required impact,
      }) async {
        final current = harness.notifier.state.activeMap!;
        harness.notifier.state = harness.notifier.state.copyWith(
          activeMap: current.copyWith(
            events: const [
              MapEventDefinition(
                id: 'event_after_confirmation',
                pages: [MapEventPage(pageNumber: 0)],
                position: EventPosition(layerId: 'middle', x: 0, y: 0),
              ),
            ],
          ),
        );
        return true;
      },
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('world-map-layer-delete-middle')),
    );
    await tester.pumpAndSettle();

    expect(
      harness.notifier.state.activeMap!.layers
          .any((layer) => layer.id == 'middle'),
      isTrue,
    );
    expect(harness.notifier.state.activeMap!.events, hasLength(1));
  });

  testWidgets('rejects deletion when non-blocking impact changes',
      (tester) async {
    final harness = _Harness(_threeLayerMap(), activeLayerId: 'middle');
    addTearDown(harness.dispose);
    await harness.pump(
      tester,
      onDeleteRequested: ({
        required context,
        required impact,
      }) async {
        final current = harness.notifier.state.activeMap!;
        harness.notifier.state = harness.notifier.state.copyWith(
          activeMap: current.copyWith(
            placedElements: const [
              MapPlacedElement(
                id: 'added_after_confirmation',
                layerId: 'middle',
                elementId: 'tree',
                pos: GridPos(x: 0, y: 0),
              ),
            ],
          ),
        );
        return true;
      },
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('world-map-layer-delete-middle')),
    );
    await tester.pumpAndSettle();

    expect(
      harness.notifier.state.activeMap!.layers
          .any((layer) => layer.id == 'middle'),
      isTrue,
    );
    expect(harness.notifier.state.activeMap!.placedElements, hasLength(1));
    expect(harness.notifier.state.canUndoMap, isFalse);
  });

  testWidgets(
      'rejects deletion when a confirmed placement is replaced one for one',
      (tester) async {
    final map = _threeLayerMap().copyWith(
      placedElements: const [
        MapPlacedElement(
          id: 'confirmed_tree',
          layerId: 'middle',
          elementId: 'tree',
          pos: GridPos(x: 0, y: 0),
        ),
      ],
    );
    final harness = _Harness(map, activeLayerId: 'middle');
    addTearDown(harness.dispose);
    await harness.pump(
      tester,
      onDeleteRequested: ({
        required context,
        required impact,
      }) async {
        final current = harness.notifier.state.activeMap!;
        harness.notifier.state = harness.notifier.state.copyWith(
          activeMap: current.copyWith(
            placedElements: const [
              MapPlacedElement(
                id: 'replacement_rock',
                layerId: 'middle',
                elementId: 'rock',
                pos: GridPos(x: 1, y: 0),
              ),
            ],
          ),
        );
        return true;
      },
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('world-map-layer-delete-middle')),
    );
    await tester.pumpAndSettle();

    expect(
      harness.notifier.state.activeMap!.layers
          .any((layer) => layer.id == 'middle'),
      isTrue,
    );
    expect(
      harness.notifier.state.activeMap!.placedElements.single.id,
      'replacement_rock',
    );
    expect(harness.notifier.state.canUndoMap, isFalse);
  });

  testWidgets('delete confirmation cannot mutate a newly active map',
      (tester) async {
    final harness = _Harness(_threeLayerMap(), activeLayerId: 'middle');
    addTearDown(harness.dispose);
    await harness.pump(
      tester,
      onDeleteRequested: ({
        required context,
        required impact,
      }) async {
        harness.notifier.state = harness.notifier.state.copyWith(
          activeMap: _threeLayerMap().copyWith(
            id: 'other_map',
            name: 'Other map',
          ),
        );
        return true;
      },
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('world-map-layer-delete-middle')),
    );
    await tester.pumpAndSettle();

    expect(harness.notifier.state.activeMap!.id, 'other_map');
    expect(
      harness.notifier.state.activeMap!.layers
          .any((layer) => layer.id == 'middle'),
      isTrue,
    );
    expect(harness.notifier.state.canUndoMap, isFalse);
  });

  testWidgets('dependency blockers disable delete with their current reason',
      (tester) async {
    var deleteRequests = 0;
    final map = MapData(
      id: 'map',
      name: 'Map',
      size: const GridSize(width: 1, height: 1),
      layers: [
        _tile('decor', 'Décor'),
        MapLayer.environment(
          id: 'forest',
          name: 'Forêt',
          content: EnvironmentLayerContent(targetTileLayerId: 'decor'),
        ),
      ],
    );
    final harness = _Harness(map, activeLayerId: 'decor');
    addTearDown(harness.dispose);
    await harness.pump(
      tester,
      onDeleteRequested: ({
        required context,
        required impact,
      }) async {
        deleteRequests += 1;
        return true;
      },
    );

    final delete = tester.widget<PokeMapIconButton>(
      find.byKey(const ValueKey<String>('world-map-layer-delete-decor')),
    );
    expect(delete.onPressed, isNull);
    expect(
      delete.tooltip,
      'Impossible de supprimer ce layer : un environnement lui est attaché.',
    );
    expect(deleteRequests, 0);
  });

  testWidgets('MapEvent and generated dependencies expose disabled reasons',
      (tester) async {
    final map = MapData(
      id: 'map',
      name: 'Map',
      size: const GridSize(width: 1, height: 1),
      layers: [
        _tile('decor', 'Décor'),
        MapLayer.environment(
          id: 'orphan_forest',
          name: 'Forêt orpheline',
          content: EnvironmentLayerContent(
            targetTileLayerId: 'missing',
            areas: [
              EnvironmentArea(
                id: 'forest_area',
                name: 'Forêt',
                presetId: 'forest',
                mask: EnvironmentAreaMask(
                  width: 1,
                  height: 1,
                  cells: [true],
                ),
                seed: 1,
                generatedPlacementIds: const ['generated_tree'],
              ),
            ],
          ),
        ),
      ],
      placedElements: const [
        MapPlacedElement(
          id: 'generated_tree',
          layerId: 'decor',
          elementId: 'tree',
          pos: GridPos(x: 0, y: 0),
        ),
      ],
      events: const [
        MapEventDefinition(
          id: 'event_gate',
          pages: [MapEventPage(pageNumber: 0)],
          position: EventPosition(layerId: 'decor', x: 0, y: 0),
        ),
      ],
    );
    final harness = _Harness(map, activeLayerId: 'decor');
    addTearDown(harness.dispose);
    await harness.pump(tester);

    final eventDelete = tester.widget<PokeMapIconButton>(
      find.byKey(const ValueKey<String>('world-map-layer-delete-decor')),
    );
    expect(eventDelete.onPressed, isNull);
    expect(eventDelete.tooltip, contains('1 événement de map'));

    final generatedDelete = tester.widget<PokeMapIconButton>(
      find.byKey(
        const ValueKey<String>('world-map-layer-delete-orphan_forest'),
      ),
    );
    expect(generatedDelete.onPressed, isNull);
    expect(generatedDelete.tooltip, contains('1 élément généré'));
  });

  testWidgets('does not fabricate lock or duplicate controls', (tester) async {
    final harness = _Harness(_threeLayerMap(), activeLayerId: 'middle');
    addTearDown(harness.dispose);
    await harness.pump(tester);

    expect(find.textContaining('Verrou'), findsNothing);
    expect(find.textContaining('Dupliquer'), findsNothing);
    expect(find.byIcon(Icons.lock), findsNothing);
    expect(find.byIcon(Icons.copy), findsNothing);
  });

  testWidgets('secondary click on the whole layer card emits its typed target',
      (tester) async {
    final harness = _Harness(_threeLayerMap(), activeLayerId: 'middle');
    addTearDown(harness.dispose);
    final requests = <WorldMapLayerContextMenuRequest>[];
    await harness.pump(
      tester,
      onContextMenuRequested: requests.add,
    );

    final row = find.byKey(
      const ValueKey<String>('world-map-layer-row-top'),
    );
    final rowRect = tester.getRect(row);
    final gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryButton,
    );
    await gesture.down(
      Offset(rowRect.left + 12, rowRect.bottom - 12),
    );
    await gesture.up();
    await tester.pump();

    expect(requests, hasLength(1));
    expect(requests.single.target, const MapLayerContextTarget('top'));
    expect(requests.single.invocation, MapContextMenuInvocation.pointer);
    expect(requests.single.invokerFocusNode.hasFocus, isTrue);
  });

  testWidgets('Menu key from a nested layer control targets the whole card',
      (tester) async {
    final harness = _Harness(_threeLayerMap(), activeLayerId: 'middle');
    addTearDown(harness.dispose);
    final requests = <WorldMapLayerContextMenuRequest>[];
    await harness.pump(
      tester,
      onContextMenuRequested: requests.add,
    );

    final rowFocus = tester.widget<Focus>(
      find.byKey(
        const ValueKey<String>('world-map-layer-context-focus-top'),
      ),
    );
    rowFocus.focusNode!.requestFocus();
    await tester.pump();
    var visibilityHasPrimaryFocus = false;
    for (var attempt = 0; attempt < 8; attempt += 1) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final focusedContext = FocusManager.instance.primaryFocus?.context;
      if (focusedContext == null) continue;
      visibilityHasPrimaryFocus = find
          .ancestor(
            of: find.byElementPredicate(
              (element) => identical(element, focusedContext),
            ),
            matching: find.byKey(
              const ValueKey<String>('world-map-layer-visibility-top'),
            ),
          )
          .evaluate()
          .isNotEmpty;
      if (visibilityHasPrimaryFocus) break;
    }
    expect(visibilityHasPrimaryFocus, isTrue);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.contextMenu);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.contextMenu);
    await tester.pump();

    expect(requests, hasLength(1));
    expect(requests.single.target, const MapLayerContextTarget('top'));
    expect(requests.single.invocation, MapContextMenuInvocation.keyboard);
    expect(requests.single.invokerFocusNode, same(rowFocus.focusNode));
    expect(requests.single.invokerFocusNode.hasFocus, isTrue);
  });
}

final class _Harness {
  _Harness(
    MapData map, {
    required String activeLayerId,
    ProjectManifest? project,
  }) : container = ProviderContainer() {
    keepAlive = container.listen(editorNotifierProvider, (_, __) {});
    notifier.state = EditorState(
      projectRootPath: '/virtual/project',
      project: project ??
          const ProjectManifest(
            name: 'Project',
            maps: [],
            tilesets: [],
          ),
      workspaceMode: EditorWorkspaceMode.map,
      activeMap: map,
      activeLayerId: activeLayerId,
    );
  }

  final ProviderContainer container;
  late final ProviderSubscription<EditorState> keepAlive;

  EditorNotifier get notifier =>
      container.read(editorNotifierProvider.notifier);

  WorldMapWorkspaceSessionController get session =>
      container.read(worldMapWorkspaceSessionProvider.notifier);

  WorldMapWorkspaceSession get sessionState =>
      container.read(worldMapWorkspaceSessionProvider);

  Future<void> pump(
    WidgetTester tester, {
    Size size = const Size(380, 760),
    WorldMapLayerRenameRequested onRenameRequested =
        showWorldMapLayerRenameDialog,
    WorldMapLayerDeleteRequested onDeleteRequested =
        showWorldMapLayerDeleteDialog,
    WorldMapLayerContextMenuRequested? onContextMenuRequested,
  }) {
    return tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: PokeMapTheme.dark(),
          home: Scaffold(
            body: SizedBox(
              width: size.width,
              height: size.height,
              child: WorldMapLayersInspector(
                onRenameRequested: onRenameRequested,
                onDeleteRequested: onDeleteRequested,
                onContextMenuRequested: onContextMenuRequested,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void dispose() {
    keepAlive.close();
    container.dispose();
  }
}

const _oneCell = <int>[0];

MapLayer _layer(_Harness harness, String id) {
  return harness.notifier.state.activeMap!.layers
      .firstWhere((layer) => layer.id == id);
}

MapData _threeLayerMap() {
  return MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 1, height: 1),
    layers: [
      _tile('top', 'Top'),
      _tile('middle', 'Middle'),
      _tile('bottom', 'Bottom'),
    ],
  );
}

TileLayer _tile(String id, String name) {
  return TileLayer(
    id: id,
    name: name,
    tiles: const [0],
  );
}

final _smartTileProject = ProjectManifest(
  name: 'Smart project',
  version: ProjectVersion.v5,
  maps: const <ProjectMapEntry>[],
  tilesets: const <ProjectTilesetEntry>[],
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
);
