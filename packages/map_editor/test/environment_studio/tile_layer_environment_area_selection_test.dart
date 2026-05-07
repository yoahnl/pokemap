import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';

void main() {
  group('EditorNotifier.selectEnvironmentAreaForActiveTileLayer', () {
    test('sélectionne une area et garde le TileLayer actif sans muter MapData',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _mapWithAreas();
      notifier.state = EditorState(
        project: _manifest(),
        activeMap: map,
        activeLayerId: 'tiles',
        selectedEnvironmentAreaId: 'area_a',
        environmentMaskEditMode: EnvironmentMaskEditMode.paint,
      );

      notifier.selectEnvironmentAreaForActiveTileLayer('area_b');

      final state = notifier.state;
      expect(state.activeMap, same(map));
      expect(state.activeLayerId, 'tiles');
      expect(state.selectedEnvironmentAreaId, 'area_b');
      expect(state.environmentMaskEditMode, isNull);
      expect(state.activeMap!.placedElements, isEmpty);
      expect(state.errorMessage, isNull);
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

      notifier.selectEnvironmentAreaForActiveTileLayer('area_b');

      final state = notifier.state;
      expect(state.activeMap, same(map));
      expect(state.activeLayerId, 'env');
      expect(state.selectedEnvironmentAreaId, 'area_a');
      expect(state.errorMessage, contains('TileLayer'));
    });

    test('refuse si aucun EnvironmentLayer attaché', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _mapWithoutAttachment();
      notifier.state = EditorState(
        project: _manifest(),
        activeMap: map,
        activeLayerId: 'tiles',
      );

      notifier.selectEnvironmentAreaForActiveTileLayer('area_b');

      final state = notifier.state;
      expect(state.activeMap, same(map));
      expect(state.activeLayerId, 'tiles');
      expect(state.selectedEnvironmentAreaId, isNull);
      expect(state.errorMessage, contains('Activez'));
    });

    test('refuse areaId vide', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _mapWithAreas();
      notifier.state = EditorState(
        project: _manifest(),
        activeMap: map,
        activeLayerId: 'tiles',
        selectedEnvironmentAreaId: 'area_a',
      );

      notifier.selectEnvironmentAreaForActiveTileLayer('   ');

      final state = notifier.state;
      expect(state.activeMap, same(map));
      expect(state.selectedEnvironmentAreaId, 'area_a');
      expect(state.errorMessage, contains('zone'));
    });

    test('refuse area introuvable', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _mapWithAreas();
      notifier.state = EditorState(
        project: _manifest(),
        activeMap: map,
        activeLayerId: 'tiles',
        selectedEnvironmentAreaId: 'area_a',
      );

      notifier.selectEnvironmentAreaForActiveTileLayer('missing');

      final state = notifier.state;
      expect(state.activeMap, same(map));
      expect(state.selectedEnvironmentAreaId, 'area_a');
      expect(state.errorMessage, contains('introuvable'));
    });
  });
}

MapData _mapWithAreas() {
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
            _area('area_a'),
            _area('area_b'),
          ],
        ),
      ),
    ],
  );
}

MapData _mapWithoutAttachment() {
  return const MapData(
    id: 'map',
    name: 'Map',
    size: GridSize(width: 3, height: 3),
    layers: [
      TileLayer(
        id: 'tiles',
        name: 'Ground',
        tiles: [0, 0, 0, 0, 0, 0, 0, 0, 0],
      ),
    ],
  );
}

EnvironmentArea _area(String id) {
  return EnvironmentArea(
    id: id,
    name: 'Zone $id',
    presetId: 'forest',
    mask: EnvironmentAreaMask(
      width: 3,
      height: 3,
      cells: List<bool>.filled(9, false),
    ),
    seed: 0,
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
