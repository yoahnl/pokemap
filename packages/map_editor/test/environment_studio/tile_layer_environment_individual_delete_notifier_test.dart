import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';

void main() {
  group('EditorNotifier TileLayer individual generated placement delete', () {
    test('start delete mode garde TileLayer et stoppe paint/erase', () {
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
      );

      notifier.startDeletingGeneratedEnvironmentPlacementForActiveTileLayer();

      final state = notifier.state;
      expect(state.activeMap, same(map));
      expect(state.activeLayerId, 'tiles');
      expect(state.selectedEnvironmentAreaId, 'area');
      expect(state.environmentMaskEditMode,
          EnvironmentMaskEditMode.generatedDelete);
      expect(state.statusMessage, contains('Suppression active'));
      expect(state.errorMessage, isNull);

      notifier.stopDeletingGeneratedEnvironmentPlacement();

      final stopped = notifier.state;
      expect(stopped.activeLayerId, 'tiles');
      expect(stopped.selectedEnvironmentAreaId, 'area');
      expect(stopped.environmentMaskEditMode, isNull);
      expect(stopped.statusMessage, contains('arrêtée'));
    });

    test('delete at supprime le placement généré et garde le mode actif', () {
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
        selectedPlacedElementInstanceId: 'generated_big',
        savedMapSnapshot: map,
      );

      notifier.deleteGeneratedEnvironmentPlacementAtForActiveTileLayer(
        const GridPos(x: 2, y: 2),
      );

      final state = notifier.state;
      expect(state.activeMap, isNot(same(map)));
      expect(state.activeLayerId, 'tiles');
      expect(state.selectedEnvironmentAreaId, 'area');
      expect(state.environmentMaskEditMode,
          EnvironmentMaskEditMode.generatedDelete);
      expect(state.selectedPlacedElementInstanceId, isNull);
      expect(state.statusMessage, contains('Placement généré supprimé'));
      expect(state.errorMessage, isNull);
      expect(state.isDirty, isTrue);
      expect(
        state.activeMap!.placedElements.map((element) => element.id).toList(),
        const ['manual', 'generated_a', 'other_generated'],
      );
      final area = _areaById(state.activeMap!, 'area');
      expect(area.generatedPlacementIds, const ['generated_a']);
      expect(area.mask, _areaById(map, 'area').mask);
      expect(area.paramsOverride, _params);
      expect(area.seed, 11);
      expect(area.presetId, 'forest');
      expect(
        _areaById(state.activeMap!, 'other').generatedPlacementIds,
        const ['other_generated'],
      );
    });

    test('clic vide ou manuel ne mute pas la MapData et garde le mode actif',
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
        environmentMaskEditMode: EnvironmentMaskEditMode.generatedDelete,
      );

      notifier.deleteGeneratedEnvironmentPlacementAtForActiveTileLayer(
        const GridPos(x: 0, y: 0),
      );

      final state = notifier.state;
      expect(state.activeMap, same(map));
      expect(state.activeLayerId, 'tiles');
      expect(state.selectedEnvironmentAreaId, 'area');
      expect(state.environmentMaskEditMode,
          EnvironmentMaskEditMode.generatedDelete);
      expect(state.statusMessage, contains('Aucun placement généré'));
      expect(state.errorMessage, isNull);
      expect(_areaById(state.activeMap!, 'area').generatedPlacementIds,
          const ['generated_a', 'generated_big']);
    });

    test('refuse sans TileLayer actif, sans area, ou sans generated ids', () {
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
      notifier.startDeletingGeneratedEnvironmentPlacementForActiveTileLayer();
      expect(notifier.state.activeMap, same(map));
      expect(notifier.state.errorMessage, contains('TileLayer'));

      notifier.state = EditorState(
        project: _manifest(),
        activeMap: map,
        activeLayerId: 'tiles',
      );
      notifier.startDeletingGeneratedEnvironmentPlacementForActiveTileLayer();
      expect(notifier.state.activeMap, same(map));
      expect(notifier.state.errorMessage, contains('zone'));

      final emptyMap = _map(generatedPlacementIds: const []);
      notifier.state = EditorState(
        project: _manifest(),
        activeMap: emptyMap,
        activeLayerId: 'tiles',
        selectedEnvironmentAreaId: 'area',
      );
      notifier.startDeletingGeneratedEnvironmentPlacementForActiveTileLayer();
      expect(notifier.state.activeMap, same(emptyMap));
      expect(notifier.state.environmentMaskEditMode, isNull);
      expect(notifier.state.statusMessage, contains('Aucun placement généré'));
    });
  });
}

final _params = EnvironmentGenerationParams(
  density: 0.7,
  variation: 0.2,
  edgeDensity: 0.8,
  minSpacingCells: 1,
);

MapData _map({
  List<String> generatedPlacementIds = const [
    'generated_a',
    'generated_big',
  ],
}) {
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
              paramsOverride: _params,
              generatedPlacementIds: generatedPlacementIds,
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
        id: 'generated_big',
        layerId: 'tiles',
        elementId: 'big_tree',
        pos: GridPos(x: 1, y: 1),
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
        defaultParams: _params,
        sortOrder: 0,
      ),
    ],
  );
}
