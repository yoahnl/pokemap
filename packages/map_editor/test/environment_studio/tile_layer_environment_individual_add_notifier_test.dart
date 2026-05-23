import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/state/environment_generated_placement_add_element_provider.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';

void main() {
  group('EditorNotifier TileLayer individual generated placement add', () {
    test('sélection élément garde TileLayer actif et ne mute pas la MapData',
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
      );

      notifier.selectEnvironmentGeneratedPlacementElementForActiveTileLayer(
        'big_tree',
      );

      expect(notifier.state.activeMap, same(map));
      expect(notifier.state.activeLayerId, 'tiles');
      expect(notifier.state.selectedEnvironmentAreaId, 'area');
      expect(
        container.read(environmentGeneratedPlacementAddElementProvider),
        'big_tree',
      );
      expect(notifier.state.statusMessage, contains('Big Tree'));
    });

    test('start et stop add mode gardent TileLayer et area', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _map();
      notifier.state = EditorState(
        project: _manifest(),
        activeMap: map,
        activeLayerId: 'tiles',
        selectedEnvironmentAreaId: 'area',
        environmentMaskEditMode: EnvironmentMaskEditMode.generatedDelete,
      );
      container
          .read(environmentGeneratedPlacementAddElementProvider.notifier)
          .state = 'tree';

      notifier.startAddingGeneratedEnvironmentPlacementForActiveTileLayer();

      final active = notifier.state;
      expect(active.activeMap, same(map));
      expect(active.activeLayerId, 'tiles');
      expect(active.selectedEnvironmentAreaId, 'area');
      expect(
          active.environmentMaskEditMode, EnvironmentMaskEditMode.generatedAdd);
      expect(active.statusMessage, contains('Ajout actif'));

      notifier.stopAddingGeneratedEnvironmentPlacement();

      final stopped = notifier.state;
      expect(stopped.activeLayerId, 'tiles');
      expect(stopped.selectedEnvironmentAreaId, 'area');
      expect(stopped.environmentMaskEditMode, isNull);
      expect(stopped.statusMessage, contains('arrêté'));
    });

    test('add at ajoute un placement généré et garde le mode actif', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _map();
      notifier.state = EditorState(
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

      notifier.addGeneratedEnvironmentPlacementAtForActiveTileLayer(
        const GridPos(x: 2, y: 2),
      );

      final state = notifier.state;
      expect(state.activeMap, isNot(same(map)));
      expect(state.activeLayerId, 'tiles');
      expect(state.selectedEnvironmentAreaId, 'area');
      expect(
          state.environmentMaskEditMode, EnvironmentMaskEditMode.generatedAdd);
      expect(state.statusMessage, contains('Élément généré ajouté'));
      expect(state.errorMessage, isNull);
      expect(state.isDirty, isTrue);

      final added = state.activeMap!.placedElements.singleWhere(
        (element) => element.id == 'env_gen_area_2_2_big_tree',
      );
      expect(added.layerId, 'tiles');
      expect(added.elementId, 'big_tree');
      expect(added.pos, const GridPos(x: 2, y: 2));
      expect(
        _areaById(state.activeMap!, 'area').generatedPlacementIds,
        const ['generated_a', 'env_gen_area_2_2_big_tree'],
      );
      expect(
        state.activeMap!.placedElements.map((element) => element.id),
        containsAll(const ['manual', 'other_generated']),
      );
      expect(
        _areaById(state.activeMap!, 'other').generatedPlacementIds,
        const ['other_generated'],
      );
    });

    test('position invalide ne mute pas la MapData et garde le mode actif', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _map();
      notifier.state = EditorState(
        project: _manifest(),
        activeMap: map,
        activeLayerId: 'tiles',
        selectedEnvironmentAreaId: 'area',
        environmentMaskEditMode: EnvironmentMaskEditMode.generatedAdd,
      );
      container
          .read(environmentGeneratedPlacementAddElementProvider.notifier)
          .state = 'big_tree';

      notifier.addGeneratedEnvironmentPlacementAtForActiveTileLayer(
        const GridPos(x: 4, y: 4),
      );

      final state = notifier.state;
      expect(state.activeMap, same(map));
      expect(state.activeLayerId, 'tiles');
      expect(state.selectedEnvironmentAreaId, 'area');
      expect(
          state.environmentMaskEditMode, EnvironmentMaskEditMode.generatedAdd);
      expect(state.errorMessage, contains('Impossible d’ajouter ici'));
    });

    test('refuse sans TileLayer actif, sans area, ou sans élément sélectionné',
        () {
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
      notifier.startAddingGeneratedEnvironmentPlacementForActiveTileLayer();
      expect(notifier.state.activeMap, same(map));
      expect(notifier.state.errorMessage, contains('TileLayer'));

      notifier.state = EditorState(
        project: _manifest(),
        activeMap: map,
        activeLayerId: 'tiles',
      );
      notifier.startAddingGeneratedEnvironmentPlacementForActiveTileLayer();
      expect(notifier.state.activeMap, same(map));
      expect(notifier.state.errorMessage, contains('zone'));

      notifier.state = EditorState(
        project: _manifest(),
        activeMap: map,
        activeLayerId: 'tiles',
        selectedEnvironmentAreaId: 'area',
      );
      container
          .read(environmentGeneratedPlacementAddElementProvider.notifier)
          .state = null;
      notifier.startAddingGeneratedEnvironmentPlacementForActiveTileLayer();
      expect(notifier.state.environmentMaskEditMode, isNull);
      expect(notifier.state.errorMessage, contains('élément'));
    });
  });
}

MapData _map() {
  return MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 5, height: 5),
    tilesetId: 'nature',
    layers: [
      const TileLayer(
        id: 'tiles',
        name: 'Ground',
        tilesetId: 'nature',
        tiles: [
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
                width: 5,
                height: 5,
                cells: List<bool>.filled(25, true),
              ),
              seed: 11,
              generatedPlacementIds: const ['generated_a'],
            ),
            EnvironmentArea(
              id: 'other',
              name: 'Other',
              presetId: 'forest',
              mask: EnvironmentAreaMask(
                width: 5,
                height: 5,
                cells: List<bool>.filled(25, true),
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
        pos: GridPos(x: 4, y: 4),
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
