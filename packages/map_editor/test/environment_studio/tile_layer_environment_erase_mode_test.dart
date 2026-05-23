import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';

void main() {
  group('EditorNotifier.startEnvironmentMaskErasingForActiveTileLayer', () {
    test('active le mode erase sans changer le TileLayer sélectionné', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _mapWithAttachedArea();
      notifier.state = EditorState(
        project: _manifest(),
        activeMap: map,
        activeLayerId: 'tiles',
        selectedEnvironmentAreaId: 'area_forest',
      );

      notifier.startEnvironmentMaskErasingForActiveTileLayer();

      final state = notifier.state;
      expect(state.activeMap, same(map));
      expect(state.activeLayerId, 'tiles');
      expect(state.selectedEnvironmentAreaId, 'area_forest');
      expect(state.environmentMaskEditMode, EnvironmentMaskEditMode.erase);
      expect(state.activeMap!.placedElements, isEmpty);
    });

    test('stop remet le mode à null et garde la zone active', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _mapWithAttachedArea();
      notifier.state = EditorState(
        project: _manifest(),
        activeMap: map,
        activeLayerId: 'tiles',
        selectedEnvironmentAreaId: 'area_forest',
        environmentMaskEditMode: EnvironmentMaskEditMode.erase,
      );

      notifier.stopEnvironmentMaskPainting();

      final state = notifier.state;
      expect(state.activeMap, same(map));
      expect(state.activeLayerId, 'tiles');
      expect(state.selectedEnvironmentAreaId, 'area_forest');
      expect(state.environmentMaskEditMode, isNull);
    });

    test('refuse si aucun TileLayer actif', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        project: _manifest(),
        activeMap: _mapWithAttachedArea(),
        activeLayerId: 'env',
        selectedEnvironmentAreaId: 'area_forest',
      );

      notifier.startEnvironmentMaskErasingForActiveTileLayer();

      final state = notifier.state;
      expect(state.environmentMaskEditMode, isNull);
      expect(state.activeLayerId, 'env');
      expect(state.errorMessage, contains('TileLayer'));
    });

    test('refuse si aucun EnvironmentLayer attaché', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        project: _manifest(),
        activeMap: _mapWithoutAttachment(),
        activeLayerId: 'tiles',
        selectedEnvironmentAreaId: 'area_forest',
      );

      notifier.startEnvironmentMaskErasingForActiveTileLayer();

      final state = notifier.state;
      expect(state.environmentMaskEditMode, isNull);
      expect(state.errorMessage, contains('Activez'));
    });

    test('refuse si aucune area est sélectionnée', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        project: _manifest(),
        activeMap: _mapWithAttachedArea(),
        activeLayerId: 'tiles',
      );

      notifier.startEnvironmentMaskErasingForActiveTileLayer();

      final state = notifier.state;
      expect(state.environmentMaskEditMode, isNull);
      expect(state.errorMessage, contains('zone'));
    });

    test('refuse si area sélectionnée introuvable', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        project: _manifest(),
        activeMap: _mapWithAttachedArea(),
        activeLayerId: 'tiles',
        selectedEnvironmentAreaId: 'missing',
      );

      notifier.startEnvironmentMaskErasingForActiveTileLayer();

      final state = notifier.state;
      expect(state.environmentMaskEditMode, isNull);
      expect(state.errorMessage, contains('introuvable'));
    });
  });
}

MapData _mapWithAttachedArea() {
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
            EnvironmentArea(
              id: 'area_forest',
              name: 'Forêt',
              presetId: 'forest',
              mask: EnvironmentAreaMask(
                width: 3,
                height: 3,
                cells: List<bool>.filled(9, true),
              ),
              seed: 0,
            ),
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
        defaultParams: EnvironmentGenerationParams.standard(),
        sortOrder: 0,
      ),
    ],
  );
}
