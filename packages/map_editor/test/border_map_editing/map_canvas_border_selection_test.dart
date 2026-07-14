import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/border_map_editing/state/border_map_editing_providers.dart';
import 'package:map_editor/src/features/border_map_editing/state/border_preview_providers.dart';
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
