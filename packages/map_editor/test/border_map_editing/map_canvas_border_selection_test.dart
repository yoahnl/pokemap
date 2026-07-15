import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/border_map_editing/state/border_map_editing_providers.dart';
import 'package:map_editor/src/features/border_map_editing/state/border_preview_providers.dart';
import 'package:map_editor/src/features/border_map_editing/application/border_preview_controller.dart';
import 'package:map_editor/src/features/border_map_editing/application/border_preview_transaction.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';
import 'package:map_editor/src/ui/canvas/map_canvas.dart';
import 'package:map_editor/src/ui/shared/pokemap_macos_ui_shim.dart';

void main() {
  testWidgets(
      'selection click chooses the uppermost overlapping Border feature',
      (tester) async {
    final lower = _feature('lower');
    final upper = _feature('upper');
    final map = MapData(
      id: 'map',
      name: 'Map',
      version: ProjectVersion.v2,
      size: const GridSize(width: 3, height: 3),
      layers: <MapLayer>[
        MapLayer.border(
          id: 'borders',
          name: 'Bordures',
          content: BorderLayerContent(features: <BorderFeature>[lower, upper]),
        ),
      ],
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final editorSubscription = container.listen(
      editorNotifierProvider,
      (_, __) {},
    );
    addTearDown(editorSubscription.close);
    container.read(editorNotifierProvider.notifier).state = EditorState(
      project: const ProjectManifest(
        name: 'Border selection',
        version: ProjectVersion.v2,
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
      ),
      workspaceMode: EditorWorkspaceMode.map,
      activeMap: map,
      activeLayerId: 'borders',
    );
    final beforeJson = map.toJson();
    await tester.binding.setSurfaceSize(const Size(600, 500));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MacosTheme(
          data: MacosThemeData.light(),
          child: const MaterialApp(
            home: CupertinoPageScaffold(
              child: SizedBox.expand(child: MapCanvas()),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    container
        .read(activeBorderFeatureControllerProvider.notifier)
        .selectFeature(map: map, layerId: 'borders', featureId: 'lower');
    await tester.pump();
    expect(
      container.read(activeBorderFeatureControllerProvider).activeFeatureId,
      'lower',
    );

    final canvas = tester.getRect(find.byType(MapCanvas));
    await tester.tapAt(canvas.topLeft + const Offset(48, 48));
    await tester.pump();

    expect(
      container.read(activeBorderFeatureControllerProvider).activeFeatureId,
      'upper',
    );
    expect(
      container.read(editorNotifierProvider).activeMap!.toJson(),
      beforeJson,
      reason: 'canvas selection must remain ephemeral',
    );
  });

  testWidgets(
      'organic Border drag previews a gapless segment without mutating the map',
      (tester) async {
    final map = MapData(
      id: 'map',
      name: 'Map',
      version: ProjectVersion.v2,
      size: const GridSize(width: 5, height: 5),
      layers: <MapLayer>[
        MapLayer.border(
          id: 'borders',
          name: 'Bordures',
          content: BorderLayerContent(
            features: <BorderFeature>[_featureForSize('coast', 5, 5)],
          ),
        ),
      ],
    );
    final beforeJson = map.toJson();
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final editorSubscription = container.listen(
      editorNotifierProvider,
      (_, __) {},
    );
    addTearDown(editorSubscription.close);
    container.read(editorNotifierProvider.notifier).state = EditorState(
      projectRootPath: '/projects/border-drag',
      project: _publishedManifest(),
      workspaceMode: EditorWorkspaceMode.map,
      activeMap: map,
      activeMapPath: '/projects/border-drag/maps/map.json',
      activeLayerId: 'borders',
      activeTool: EditorToolType.borderPaint,
    );
    container
        .read(activeBorderFeatureControllerProvider.notifier)
        .selectFeature(map: map, layerId: 'borders', featureId: 'coast');

    await tester.binding.setSurfaceSize(const Size(600, 500));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MacosTheme(
          data: MacosThemeData.light(),
          child: const MaterialApp(
            home: CupertinoPageScaffold(
              child: SizedBox.expand(child: MapCanvas()),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final canvas = tester.getRect(find.byType(MapCanvas));
    final gesture = await tester.startGesture(
      canvas.topLeft + const Offset(16, 16),
    );
    await gesture.moveBy(const Offset(34, 0));
    await tester.pump();
    await gesture.moveTo(canvas.topLeft + const Offset(144, 144));
    await tester.pump();

    final drawing = container.read(borderPreviewControllerProvider);
    expect(drawing.phase, BorderPreviewPhase.drawing);
    expect(drawing.transaction?.result, isNotNull);
    final geometry =
        drawing.transaction!.proposedFeature.geometry as BorderRegionGeometry;
    final painted = <GridPos>[
      for (var y = 0; y < geometry.height; y += 1)
        for (var x = 0; x < geometry.width; x += 1)
          if (geometry.cells[y * geometry.width + x]) GridPos(x: x, y: y),
    ];
    expect(painted.length, greaterThan(2));
    for (var index = 1; index < painted.length; index += 1) {
      final dx = (painted[index].x - painted[index - 1].x).abs();
      final dy = (painted[index].y - painted[index - 1].y).abs();
      expect(dx + dy, 1);
    }
    expect(
        container.read(editorNotifierProvider).activeMap!.toJson(), beforeJson);

    await gesture.up();
    await tester.pump();

    expect(
      container.read(borderPreviewControllerProvider).phase,
      isNot(BorderPreviewPhase.drawing),
    );
    expect(
        container.read(editorNotifierProvider).activeMap!.toJson(), beforeJson);
    expect(container.read(editorNotifierProvider).mapUndoStack, isEmpty);
  });

  testWidgets(
      'organic Border erase drag previews a gapless segment without mutating the map',
      (tester) async {
    final map = MapData(
      id: 'map',
      name: 'Map',
      version: ProjectVersion.v2,
      size: const GridSize(width: 5, height: 5),
      layers: <MapLayer>[
        MapLayer.border(
          id: 'borders',
          name: 'Bordures',
          content: BorderLayerContent(
            features: <BorderFeature>[
              _featureForSize('coast', 5, 5, filled: true),
            ],
          ),
        ),
      ],
    );
    final beforeJson = map.toJson();
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final editorSubscription = container.listen(
      editorNotifierProvider,
      (_, __) {},
    );
    addTearDown(editorSubscription.close);
    container.read(editorNotifierProvider.notifier).state = EditorState(
      projectRootPath: '/projects/border-erase',
      project: _publishedManifest(),
      workspaceMode: EditorWorkspaceMode.map,
      activeMap: map,
      activeMapPath: '/projects/border-erase/maps/map.json',
      activeLayerId: 'borders',
      activeTool: EditorToolType.borderErase,
    );
    container
        .read(activeBorderFeatureControllerProvider.notifier)
        .selectFeature(map: map, layerId: 'borders', featureId: 'coast');

    await tester.binding.setSurfaceSize(const Size(600, 500));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MacosTheme(
          data: MacosThemeData.light(),
          child: const MaterialApp(
            home: CupertinoPageScaffold(
              child: SizedBox.expand(child: MapCanvas()),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final canvas = tester.getRect(find.byType(MapCanvas));
    final gesture = await tester.startGesture(
      canvas.topLeft + const Offset(16, 16),
    );
    await gesture.moveBy(const Offset(34, 0));
    await tester.pump();
    await gesture.moveTo(canvas.topLeft + const Offset(144, 144));
    await tester.pump();

    final drawing = container.read(borderPreviewControllerProvider);
    expect(drawing.phase, BorderPreviewPhase.drawing);
    expect(drawing.transaction?.result, isNotNull);
    final geometry =
        drawing.transaction!.proposedFeature.geometry as BorderRegionGeometry;
    final erased = <GridPos>[
      for (var y = 0; y < geometry.height; y += 1)
        for (var x = 0; x < geometry.width; x += 1)
          if (!geometry.cells[y * geometry.width + x]) GridPos(x: x, y: y),
    ];
    expect(erased.length, greaterThan(2));
    for (var index = 1; index < erased.length; index += 1) {
      final dx = (erased[index].x - erased[index - 1].x).abs();
      final dy = (erased[index].y - erased[index - 1].y).abs();
      expect(dx + dy, 1);
    }
    expect(
        container.read(editorNotifierProvider).activeMap!.toJson(), beforeJson);

    await gesture.up();
    await tester.pump();

    expect(
      container.read(borderPreviewControllerProvider).phase,
      isNot(BorderPreviewPhase.drawing),
    );
    expect(
        container.read(editorNotifierProvider).activeMap!.toJson(), beforeJson);
    expect(container.read(editorNotifierProvider).mapUndoStack, isEmpty);
  });

  testWidgets(
      'line Border drag previews one stroke from pointer-down without mutating the map',
      (tester) async {
    final fixture = await _pumpLineCanvas(
      tester,
      tool: EditorToolType.borderPaint,
    );
    final feature = fixture.map.layers
        .whereType<BorderLayer>()
        .single
        .content
        .features
        .single;
    final beforeJson = fixture.map.toJson();
    final gesture = await tester.startGesture(
      fixture.canvas.topLeft + const Offset(16, 16),
    );
    await gesture.moveTo(fixture.canvas.topLeft + const Offset(80, 16));
    await tester.pump();
    await gesture.moveTo(fixture.canvas.topLeft + const Offset(144, 80));
    await tester.pump();

    final drawing = fixture.container.read(borderPreviewControllerProvider);
    expect(drawing.phase, BorderPreviewPhase.drawing);
    expect(drawing.transaction?.result, isNotNull);
    final geometry =
        drawing.transaction!.proposedFeature.geometry as BorderStrokeGeometry;
    expect(geometry.strokes, hasLength(1));
    expect(geometry.strokes.single.points.length, greaterThan(2));
    expect(drawing.transaction!.proposedFeature.seed, feature.seed);
    expect(
      fixture.container.read(editorNotifierProvider).activeMap!.toJson(),
      beforeJson,
    );
    expect(
        fixture.container.read(editorNotifierProvider).mapUndoStack, isEmpty);

    await gesture.up();
    await tester.pump();

    expect(
      fixture.container.read(borderPreviewControllerProvider).phase,
      BorderPreviewPhase.resolved,
    );
    expect(
      fixture.container.read(editorNotifierProvider).activeMap!.toJson(),
      beforeJson,
    );
    expect(
        fixture.container.read(editorNotifierProvider).mapUndoStack, isEmpty);
  });

  testWidgets(
      'line draw backtrack cancels the whole gesture without leaking an exception',
      (tester) async {
    final fixture = await _pumpLineCanvas(
      tester,
      tool: EditorToolType.borderPaint,
    );
    final beforeJson = fixture.map.toJson();
    final gesture = await tester.startGesture(
      fixture.canvas.topLeft + const Offset(16, 16),
    );
    await gesture.moveTo(fixture.canvas.topLeft + const Offset(80, 16));
    await tester.pump();
    await gesture.moveTo(fixture.canvas.topLeft + const Offset(144, 16));
    await tester.pump();
    expect(
      fixture.container.read(borderPreviewControllerProvider).phase,
      BorderPreviewPhase.drawing,
    );
    expect(
      fixture.container
          .read(borderPreviewControllerProvider)
          .transaction
          ?.result,
      isNotNull,
    );

    // Returning through an already sampled cell violates the V1 canonical
    // stroke contract. The editor must reject the entire gesture rather than
    // preserve the earlier, now-unintended valid prefix.
    await gesture.moveTo(fixture.canvas.topLeft + const Offset(112, 16));
    await tester.pump();
    expect(tester.takeException(), isNull);

    // Further movement belongs to the same rejected pointer gesture. It must
    // not start a fresh preview from the post-error suffix.
    await gesture.moveTo(fixture.canvas.topLeft + const Offset(112, 80));
    await tester.pump();
    await gesture.moveTo(fixture.canvas.topLeft + const Offset(48, 80));
    await tester.pump();
    expect(
      fixture.container.read(borderPreviewControllerProvider).phase,
      BorderPreviewPhase.idle,
    );
    expect(
      fixture.container.read(borderPreviewControllerProvider).transaction,
      isNull,
    );
    await gesture.up();
    await tester.pump();

    final state = fixture.container.read(borderPreviewControllerProvider);
    expect(state.phase, BorderPreviewPhase.idle);
    expect(state.transaction, isNull);
    expect(
      fixture.container.read(editorNotifierProvider).activeMap!.toJson(),
      beforeJson,
    );
    expect(
      fixture.container.read(editorNotifierProvider).mapUndoStack,
      isEmpty,
    );
  });

  testWidgets(
      'line draw touching an existing stroke cancels without a poisoned preview',
      (tester) async {
    final sourceStroke = BorderStroke(
      id: 'existing-wall',
      points: <GridPos>[
        for (var x = 0; x <= 4; x += 1) GridPos(x: x, y: 0),
      ],
      closed: false,
    );
    final fixture = await _pumpLineCanvas(
      tester,
      tool: EditorToolType.borderPaint,
      strokes: <BorderStroke>[sourceStroke],
    );
    final beforeJson = fixture.map.toJson();
    final gesture = await tester.startGesture(
      fixture.canvas.topLeft + const Offset(16, 80),
    );
    await gesture.moveTo(fixture.canvas.topLeft + const Offset(80, 80));
    await tester.pump();
    await gesture.moveTo(fixture.canvas.topLeft + const Offset(144, 80));
    await tester.pump();
    expect(
      fixture.container.read(borderPreviewControllerProvider).phase,
      BorderPreviewPhase.drawing,
    );
    expect(
      fixture.container
          .read(borderPreviewControllerProvider)
          .transaction
          ?.result,
      isNotNull,
    );

    // Independent strokes represent openings and may not share a cell or
    // edge. Touching the persisted stroke is an invalid gesture, not a reason
    // to expose a core ValidationException through Flutter.
    await gesture.moveTo(fixture.canvas.topLeft + const Offset(144, 16));
    await tester.pump();
    expect(tester.takeException(), isNull);

    // The pointer remains down after contact rejection. A later valid suffix
    // is still part of the rejected gesture and must remain ignored.
    await gesture.moveTo(fixture.canvas.topLeft + const Offset(144, 80));
    await tester.pump();
    await gesture.moveTo(fixture.canvas.topLeft + const Offset(80, 80));
    await tester.pump();
    expect(
      fixture.container.read(borderPreviewControllerProvider).phase,
      BorderPreviewPhase.idle,
    );
    expect(
      fixture.container.read(borderPreviewControllerProvider).transaction,
      isNull,
    );
    await gesture.up();
    await tester.pump();

    final state = fixture.container.read(borderPreviewControllerProvider);
    expect(state.phase, BorderPreviewPhase.idle);
    expect(state.transaction, isNull);
    expect(
      fixture.container.read(editorNotifierProvider).activeMap!.toJson(),
      beforeJson,
    );
    expect(
      fixture.container.read(editorNotifierProvider).mapUndoStack,
      isEmpty,
    );
  });

  testWidgets(
      'line draw self-crossing cancels the whole gesture without leaking an exception',
      (tester) async {
    final fixture = await _pumpLineCanvas(
      tester,
      tool: EditorToolType.borderPaint,
    );
    final beforeJson = fixture.map.toJson();
    final gesture = await tester.startGesture(
      fixture.canvas.topLeft + const Offset(80, 16),
    );
    for (final target in const <Offset>[
      Offset(144, 80),
      Offset(80, 144),
    ]) {
      await gesture.moveTo(fixture.canvas.topLeft + target);
      await tester.pump();
    }
    expect(
      fixture.container.read(borderPreviewControllerProvider).phase,
      BorderPreviewPhase.drawing,
    );

    // Returning to the first horizontal run creates a self-contact/crossing
    // in the sampled lattice. The full gesture is rejected atomically.
    await gesture.moveTo(fixture.canvas.topLeft + const Offset(112, 16));
    await tester.pump();
    expect(tester.takeException(), isNull);

    // Keep moving after the self-cross while the same pointer stays down. The
    // complete gesture remains rejected even if this suffix is valid alone.
    await gesture.moveTo(fixture.canvas.topLeft + const Offset(144, 144));
    await tester.pump();
    await gesture.moveTo(fixture.canvas.topLeft + const Offset(16, 144));
    await tester.pump();
    expect(
      fixture.container.read(borderPreviewControllerProvider).phase,
      BorderPreviewPhase.idle,
    );
    expect(
      fixture.container.read(borderPreviewControllerProvider).transaction,
      isNull,
    );
    await gesture.up();
    await tester.pump();

    final state = fixture.container.read(borderPreviewControllerProvider);
    expect(state.phase, BorderPreviewPhase.idle);
    expect(state.transaction, isNull);
    expect(
      fixture.container.read(editorNotifierProvider).activeMap!.toJson(),
      beforeJson,
    );
    expect(
      fixture.container.read(editorNotifierProvider).mapUndoStack,
      isEmpty,
    );
  });

  testWidgets('single-cell line draw cancels the transient preview',
      (tester) async {
    final fixture = await _pumpLineCanvas(
      tester,
      tool: EditorToolType.borderPaint,
    );
    final beforeJson = fixture.map.toJson();

    await tester.tapAt(fixture.canvas.topLeft + const Offset(16, 16));
    await tester.pump();

    expect(
      fixture.container.read(borderPreviewControllerProvider),
      const BorderPreviewState.idle(),
    );
    expect(
      fixture.container.read(editorNotifierProvider).activeMap!.toJson(),
      beforeJson,
    );
    expect(
        fixture.container.read(editorNotifierProvider).mapUndoStack, isEmpty);
  });

  testWidgets('line erase creates an explicit opening without mutating the map',
      (tester) async {
    final sourceStroke = BorderStroke(
      id: 'wall',
      points: <GridPos>[
        for (var x = 0; x <= 4; x += 1) GridPos(x: x, y: 0),
      ],
      closed: false,
    );
    final fixture = await _pumpLineCanvas(
      tester,
      tool: EditorToolType.borderErase,
      strokes: <BorderStroke>[sourceStroke],
    );
    final beforeJson = fixture.map.toJson();

    await tester.tapAt(fixture.canvas.topLeft + const Offset(80, 16));
    await tester.pump();

    final preview = fixture.container.read(borderPreviewControllerProvider);
    expect(preview.phase, BorderPreviewPhase.resolved);
    final geometry =
        preview.transaction!.proposedFeature.geometry as BorderStrokeGeometry;
    expect(
      geometry.strokes.map((stroke) => stroke.id),
      orderedEquals(const <String>['wall', 'wall__fragment_2']),
    );
    expect(
      geometry.strokes.first.points,
      orderedEquals(const <GridPos>[
        GridPos(x: 0, y: 0),
        GridPos(x: 1, y: 0),
      ]),
    );
    expect(
      geometry.strokes.last.points,
      orderedEquals(const <GridPos>[
        GridPos(x: 3, y: 0),
        GridPos(x: 4, y: 0),
      ]),
    );
    expect(
      fixture.container.read(editorNotifierProvider).activeMap!.toJson(),
      beforeJson,
    );
    expect(
        fixture.container.read(editorNotifierProvider).mapUndoStack, isEmpty);
  });
}

Future<
    ({
      ProviderContainer container,
      MapData map,
      BorderPreviewController preview,
      Rect canvas,
    })> _pumpLineCanvas(
  WidgetTester tester, {
  required EditorToolType tool,
  List<BorderStroke> strokes = const <BorderStroke>[],
}) async {
  final feature = _lineFeature('wall', strokes: strokes);
  final map = MapData(
    id: 'map',
    name: 'Map',
    version: ProjectVersion.v2,
    size: const GridSize(width: 5, height: 5),
    layers: <MapLayer>[
      MapLayer.border(
        id: 'borders',
        name: 'Bordures',
        content: BorderLayerContent(features: <BorderFeature>[feature]),
      ),
    ],
  );
  final preview = BorderPreviewController(resolver: _successfulLinePreview);
  final container = ProviderContainer(
    overrides: <Override>[
      borderPreviewControllerProvider.overrideWith((ref) => preview),
    ],
  );
  addTearDown(container.dispose);
  final subscription = container.listen(editorNotifierProvider, (_, __) {});
  addTearDown(subscription.close);
  container.read(editorNotifierProvider.notifier).state = EditorState(
    projectRootPath: '/projects/border-line-test',
    project: _publishedLineManifest(),
    workspaceMode: EditorWorkspaceMode.map,
    activeMap: map,
    activeMapPath: '/projects/border-line-test/maps/map.json',
    activeLayerId: 'borders',
    activeTool: tool,
  );
  container
      .read(activeBorderFeatureControllerProvider.notifier)
      .selectFeature(map: map, layerId: 'borders', featureId: 'wall');
  await tester.binding.setSurfaceSize(const Size(600, 500));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MacosTheme(
        data: MacosThemeData.light(),
        child: const MaterialApp(
          home: CupertinoPageScaffold(
            child: SizedBox.expand(child: MapCanvas()),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return (
    container: container,
    map: map,
    preview: preview,
    canvas: tester.getRect(find.byType(MapCanvas)),
  );
}

BorderFeature _feature(String id) {
  final cells = List<bool>.filled(9, false)..[4] = true;
  return BorderFeature(
    id: id,
    name: id,
    blueprintId: 'coast',
    seed: BorderSignedInt64.zero,
    geometry: BorderRegionGeometry(width: 3, height: 3, cells: cells),
    overrides: const <BorderSlotOverride>[],
    keepOutRegions: const <BorderKeepOutRegion>[],
  );
}

BorderFeature _featureForSize(
  String id,
  int width,
  int height, {
  bool filled = false,
}) =>
    BorderFeature(
      id: id,
      name: id,
      blueprintId: 'coast',
      seed: BorderSignedInt64.zero,
      geometry: BorderRegionGeometry(
        width: width,
        height: height,
        cells: List<bool>.filled(width * height, filled),
      ),
      overrides: const <BorderSlotOverride>[],
      keepOutRegions: const <BorderKeepOutRegion>[],
    );

BorderFeature _lineFeature(
  String id, {
  List<BorderStroke> strokes = const <BorderStroke>[],
}) =>
    BorderFeature(
      id: id,
      name: id,
      blueprintId: 'wall-blueprint',
      seed: BorderSignedInt64.fromInt(23),
      geometry: BorderStrokeGeometry(strokes: strokes),
      overrides: const <BorderSlotOverride>[],
      keepOutRegions: const <BorderKeepOutRegion>[],
    );

ProjectManifest _publishedManifest() {
  final params = BorderGenerationParams(
    irregularityPermille: 0,
    detailDensityPermille: 0,
    variationPermille: 0,
    maxOverlapPx: 0,
    gapTolerancePx: 0,
    depthRows: 1,
  );
  return ProjectManifest(
    name: 'Border drag',
    version: ProjectVersion.v2,
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    borderCatalog: ProjectBorderCatalog(
      records: <BorderBlueprintRecord>[
        BorderBlueprintRecord(
          id: 'coast',
          draft: BorderBlueprintDraft(
            baseRevision: 1,
            definition: BorderBlueprintDraftDefinition(
              name: 'Coast',
              previewSeed: BorderSignedInt64.zero,
              template: BorderBlueprintTemplate.organicEdge,
              primitives: const <BorderPrimitiveDraft>[],
              defaults: params,
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
              defaults: params,
              sortOrder: 0,
            ),
          ),
        ),
      ],
    ),
  );
}

ProjectManifest _publishedLineManifest() {
  final params = BorderGenerationParams(
    irregularityPermille: 0,
    detailDensityPermille: 0,
    variationPermille: 0,
    maxOverlapPx: 0,
    gapTolerancePx: 0,
    depthRows: 1,
  );
  return ProjectManifest(
    name: 'Border line drag',
    version: ProjectVersion.v2,
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    borderCatalog: ProjectBorderCatalog(
      records: <BorderBlueprintRecord>[
        BorderBlueprintRecord(
          id: 'wall-blueprint',
          draft: BorderBlueprintDraft(
            baseRevision: 1,
            definition: BorderBlueprintDraftDefinition(
              name: 'Muret',
              previewSeed: BorderSignedInt64.zero,
              template: BorderBlueprintTemplate.masonryLine,
              primitives: const <BorderPrimitiveDraft>[],
              defaults: params,
              sortOrder: 0,
            ),
          ),
          latestPublished: BorderBlueprintRevision(
            revision: 1,
            definition: BorderBlueprintPublishedDefinition(
              name: 'Muret',
              previewSeed: BorderSignedInt64.zero,
              template: BorderBlueprintTemplate.masonryLine,
              primitives: const <BorderPublishedPrimitive>[],
              defaults: params,
              sortOrder: 0,
            ),
          ),
        ),
      ],
    ),
  );
}

BorderResolutionResult _successfulLinePreview(BorderResolutionRequest _) =>
    BorderResolutionResult(
      materialization: BorderMaterialization(
        receipt: BorderResolutionReceipt(
          resolverVersion: 1,
          blueprintRevision: 1,
          components: BorderInputFingerprints(
            blueprint: _hash('0'),
            geometryAndSeed: _hash('1'),
            parameters: _hash('2'),
            overrides: _hash('3'),
            keepOutRegions: _hash('4'),
            mapContext: _hash('5'),
            visualSnapshots: _hash('6'),
          ),
          inputFingerprint: _hash('7'),
          outputFingerprint: _hash('8'),
        ),
        ground: <BorderResolvedGroundCell>[
          BorderResolvedGroundCell(
            x: 0,
            y: 0,
            visualSnapshotId: 'border-snapshot-${_hash('a')}',
            resolvedRole: SurfaceVariantRole.isolated,
          ),
        ],
        placements: const <BorderResolvedPlacement>[],
      ),
      diagnosticReport: const BorderDiagnosticsReport.empty(),
    );

String _hash(String character) =>
    'sha256:${List<String>.filled(64, character).join()}';
