import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';

void main() {
  group('EditorNotifier TileLayer environment clear', () {
    test('efface les placements générés et garde la sélection TileLayer stable',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _map();
      notifier.state = EditorState(
        project: _manifest(),
        activeMap: map,
        activeLayerId: 'tiles',
        selectedEnvironmentAreaId: 'area',
        environmentMaskEditMode: EnvironmentMaskEditMode.erase,
        selectedPlacedElementInstanceId: 'generated_a',
        savedMapSnapshot: map,
      );

      notifier.clearEnvironmentGeneratedPlacementsForActiveTileLayer();

      final state = notifier.state;
      expect(state.activeMap, isNot(same(map)));
      expect(state.activeLayerId, 'tiles');
      expect(state.selectedEnvironmentAreaId, 'area');
      expect(state.environmentMaskEditMode, isNull);
      expect(state.selectedPlacedElementInstanceId, isNull);
      expect(state.errorMessage, isNull);
      expect(state.statusMessage, contains('effacé'));
      expect(state.isDirty, isTrue);
      expect(
        state.activeMap!.placedElements.map((element) => element.id).toList(),
        const ['manual'],
      );
      final area = _areaById(state.activeMap!, 'area');
      expect(area.generatedPlacementIds, isEmpty);
      expect(area.mask, _areaById(map, 'area').mask);
      expect(area.paramsOverride, _params);
      expect(area.seed, 5);
      expect(area.presetId, 'forest');
    });

    test('refuse si aucun TileLayer actif', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _map();
      notifier.state = EditorState(
        project: _manifest(),
        activeMap: map,
        activeLayerId: 'env',
        selectedEnvironmentAreaId: 'area',
      );

      notifier.clearEnvironmentGeneratedPlacementsForActiveTileLayer();

      final state = notifier.state;
      expect(state.activeMap, same(map));
      expect(state.activeLayerId, 'env');
      expect(state.selectedEnvironmentAreaId, 'area');
      expect(state.errorMessage, contains('TileLayer'));
    });

    test('refuse si aucune area est sélectionnée', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _mapWithTwoAreas();
      notifier.state = EditorState(
        project: _manifest(),
        activeMap: map,
        activeLayerId: 'tiles',
      );

      notifier.clearEnvironmentGeneratedPlacementsForActiveTileLayer();

      final state = notifier.state;
      expect(state.activeMap, same(map));
      expect(state.activeLayerId, 'tiles');
      expect(state.selectedEnvironmentAreaId, isNull);
      expect(state.errorMessage, contains('zone'));
    });

    test('aucun generatedPlacementId ne mute pas la MapData', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _map(generatedPlacementIds: const []);
      notifier.state = EditorState(
        project: _manifest(),
        activeMap: map,
        activeLayerId: 'tiles',
        selectedEnvironmentAreaId: 'area',
        environmentMaskEditMode: EnvironmentMaskEditMode.paint,
      );

      notifier.clearEnvironmentGeneratedPlacementsForActiveTileLayer();

      final state = notifier.state;
      expect(state.activeMap, same(map));
      expect(state.activeLayerId, 'tiles');
      expect(state.selectedEnvironmentAreaId, 'area');
      expect(state.environmentMaskEditMode, isNull);
      expect(state.statusMessage, contains('Aucun placement'));
      expect(state.errorMessage, isNull);
    });
  });
}

final _params = EnvironmentGenerationParams(
  density: 1,
  variation: 0,
  edgeDensity: 1,
  minSpacingCells: 0,
);

MapData _map({
  List<String> generatedPlacementIds = const ['generated_a', 'generated_b'],
}) {
  return MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 2, height: 2),
    tilesetId: 'nature',
    layers: [
      const TileLayer(
        id: 'tiles',
        name: 'Ground',
        tilesetId: 'nature',
        tiles: [0, 0, 0, 0],
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
                width: 2,
                height: 2,
                cells: List<bool>.filled(4, true),
              ),
              seed: 5,
              paramsOverride: _params,
              generatedPlacementIds: generatedPlacementIds,
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
        pos: GridPos(x: 0, y: 1),
      ),
      MapPlacedElement(
        id: 'generated_b',
        layerId: 'tiles',
        elementId: 'tree',
        pos: GridPos(x: 1, y: 0),
      ),
    ],
  );
}

MapData _mapWithTwoAreas() {
  final map = _map();
  return map.copyWith(
    layers: [
      for (final layer in map.layers)
        if (layer is EnvironmentLayer)
          MapLayer.environment(
            id: layer.id,
            name: layer.name,
            content: EnvironmentLayerContent(
              targetTileLayerId: layer.content.targetTileLayerId,
              areas: [
                ...layer.content.areas,
                EnvironmentArea(
                  id: 'area_b',
                  name: 'Zone B',
                  presetId: 'forest',
                  mask: EnvironmentAreaMask(
                    width: 2,
                    height: 2,
                    cells: List<bool>.filled(4, true),
                  ),
                  seed: 6,
                  paramsOverride: _params,
                  generatedPlacementIds: const ['generated_b'],
                ),
              ],
            ),
          )
        else
          layer,
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
    ],
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
    environmentPresets: [
      EnvironmentPreset(
        id: 'forest',
        name: 'Forêt',
        templateId: 'forest',
        palette: [
          EnvironmentPaletteItem(elementId: 'tree', weight: 1),
        ],
        defaultParams: _params,
        sortOrder: 0,
      ),
    ],
  );
}
