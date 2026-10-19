import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_canvas_stroke.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_terrain_patterns.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_terrain_tool_panel.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_visuals.dart';
import 'package:avelune_studio/presentation/features/map_workspace/spatial_map_editor.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';

import '../application/spatial_terrain_draft_test.dart'
    show spatialPathDraft, spatialPathModel;
import '../terrain_creation_test.dart'
    show terrainDraft, assignAll, publishFixture;
import '../support/map_workspace_fixture.dart';

void main() {
  test('fixed-height whole models remain available only in native spatial channels', () {
    final fixture = _fixture();
    for (final channel in SmartTileRenderChannel.values) {
      final original = fixture.pattern.cells.first.parts.first;
      final source = original.source as SmartTileModel3dSource;
      final part = original.copyWith(
        channel: channel,
        source: source.copyWith(followTerrain: false),
      );
      final pattern = fixture.pattern.copyWith(cells: [
        SmartTilePatternCell(x: 0, y: 0, parts: [part]),
      ]);
      final patterns = availableTerrainPatterns(
        project: _withStampPatterns(fixture.project, [pattern]),
        map: fixture.map,
        preset: fixture.preset,
      );
      expect(patterns.map((p) => p.id).contains(pattern.id),
          [SmartTileRenderChannel.ground, SmartTileRenderChannel.understory,
            SmartTileRenderChannel.canopy].contains(channel), reason: channel.name);
    }
  });

  test('fixed-height static clipped walls remain available in native channels', () {
    final fixture = _fixture();
    for (final channel in SmartTileRenderChannel.values) {
      final original = fixture.pattern.cells.first.parts.first;
      final source = original.source as SmartTileModel3dSource;
      final part = original.copyWith(
        channel: channel,
        source: source.copyWith(followTerrain: false),
        spatialClip: SmartTileSpatialClip(left: 0, top: 0, right: 1, bottom: 1),
      );
      final pattern = fixture.pattern.copyWith(cells: [
        SmartTilePatternCell(x: 0, y: 0, parts: [part]),
      ]);
      final patterns = availableTerrainPatterns(
        project: _withStampPatterns(fixture.project, [pattern]),
        map: fixture.map,
        preset: fixture.preset,
      );
      expect(patterns.map((p) => p.id).contains(pattern.id),
          [SmartTileRenderChannel.ground, SmartTileRenderChannel.understory,
            SmartTileRenderChannel.canopy].contains(channel), reason: channel.name);
    }
  });

  testWidgets('whole fixed native stamp panel exposes its complete footprint', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final fixture = _adaptiveBridgeFixture();
    final pattern = fixture.pattern.copyWith(construction: null, repeatMode: SmartTilePatternRepeatMode.stamp,
      clippingPolicy: SmartTilePatternClippingPolicy.reject);
    final view = MapWorkspaceViewState()..prepareTerrainPainting(fixture.preset)..selectTerrainPattern(pattern);
    addTearDown(view.dispose);
    final document = EditableMapDocument(MapWorkspaceDocument(map: fixture.map, mapId: fixture.map.id, revision: 'r0'));
    await tester.pumpWidget(MaterialApp(theme: studioTheme(), home: Scaffold(body: MapTerrainToolPanel(
      document: document, project: _withStampPatterns(fixture.project, [pattern]),
      visuals: _PatternVisuals(), view: view, onChanged: () {},
    ))));
    expect(find.byKey(const ValueKey('terrain-pattern-whole-placement')), findsOneWidget);
    expect(find.text('Placement entier : 5 × 4 cases'), findsOneWidget);
    expect(find.text('Tampon'), findsOneWidget);
  });

  test('whole fixed native stamp previews nothing at an edge and commits a complete anchored envelope', () {
    final fixture = _adaptiveBridgeFixture();
    final pattern = fixture.pattern.copyWith(construction: null, repeatMode: SmartTilePatternRepeatMode.stamp,
      clippingPolicy: SmartTilePatternClippingPolicy.reject, anchorX: 2, anchorY: 1);
    final catalog = fixture.project.smartTileCatalog;
    final project = fixture.project.copyWith(smartTileCatalog: ProjectSmartTileCatalog(
      categories: catalog.categories, atlases: catalog.atlases, materials: catalog.materials,
      presets: catalog.presets, patterns: [pattern],
    ));
    final document = EditableMapDocument(MapWorkspaceDocument(map: fixture.map, mapId: fixture.map.id, revision: 'r0'));
    final view = MapWorkspaceViewState()..prepareTerrainPainting(fixture.preset)..selectTerrainPattern(pattern);
    addTearDown(view.dispose);
    final invalid = MapCanvasStroke.start(map: fixture.map, project: project, view: view,
      commands: MapEditingCommands(document, project), origin: const GridPos(x: 0, y: 0))!;
    expect(invalid.preview, fixture.map);
    expect(() => invalid.commit(), throwsA(isA<ValidationException>().having((e) => e.message,
      'message', 'Le motif entier doit tenir dans la carte.')));
    expect(document.undoCount, 0);
    final valid = MapCanvasStroke.start(map: fixture.map, project: project, view: view,
      commands: MapEditingCommands(document, project), origin: const GridPos(x: 2, y: 1))!;
    expect(valid.preview.layers.whereType<SmartTileLayer>().single.patternStrokes.single.cells, hasLength(20));
    document.commit(valid.commit());
    document.restore(redo: false);
    expect(document.current, fixture.map);
  });

  for (final kind in ['unique adaptive', 'ordinary', 'multiple adaptive', 'visible ordinary with adaptive sibling', 'incomplete template support']) {
    testWidgets('preset selection initializes $kind construction coherently', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final fixture = _adaptiveBridgeFixture();
      final catalog = fixture.project.smartTileCatalog;
      final preset = kind == 'visible ordinary with adaptive sibling'
          ? fixture.preset.copyWith(rules: [SmartTileRule(
              id: 'visible', centerMatch: SmartTileSlotMatch.material(fixture.preset.defaultMaterialId),
              candidates: [SmartTileCandidate(id: 'visible', parts: fixture.pattern.cells.first.parts)],
            )])
          : kind == 'incomplete template support'
          ? fixture.preset.copyWith(coverageProfile: const SmartTileCoverageProfile(mode: SmartTileCoverageMode.template))
          : fixture.preset;
      final patterns = kind == 'ordinary'
          ? [fixture.pattern.copyWith(construction: null)]
          : [fixture.pattern, if (kind == 'multiple adaptive') fixture.pattern.copyWith(id: 'bridge-alt')];
      final project = fixture.project.copyWith(smartTileCatalog: ProjectSmartTileCatalog(
        categories: catalog.categories, atlases: catalog.atlases, materials: catalog.materials,
        presets: [preset], patterns: patterns,
      ));
      final view = MapWorkspaceViewState()..prepareTerrainPainting(preset);
      addTearDown(view.dispose);
      view.reconcileResources(project, mapId: fixture.map.id, map: fixture.map);
      final document = EditableMapDocument(MapWorkspaceDocument(
        map: fixture.map, mapId: fixture.map.id, revision: 'r0',
      ));
      await tester.pumpWidget(MaterialApp(
        theme: studioTheme(),
        home: Scaffold(body: MapTerrainToolPanel(
          document: document, project: project, visuals: _PatternVisuals(),
          view: view, onChanged: () {},
        )),
      ));
      final unique = kind == 'unique adaptive';
      expect(view.terrainPatternId, unique ? fixture.pattern.id : null);
      expect(find.byKey(const ValueKey('terrain-construction-dimensions')), unique ? findsOneWidget : findsNothing);
      expect(find.text('Ligne'), unique ? findsOneWidget : findsNothing);
      expect(jsonEncode(document.current.toJson()), jsonEncode(fixture.map.toJson()));
      if (unique) {
        view.selectTerrainPattern(null);
        view.reconcileResources(project, mapId: fixture.map.id, map: fixture.map);
        expect(view.terrainPatternId, isNull);
      }
    });
  }

  testWidgets('adaptive construction panel exposes native dimensions and gestures', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final fixture = _adaptiveBridgeFixture();
    final view = MapWorkspaceViewState()
      ..prepareTerrainPainting(fixture.preset)
      ..selectTerrainPattern(fixture.pattern);
    addTearDown(view.dispose);
    final document = EditableMapDocument(MapWorkspaceDocument(
      map: fixture.map, mapId: fixture.map.id, revision: 'r0',
    ));
    await tester.pumpWidget(MaterialApp(
      theme: studioTheme(),
      home: Scaffold(body: MapTerrainToolPanel(
        document: document, project: fixture.project, visuals: _PatternVisuals(),
        view: view, onChanged: () {},
      )),
    ));
    expect(find.byKey(const ValueKey('terrain-construction-dimensions')), findsOneWidget);
    expect(find.text('Largeur fixe : 5 cases · Hauteur : 4 minimum, par 2'), findsOneWidget);
    expect(find.text('Ligne'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('terrain-pattern-mode')));
    await tester.pumpAndSettle();
    expect(find.text('Rectangle'), findsOneWidget);
  });

  test('adaptive native bridge selects a full-width line gesture by default', () {
    final fixture = _adaptiveBridgeFixture();
    final view = MapWorkspaceViewState()
      ..prepareTerrainPainting(fixture.preset)
      ..selectTerrainPattern(fixture.pattern);
    addTearDown(view.dispose);

    expect(view.terrainPatternMode, SmartTilePatternSelectionKind.line);
  });

  test('adaptive native bridge survives intermediate lengths, previews and undoes a complete section', () {
    final fixture = _adaptiveBridgeFixture();
    final before = jsonEncode(fixture.map.toJson());
    final document = EditableMapDocument(MapWorkspaceDocument(
      map: fixture.map, mapId: fixture.map.id, revision: 'r0',
    ));
    final view = MapWorkspaceViewState()
      ..prepareTerrainPainting(fixture.preset)
      ..selectTerrainPattern(fixture.pattern)
      ..terrainPatternMode = SmartTilePatternSelectionKind.line;
    addTearDown(view.dispose);
    MapCanvasStroke? stroke;
    expect(() => stroke = MapCanvasStroke.start(
      map: fixture.map, project: fixture.project, view: view,
      commands: MapEditingCommands(document, fixture.project),
      origin: const GridPos(x: 1, y: 1),
    ), returnsNormally);
    expect(stroke, isNotNull);
    expect(jsonEncode(document.current.toJson()), before);
    expect(stroke!.preview.layers.whereType<SmartTileLayer>().single.patternStrokes, isEmpty);
    stroke!.paint(const GridPos(x: 1, y: 6));
    final previewLayer = stroke!.preview.layers.whereType<SmartTileLayer>().single;
    expect(previewLayer.patternStrokes.single.cells, hasLength(30));
    expect(previewLayer.patternStrokes.single.constructionBounds,
        const MapRect(pos: GridPos(x: 1, y: 1), size: GridSize(width: 5, height: 6)));
    stroke!.paint(const GridPos(x: 1, y: 5));
    expect(stroke!.preview.layers.whereType<SmartTileLayer>().single.patternStrokes, isEmpty);
    expect(() => stroke!.commit(), throwsA(isA<ValidationException>()));
    expect(jsonEncode(document.current.toJson()), before);
    stroke!.paint(const GridPos(x: 1, y: 6));
    final committed = stroke!.commit();
    expect(committed, stroke!.preview);
    document.commit(committed);
    expect(document.undoCount, 1);
    document.restore(redo: false);
    expect(jsonEncode(document.current.toJson()), before);
  });

  test('adaptive construction picker scopes native families through existing categories', () {
    final fixture = _adaptiveBridgeFixture();
    final catalog = fixture.project.smartTileCatalog;
    final project = fixture.project.copyWith(smartTileCatalog: ProjectSmartTileCatalog(
      categories: [...catalog.categories, const ProjectSmartTileCategory(id: 'foreign-style', name: 'Foreign')],
      atlases: catalog.atlases, materials: catalog.materials, presets: catalog.presets,
      patterns: [fixture.pattern, fixture.pattern.copyWith(id: 'foreign', categoryId: 'foreign-style')],
    ));

    expect(availableTerrainPatterns(project: project, map: fixture.map, preset: fixture.preset)
        .map((pattern) => pattern.id), [fixture.pattern.id]);
  });
  for (final spatial in [true, false]) {
    test('reactive path motifs synchronize material and erase: spatial $spatial', () {
      final fixture = _fixture(spatial: spatial);
      final preset = fixture.preset.copyWith(usage: SmartTileUsage.path);
      final pattern = fixture.pattern.copyWith(usage: SmartTileUsage.path);
      final project = fixture.project.copyWith(smartTileCatalog: ProjectSmartTileCatalog(
          atlases: fixture.project.smartTileCatalog.atlases,
          materials: fixture.project.smartTileCatalog.materials,
          presets: [preset], patterns: [pattern]));
      final original = fixture.map.layers.whereType<SmartTileLayer>().single;
      final source = fixture.map.copyWith(layers: [original.copyWith(
          usage: SmartTileUsage.path,
          animationActivation: SmartTileAnimationActivation.onEnter,
          patternStrokes: [])]);
      final document = EditableMapDocument(MapWorkspaceDocument(
          map: source, mapId: source.id, revision: 'r0'));
      final view = MapWorkspaceViewState()
        ..prepareTerrainPainting(preset)
        ..selectTerrainPattern(pattern)
        ..terrainPatternMode = SmartTilePatternSelectionKind.stamp
        ..tool = StudioMapTool.terrain;
      addTearDown(view.dispose);
      final stroke = MapCanvasStroke.start(map: source,
          project: project, view: view,
          commands: MapEditingCommands(document, project),
          origin: const GridPos(x: 2, y: 3))!;
      final painted = stroke.commit();
      final paintedLayer = painted.layers.whereType<SmartTileLayer>().single;
      expect(smartTileSemanticCells(paintedLayer)[26], 1);
      expect(smartTileSemanticCells(paintedLayer)[27], 1);
      expect(smartTileSemanticCells(paintedLayer).where((value) => value != 0), hasLength(2));
      expect(smartTileSemanticCells(source.layers.single as SmartTileLayer)[26], 0);
      document.commit(painted);
      view.tool = StudioMapTool.erase;
      final erase = MapCanvasStroke.start(map: painted,
          project: project, view: view,
          commands: MapEditingCommands(document, project),
          origin: const GridPos(x: 2, y: 3))!;
      final erased = erase.commit();
      final erasedLayer = erased.layers.whereType<SmartTileLayer>().single;
      expect(smartTileSemanticCells(erasedLayer)[26], 0);
      expect(smartTileSemanticCells(erasedLayer)[27], 1);
      expect(erasedLayer.patternStrokes.single.cells, [const GridPos(x: 3, y: 3)]);
      document.commit(erased);
      document.restore(redo: false);
      expect(document.current, painted);
      expect(painted.spatialScene, source.spatialScene);
    });
  }

  test('selected small 3D stamp erases from its empty centre with exact preview, commit and Undo', () {
    final fixture = _atomicStampFixture();
    final source = fixture.map;
    final before = jsonEncode(source.toJson());
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: source, mapId: source.id, revision: 'r0'),
    );
    final view = _selectedStampEraseView(fixture.preset, fixture.pattern);
    addTearDown(view.dispose);
    final stroke = MapCanvasStroke.start(
      map: source,
      project: fixture.project,
      view: view,
      commands: MapEditingCommands(document, fixture.project),
      origin: const GridPos(x: 3, y: 3),
    )!;
    final originalLayer = source.layers.whereType<SmartTileLayer>().single;
    final previewLayer = stroke.preview.layers
        .whereType<SmartTileLayer>()
        .single;
    expect(previewLayer.patternStrokes, isEmpty);
    expect(previewLayer.field, originalLayer.field);
    expect(previewLayer.materialPalette, originalLayer.materialPalette);
    expect(stroke.preview.spatialScene, source.spatialScene);
    expect(document.current, same(source));
    expect(document.undoCount, 0);
    final committed = stroke.commit();
    expect(committed, stroke.preview);
    expect(
      resolveSpatialSmartTileInstances(
        map: committed,
        catalog: fixture.project.smartTileCatalog,
      ).where((instance) => instance.modelId == 'ground-detail'),
      isEmpty,
    );
    document.commit(committed);
    expect(document.undoCount, 1);
    document.restore(redo: false);
    expect(jsonEncode(document.current.toJson()), before);
    document.restore(redo: true);
    expect(document.current, committed);
  });

  test('selected small 3D stamp does not erase the underlying material outside its ownership', () {
    final fixture = _atomicStampFixture();
    final document = EditableMapDocument(
      MapWorkspaceDocument(
        map: fixture.map,
        mapId: fixture.map.id,
        revision: 'r0',
      ),
    );
    final view = _selectedStampEraseView(fixture.preset, fixture.pattern);
    addTearDown(view.dispose);
    expect(
      MapCanvasStroke.start(
        map: fixture.map,
        project: fixture.project,
        view: view,
        commands: MapEditingCommands(document, fixture.project),
        origin: const GridPos(x: 0, y: 0),
      ),
      isNull,
    );
    expect(document.current, same(fixture.map));
    expect(document.undoCount, 0);
  });

  for (final samePattern in [false, true]) {
    test(
      'selected small 3D stamp removes only the top ${samePattern ? "same" : "different"} overlapping unit',
      () {
        final fixture = _atomicStampFixture();
        final other = fixture.pattern.copyWith(id: 'other-detail');
        final project = _withStampPatterns(fixture.project, [
          fixture.pattern,
          other,
        ]);
        final originalLayer = fixture.map.layers
            .whereType<SmartTileLayer>()
            .single;
        final applied = applySmartTilePatternGesture(
          originalLayer,
          pattern: samePattern ? fixture.pattern : other,
          mapSize: fixture.map.size,
          selection: const SmartTilePatternSelection.stamp(
            anchor: GridPos(x: 3, y: 3),
          ),
          strokeId: 'top-unit',
        );
        final source = replaceSmartTileLayer(fixture.map, layer: applied.layer);
        final document = EditableMapDocument(
          MapWorkspaceDocument(map: source, mapId: source.id, revision: 'r0'),
        );
        final view = _selectedStampEraseView(
          fixture.preset,
          samePattern ? fixture.pattern : other,
        );
        addTearDown(view.dispose);
        final stroke = MapCanvasStroke.start(
          map: source,
          project: project,
          view: view,
          commands: MapEditingCommands(document, project),
          origin: const GridPos(x: 4, y: 4),
        )!;
        stroke.paint(const GridPos(x: 4, y: 4));
        final erased = stroke.commit();
        expect(erased.layers.whereType<SmartTileLayer>().single, originalLayer);
        expect(stroke.preview, erased);
        document.commit(erased);
        expect(document.undoCount, 1);
        document.restore(redo: false);
        expect(
          jsonEncode(document.current.toJson()),
          jsonEncode(source.toJson()),
        );
      },
    );
  }

  test('selected small 3D stamp cannot erase through a different top owner even when that owner has no part', () {
    final fixture = _atomicStampFixture();
    final other = fixture.pattern.copyWith(id: 'other-detail');
    final project = _withStampPatterns(fixture.project, [
      fixture.pattern,
      other,
    ]);
    final layer = fixture.map.layers.whereType<SmartTileLayer>().single;
    final source = replaceSmartTileLayer(
      fixture.map,
      layer: layer.copyWith(
        patternStrokes: [
          ...layer.patternStrokes,
          layer.patternStrokes.single.copyWith(
            id: 'covering-unit',
            patternId: other.id,
          ),
        ],
      ),
    );
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: source, mapId: source.id, revision: 'r0'),
    );
    final view = _selectedStampEraseView(fixture.preset, fixture.pattern);
    addTearDown(view.dispose);
    expect(
      MapCanvasStroke.start(
        map: source,
        project: project,
        view: view,
        commands: MapEditingCommands(document, project),
        origin: const GridPos(x: 3, y: 3),
      ),
      isNull,
    );
    expect(document.current, same(source));
  });

  test('selected small 3D stamp drag erases two units with one Undo and keeps neighbours', () {
    final fixture = _atomicStampFixture();
    final layer = fixture.map.layers.whereType<SmartTileLayer>().single;
    final applied = applySmartTilePatternGesture(
      layer,
      pattern: fixture.pattern,
      mapSize: fixture.map.size,
      selection: const SmartTilePatternSelection.stamp(
        anchor: GridPos(x: 5, y: 2),
      ),
      strokeId: 'second-unit',
    );
    final source = replaceSmartTileLayer(fixture.map, layer: applied.layer);
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: source, mapId: source.id, revision: 'r0'),
    );
    final view = _selectedStampEraseView(fixture.preset, fixture.pattern);
    addTearDown(view.dispose);
    final stroke = MapCanvasStroke.start(
      map: source,
      project: fixture.project,
      view: view,
      commands: MapEditingCommands(document, fixture.project),
      origin: const GridPos(x: 3, y: 3),
    )!;
    stroke.paint(const GridPos(x: 6, y: 3));
    final committed = stroke.commit();
    expect(
      committed.layers.whereType<SmartTileLayer>().single.patternStrokes,
      isEmpty,
    );
    expect(
      committed.layers.whereType<SmartTileLayer>().single.field,
      layer.field,
    );
    expect(committed.spatialScene, source.spatialScene);
    expect(committed, stroke.preview);
    document.commit(committed);
    expect(document.undoCount, 1);
    document.restore(redo: false);
    expect(jsonEncode(document.current.toJson()), jsonEncode(source.toJson()));
  });

  test('selected clipped small 3D stamp erases only its existing cells', () {
    final fixture = _atomicStampFixture(origin: const GridPos(x: 6, y: 6));
    final layer = fixture.map.layers.whereType<SmartTileLayer>().single;
    expect(layer.patternStrokes.single.cells, hasLength(4));
    final document = EditableMapDocument(
      MapWorkspaceDocument(
        map: fixture.map,
        mapId: fixture.map.id,
        revision: 'r0',
      ),
    );
    final view = _selectedStampEraseView(fixture.preset, fixture.pattern);
    addTearDown(view.dispose);
    final stroke = MapCanvasStroke.start(
      map: fixture.map,
      project: fixture.project,
      view: view,
      commands: MapEditingCommands(document, fixture.project),
      origin: const GridPos(x: 7, y: 7),
    )!;
    expect(
      stroke.preview.layers.whereType<SmartTileLayer>().single.patternStrokes,
      isEmpty,
    );
    expect(
      stroke.commit().layers.whereType<SmartTileLayer>().single.field,
      layer.field,
    );
  });

  test('selected small 3D stamp refuses a scattered or oversized historical stroke', () {
    final fixture = _atomicStampFixture();
    for (final cells in [
      [const GridPos(x: 2, y: 2), const GridPos(x: 7, y: 7)],
      [
        for (var y = 2; y < 6; y++)
          for (var x = 2; x < 6; x++) GridPos(x: x, y: y),
      ],
    ]) {
      final layer = fixture.map.layers.whereType<SmartTileLayer>().single;
      final source = replaceSmartTileLayer(
        fixture.map,
        layer: layer.copyWith(
          patternStrokes: [layer.patternStrokes.single.copyWith(cells: cells)],
        ),
      );
      final document = EditableMapDocument(
        MapWorkspaceDocument(map: source, mapId: source.id, revision: 'r0'),
      );
      final view = _selectedStampEraseView(fixture.preset, fixture.pattern);
      addTearDown(view.dispose);
      expect(
        MapCanvasStroke.start(
          map: source,
          project: fixture.project,
          view: view,
          commands: MapEditingCommands(document, fixture.project),
          origin: cells.first,
        ),
        isNull,
      );
    }
  });

  for (final bottomToTop in [false, true]) {
    test(
      'selected small stamp does not erase through a foreign owner on a ${bottomToTop ? "back-first" : "front-first"} upper layer',
      () {
        final fixture = _atomicStampFixture();
        final foreign = fixture.pattern.copyWith(id: 'foreign-unit');
        final project = _withStampPatterns(fixture.project, [
          fixture.pattern,
          foreign,
        ]);
        final lower = fixture.map.layers.whereType<SmartTileLayer>().single;
        final upper = lower.copyWith(
          id: 'upper',
          patternStrokes: [
            lower.patternStrokes.single.copyWith(
              id: 'upper-unit',
              patternId: foreign.id,
            ),
          ],
        );
        final source = fixture.map.copyWith(
          layers: bottomToTop ? [lower, upper] : [upper, lower],
          properties: bottomToTop ? {'tileLayerOrder': 'bottom_to_top'} : {},
        );
        final document = EditableMapDocument(
          MapWorkspaceDocument(map: source, mapId: source.id, revision: 'r0'),
        );
        final view = _selectedStampEraseView(fixture.preset, fixture.pattern);
        addTearDown(view.dispose);
        expect(
          MapCanvasStroke.start(
            map: source,
            project: project,
            view: view,
            commands: MapEditingCommands(document, project),
            origin: const GridPos(x: 3, y: 3),
          ),
          isNull,
        );
        expect(document.current, same(source));
        expect(document.undoCount, 0);
      },
    );
  }

  for (final kind in ['frame', 'animation', 'mixed']) {
    test(
      'selected 3D $kind stamp keeps cell-region erasure and protects native ownership beneath it',
      () {
        final fixture = _atomicStampFixture();
        final raster = _fixture(spatial: false);
        final frame =
            (raster.pattern.cells.first.parts.first.source
                    as SmartTileFrameSource)
                .frame;
        final part = SmartTileVisualPart(
          source: kind == 'animation'
              ? const SmartTileVisualSource.animation(
                  animationId: 'raster-animation',
                )
              : SmartTileVisualSource.frame(frame: frame),
        );
        final pattern = fixture.pattern.copyWith(
          id: 'raster-stamp',
          cells: [
            SmartTilePatternCell(
              x: 0,
              y: 0,
              parts: [
                part,
                if (kind == 'mixed') fixture.pattern.cells.first.parts.first,
              ],
            ),
          ],
        );
        final project = fixture.project.copyWith(
          tilesets: raster.project.tilesets,
          smartTileCatalog: ProjectSmartTileCatalog(
            atlases: raster.project.smartTileCatalog.atlases,
            materials: fixture.project.smartTileCatalog.materials,
            presets: fixture.project.smartTileCatalog.presets,
            patterns: [fixture.pattern, pattern],
            animations: [
              if (kind == 'animation')
                ProjectSmartTileAnimation(
                  id: 'raster-animation',
                  name: 'Eau',
                  frames: [
                    ProjectSmartTileAnimationFrame(
                      frame: frame,
                      durationMs: 100,
                    ),
                  ],
                ),
            ],
          ),
        );
        final layer = fixture.map.layers.whereType<SmartTileLayer>().single;
        final rasterStroke = layer.patternStrokes.single.copyWith(
          patternId: pattern.id,
        );
        final source = replaceSmartTileLayer(
          fixture.map,
          layer: layer.copyWith(patternStrokes: [rasterStroke]),
        );
        final document = EditableMapDocument(
          MapWorkspaceDocument(map: source, mapId: source.id, revision: 'r0'),
        );
        final view = _selectedStampEraseView(fixture.preset, pattern);
        addTearDown(view.dispose);
        final stroke = MapCanvasStroke.start(
          map: source,
          project: project,
          view: view,
          commands: MapEditingCommands(document, project),
          origin: const GridPos(x: 3, y: 3),
        )!;
        final erased = stroke
            .commit()
            .layers
            .whereType<SmartTileLayer>()
            .single;
        expect(erased.patternStrokes.single.cells, hasLength(8));
        expect(
          erased.patternStrokes.single.cells,
          contains(const GridPos(x: 2, y: 2)),
        );
        expect(erased.field, layer.field);
        final covered = replaceSmartTileLayer(
          fixture.map,
          layer: layer.copyWith(
            patternStrokes: [
              ...layer.patternStrokes,
              rasterStroke.copyWith(id: 'covering-raster'),
            ],
          ),
        );
        view.selectTerrainPattern(fixture.pattern);
        view.tool = StudioMapTool.erase;
        expect(
          MapCanvasStroke.start(
            map: covered,
            project: project,
            view: view,
            commands: MapEditingCommands(document, project),
            origin: const GridPos(x: 3, y: 3),
          ),
          isNull,
        );
      },
    );
  }

  for (final large in [false, true]) {
    test(
      '${large ? "large source" : "repeat"} 3D motif retains region erasure',
      () {
        final fixture = _atomicStampFixture();
        final pattern = fixture.pattern.copyWith(
          width: large ? 57 : 3,
          height: large ? 36 : 3,
          repeatMode: large
              ? SmartTilePatternRepeatMode.stamp
              : SmartTilePatternRepeatMode.tiled,
        );
        final project = _withStampPatterns(fixture.project, [pattern]);
        final layer = fixture.map.layers.whereType<SmartTileLayer>().single;
        final document = EditableMapDocument(
          MapWorkspaceDocument(
            map: fixture.map,
            mapId: fixture.map.id,
            revision: 'r0',
          ),
        );
        final view = _selectedStampEraseView(fixture.preset, pattern);
        addTearDown(view.dispose);
        final stroke = MapCanvasStroke.start(
          map: fixture.map,
          project: project,
          view: view,
          commands: MapEditingCommands(document, project),
          origin: const GridPos(x: 3, y: 3),
        )!;
        final erased = stroke
            .commit()
            .layers
            .whereType<SmartTileLayer>()
            .single;
        expect(
          erased.patternStrokes.single.cells,
          hasLength(layer.patternStrokes.single.cells.length - 1),
        );
        expect(erased.field, layer.field);
      },
    );
  }

  for (final animated in [false, true]) {
    test(
      '3D raster ${animated ? "animation" : "frame"} motifs paint native strokes and only expose visible ground channels',
      () {
        final fixture = _fixture(spatial: false);
        final frame =
            (fixture.pattern.cells.first.parts.first.source
                    as SmartTileFrameSource)
                .frame;
        final pattern = fixture.pattern.copyWith(
          cells: [
            for (final cell in fixture.pattern.cells)
              cell.copyWith(
                parts: [
                  SmartTileVisualPart(
                    source: animated
                        ? SmartTileVisualSource.animation(
                            animationId: 'raster-animation',
                          )
                        : SmartTileVisualSource.frame(frame: frame),
                  ),
                ],
              ),
          ],
        );
        final project = fixture.project.copyWith(
          version: ProjectVersion.v9,
          settings: fixture.project.settings.copyWith(
            dimension: ProjectDimension.threeD,
            spatialCamera: SpatialCameraProfile(),
          ),
          smartTileCatalog: ProjectSmartTileCatalog(
            atlases: fixture.project.smartTileCatalog.atlases,
            materials: fixture.project.smartTileCatalog.materials,
            presets: fixture.project.smartTileCatalog.presets,
            patterns: [pattern],
            animations: [
              if (animated)
                ProjectSmartTileAnimation(
                  id: 'raster-animation',
                  name: 'Sol animé',
                  frames: [
                    ProjectSmartTileAnimationFrame(
                      frame: frame,
                      durationMs: 100,
                    ),
                  ],
                ),
            ],
          ),
        );
        final source = fixture.map.copyWith(
          version: ProjectVersion.v9,
          spatialScene: MapSpatialScene(width: 8, depth: 8),
          layers: [
            fixture.map.layers.whereType<SmartTileLayer>().single.copyWith(
              field: SmartTileField.cell(semanticCells: List.filled(64, 1)),
              patternStrokes: [],
            ),
          ],
        );
        for (final channel in SmartTileRenderChannel.values) {
          final candidate = pattern.copyWith(
            cells: [
              for (final cell in pattern.cells)
                cell.copyWith(
                  parts: [
                    for (final part in cell.parts)
                      part.copyWith(channel: channel),
                  ],
                ),
            ],
          );
          expect(
            availableTerrainPatterns(
              project: project.copyWith(
                smartTileCatalog: ProjectSmartTileCatalog(
                  atlases: project.smartTileCatalog.atlases,
                  materials: project.smartTileCatalog.materials,
                  presets: project.smartTileCatalog.presets,
                  animations: project.smartTileCatalog.animations,
                  patterns: [candidate],
                ),
              ),
              map: source,
              preset: fixture.preset,
            ),
            channel == SmartTileRenderChannel.ground ||
                    channel == SmartTileRenderChannel.understory
                ? [candidate]
                : isEmpty,
          );
        }
        final document = EditableMapDocument(
          MapWorkspaceDocument(map: source, mapId: source.id, revision: 'r0'),
        );
        final view = MapWorkspaceViewState()
          ..prepareTerrainPainting(fixture.preset)
          ..selectTerrainPattern(pattern);
        addTearDown(view.dispose);
        final stroke = MapCanvasStroke.start(
          map: source,
          project: project,
          view: view,
          commands: MapEditingCommands(document, project),
          origin: const GridPos(x: 1, y: 1),
        )!;
        expect(document.current, same(source));
        expect(
          stroke.preview.layers
              .whereType<SmartTileLayer>()
              .single
              .patternStrokes
              .single
              .patternId,
          pattern.id,
        );
        document.commit(stroke.commit());
        expect(document.current.spatialScene, source.spatialScene);
        expect(document.undoCount, 1);
        final painted = document.current;
        view.tool = StudioMapTool.erase;
        final erasing = MapCanvasStroke.start(
          map: painted,
          project: project,
          view: view,
          commands: MapEditingCommands(document, project),
          origin: const GridPos(x: 1, y: 1),
        )!;
        final erased = erasing.commit();
        final erasedLayer = erased.layers.whereType<SmartTileLayer>().single;
        expect(
          erasedLayer.field,
          source.layers.whereType<SmartTileLayer>().single.field,
        );
        expect(erasedLayer.patternStrokes.single.cells, [
          const GridPos(x: 2, y: 1),
        ]);
        expect(erased.spatialScene, source.spatialScene);
        document.commit(erased);
        expect(document.undoCount, 2);
        document.restore(redo: false);
        expect(document.current, painted);
        document.restore(redo: false);
        expect(document.current, source);
        final privateProject = project.copyWith(
          resourceLibraryCatalog: ResourceLibraryCatalog(
            entries: [
              ResourceLibraryEntry(
                resourceKind: 'tileset',
                resourceId: project.smartTileCatalog.atlases.single.tilesetId,
                mapId: 'other-map',
              ),
            ],
          ),
        );
        expect(
          availableTerrainPatterns(
            project: privateProject,
            map: source,
            preset: fixture.preset,
          ),
          isEmpty,
        );
      },
    );
  }
  for (final animated in [false, true]) {
    for (final bottomToTop in [false, true]) {
      for (final coveredByEmptyStroke in [false, true]) {
        test(
          'native raster erase targets ${animated ? "animation" : "frame"} parts with ${bottomToTop ? "back-first" : "front-first"} layers and ${coveredByEmptyStroke ? "overlapping" : "single"} stamps',
          () {
            final fixture = _fixture(spatial: false);
            final frame =
                (fixture.pattern.cells.first.parts.first.source
                        as SmartTileFrameSource)
                    .frame;
            final pattern = fixture.pattern.copyWith(
              cells: [
                for (final cell in fixture.pattern.cells)
                  cell.copyWith(
                    parts: [
                      SmartTileVisualPart(
                        source: animated
                            ? SmartTileVisualSource.animation(
                                animationId: 'raster-animation',
                              )
                            : SmartTileVisualSource.frame(frame: frame),
                      ),
                    ],
                  ),
              ],
            );
            final sparse = pattern.copyWith(
              id: 'sparse-raster',
              cells: [pattern.cells.first],
            );
            final project = fixture.project.copyWith(
              version: ProjectVersion.v9,
              settings: fixture.project.settings.copyWith(
                dimension: ProjectDimension.threeD,
                spatialCamera: SpatialCameraProfile(),
              ),
              smartTileCatalog: ProjectSmartTileCatalog(
                atlases: fixture.project.smartTileCatalog.atlases,
                materials: fixture.project.smartTileCatalog.materials,
                presets: fixture.project.smartTileCatalog.presets,
                patterns: [pattern, sparse],
                animations: [
                  if (animated)
                    ProjectSmartTileAnimation(
                      id: 'raster-animation',
                      name: 'Sol animé',
                      frames: [
                        ProjectSmartTileAnimationFrame(
                          frame: frame,
                          durationMs: 100,
                        ),
                      ],
                    ),
                ],
              ),
            );
            final lower = fixture.map.layers.whereType<SmartTileLayer>().single;
            final upper = lower.copyWith(
              id: 'raster-layer',
              patternStrokes: [
                if (coveredByEmptyStroke) ...lower.patternStrokes,
                lower.patternStrokes.single.copyWith(
                  id: 'sparse-raster-stroke',
                  patternId: sparse.id,
                ),
              ],
            );
            final source = fixture.map.copyWith(
              version: ProjectVersion.v9,
              spatialScene: MapSpatialScene(width: 8, depth: 8),
              properties: bottomToTop
                  ? {'tileLayerOrder': 'bottom_to_top'}
                  : {},
              layers: bottomToTop ? [lower, upper] : [upper, lower],
            );
            final document = EditableMapDocument(
              MapWorkspaceDocument(
                map: source,
                mapId: source.id,
                revision: 'r0',
              ),
            );
            final view = MapWorkspaceViewState()..tool = StudioMapTool.erase;
            addTearDown(view.dispose);
            final commands = MapEditingCommands(document, project);
            final emptyUpperStroke = MapCanvasStroke.start(
              map: source,
              project: project,
              view: view,
              commands: commands,
              origin: const GridPos(x: 4, y: 2),
            );
            expect(emptyUpperStroke, isNotNull);
            expect(emptyUpperStroke!.buffer.layerId, lower.id);
            expect(
              emptyUpperStroke.commit().layers.firstWhere(
                (layer) => layer.id == upper.id,
              ),
              upper,
            );
            final stroke = MapCanvasStroke.start(
              map: source,
              project: project,
              view: view,
              commands: commands,
              origin: const GridPos(x: 3, y: 2),
            );
            expect(stroke, isNotNull);
            expect(stroke!.buffer.layerId, upper.id);
            expect(document.current, same(source));
            final erased = stroke.commit();
            expect(
              erased.layers.firstWhere((layer) => layer.id == lower.id),
              lower,
            );
            final erasedUpper = erased.layers
                .whereType<SmartTileLayer>()
                .firstWhere((layer) => layer.id == upper.id);
            for (final remaining in erasedUpper.patternStrokes) {
              expect(remaining.cells, [
                const GridPos(x: 2, y: 2),
                const GridPos(x: 4, y: 2),
                const GridPos(x: 5, y: 2),
              ]);
            }
            expect(erasedUpper.field, upper.field);
            expect(erased.spatialScene, source.spatialScene);
            document.commit(erased);
            expect(document.undoCount, 1);
            document.restore(redo: false);
            expect(document.current, source);
          },
        );
      }
    }
  }

  for (final bottomToTop in [false, true]) {
    for (final coveredByEmptyStroke in [false, true]) {
      test(
        'native erase skips sparse empty ownership with ${bottomToTop ? "back-first" : "front-first"} layers and ${coveredByEmptyStroke ? "overlapping" : "single"} stamps',
        () {
          final fixture = _fixture();
          final sparse = fixture.pattern.copyWith(
            id: 'sparse',
            cells: [fixture.pattern.cells.first],
          );
          final project = fixture.project.copyWith(
            smartTileCatalog: ProjectSmartTileCatalog(
              atlases: fixture.project.smartTileCatalog.atlases,
              materials: fixture.project.smartTileCatalog.materials,
              presets: fixture.project.smartTileCatalog.presets,
              patterns: [fixture.pattern, sparse],
            ),
          );
          final lower = fixture.map.layers.whereType<SmartTileLayer>().single;
          final upper = lower.copyWith(
            id: 'sparse-layer',
            name: 'Clôture',
            patternStrokes: [
              if (coveredByEmptyStroke) ...lower.patternStrokes,
              lower.patternStrokes.single.copyWith(
                id: 'sparse-stroke',
                patternId: sparse.id,
              ),
            ],
          );
          final source = fixture.map.copyWith(
            properties: bottomToTop ? {'tileLayerOrder': 'bottom_to_top'} : {},
            layers: bottomToTop ? [lower, upper] : [upper, lower],
          );
          final document = EditableMapDocument(
            MapWorkspaceDocument(map: source, mapId: source.id, revision: 'r0'),
          );
          final view = MapWorkspaceViewState()..tool = StudioMapTool.erase;
          addTearDown(view.dispose);
          final stroke = MapCanvasStroke.start(
            map: source,
            project: project,
            view: view,
            commands: MapEditingCommands(document, project),
            origin: const GridPos(x: 4, y: 2),
          )!;
          expect(stroke.buffer.layerId, lower.id);
          final erased = stroke.commit();
          expect(
            erased.layers.firstWhere((layer) => layer.id == upper.id),
            upper,
          );
          expect(
            erased.layers
                .whereType<SmartTileLayer>()
                .firstWhere((layer) => layer.id == lower.id)
                .patternStrokes
                .single
                .cells,
            [
              const GridPos(x: 2, y: 2),
              const GridPos(x: 3, y: 2),
              const GridPos(x: 5, y: 2),
            ],
          );
          document.commit(erased);
          expect(document.undoCount, 1);
          document.restore(redo: false);
          expect(document.current, source);
        },
      );
    }
  }

  test(
    'native erase still selects a sparse cell containing a visible part',
    () {
      final fixture = _fixture();
      final sparse = fixture.pattern.copyWith(
        id: 'sparse',
        cells: [fixture.pattern.cells.first],
      );
      final project = fixture.project.copyWith(
        smartTileCatalog: ProjectSmartTileCatalog(
          atlases: fixture.project.smartTileCatalog.atlases,
          materials: fixture.project.smartTileCatalog.materials,
          presets: fixture.project.smartTileCatalog.presets,
          patterns: [fixture.pattern, sparse],
        ),
      );
      final lower = fixture.map.layers.whereType<SmartTileLayer>().single;
      final upper = lower.copyWith(
        id: 'sparse-layer',
        patternStrokes: [
          lower.patternStrokes.single.copyWith(
            id: 'sparse-stroke',
            patternId: sparse.id,
          ),
        ],
      );
      final source = fixture.map.copyWith(layers: [upper, lower]);
      final document = EditableMapDocument(
        MapWorkspaceDocument(map: source, mapId: source.id, revision: 'r0'),
      );
      final view = MapWorkspaceViewState()..tool = StudioMapTool.erase;
      addTearDown(view.dispose);
      final stroke = MapCanvasStroke.start(
        map: source,
        project: project,
        view: view,
        commands: MapEditingCommands(document, project),
        origin: const GridPos(x: 3, y: 2),
      )!;
      expect(stroke.buffer.layerId, upper.id);
      expect(stroke.commit().layers.last, lower);
      final emptySource = source.copyWith(layers: [upper]);
      expect(
        MapCanvasStroke.start(
          map: emptySource,
          project: project,
          view: view,
          commands: MapEditingCommands(document, project),
          origin: const GridPos(x: 4, y: 2),
        ),
        isNull,
      );
      final materialUpper = applySmartTileMaterialGesture(
        upper,
        mapSize: source.size,
        cells: [const GridPos(x: 4, y: 2)],
        materialId: fixture.preset.defaultMaterialId,
      );
      final materialSource = source.copyWith(layers: [materialUpper, lower]);
      final materialStroke = MapCanvasStroke.start(
        map: materialSource,
        project: project,
        view: view,
        commands: MapEditingCommands(document, project),
        origin: const GridPos(x: 4, y: 2),
      )!;
      expect(materialStroke.buffer.layerId, upper.id);
      final materialErased = materialStroke.commit();
      expect(materialErased.layers.last, lower);
      expect(
        smartTileMaterialIdAt(
          materialErased.layers.whereType<SmartTileLayer>().first,
          mapSize: source.size,
          x: 4,
          y: 2,
        ),
        isNull,
      );
    },
  );

  for (final bottomToTop in [false, true]) {
    test(
      'selected 3D preset erases its layer behind soil with ${bottomToTop ? "back-first" : "front-first"} layers',
      () {
        final fixture = _selectedPresetEraseFixture(bottomToTop: bottomToTop);
        final source = fixture.map;
        final before = jsonEncode(source.toJson());
        final grass = source.layers.whereType<SmartTileLayer>().firstWhere(
          (layer) => layer.presetId == fixture.preset.id,
        );
        final document = EditableMapDocument(
          MapWorkspaceDocument(map: source, mapId: source.id, revision: 'r0'),
        );
        final view = MapWorkspaceViewState()
          ..prepareTerrainPainting(fixture.preset)
          ..tool = StudioMapTool.erase;
        addTearDown(view.dispose);
        final stroke = MapCanvasStroke.start(
          map: source,
          project: fixture.project,
          view: view,
          commands: MapEditingCommands(document, fixture.project),
          origin: const GridPos(x: 3, y: 2),
        )!;
        expect(stroke.buffer.layerId, grass.id);
        expect(document.current, same(source));
        expect(document.undoCount, 0);
        final preview = stroke.preview.layers
            .whereType<SmartTileLayer>()
            .firstWhere((layer) => layer.id == grass.id);
        expect(
          smartTileMaterialIdAt(preview, mapSize: source.size, x: 3, y: 2),
          isNull,
        );
        expect(preview.patternStrokes.single.cells, [
          const GridPos(x: 2, y: 2),
          const GridPos(x: 4, y: 2),
          const GridPos(x: 5, y: 2),
        ]);
        expect(preview.patternStrokes.single.phaseX, grass.patternStrokes.single.phaseX);
        expect(preview.patternStrokes.single.phaseY, grass.patternStrokes.single.phaseY);
        for (final layer in source.layers.where((layer) => layer.id != grass.id)) {
          expect(
            stroke.preview.layers.firstWhere((entry) => entry.id == layer.id),
            layer,
          );
        }
        expect(stroke.preview.spatialScene, source.spatialScene);
        final committed = stroke.commit();
        expect(committed, stroke.preview);
        document.commit(committed);
        expect(document.undoCount, 1);
        document.restore(redo: false);
        expect(jsonEncode(document.current.toJson()), before);
        document.restore(redo: true);
        expect(document.current, committed);
      },
    );
    for (final selectedLayerPresent in [false, true]) {
      test(
        'selected 3D preset refuses foreign soil when ${selectedLayerPresent ? "its cell is empty" : "its layer is absent"} with ${bottomToTop ? "back-first" : "front-first"} layers',
        () {
          final fixture = _selectedPresetEraseFixture(
            bottomToTop: bottomToTop,
            selectedLayerPresent: selectedLayerPresent,
            selectedCellOwned: false,
          );
          final source = fixture.map;
          final document = EditableMapDocument(
            MapWorkspaceDocument(map: source, mapId: source.id, revision: 'r0'),
          );
          final view = MapWorkspaceViewState()
            ..prepareTerrainPainting(fixture.preset)
            ..tool = StudioMapTool.erase;
          addTearDown(view.dispose);
          expect(
            MapCanvasStroke.start(
              map: source,
              project: fixture.project,
              view: view,
              commands: MapEditingCommands(document, fixture.project),
              origin: const GridPos(x: 3, y: 2),
            ),
            isNull,
          );
          expect(document.current, same(source));
          expect(document.undoCount, 0);
        },
      );
    }
  }

  for (final spatial in [false, true]) {
    test(
      '${spatial ? "unselected 3D" : "selected 2D"} preset erase preserves frontmost selection',
      () {
        final fixture = _selectedPresetEraseFixture(spatial: spatial);
        final source = fixture.map;
        final document = EditableMapDocument(
          MapWorkspaceDocument(map: source, mapId: source.id, revision: 'r0'),
        );
        final view = MapWorkspaceViewState();
        if (!spatial) view.prepareTerrainPainting(fixture.preset);
        view.tool = StudioMapTool.erase;
        addTearDown(view.dispose);
        final stroke = MapCanvasStroke.start(
          map: source,
          project: fixture.project,
          view: view,
          commands: MapEditingCommands(document, fixture.project),
          origin: const GridPos(x: 3, y: 2),
        )!;
        expect(stroke.buffer.layerId, 'soil-layer');
        final erased = stroke.commit();
        final soil = erased.layers.whereType<SmartTileLayer>().firstWhere(
          (layer) => layer.id == 'soil-layer',
        );
        expect(
          smartTileMaterialIdAt(soil, mapSize: source.size, x: 3, y: 2),
          isNull,
        );
        for (final layer in source.layers.where((layer) => layer.id != soil.id)) {
          expect(erased.layers.firstWhere((entry) => entry.id == layer.id), layer);
        }
      },
    );
  }

  test('native erase commits visual-only pattern cells and interpolates without changing neighbours', () {
    final fixture = _fixture(followTerrain: false);
    final source = fixture.map;
    final view = MapWorkspaceViewState()..tool = StudioMapTool.erase;
    addTearDown(view.dispose);
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: source, mapId: source.id, revision: 'r0'),
    );
    final stroke = MapCanvasStroke.start(
      map: source,
      project: fixture.project,
      view: view,
      commands: MapEditingCommands(document, fixture.project),
      origin: const GridPos(x: 3, y: 2),
    );
    expect(stroke, isNotNull);
    stroke!.paint(const GridPos(x: 5, y: 2));
    expect(document.current, same(source));
    final preview = stroke.preview.layers.whereType<SmartTileLayer>().single;
    expect(preview.patternStrokes.single.cells, [const GridPos(x: 2, y: 2)]);
    expect(preview.patternStrokes.single.phaseX, 1);
    expect(preview.patternStrokes.single.phaseY, 0);
    expect(
      preview.field,
      source.layers.whereType<SmartTileLayer>().single.field,
    );
    document.commit(stroke.commit());
    expect(document.current, stroke.preview);
    expect(document.undoCount, 1);
    expect(document.current.spatialScene, source.spatialScene);
    expect(
      resolveSpatialSmartTileInstances(
        map: document.current,
        catalog: fixture.project.smartTileCatalog,
      ),
      hasLength(1),
    );
    document.restore(redo: false);
    expect(document.current, source);
    expect(
      resolveSpatialSmartTileInstances(
        map: document.current,
        catalog: fixture.project.smartTileCatalog,
      ),
      hasLength(4),
    );
  });

  test('2D material erase preserves existing pattern ownership', () {
    final fixture = _fixture(spatial: false);
    final spatial = fixture.map.layers.whereType<SmartTileLayer>().single;
    final layer = applySmartTileMaterialGesture(
      spatial,
      mapSize: fixture.map.size,
      cells: [const GridPos(x: 3, y: 2)],
      materialId: fixture.preset.defaultMaterialId,
    );
    final source = MapData(
      id: fixture.map.id,
      name: 'Plan 2D',
      version: ProjectVersion.v8,
      size: fixture.map.size,
      layers: [layer],
    );
    final view = MapWorkspaceViewState()..tool = StudioMapTool.erase;
    addTearDown(view.dispose);
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: source, mapId: source.id, revision: 'r0'),
    );
    final stroke = MapCanvasStroke.start(
      map: source,
      project: fixture.project,
      view: view,
      commands: MapEditingCommands(document, fixture.project),
      origin: const GridPos(x: 3, y: 2),
    )!;
    final erased = stroke.commit().layers.whereType<SmartTileLayer>().single;
    expect(
      smartTileMaterialIdAt(erased, mapSize: source.size, x: 3, y: 2),
      isNull,
    );
    expect(erased.patternStrokes, layer.patternStrokes);
    document.commit(stroke.commit());
    document.restore(redo: false);
    expect(document.current, source);
  });

  test('changing the selected recipe cancels a 2D pattern erase gesture', () {
    final fixture = _fixture(spatial: false);
    final document = EditableMapDocument(
      MapWorkspaceDocument(
        map: fixture.map,
        mapId: fixture.map.id,
        revision: 'r0',
      ),
    );
    final view = MapWorkspaceViewState()
      ..prepareTerrainPainting(fixture.preset)
      ..selectTerrainPattern(fixture.pattern)
      ..tool = StudioMapTool.erase;
    addTearDown(view.dispose);
    final stroke = MapCanvasStroke.start(
      map: fixture.map,
      project: fixture.project,
      view: view,
      commands: MapEditingCommands(document, fixture.project),
      origin: const GridPos(x: 3, y: 2),
    )!;
    expect(stroke.matches(view), isTrue);
    view.terrainPatternId = 'another';
    expect(stroke.matches(view), isFalse);
    expect(document.current, fixture.map);
    expect(document.canUndo, isFalse);
  });

  test('2D pattern erase removes only ownership and preserves materials', () {
    final fixture = _fixture(spatial: false);
    final sourceLayer = fixture.map.layers.whereType<SmartTileLayer>().single;
    final source = replaceSmartTileLayer(
      fixture.map,
      layer: applySmartTileMaterialGesture(
        sourceLayer,
        mapSize: fixture.map.size,
        cells: [const GridPos(x: 3, y: 2)],
        materialId: fixture.preset.defaultMaterialId,
      ),
    );
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: source, mapId: source.id, revision: 'r0'),
    );
    final view = MapWorkspaceViewState()
      ..prepareTerrainPainting(fixture.preset)
      ..selectTerrainPattern(fixture.pattern)
      ..tool = StudioMapTool.erase;
    addTearDown(view.dispose);
    final stroke = MapCanvasStroke.start(
      map: source,
      project: fixture.project,
      view: view,
      commands: MapEditingCommands(document, fixture.project),
      origin: const GridPos(x: 3, y: 2),
    )!;
    document.commit(stroke.commit());
    final layer = document.current.layers.whereType<SmartTileLayer>().single;
    expect(
      smartTileMaterialIdAt(layer, mapSize: source.size, x: 3, y: 2),
      fixture.preset.defaultMaterialId,
    );
    expect(layer.patternStrokes.single.cells, [
      const GridPos(x: 2, y: 2),
      const GridPos(x: 4, y: 2),
      const GridPos(x: 5, y: 2),
    ]);
    document.restore(redo: false);
    expect(document.current, source);
  });

  test('stamp clips at an edge and keeps its authored anchor phase', () {
    final fixture = _fixture();
    final pattern = fixture.pattern.copyWith(anchorX: 1);
    final project = fixture.project.copyWith(
      smartTileCatalog: ProjectSmartTileCatalog(
        materials: fixture.project.smartTileCatalog.materials,
        presets: [fixture.preset],
        patterns: [pattern],
      ),
    );
    final document = EditableMapDocument(
      MapWorkspaceDocument(
        map: fixture.map,
        mapId: fixture.map.id,
        revision: 'r0',
      ),
    );
    final view = MapWorkspaceViewState()
      ..prepareTerrainPainting(fixture.preset)
      ..selectTerrainPattern(pattern);
    addTearDown(view.dispose);
    final stroke = MapCanvasStroke.start(
      map: fixture.map,
      project: project,
      view: view,
      commands: MapEditingCommands(document, project),
      origin: const GridPos(x: 0, y: 0),
    )!;
    final placed = stroke
        .commit()
        .layers
        .whereType<SmartTileLayer>()
        .single
        .patternStrokes
        .last;
    expect(placed.cells, [const GridPos(x: 0, y: 0)]);
    expect(placed.phaseX, 1);
    expect(placed.phaseY, 0);
    expect(
      smartTilePatternCellAt(
        pattern: pattern,
        stroke: placed,
        cell: const GridPos(x: 0, y: 0),
      )!.x,
      1,
    );
  });

  test('an excessive rectangle is rejected without a commit or undo entry', () {
    final fixture = _fixture();
    final sourceLayer = fixture.map.layers.whereType<SmartTileLayer>().single;
    final map = fixture.map.copyWith(
      size: const GridSize(width: 80, height: 80),
      spatialScene: MapSpatialScene(width: 80, depth: 80),
      layers: [
        sourceLayer.copyWith(
          field: SmartTileField.cell(semanticCells: List.filled(6400, 0)),
        ),
      ],
    );
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: map, mapId: map.id, revision: 'r0'),
    );
    final view = MapWorkspaceViewState()
      ..prepareTerrainPainting(fixture.preset)
      ..selectTerrainPattern(fixture.pattern)
      ..terrainPatternMode = SmartTilePatternSelectionKind.rectangle;
    addTearDown(view.dispose);
    final stroke = MapCanvasStroke.start(
      map: map,
      project: fixture.project,
      view: view,
      commands: MapEditingCommands(document, fixture.project),
      origin: const GridPos(x: 0, y: 0),
    )!;
    expect(
      () => stroke.paint(const GridPos(x: 64, y: 64)),
      throwsA(isA<SmartTileGestureLimitException>()),
    );
    expect(document.current, same(map));
    expect(document.canUndo, isFalse);
  });

  for (final spatial in [false, true]) {
    testWidgets(
      '${spatial ? "3D" : "2D"} picker checks normalized stamp footprints without changing tiled recipes',
      (tester) async {
        tester.view.physicalSize = const Size(1400, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final fixture = _fixture(spatial: spatial);
        final compact = fixture.pattern.copyWith(
          id: 'compact',
          name: 'Raccord compact',
          repeatMode: SmartTilePatternRepeatMode.stamp,
        );
        final shifted = compact.copyWith(
          id: 'shifted',
          name: 'Raccord décalé',
          width: 8,
          cells: [
            for (final cell in compact.cells) cell.copyWith(x: cell.x + 6),
          ],
        );
        final shiftedVertical = compact.copyWith(
          id: 'shifted-vertical',
          name: 'Raccord décalé en profondeur',
          height: 8,
          cells: [
            for (final cell in compact.cells) cell.copyWith(y: cell.y + 6),
          ],
        );
        final emptyOrigin = shifted.copyWith(
          id: 'empty-origin',
          name: 'Raccord avec origine vide',
          cells: [
            const SmartTilePatternCell(x: 0, y: 0, eraseMaterial: true),
            ...shifted.cells,
          ],
        );
        final tiled = shifted.copyWith(
          id: 'shifted-tiled',
          name: 'Trame décalée',
          repeatMode: SmartTilePatternRepeatMode.tiled,
        );
        final project = fixture.project.copyWith(
          smartTileCatalog: ProjectSmartTileCatalog(
            materials: fixture.project.smartTileCatalog.materials,
            atlases: fixture.project.smartTileCatalog.atlases,
            presets: [fixture.preset],
            patterns: [compact, shifted, shiftedVertical, emptyOrigin, tiled],
          ),
        );
        final map = fixture.map.copyWith(layers: []);
        expect(
          availableTerrainPatterns(
            project: project,
            map: map,
            preset: fixture.preset,
          ).map((pattern) => pattern.id).toSet(),
          {
            compact.id,
            tiled.id,
            if (!spatial) ...{shifted.id, shiftedVertical.id, emptyOrigin.id},
          },
        );
        final view = MapWorkspaceViewState()
          ..prepareTerrainPainting(fixture.preset);
        addTearDown(view.dispose);
        final document = EditableMapDocument(
          MapWorkspaceDocument(map: map, mapId: map.id, revision: 'r0'),
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: studioTheme(),
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) => MapTerrainToolPanel(
                  document: document,
                  project: project,
                  visuals: _PatternVisuals(),
                  view: view,
                  onChanged: () => setState(() {}),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.byKey(const ValueKey('terrain-pattern-picker')));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Raccord compact'), findsOneWidget);
        expect(find.text('Trame décalée'), findsOneWidget);
        expect(
          find.text('Raccord décalé'),
          spatial ? findsNothing : findsOneWidget,
        );
        expect(
          find.text('Raccord décalé en profondeur'),
          spatial ? findsNothing : findsOneWidget,
        );
        expect(
          find.text('Raccord avec origine vide'),
          spatial ? findsNothing : findsOneWidget,
        );
        await tester.tap(find.text('Raccord compact'));
        await tester.pump(const Duration(milliseconds: 300));
        final stroke = MapCanvasStroke.start(
          map: map,
          project: project,
          view: view,
          commands: MapEditingCommands(document, project),
          origin: const GridPos(x: 1, y: 1),
        )!;
        document.commit(stroke.commit());
        expect(
          document.current.layers
              .whereType<SmartTileLayer>()
              .single
              .patternStrokes
              .single
              .cells,
          [const GridPos(x: 1, y: 1), const GridPos(x: 2, y: 1)],
        );
        expect(tester.takeException(), isNull);
      },
    );
    for (final erase in [false, true]) {
      test(
        '${spatial ? "3D" : "2D"} diagonal ${erase ? "erase" : "paint"} uses one interpolation and preserves the opposite neighbour',
        () {
          final fixture = _fixture(spatial: spatial);
          final layer = fixture.map.layers.whereType<SmartTileLayer>().single;
          final source = replaceSmartTileLayer(
            fixture.map,
            layer: layer.copyWith(
              field: SmartTileField.cell(
                semanticCells: List.filled(64, erase ? 1 : 0),
              ),
              patternStrokes: [],
            ),
          );
          final document = EditableMapDocument(
            MapWorkspaceDocument(map: source, mapId: source.id, revision: 'r0'),
          );
          final view = MapWorkspaceViewState()
            ..prepareTerrainPainting(fixture.preset)
            ..tool = erase ? StudioMapTool.erase : StudioMapTool.terrain;
          addTearDown(view.dispose);
          final stroke = MapCanvasStroke.start(
            map: source,
            project: fixture.project,
            view: view,
            commands: MapEditingCommands(document, fixture.project),
            origin: const GridPos(x: 3, y: 2),
          )!;
          stroke.paint(const GridPos(x: 5, y: 3));
          final selected = {
            const GridPos(x: 3, y: 2),
            GridPos(x: 4, y: spatial ? 2 : 3),
            const GridPos(x: 5, y: 3),
          };
          final previewLayer = stroke.preview.layers
              .whereType<SmartTileLayer>()
              .single;
          final changed = <GridPos>{};
          for (var y = 0; y < source.size.height; y++) {
            for (var x = 0; x < source.size.width; x++) {
              final cell = GridPos(x: x, y: y);
              final painted =
                  smartTileMaterialIdAt(
                    previewLayer,
                    mapSize: source.size,
                    x: x,
                    y: y,
                  ) !=
                  null;
              if (painted != erase) changed.add(cell);
            }
          }
          expect(changed, selected);
          expect(changed.contains(GridPos(x: 4, y: spatial ? 3 : 2)), isFalse);
          expect(document.current, same(source));
          document.commit(stroke.commit());
          expect(document.current, stroke.preview);
          expect(document.undoCount, 1);
          document.restore(redo: false);
          expect(document.current, source);
        },
      );
    }
    testWidgets(
      '${spatial ? "3D" : "2D"} a new manifest changing the same ID to stamp reconciles the displayed mode and gesture',
      (tester) async {
        tester.view.physicalSize = const Size(1400, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final fixture = _fixture(spatial: spatial);
        final view = MapWorkspaceViewState()
          ..prepareTerrainPainting(fixture.preset)
          ..selectTerrainPattern(fixture.pattern)
          ..terrainPatternMode = SmartTilePatternSelectionKind.line;
        addTearDown(view.dispose);
        final document = EditableMapDocument(
          MapWorkspaceDocument(
            map: fixture.map,
            mapId: fixture.map.id,
            revision: 'r0',
          ),
        );
        Widget panel(ProjectManifest project) => MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: MapTerrainToolPanel(
              document: document,
              project: project,
              visuals: _PatternVisuals(),
              view: view,
              onChanged: () {},
            ),
          ),
        );
        await tester.pumpWidget(panel(fixture.project));
        expect(find.text('Ligne'), findsOneWidget);
        final stamp = fixture.pattern.copyWith(
          repeatMode: SmartTilePatternRepeatMode.stamp,
        );
        final currentProject = fixture.project.copyWith(
          smartTileCatalog: ProjectSmartTileCatalog(
            materials: fixture.project.smartTileCatalog.materials,
            atlases: fixture.project.smartTileCatalog.atlases,
            presets: [fixture.preset],
            patterns: [stamp],
          ),
        );
        view.reconcileResources(
          currentProject,
          mapId: fixture.map.id,
          map: fixture.map,
        );
        expect(view.terrainPatternId, stamp.id);
        expect(view.terrainPatternMode, SmartTilePatternSelectionKind.stamp);
        await tester.pumpWidget(panel(currentProject));
        expect(find.text('Tampon'), findsOneWidget);
        expect(find.text('Ligne'), findsNothing);
        final stroke = MapCanvasStroke.start(
          map: fixture.map,
          project: currentProject,
          view: view,
          commands: MapEditingCommands(document, currentProject),
          origin: const GridPos(x: 0, y: 0),
        )!;
        stroke.paint(const GridPos(x: 6, y: 6));
        expect(stroke.patternMode, SmartTilePatternSelectionKind.stamp);
        document.commit(stroke.commit());
        expect(
          document.current.layers
              .whereType<SmartTileLayer>()
              .single
              .patternStrokes
              .last
              .cells,
          [const GridPos(x: 0, y: 0), const GridPos(x: 1, y: 0)],
        );
        document.restore(redo: false);
        expect(document.current, fixture.map);
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets(
      '${spatial ? "3D" : "2D"} Motif shows reusable catalogue recipes and keeps the material',
      (tester) async {
        tester.view.physicalSize = const Size(1400, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final fixture = _fixture(spatial: spatial);
        final stamp = fixture.pattern.copyWith(
          id: 'stamp',
          name: 'Bouquet isolé',
          repeatMode: SmartTilePatternRepeatMode.stamp,
        );
        final giant = fixture.pattern.copyWith(
          id: 'giant',
          name: 'Recette source entière',
          width: 9,
        );
        final unreferenced = fixture.pattern.copyWith(
          id: 'public-unused',
          name: 'Motif du catalogue',
        );
        final incompatible = fixture.pattern.copyWith(
          id: 'other-usage',
          name: 'Autre usage',
          usage: fixture.pattern.usage == SmartTileUsage.path
              ? SmartTileUsage.terrain
              : SmartTileUsage.path,
        );
        final unavailable = fixture.pattern.copyWith(
          id: 'unavailable',
          name: 'Source privée ailleurs',
          cells: [
            const SmartTilePatternCell(
              x: 0,
              y: 0,
              parts: [
                SmartTileVisualPart(
                  source: SmartTileVisualSource.model3d(modelId: 'other-model'),
                ),
              ],
            ),
          ],
        );
        final absolute = fixture.pattern.copyWith(
          id: 'absolute-water',
          name: 'Eau source à altitude fixe',
          cells: [
            const SmartTilePatternCell(
              x: 0,
              y: 0,
              parts: [
                SmartTileVisualPart(
                  source: SmartTileVisualSource.model3d(
                    modelId: 'oak',
                    followTerrain: false,
                    offsetY: -2.25,
                  ),
                ),
              ],
            ),
          ],
        );
        final project = fixture.project.copyWith(
          models3d: [
            ...fixture.project.models3d,
            spatialPathModel('other-model'),
          ],
          resourceLibraryCatalog: ResourceLibraryCatalog(
            entries: [
              ResourceLibraryEntry(
                resourceKind: 'model3d',
                resourceId: 'other-model',
                mapId: 'b',
              ),
            ],
          ),
          smartTileCatalog: ProjectSmartTileCatalog(
            materials: fixture.project.smartTileCatalog.materials,
            atlases: fixture.project.smartTileCatalog.atlases,
            presets: [fixture.preset],
            patterns: [
              fixture.pattern,
              stamp,
              giant,
              unreferenced,
              incompatible,
              unavailable,
              absolute,
            ],
          ),
        );
        final layer = fixture.map.layers.whereType<SmartTileLayer>().single;
        final map = replaceSmartTileLayer(
          fixture.map,
          layer: layer.copyWith(
            patternStrokes: [
              ...layer.patternStrokes,
              for (final pattern in [stamp, giant, incompatible, unavailable])
                SmartTilePatternStroke(
                  id: pattern.id,
                  patternId: pattern.id,
                  cells: [const GridPos(x: 7, y: 7)],
                ),
            ],
          ),
        );
        expect(
          availableTerrainPatterns(
            project: project,
            map: map,
            preset: fixture.preset,
          ).map((pattern) => pattern.id).toSet(),
          {fixture.pattern.id, stamp.id, unreferenced.id, if (spatial) absolute.id},
        );
        final view = MapWorkspaceViewState()
          ..prepareTerrainPainting(fixture.preset);
        addTearDown(view.dispose);
        final document = EditableMapDocument(
          MapWorkspaceDocument(map: map, mapId: map.id, revision: 'r0'),
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: studioTheme(),
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) => MapTerrainToolPanel(
                  document: document,
                  project: project,
                  visuals: _PatternVisuals(),
                  view: view,
                  onChanged: () => setState(() {}),
                ),
              ),
            ),
          ),
        );
        final material = view.terrainMaterialId;
        await tester.tap(find.byKey(const ValueKey('terrain-pattern-picker')));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Recette source entière'), findsNothing);
        expect(find.text('Motif du catalogue'), findsOneWidget);
        expect(find.text('Source privée ailleurs'), findsNothing);
        expect(find.text('Eau source à altitude fixe'), spatial ? findsOneWidget : findsNothing);
        await tester.tap(find.text('Eau animée').last);
        await tester.pump(const Duration(milliseconds: 300));
        expect(view.terrainPatternId, fixture.pattern.id);
        await tester.tap(find.byKey(const ValueKey('terrain-pattern-mode')));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.text('Rectangle').last);
        await tester.pump(const Duration(milliseconds: 300));
        expect(
          view.terrainPatternMode,
          SmartTilePatternSelectionKind.rectangle,
        );
        await tester.tap(find.byKey(const ValueKey('terrain-pattern-picker')));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.text('Bouquet isolé').last);
        await tester.pump(const Duration(milliseconds: 300));
        expect(view.terrainPatternMode, SmartTilePatternSelectionKind.stamp);
        await tester.tap(find.byKey(const ValueKey('terrain-pattern-mode')));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Ligne'), findsNothing);
        expect(find.text('Rectangle'), findsNothing);
        await tester.tap(find.text('Tampon').last);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.byKey(const ValueKey('terrain-pattern-picker')));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.text('Peinture libre').last);
        await tester.pump(const Duration(milliseconds: 300));
        expect(view.terrainPatternId, isNull);
        expect(view.terrainMaterialId, material);
        expect(tester.takeException(), isNull);
      },
    );
    test(
      '${spatial ? "3D" : "2D"} public motif creates an empty layer on an unused map and undoes exactly',
      () {
        final fixture = _fixture(spatial: spatial);
        final source = fixture.map.copyWith(layers: []);
        expect(
          availableTerrainPatterns(
            project: fixture.project,
            map: source,
            preset: fixture.preset,
          ),
          [fixture.pattern],
        );
        final document = EditableMapDocument(
          MapWorkspaceDocument(map: source, mapId: source.id, revision: 'r0'),
        );
        final view = MapWorkspaceViewState()
          ..prepareTerrainPainting(fixture.preset)
          ..selectTerrainPattern(fixture.pattern);
        addTearDown(view.dispose);
        final material = view.terrainMaterialId;
        final stroke = MapCanvasStroke.start(
          map: source,
          project: fixture.project,
          view: view,
          commands: MapEditingCommands(document, fixture.project),
          origin: const GridPos(x: 1, y: 1),
        )!;
        expect(document.current, same(source));
        final previewLayer = stroke.preview.layers
            .whereType<SmartTileLayer>()
            .single;
        expect(smartTileSemanticCells(previewLayer), everyElement(0));
        expect(
          previewLayer.patternStrokes.single.patternId,
          fixture.pattern.id,
        );
        expect(previewLayer.patternStrokes.single.cells, [
          const GridPos(x: 1, y: 1),
          const GridPos(x: 2, y: 1),
        ]);
        document.commit(stroke.commit());
        expect(document.undoCount, 1);
        expect(view.terrainMaterialId, material);
        expect(
          document.current.spatialScene?.instances,
          spatial ? isEmpty : isNull,
        );
        document.restore(redo: false);
        expect(document.current, source);
      },
    );
    test(
      '${spatial ? "3D" : "2D"} motif availability respects the typed source map scope and allows components',
      () {
        final fixture = _fixture(spatial: spatial);
        final sourceId = spatial
            ? 'oak'
            : fixture.project.smartTileCatalog.atlases.single.tilesetId;
        final project = fixture.project.copyWith(
          resourceLibraryCatalog: ResourceLibraryCatalog(
            entries: [
              ResourceLibraryEntry(
                resourceKind: spatial ? 'model3d' : 'tileset',
                resourceId: sourceId,
                mapId: fixture.map.id,
                role: ResourceLibraryRole.component,
              ),
            ],
          ),
        );
        expect(
          availableTerrainPatterns(
            project: project,
            map: fixture.map.copyWith(layers: []),
            preset: fixture.preset,
          ),
          [fixture.pattern],
        );
        expect(
          availableTerrainPatterns(
            project: project,
            map: fixture.map.copyWith(id: 'b', layers: []),
            preset: fixture.preset,
          ),
          isEmpty,
        );
        final view = MapWorkspaceViewState()
          ..prepareTerrainPainting(fixture.preset)
          ..selectTerrainPattern(fixture.pattern);
        addTearDown(view.dispose);
        view.reconcileResources(
          project,
          mapId: 'b',
          map: fixture.map.copyWith(id: 'b', layers: []),
        );
        expect(view.terrainPatternId, isNull);
        expect(view.terrainMaterialId, fixture.preset.defaultMaterialId);
      },
    );
    for (final mode in SmartTilePatternSelectionKind.values) {
      test(
        '${spatial ? "3D" : "2D"} ${mode.name} previews one stable pattern and commits one exact undo',
        () {
          final fixture = _fixture(spatial: spatial);
          final source = fixture.map;
          final view = MapWorkspaceViewState()
            ..prepareTerrainPainting(fixture.preset)
            ..selectTerrainPattern(fixture.pattern)
            ..terrainPatternMode = mode;
          addTearDown(view.dispose);
          final material = view.terrainMaterialId;
          final document = EditableMapDocument(
            MapWorkspaceDocument(map: source, mapId: source.id, revision: 'r0'),
          );
          final stroke = MapCanvasStroke.start(
            map: source,
            project: fixture.project,
            view: view,
            commands: MapEditingCommands(document, fixture.project),
            origin: const GridPos(x: 0, y: 0),
          )!;
          stroke.paint(const GridPos(x: 3, y: 2));
          stroke.paint(const GridPos(x: 1, y: 1));
          final strokes = stroke.preview.layers
              .whereType<SmartTileLayer>()
              .single
              .patternStrokes;
          expect(strokes, hasLength(2));
          expect(
            strokes.first,
            source.layers
                .whereType<SmartTileLayer>()
                .single
                .patternStrokes
                .single,
          );
          expect(
            strokes.last.cells,
            hasLength(switch (mode) {
              SmartTilePatternSelectionKind.stamp => 2,
              SmartTilePatternSelectionKind.line => 2,
              SmartTilePatternSelectionKind.rectangle => 4,
            }),
          );
          expect(strokes.last.phaseX, 0);
          expect(strokes.last.phaseY, 0);
          expect(
            smartTileSemanticCells(
              stroke.preview.layers.whereType<SmartTileLayer>().single,
            ),
            everyElement(0),
          );
          expect(view.terrainMaterialId, material);
          expect(document.current, same(source));
          document.commit(stroke.commit());
          expect(document.current, stroke.preview);
          expect(document.undoCount, 1);
          expect(
            document.current.spatialScene?.instances,
            spatial ? isEmpty : isNull,
          );
          document.restore(redo: false);
          expect(document.current, source);
          document.restore(redo: true);
          expect(document.current, stroke.preview);
        },
      );
    }
  }

  testWidgets(
    'native pattern drag previews without writing and cancels when selection changes',
    (tester) async {
      final fixture = _fixture();
      final document = EditableMapDocument(
        MapWorkspaceDocument(
          map: fixture.map,
          mapId: fixture.map.id,
          revision: 'r0',
        ),
      );
      final view = MapWorkspaceViewState()
        ..prepareTerrainPainting(fixture.preset)
        ..selectTerrainPattern(fixture.pattern)
        ..terrainPatternMode = SmartTilePatternSelectionKind.rectangle;
      final controller = MapWorkspaceController(
        workspaceSession,
        WorkspaceMemoryPort(),
      );
      addTearDown(view.dispose);
      addTearDown(controller.dispose);
      Widget canvas() => MaterialApp(
        home: Scaffold(
          body: SpatialMapEditor(
            document: document,
            controller: controller,
            project: fixture.project,
            visuals: _PatternVisuals(),
            view: view,
            onChanged: () {},
          ),
        ),
      );
      await tester.pumpWidget(canvas());
      var scene = tester.widget<SpatialSceneView>(
        find.byType(SpatialSceneView),
      );
      expect(scene.onDragStart!(0, 0, null), isTrue, reason: document.error);
      scene.onDragUpdate!((1, 1));
      expect(document.current, same(fixture.map));
      view.selectTerrainPattern(null);
      await tester.pumpWidget(canvas());
      scene.onDragEnd!();
      expect(document.current, same(fixture.map));
      expect(document.canUndo, isFalse);
      view.selectTerrainPattern(fixture.pattern);
      await tester.pumpWidget(canvas());
      scene = tester.widget<SpatialSceneView>(find.byType(SpatialSceneView));
      expect(scene.onDragStart!(0, 0, null), isTrue);
      scene.onDragUpdate!((1, 1));
      scene.onDragEnd!();
      expect(document.undoCount, 1);
      expect(
        document.current.layers
            .whereType<SmartTileLayer>()
            .single
            .patternStrokes,
        hasLength(2),
      );
      view.tool = StudioMapTool.erase;
      await tester.pumpWidget(canvas());
      scene = tester.widget<SpatialSceneView>(find.byType(SpatialSceneView));
      expect(scene.onDragStart!(0, 0, null), isTrue);
      scene.onDragEnd!();
      expect(
        document.current.layers
            .whereType<SmartTileLayer>()
            .single
            .patternStrokes
            .last
            .cells,
        hasLength(3),
      );
      document.restore(redo: false);
      expect(
        document.current.layers
            .whereType<SmartTileLayer>()
            .single
            .patternStrokes
            .last
            .cells,
        hasLength(4),
      );
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'native pattern stamp and erase survive Studio save then reopen',
    () async {
      final fixture = _fixture();
      final directory = await Directory.systemTemp.createTemp(
        'studio-pattern-save-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final project = fixture.project.copyWith(
        maps: [
          const ProjectMapEntry(
            id: 'a',
            name: 'Eau native',
            relativePath: 'map.json',
          ),
        ],
      );
      await File('${directory.path}/project.json')
          .writeAsString(jsonEncode(project.toJson()));
      await File('${directory.path}/map.json')
          .writeAsString(jsonEncode(fixture.map.toJson()));
      final session = ProjectSession(
        sessionId: 'pattern',
        name: project.name,
        directoryPath: await directory.resolveSymbolicLinks(),
      );
      final port = LocalMapWorkspaceAdapter();
      await port.loadProject(session);
      final opened = await port.loadMap(session, project.maps.single);
      final document = EditableMapDocument(opened);
      final view = MapWorkspaceViewState()
        ..prepareTerrainPainting(fixture.preset)
        ..selectTerrainPattern(fixture.pattern);
      addTearDown(view.dispose);
      final stroke = MapCanvasStroke.start(
        map: document.current,
        project: project,
        view: view,
        commands: MapEditingCommands(document, project),
        origin: const GridPos(x: 0, y: 0),
      )!;
      document.commit(stroke.commit());
      final stamped = document.current;
      final revision = await port.saveMap(session, document.base, stamped);
      document.acceptSave(stamped, revision);
      view.tool = StudioMapTool.erase;
      final erased = MapCanvasStroke.start(
        map: stamped,
        project: project,
        view: view,
        commands: MapEditingCommands(document, project),
        origin: const GridPos(x: 3, y: 2),
      )!.commit();
      document.commit(erased);
      await port.saveMap(session, document.base, erased);
      final fresh = LocalMapWorkspaceAdapter();
      await fresh.loadProject(session);
      final reopened = await fresh.loadMap(session, project.maps.single);
      expect(reopened.map, erased);
      expect(
        resolveSpatialSmartTileInstances(
          map: reopened.map,
          catalog: project.smartTileCatalog,
        ),
        resolveSpatialSmartTileInstances(
          map: erased,
          catalog: project.smartTileCatalog,
        ),
      );
      expect(reopened.map.spatialScene!.instances, isEmpty);
      document.restore(redo: false);
      expect(document.current, stamped);
    },
  );
}

({ProjectManifest project, MapData map, ProjectSmartTilePreset preset})
_selectedPresetEraseFixture({
  bool spatial = true,
  bool bottomToTop = false,
  bool selectedLayerPresent = true,
  bool selectedCellOwned = true,
}) {
  final fixture = _fixture(spatial: spatial);
  final soilPreset = fixture.preset.copyWith(
    id: 'soil',
    name: 'Sol',
    usage: SmartTileUsage.terrain,
  );
  final soil = MapLayer.smartTile(
    id: 'soil-layer',
    name: 'Sol',
    presetId: soilPreset.id,
    usage: soilPreset.usage,
    materialPalette: ['', soilPreset.defaultMaterialId],
    field: SmartTileField.cell(semanticCells: List.filled(64, 1)),
  );
  final original = fixture.map.layers.whereType<SmartTileLayer>().single;
  final grass = original.copyWith(
    field: SmartTileField.cell(
      semanticCells: [
        for (var index = 0; index < 64; index++)
          index == 19 && selectedCellOwned ? 1 : 0,
      ],
    ),
    patternStrokes: [
      original.patternStrokes.single.copyWith(
        cells: [
          for (final cell in original.patternStrokes.single.cells)
            if (selectedCellOwned || cell != const GridPos(x: 3, y: 2)) cell,
        ],
      ),
    ],
  );
  final tiles = MapLayer.tile(
    id: 'foreign-tiles',
    name: 'Autre sol',
    palette: const [TileLayerPaletteEntry(tilesetId: 'atlas', localTileId: 0)],
    cells: List.filled(64, 0),
  );
  final layers = <MapLayer>[
    soil,
    if (selectedLayerPresent) grass,
    if (!spatial) tiles,
  ];
  final project = fixture.project.copyWith(
    tilesets: [
      ...fixture.project.tilesets,
      ...workspaceProject.tilesets.where(
        (entry) => !fixture.project.tilesets.any((item) => item.id == entry.id),
      ),
    ],
    smartTileCatalog: ProjectSmartTileCatalog(
      formatVersion: fixture.project.smartTileCatalog.formatVersion,
      categories: fixture.project.smartTileCatalog.categories,
      atlases: fixture.project.smartTileCatalog.atlases,
      materials: fixture.project.smartTileCatalog.materials,
      animations: fixture.project.smartTileCatalog.animations,
      presets: [soilPreset, fixture.preset],
      patterns: fixture.project.smartTileCatalog.patterns,
      drafts: fixture.project.smartTileCatalog.drafts,
    ),
  );
  return (
    project: project,
    map: fixture.map.copyWith(
      layers: bottomToTop ? layers.reversed.toList() : layers,
      properties: bottomToTop ? {'tileLayerOrder': 'bottom_to_top'} : {},
    ),
    preset: fixture.preset,
  );
}

({
  ProjectManifest project,
  MapData map,
  ProjectSmartTilePreset preset,
  ProjectSmartTilePattern pattern,
})
_fixture({bool spatial = true, bool followTerrain = true}) {
  final draft = spatialPathDraft();
  final imageDraft = terrainDraft();
  assignAll(imageDraft);
  final base = spatial ? draft.manifest : publishFixture(imageDraft);
  final preset = spatial
      ? draft.previewPreset
      : base.smartTileCatalog.presets.single;
  final pattern = ProjectSmartTilePattern(
    id: 'water',
    name: 'Eau animée',
    usage: preset.usage,
    width: 2,
    height: 1,
    cells: [
      for (var x = 0; x < 2; x++)
        SmartTilePatternCell(
          x: x,
          y: 0,
          parts: [
            SmartTileVisualPart(
              source: spatial
                  ? SmartTileVisualSource.model3d(
                      modelId: 'oak',
                      scale: 1 + x.toDouble(),
                      followTerrain: followTerrain,
                    )
                  : preset.rules.first.candidates.first.parts.first.source,
            ),
          ],
        ),
    ],
  );
  final project = base.copyWith(
    settings: spatial
        ? base.settings.copyWith(spatialCamera: SpatialCameraProfile())
        : base.settings,
    elements: spatial ? const [] : base.elements,
    tilesets: spatial ? const [] : base.tilesets,
    smartTileCatalog: ProjectSmartTileCatalog(
      atlases: base.smartTileCatalog.atlases,
      materials: spatial
          ? draft.draft.materials
          : base.smartTileCatalog.materials,
      presets: [preset],
      patterns: [pattern],
    ),
  );
  final map = MapData(
    id: 'a',
    name: 'Eau native',
    version: spatial ? ProjectVersion.v9 : ProjectVersion.v8,
    size: const GridSize(width: 8, height: 8),
    spatialScene: spatial ? MapSpatialScene(width: 8, depth: 8) : null,
    layers: [
      MapLayer.smartTile(
        id: 'water-layer',
        name: 'Eau',
        presetId: preset.id,
        usage: preset.usage,
        materialPalette: ['', preset.defaultMaterialId],
        field: SmartTileField.cell(semanticCells: List.filled(64, 0)),
        patternStrokes: [
          SmartTilePatternStroke(
            id: 'source-water',
            patternId: pattern.id,
            phaseX: 1,
            cells: [for (var x = 2; x < 6; x++) GridPos(x: x, y: 2)],
          ),
        ],
      ),
    ],
  );
  return (project: project, map: map, preset: preset, pattern: pattern);
}

({ProjectManifest project, MapData map, ProjectSmartTilePreset preset, ProjectSmartTilePattern pattern})
_adaptiveBridgeFixture() {
  final base = _fixture(spatial: false);
  final preset = base.preset.copyWith(
    categoryId: 'bridge-style', coveragePolicy: SmartTileCoveragePolicy.sparse,
    status: SmartTilePresetStatus.published, rules: [],
    coverageProfile: const SmartTileCoverageProfile(mode: SmartTileCoverageMode.explicit),
  );
  final part = base.pattern.cells.first.parts.first;
  final pattern = ProjectSmartTilePattern(
    id: 'bridge', name: 'Pont natif', categoryId: preset.categoryId,
    usage: preset.usage, width: 5, height: 4,
    construction: SmartTilePatternConstruction(
      y: SmartTilePatternRepeatAxis(repeatStart: 1, repeatLength: 2),
    ),
    cells: [for (var y = 0; y < 4; y++) for (var x = 0; x < 5; x++)
      SmartTilePatternCell(x: x, y: y, parts: [part])],
  );
  final catalog = base.project.smartTileCatalog;
  final project = base.project.copyWith(smartTileCatalog: ProjectSmartTileCatalog(
    categories: [...catalog.categories, const ProjectSmartTileCategory(id: 'bridge-style', name: 'Pont')],
    atlases: catalog.atlases, materials: catalog.materials,
    animations: catalog.animations, presets: [preset], patterns: [pattern],
  ));
  final source = base.map.layers.whereType<SmartTileLayer>().single;
  final map = base.map.copyWith(layers: [source.copyWith(patternStrokes: [])]);
  return (project: project, map: map, preset: preset, pattern: pattern);
}

({
  ProjectManifest project,
  MapData map,
  ProjectSmartTilePreset preset,
  ProjectSmartTilePattern pattern,
})
_atomicStampFixture({GridPos origin = const GridPos(x: 2, y: 2)}) {
  final fixture = _fixture();
  final pattern = fixture.pattern.copyWith(
    id: 'ground-unit',
    width: 3,
    height: 3,
    repeatMode: SmartTilePatternRepeatMode.stamp,
    cells: [
      const SmartTilePatternCell(
        x: 0,
        y: 0,
        parts: [
          SmartTileVisualPart(
            source: SmartTileVisualSource.model3d(
              modelId: 'ground-detail',
              offsetX: 1,
              offsetY: .001,
              offsetZ: 1,
            ),
          ),
        ],
      ),
    ],
  );
  final project = _withStampPatterns(
    fixture.project.copyWith(
      models3d: [
        ...fixture.project.models3d,
        spatialPathModel('ground-detail'),
      ],
    ),
    [pattern],
  );
  final layer = fixture.map.layers.whereType<SmartTileLayer>().single.copyWith(
    field: SmartTileField.cell(semanticCells: List.filled(64, 1)),
    patternStrokes: [],
  );
  final applied = applySmartTilePatternGesture(
    layer,
    pattern: pattern,
    mapSize: fixture.map.size,
    selection: SmartTilePatternSelection.stamp(anchor: origin),
    strokeId: 'unit',
  );
  final map = fixture.map.copyWith(
    layers: [applied.layer],
    spatialScene: MapSpatialScene(
      width: 8,
      depth: 8,
      heightLevels: List.generate(64, (index) => index == 27 ? 4 : 2),
    ),
  );
  return (project: project, map: map, preset: fixture.preset, pattern: pattern);
}

ProjectManifest _withStampPatterns(
  ProjectManifest project,
  List<ProjectSmartTilePattern> patterns,
) => project.copyWith(
  smartTileCatalog: ProjectSmartTileCatalog(
    atlases: project.smartTileCatalog.atlases,
    materials: project.smartTileCatalog.materials,
    presets: project.smartTileCatalog.presets,
    animations: project.smartTileCatalog.animations,
    patterns: patterns,
  ),
);

MapWorkspaceViewState _selectedStampEraseView(
  ProjectSmartTilePreset preset,
  ProjectSmartTilePattern pattern,
) => MapWorkspaceViewState()
  ..prepareTerrainPainting(preset)
  ..selectTerrainPattern(pattern)
  ..tool = StudioMapTool.erase;

class _PatternVisuals extends WorkspaceTestVisuals
    implements SpatialWorkspaceVisuals {
  final source = Completer<Uint8List>();
  @override
  Future<Uint8List> readModel(String modelId) => source.future;
  @override
  Future<Uint8List> readGroundImage(String tilesetId) async => Uint8List(0);
  @override
  Future<SpatialNpcPreview> spatialPreview(MapData map) async =>
      SpatialNpcPreview({}, () {});
}
