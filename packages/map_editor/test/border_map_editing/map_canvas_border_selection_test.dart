import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
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
      version: ProjectVersion.v6,
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
        version: ProjectVersion.v6,
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
      ),
      workspaceMode: EditorWorkspaceMode.map,
      activeMap: map,
      activeLayerId: 'borders',
      selectedEntityId: 'stale-entity',
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
    expect(container.read(editorNotifierProvider).selectedEntityId, isNull);

    final mapWithWarp = map.copyWith(
      warps: const <MapWarp>[
        MapWarp(
          id: 'warp-over-border',
          pos: GridPos(x: 1, y: 1),
          targetMapId: 'map',
          targetPos: GridPos(x: 0, y: 0),
        ),
      ],
    );
    final notifier = container.read(editorNotifierProvider.notifier);
    notifier.state = notifier.state.copyWith(activeMap: mapWithWarp);
    await tester.pump();
    await tester.tapAt(canvas.topLeft + const Offset(48, 48));
    await tester.pump();

    expect(
      container.read(editorNotifierProvider).selectedWarpId,
      'warp-over-border',
    );
    expect(
      container.read(activeBorderFeatureControllerProvider).activeFeatureId,
      isNull,
      reason: 'objects painted above Border must win the common selection hit',
    );
    expect(
      container.read(editorNotifierProvider).activeMap!.toJson(),
      mapWithWarp.toJson(),
    );
  });

  testWidgets(
      'organic Border drag previews a gapless segment without mutating the map',
      (tester) async {
    final map = MapData(
      id: 'map',
      name: 'Map',
      version: ProjectVersion.v6,
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
      version: ProjectVersion.v6,
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
    var resolverCalls = 0;
    final fixture = await _pumpLineCanvas(
      tester,
      tool: EditorToolType.borderPaint,
      resolver: (request) {
        resolverCalls += 1;
        return _successfulLinePreview(request);
      },
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
    expect(drawing.transaction?.result, isNull);
    expect(resolverCalls, 0);
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
    expect(resolverCalls, 1);
    expect(
      fixture.container.read(editorNotifierProvider).activeMap!.toJson(),
      beforeJson,
    );
    expect(
        fixture.container.read(editorNotifierProvider).mapUndoStack, isEmpty);
  });

  testWidgets(
      'connected line reuses cardinal drag without mutating the map before Apply',
      (tester) async {
    final fixture = await _pumpLineCanvas(
      tester,
      tool: EditorToolType.borderPaint,
      template: BorderBlueprintTemplate.connectedLine,
    );
    final beforeJson = fixture.map.toJson();
    final gesture = await tester.startGesture(
      fixture.canvas.topLeft + const Offset(16, 16),
    );
    await gesture.moveTo(fixture.canvas.topLeft + const Offset(112, 16));
    await tester.pump();
    await gesture.moveTo(fixture.canvas.topLeft + const Offset(112, 80));
    await tester.pump();

    final drawing = fixture.container.read(borderPreviewControllerProvider);
    final geometry =
        drawing.transaction!.proposedFeature.geometry as BorderStrokeGeometry;
    expect(drawing.phase, BorderPreviewPhase.drawing);
    expect(geometry.strokes, hasLength(1));
    for (var index = 1;
        index < geometry.strokes.single.points.length;
        index++) {
      final previous = geometry.strokes.single.points[index - 1];
      final current = geometry.strokes.single.points[index];
      expect(
        (current.x - previous.x).abs() + (current.y - previous.y).abs(),
        1,
      );
    }
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
      isNull,
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
      isNull,
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

  testWidgets(
      'stone-chain drag snaps to inclusive right and bottom grid edges without map writes',
      (tester) async {
    final fixture = await _pumpLineCanvas(
      tester,
      tool: EditorToolType.borderPaint,
      template: BorderBlueprintTemplate.stoneChainLine,
    );
    final beforeJson = fixture.map.toJson();
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(
      location: fixture.canvas.topLeft + const Offset(32, 32),
    );
    await mouse.moveTo(
      fixture.canvas.topLeft + const Offset(32, 32),
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('border-grid-edge-guide')),
      findsOneWidget,
    );

    final gesture = await tester.startGesture(
      fixture.canvas.topLeft + const Offset(0.5, 0.5),
    );
    await gesture.moveTo(
      fixture.canvas.topLeft + const Offset(160, 0.5),
    );
    await tester.pump();
    await gesture.moveTo(
      fixture.canvas.topLeft + const Offset(160, 160),
    );
    await tester.pump();

    final drawing = fixture.container.read(borderPreviewControllerProvider);
    expect(drawing.phase, BorderPreviewPhase.drawing);
    final geometry =
        drawing.transaction!.proposedFeature.geometry as BorderStrokeGeometry;
    expect(geometry.alignment, BorderStrokeAlignment.gridEdges);
    expect(geometry.strokes.single.points.first, const GridPos(x: 0, y: 0));
    expect(geometry.strokes.single.points.last, const GridPos(x: 5, y: 5));
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
  });

  testWidgets(
      'resolved stone-chain preview accepts a second stroke before one Apply',
      (tester) async {
    final fixture = await _pumpLineCanvas(
      tester,
      tool: EditorToolType.borderPaint,
      template: BorderBlueprintTemplate.stoneChainLine,
      applier: ({required map, required transaction}) =>
          updateBorderFeatureGeometry(
        map,
        layerId: transaction.layerId,
        featureId: transaction.featureId,
        geometry: transaction.proposedFeature.geometry,
      ),
    );
    final beforeJson = fixture.map.toJson();

    Future<void> drawHorizontalStroke(double y) async {
      final gesture = await tester.startGesture(
        fixture.canvas.topLeft + Offset(0.5, y),
      );
      await gesture.moveTo(
        fixture.canvas.topLeft + Offset(128, y),
      );
      await tester.pump();
      await gesture.up();
      await tester.pump();
    }

    await drawHorizontalStroke(32);
    final firstPreview =
        fixture.container.read(borderPreviewControllerProvider);
    expect(firstPreview.phase, BorderPreviewPhase.resolved);
    expect(
      (firstPreview.transaction!.proposedFeature.geometry
              as BorderStrokeGeometry)
          .strokes
          .map((stroke) => stroke.id),
      orderedEquals(<String>['stroke']),
    );

    await drawHorizontalStroke(128);

    final secondPreview =
        fixture.container.read(borderPreviewControllerProvider);
    expect(secondPreview.phase, BorderPreviewPhase.resolved);
    expect(secondPreview.transaction!.baseFeatureFingerprint,
        firstPreview.transaction!.baseFeatureFingerprint);
    expect(secondPreview.transaction!.variationOrdinal,
        firstPreview.transaction!.variationOrdinal);
    expect(
      (secondPreview.transaction!.proposedFeature.geometry
              as BorderStrokeGeometry)
          .strokes
          .map((stroke) => stroke.id),
      orderedEquals(<String>['stroke', 'stroke_2']),
    );
    expect(
      fixture.container.read(editorNotifierProvider).activeMap!.toJson(),
      beforeJson,
    );
    expect(
      fixture.container.read(editorNotifierProvider).mapUndoStack,
      isEmpty,
    );

    expect(
      fixture.container
          .read(editorNotifierProvider.notifier)
          .applyPendingBorderPreview(),
      isTrue,
    );
    final persistedGeometry = fixture.container
        .read(editorNotifierProvider)
        .activeMap!
        .layers
        .whereType<BorderLayer>()
        .single
        .content
        .features
        .single
        .geometry as BorderStrokeGeometry;
    expect(
      persistedGeometry.strokes.map((stroke) => stroke.id),
      orderedEquals(<String>['stroke', 'stroke_2']),
    );
    expect(
      fixture.container.read(editorNotifierProvider).mapUndoStack,
      hasLength(1),
    );
    expect(
      fixture.container.read(borderPreviewControllerProvider),
      const BorderPreviewState.idle(),
    );
  });

  testWidgets(
      'cancelling a second stone-chain gesture preserves the first preview',
      (tester) async {
    final fixture = await _pumpLineCanvas(
      tester,
      tool: EditorToolType.borderPaint,
      template: BorderBlueprintTemplate.stoneChainLine,
    );
    final beforeJson = fixture.map.toJson();
    final firstGesture = await tester.startGesture(
      fixture.canvas.topLeft + const Offset(0.5, 32),
    );
    await firstGesture.moveTo(
      fixture.canvas.topLeft + const Offset(128, 32),
    );
    await tester.pump();
    await firstGesture.up();
    await tester.pump();
    final firstPreview =
        fixture.container.read(borderPreviewControllerProvider);
    expect(firstPreview.phase, BorderPreviewPhase.resolved);
    final firstTransaction = firstPreview.transaction!;

    final cancelledGesture = await tester.startGesture(
      fixture.canvas.topLeft + const Offset(0.5, 128),
    );
    await cancelledGesture.moveTo(
      fixture.canvas.topLeft + const Offset(128, 128),
    );
    await tester.pump();
    tester
        .widget<GestureDetector>(
          find.byKey(
            const ValueKey<String>('map-canvas-gesture-detector'),
          ),
        )
        .onPanCancel!();
    await tester.pump();
    await cancelledGesture.cancel();
    await tester.pump();

    final restored = fixture.container.read(borderPreviewControllerProvider);
    expect(restored.phase, BorderPreviewPhase.resolved);
    expect(restored.transaction!.baseFeatureFingerprint,
        firstTransaction.baseFeatureFingerprint);
    expect(restored.transaction!.variationOrdinal,
        firstTransaction.variationOrdinal);
    expect(
      (restored.transaction!.proposedFeature.geometry as BorderStrokeGeometry)
          .strokes
          .map((stroke) => stroke.id),
      orderedEquals(<String>['stroke']),
    );
    expect(
      fixture.container.read(editorNotifierProvider).activeMap!.toJson(),
      beforeJson,
    );
    expect(
        fixture.container.read(editorNotifierProvider).mapUndoStack, isEmpty);
  });

  testWidgets(
      'resolved preview cannot resume after another Border feature is selected',
      (tester) async {
    final secondFeature = _lineFeature(
      'wall-b',
      alignment: BorderStrokeAlignment.gridEdges,
    );
    final fixture = await _pumpLineCanvas(
      tester,
      tool: EditorToolType.borderPaint,
      template: BorderBlueprintTemplate.stoneChainLine,
      additionalFeatures: <BorderFeature>[secondFeature],
    );
    final beforeJson = fixture.map.toJson();
    final firstGesture = await tester.startGesture(
      fixture.canvas.topLeft + const Offset(0.5, 32),
    );
    await firstGesture.moveTo(
      fixture.canvas.topLeft + const Offset(128, 32),
    );
    await tester.pump();
    await firstGesture.up();
    await tester.pump();
    final resolvedForA =
        fixture.container.read(borderPreviewControllerProvider);
    expect(resolvedForA.phase, BorderPreviewPhase.resolved);
    expect(resolvedForA.transaction!.featureId, 'wall');

    fixture.container
        .read(activeBorderFeatureControllerProvider.notifier)
        .selectFeature(
          map: fixture.map,
          layerId: 'borders',
          featureId: secondFeature.id,
        );
    await tester.pump();
    expect(
      fixture.container
          .read(activeBorderFeatureControllerProvider)
          .activeFeatureId,
      secondFeature.id,
    );

    final secondGesture = await tester.startGesture(
      fixture.canvas.topLeft + const Offset(0.5, 128),
    );
    await secondGesture.moveTo(
      fixture.canvas.topLeft + const Offset(128, 128),
    );
    await tester.pump();
    await secondGesture.up();
    await tester.pump();

    final afterRejectedResume =
        fixture.container.read(borderPreviewControllerProvider);
    expect(afterRejectedResume, same(resolvedForA));
    expect(afterRejectedResume.transaction!.featureId, 'wall');
    expect(
      (afterRejectedResume.transaction!.proposedFeature.geometry
              as BorderStrokeGeometry)
          .strokes
          .map((stroke) => stroke.id),
      orderedEquals(<String>['stroke']),
    );
    expect(
      fixture.container.read(editorNotifierProvider).activeMap!.toJson(),
      beforeJson,
    );
    expect(
      fixture.container.read(editorNotifierProvider).mapUndoStack,
      isEmpty,
    );
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
      geometry.strokes.map((stroke) => borderStrokeAuthoredIdV1(stroke.id)),
      orderedEquals(const <String>['wall', 'wall__fragment_2']),
    );
    final lineage = geometry.strokes
        .map(resolveBorderStrokeLineageIdentityV1)
        .toList(growable: false);
    expect(lineage.map((identity) => identity.preserveTraversal),
        everyElement(isTrue));
    expect(
      lineage.map((identity) => identity.sourceEdgeOffset),
      orderedEquals(const <int>[0, 3]),
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
  BorderBlueprintTemplate template = BorderBlueprintTemplate.masonryLine,
  BorderPreviewMapApplier? applier,
  BorderFeatureResolver? resolver,
  List<BorderFeature> additionalFeatures = const <BorderFeature>[],
}) async {
  final feature = _lineFeature(
    'wall',
    strokes: strokes,
    alignment: template == BorderBlueprintTemplate.stoneChainLine
        ? BorderStrokeAlignment.gridEdges
        : BorderStrokeAlignment.cellCenters,
  );
  final map = MapData(
    id: 'map',
    name: 'Map',
    version: ProjectVersion.v6,
    size: const GridSize(width: 5, height: 5),
    layers: <MapLayer>[
      MapLayer.border(
        id: 'borders',
        name: 'Bordures',
        content: BorderLayerContent(
          formatVersion: template == BorderBlueprintTemplate.stoneChainLine
              ? BorderLayerContent.formatVersionV3
              : BorderLayerContent.formatVersionV1,
          features: <BorderFeature>[feature, ...additionalFeatures],
        ),
      ),
    ],
  );
  final preview = BorderPreviewController(
    resolver: resolver ?? _successfulLinePreview,
    applier: applier,
  );
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
    project: _publishedLineManifest(template: template),
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
  BorderStrokeAlignment alignment = BorderStrokeAlignment.cellCenters,
}) =>
    BorderFeature(
      id: id,
      name: id,
      blueprintId: 'wall-blueprint',
      seed: BorderSignedInt64.fromInt(23),
      geometry: BorderStrokeGeometry(alignment: alignment, strokes: strokes),
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
    version: ProjectVersion.v6,
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

ProjectManifest _publishedLineManifest({
  BorderBlueprintTemplate template = BorderBlueprintTemplate.masonryLine,
}) {
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
    version: ProjectVersion.v6,
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    borderCatalog: ProjectBorderCatalog(
      formatVersion: template == BorderBlueprintTemplate.stoneChainLine
          ? ProjectBorderCatalog.formatVersionV3
          : template == BorderBlueprintTemplate.connectedLine
              ? ProjectBorderCatalog.formatVersionV2
              : ProjectBorderCatalog.formatVersionV1,
      records: <BorderBlueprintRecord>[
        BorderBlueprintRecord(
          id: 'wall-blueprint',
          draft: BorderBlueprintDraft(
            baseRevision: 1,
            definition: BorderBlueprintDraftDefinition(
              name: 'Muret',
              previewSeed: BorderSignedInt64.zero,
              template: template,
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
              template: template,
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
            resolvedRole: BorderGroundVariantRole.isolated,
          ),
        ],
        placements: const <BorderResolvedPlacement>[],
      ),
      diagnosticReport: const BorderDiagnosticsReport.empty(),
    );

String _hash(String character) =>
    'sha256:${List<String>.filled(64, character).join()}';
