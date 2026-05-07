import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

void main() {
  group('EditorNotifier.createEnvironmentAreaForActiveTileLayer', () {
    test('crée une area et garde le TileLayer sélectionné', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        project: _manifest(),
        activeMap: _mapWithAttachment(),
        activeLayerId: 'tiles',
      );

      notifier.createEnvironmentAreaForActiveTileLayer(presetId: 'forest');

      final state = notifier.state;
      final map = state.activeMap!;
      final envLayer = map.layers.whereType<EnvironmentLayer>().single;
      final area = envLayer.content.areas.single;
      expect(state.activeLayerId, 'tiles');
      expect(state.selectedEnvironmentAreaId, area.id);
      expect(state.environmentMaskEditMode, isNull);
      expect(area.presetId, 'forest');
      expect(area.mask.activeCellCount, 0);
      expect(area.generatedPlacementIds, isEmpty);
      expect(map.placedElements, isEmpty);
    });

    test('refuse un preset absent sans créer de zone', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        project: _manifest(),
        activeMap: _mapWithAttachment(),
        activeLayerId: 'tiles',
      );

      notifier.createEnvironmentAreaForActiveTileLayer(presetId: 'missing');

      final state = notifier.state;
      final envLayer =
          state.activeMap!.layers.whereType<EnvironmentLayer>().single;
      expect(envLayer.content.areas, isEmpty);
      expect(state.activeLayerId, 'tiles');
      expect(state.selectedEnvironmentAreaId, isNull);
      expect(state.environmentMaskEditMode, isNull);
      expect(state.errorMessage, contains('preset'));
    });
  });
}

MapData _mapWithAttachment() {
  return MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 2, height: 2),
    layers: [
      const TileLayer(id: 'tiles', name: 'Ground', tiles: [0, 0, 0, 0]),
      MapLayer.environment(
        id: 'env',
        name: 'Environment',
        content: EnvironmentLayerContent(targetTileLayerId: 'tiles'),
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
    surfaceCatalog: ProjectSurfaceCatalog(),
    environmentPresets: [
      EnvironmentPreset(
        id: 'forest',
        name: 'Forêt',
        templateId: 'forest',
        palette: [
          EnvironmentPaletteItem(elementId: 'tree', weight: 1),
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
