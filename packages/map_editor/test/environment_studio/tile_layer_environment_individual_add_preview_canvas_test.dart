import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/state/environment_generated_placement_add_element_provider.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';
import 'package:map_editor/src/ui/canvas/map_canvas.dart';

void main() {
  testWidgets('hover canvas fournit un ghost preview sans muter la MapData',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final map = _map();
    container.read(editorNotifierProvider.notifier).state = EditorState(
      project: _manifest(),
      activeMap: map,
      activeLayerId: 'tiles',
      selectedEnvironmentAreaId: 'area',
      environmentMaskEditMode: EnvironmentMaskEditMode.generatedAdd,
      savedMapSnapshot: map,
    );
    container
        .read(environmentGeneratedPlacementAddElementProvider.notifier)
        .state = 'big_tree';

    await _pumpCanvas(tester, container);

    final mapBox = tester.getRect(find.byType(MapCanvas));
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await gesture.addPointer(location: mapBox.topLeft + const Offset(48, 48));
    await gesture.moveTo(mapBox.topLeft + const Offset(48, 48));
    await tester.pump();

    final customPaint = tester.widget<CustomPaint>(
      find.byWidgetPredicate(
        (widget) => widget is CustomPaint && widget.painter is MapGridPainter,
      ),
    );
    final painter = customPaint.painter as MapGridPainter;
    expect(painter.environmentGeneratedAddPreview, isNotNull);
    expect(
      painter.environmentGeneratedAddPreview!.placed.elementId,
      'big_tree',
    );
    expect(
      painter.environmentGeneratedAddPreview!.placed.pos,
      const GridPos(x: 1, y: 1),
    );
    expect(painter.environmentGeneratedAddPreview!.isValid, isTrue);
    expect(container.read(editorNotifierProvider).activeMap, same(map));

    await gesture.moveTo(mapBox.bottomRight + const Offset(32, 32));
    await tester.pump();

    final exitedPaint = tester.widget<CustomPaint>(
      find.byWidgetPredicate(
        (widget) => widget is CustomPaint && widget.painter is MapGridPainter,
      ),
    );
    final exitedPainter = exitedPaint.painter as MapGridPainter;
    expect(exitedPainter.environmentGeneratedAddPreview, isNull);
  });
}

Future<void> _pumpCanvas(
  WidgetTester tester,
  ProviderContainer container,
) async {
  await tester.binding.setSurfaceSize(const Size(900, 700));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MacosTheme(
        data: MacosThemeData.light(),
        child: const MaterialApp(
          home: CupertinoPageScaffold(
            child: Center(
              child: SizedBox(
                width: 900,
                height: 700,
                child: MapCanvas(),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

MapData _map() {
  return MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 4, height: 4),
    tilesetId: 'nature',
    layers: [
      const TileLayer(
        id: 'tiles',
        name: 'Ground',
        tilesetId: 'nature',
        tiles: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      ),
      MapLayer.environment(
        id: 'env',
        name: 'Environment',
        content: EnvironmentLayerContent(
          targetTileLayerId: 'tiles',
          areas: [
            EnvironmentArea(
              id: 'area',
              name: 'Zone',
              presetId: 'forest',
              mask: EnvironmentAreaMask(
                width: 4,
                height: 4,
                cells: List<bool>.filled(16, true),
              ),
              seed: 11,
              generatedPlacementIds: const ['generated_a'],
            ),
          ],
        ),
      ),
    ],
    placedElements: const [
      MapPlacedElement(
        id: 'generated_a',
        layerId: 'tiles',
        elementId: 'tree',
        pos: GridPos(x: 0, y: 2),
      ),
    ],
  );
}

ProjectManifest _manifest() {
  return ProjectManifest(
    name: 'Project',
    maps: const [],
    tilesets: const [],
    elements: const [
      ProjectElementEntry(
        id: 'tree',
        name: 'Tree',
        tilesetId: 'nature',
        categoryId: 'trees',
        frames: [
          TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
        ],
      ),
      ProjectElementEntry(
        id: 'big_tree',
        name: 'Big Tree',
        tilesetId: 'nature',
        categoryId: 'trees',
        frames: [
          TilesetVisualFrame(
            source: TilesetSourceRect(x: 0, y: 0, width: 2, height: 2),
          ),
        ],
      ),
    ],
    surfaceCatalog: ProjectSurfaceCatalog(),
    environmentPresets: [
      EnvironmentPreset(
        id: 'forest',
        name: 'Forêt',
        templateId: 'forest',
        palette: [
          EnvironmentPaletteItem(elementId: 'tree', weight: 1),
          EnvironmentPaletteItem(elementId: 'big_tree', weight: 1),
        ],
        defaultParams: EnvironmentGenerationParams(
          density: 1,
          variation: 0,
          edgeDensity: 1,
          minSpacingCells: 0,
        ),
        sortOrder: 0,
      ),
    ],
  );
}
