import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/use_cases/environment_generator_regenerate_use_cases.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';

void main() {
  group('EditorNotifier TileLayer regenerate / shuffle', () {
    test('regenerate garde la sélection TileLayer et conserve le seed', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _map();
      notifier.state = EditorState(
        project: _manifest(),
        activeMap: map,
        activeLayerId: 'tiles',
        selectedEnvironmentAreaId: 'area',
        environmentMaskEditMode: EnvironmentMaskEditMode.paint,
        savedMapSnapshot: map,
      );

      notifier.regenerateEnvironmentAreaPlacementsForActiveTileLayer();

      final state = notifier.state;
      final area = _areaById(state.activeMap!, 'area');
      expect(state.activeMap, isNot(same(map)));
      expect(state.activeLayerId, 'tiles');
      expect(state.selectedEnvironmentAreaId, 'area');
      expect(state.environmentMaskEditMode, isNull);
      expect(state.errorMessage, isNull);
      expect(state.statusMessage, contains('régénér'));
      expect(state.isDirty, isTrue);
      expect(area.seed, 7);
      expect(area.generatedPlacementIds, isNotEmpty);
      expect(area.generatedPlacementIds, isNot(contains('old_a')));
      expect(
          state.activeMap!.placedElements.any((e) => e.id == 'manual'), isTrue);
    });

    test('shuffle garde la sélection TileLayer et change le seed', () {
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
        savedMapSnapshot: map,
      );

      notifier.shuffleEnvironmentAreaPlacementsForActiveTileLayer();

      final state = notifier.state;
      final area = _areaById(state.activeMap!, 'area');
      expect(state.activeLayerId, 'tiles');
      expect(state.selectedEnvironmentAreaId, 'area');
      expect(state.environmentMaskEditMode, isNull);
      expect(state.errorMessage, isNull);
      expect(state.statusMessage, contains('Seed'));
      expect(area.seed, nextEnvironmentAreaSeed(7));
      expect(area.generatedPlacementIds, isNotEmpty);
      expect(
          state.activeMap!.placedElements.any((e) => e.id == 'manual'), isTrue);
    });

    test('refuse sans TileLayer actif ou sans area sélectionnée', () {
      final noTileContainer = ProviderContainer();
      addTearDown(noTileContainer.dispose);
      final noTileNotifier =
          noTileContainer.read(editorNotifierProvider.notifier);
      final map = _map();
      noTileNotifier.state = EditorState(
        project: _manifest(),
        activeMap: map,
        activeLayerId: 'env',
        selectedEnvironmentAreaId: 'area',
      );

      noTileNotifier.regenerateEnvironmentAreaPlacementsForActiveTileLayer();

      expect(noTileNotifier.state.activeMap, same(map));
      expect(noTileNotifier.state.activeLayerId, 'env');
      expect(noTileNotifier.state.selectedEnvironmentAreaId, 'area');
      expect(noTileNotifier.state.errorMessage, contains('TileLayer'));

      final noAreaContainer = ProviderContainer();
      addTearDown(noAreaContainer.dispose);
      final noAreaNotifier =
          noAreaContainer.read(editorNotifierProvider.notifier);
      final noAreaMap = _mapWithTwoAreas();
      noAreaNotifier.state = EditorState(
        project: _manifest(),
        activeMap: noAreaMap,
        activeLayerId: 'tiles',
      );

      noAreaNotifier.shuffleEnvironmentAreaPlacementsForActiveTileLayer();

      expect(noAreaNotifier.state.activeMap, same(noAreaMap));
      expect(noAreaNotifier.state.activeLayerId, 'tiles');
      expect(noAreaNotifier.state.selectedEnvironmentAreaId, isNull);
      expect(noAreaNotifier.state.errorMessage, contains('zone'));
    });

    test('refuse si generatedPlacementIds est vide', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _map(generatedPlacementIds: const []);
      notifier.state = EditorState(
        project: _manifest(),
        activeMap: map,
        activeLayerId: 'tiles',
        selectedEnvironmentAreaId: 'area',
      );

      notifier.regenerateEnvironmentAreaPlacementsForActiveTileLayer();

      expect(notifier.state.activeMap, same(map));
      expect(notifier.state.errorMessage, contains('placement'));
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
  List<String> generatedPlacementIds = const ['old_a', 'old_b'],
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
              seed: 7,
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
        id: 'old_a',
        layerId: 'tiles',
        elementId: 'tree',
        pos: GridPos(x: 0, y: 1),
      ),
      MapPlacedElement(
        id: 'old_b',
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
                  seed: 8,
                  paramsOverride: _params,
                  generatedPlacementIds: const ['old_b'],
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
    surfaceCatalog: ProjectSurfaceCatalog(),
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
