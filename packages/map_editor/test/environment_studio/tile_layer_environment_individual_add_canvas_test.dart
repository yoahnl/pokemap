import 'package:flutter/cupertino.dart';
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
  testWidgets('tap canvas ajoute un placement généré au TileLayer actif',
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
        .state = 'tree';

    await _pumpCanvas(tester, container);

    final mapBox = tester.getRect(find.byType(MapCanvas));
    await tester.tapAt(mapBox.topLeft + const Offset(48, 48));
    await tester.pump();

    final state = container.read(editorNotifierProvider);
    expect(state.activeLayerId, 'tiles');
    expect(state.selectedEnvironmentAreaId, 'area');
    expect(state.environmentMaskEditMode, EnvironmentMaskEditMode.generatedAdd);
    expect(
      state.activeMap!.placedElements.map((element) => element.id),
      contains('env_gen_area_1_1_tree'),
    );
    final added = state.activeMap!.placedElements.singleWhere(
      (element) => element.id == 'env_gen_area_1_1_tree',
    );
    expect(added.layerId, 'tiles');
    expect(added.elementId, 'tree');
    expect(added.pos, const GridPos(x: 1, y: 1));
    expect(
      _areaById(state.activeMap!, 'area').generatedPlacementIds,
      const ['generated_a', 'env_gen_area_1_1_tree'],
    );
    expect(
      _areaById(state.activeMap!, 'other').generatedPlacementIds,
      const ['other_generated'],
    );
    expect(
      state.activeMap!.placedElements.map((element) => element.id),
      containsAll(const ['manual', 'other_generated']),
    );
  });

  testWidgets('tap canvas avec footprint invalide ne mute pas la MapData',
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
    );
    container
        .read(environmentGeneratedPlacementAddElementProvider.notifier)
        .state = 'big_tree';

    await _pumpCanvas(tester, container);

    final mapBox = tester.getRect(find.byType(MapCanvas));
    await tester.tapAt(mapBox.topLeft + const Offset(112, 112));
    await tester.pump();

    final state = container.read(editorNotifierProvider);
    expect(state.activeMap, same(map));
    expect(state.activeLayerId, 'tiles');
    expect(state.selectedEnvironmentAreaId, 'area');
    expect(state.environmentMaskEditMode, EnvironmentMaskEditMode.generatedAdd);
    expect(state.errorMessage, contains('Impossible d’ajouter ici'));
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
            EnvironmentArea(
              id: 'other',
              name: 'Other',
              presetId: 'forest',
              mask: EnvironmentAreaMask(
                width: 4,
                height: 4,
                cells: List<bool>.filled(16, true),
              ),
              seed: 3,
              generatedPlacementIds: const ['other_generated'],
            ),
          ],
        ),
      ),
    ],
    placedElements: const [
      MapPlacedElement(
        id: 'manual',
        layerId: 'tiles',
        elementId: 'tree',
        pos: GridPos(x: 0, y: 0),
      ),
      MapPlacedElement(
        id: 'generated_a',
        layerId: 'tiles',
        elementId: 'tree',
        pos: GridPos(x: 0, y: 2),
      ),
      MapPlacedElement(
        id: 'other_generated',
        layerId: 'tiles',
        elementId: 'tree',
        pos: GridPos(x: 2, y: 2),
      ),
    ],
  );
}

EnvironmentArea _areaById(MapData map, String areaId) {
  return map.layers
      .whereType<EnvironmentLayer>()
      .single
      .content
      .areas
      .singleWhere((area) => area.id == areaId);
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
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
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
