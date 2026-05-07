import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';

void main() {
  group('EditorNotifier TileLayer environment area settings', () {
    test('applique un paramsOverride et garde la sélection stable', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _mapWithAreas();
      final params = _params(
        density: 0.75,
        variation: 0.2,
        edgeDensity: 0.65,
        minSpacingCells: 2,
      );
      notifier.state = EditorState(
        project: _manifest(),
        activeMap: map,
        activeLayerId: 'tiles',
        selectedEnvironmentAreaId: 'area_a',
        environmentMaskEditMode: EnvironmentMaskEditMode.paint,
      );

      notifier.setEnvironmentAreaParamsOverrideForActiveTileLayer(params);

      final state = notifier.state;
      final area = _areaById(_environmentLayer(state.activeMap!), 'area_a');
      expect(state.activeMap, isNot(same(map)));
      expect(area.paramsOverride, params);
      expect(state.activeLayerId, 'tiles');
      expect(state.selectedEnvironmentAreaId, 'area_a');
      expect(state.environmentMaskEditMode, EnvironmentMaskEditMode.paint);
      expect(state.activeMap!.placedElements, isEmpty);
      expect(state.errorMessage, isNull);
    });

    test('retire un paramsOverride et garde seed masque et mode', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final override = _params(
        density: 0.75,
        variation: 0.2,
        edgeDensity: 0.65,
        minSpacingCells: 2,
      );
      final map = _mapWithAreas(areaAParamsOverride: override);
      notifier.state = EditorState(
        project: _manifest(),
        activeMap: map,
        activeLayerId: 'tiles',
        selectedEnvironmentAreaId: 'area_a',
        environmentMaskEditMode: EnvironmentMaskEditMode.erase,
      );

      notifier.resetEnvironmentAreaParamsOverrideForActiveTileLayer();

      final state = notifier.state;
      final area = _areaById(_environmentLayer(state.activeMap!), 'area_a');
      expect(area.paramsOverride, isNull);
      expect(area.seed, 11);
      expect(area.mask, _areaById(_environmentLayer(map), 'area_a').mask);
      expect(state.activeLayerId, 'tiles');
      expect(state.selectedEnvironmentAreaId, 'area_a');
      expect(state.environmentMaskEditMode, EnvironmentMaskEditMode.erase);
      expect(state.activeMap!.placedElements, isEmpty);
    });

    test('modifie le seed sans changer paramsOverride ni mode', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final override = _params(
        density: 0.75,
        variation: 0.2,
        edgeDensity: 0.65,
        minSpacingCells: 2,
      );
      final map = _mapWithAreas(areaAParamsOverride: override);
      notifier.state = EditorState(
        project: _manifest(),
        activeMap: map,
        activeLayerId: 'tiles',
        selectedEnvironmentAreaId: 'area_a',
        environmentMaskEditMode: EnvironmentMaskEditMode.paint,
      );

      notifier.setEnvironmentAreaSeedForActiveTileLayer(123);

      final state = notifier.state;
      final area = _areaById(_environmentLayer(state.activeMap!), 'area_a');
      expect(area.seed, 123);
      expect(area.paramsOverride, override);
      expect(state.activeLayerId, 'tiles');
      expect(state.selectedEnvironmentAreaId, 'area_a');
      expect(state.environmentMaskEditMode, EnvironmentMaskEditMode.paint);
      expect(state.activeMap!.placedElements, isEmpty);
    });

    test('refuse si aucun TileLayer actif', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _mapWithAreas();
      notifier.state = EditorState(
        project: _manifest(),
        activeMap: map,
        activeLayerId: 'env',
        selectedEnvironmentAreaId: 'area_a',
      );

      notifier.setEnvironmentAreaSeedForActiveTileLayer(123);

      final state = notifier.state;
      expect(state.activeMap, same(map));
      expect(state.activeLayerId, 'env');
      expect(state.selectedEnvironmentAreaId, 'area_a');
      expect(state.errorMessage, contains('TileLayer'));
    });

    test('refuse si aucune area est sélectionnée', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _mapWithAreas();
      notifier.state = EditorState(
        project: _manifest(),
        activeMap: map,
        activeLayerId: 'tiles',
      );

      notifier.resetEnvironmentAreaParamsOverrideForActiveTileLayer();

      final state = notifier.state;
      expect(state.activeMap, same(map));
      expect(state.activeLayerId, 'tiles');
      expect(state.selectedEnvironmentAreaId, isNull);
      expect(state.errorMessage, contains('zone'));
    });

    test('refuse si area sélectionnée est introuvable', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _mapWithAreas();
      notifier.state = EditorState(
        project: _manifest(),
        activeMap: map,
        activeLayerId: 'tiles',
        selectedEnvironmentAreaId: 'missing',
      );

      notifier.setEnvironmentAreaSeedForActiveTileLayer(123);

      final state = notifier.state;
      expect(state.activeMap, same(map));
      expect(state.selectedEnvironmentAreaId, 'missing');
      expect(state.errorMessage, contains('introuvable'));
    });
  });
}

MapData _mapWithAreas({
  EnvironmentGenerationParams? areaAParamsOverride,
}) {
  return MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 3, height: 3),
    layers: [
      const TileLayer(
        id: 'tiles',
        name: 'Ground',
        tiles: [0, 0, 0, 0, 0, 0, 0, 0, 0],
      ),
      MapLayer.environment(
        id: 'env',
        name: 'Environment',
        content: EnvironmentLayerContent(
          targetTileLayerId: 'tiles',
          areas: [
            _area(
              id: 'area_a',
              seed: 11,
              paramsOverride: areaAParamsOverride,
            ),
            _area(id: 'area_b', seed: 22),
          ],
        ),
      ),
    ],
  );
}

EnvironmentArea _area({
  required String id,
  required int seed,
  EnvironmentGenerationParams? paramsOverride,
}) {
  return EnvironmentArea(
    id: id,
    name: 'Zone $id',
    presetId: 'forest',
    mask: EnvironmentAreaMask(
      width: 3,
      height: 3,
      cells: List<bool>.filled(9, false),
    ),
    seed: seed,
    paramsOverride: paramsOverride,
  );
}

EnvironmentLayer _environmentLayer(MapData map) {
  return map.layers.whereType<EnvironmentLayer>().single;
}

EnvironmentArea _areaById(EnvironmentLayer layer, String id) {
  return layer.content.areas.singleWhere((area) => area.id == id);
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
        defaultParams: EnvironmentGenerationParams.standard(),
        sortOrder: 0,
      ),
    ],
  );
}

EnvironmentGenerationParams _params({
  required double density,
  required double variation,
  required double edgeDensity,
  required int minSpacingCells,
}) {
  return EnvironmentGenerationParams(
    density: density,
    variation: variation,
    edgeDensity: edgeDensity,
    minSpacingCells: minSpacingCells,
  );
}
