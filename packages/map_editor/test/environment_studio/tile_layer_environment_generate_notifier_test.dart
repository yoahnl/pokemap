import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';

void main() {
  group('EditorNotifier TileLayer environment generation', () {
    test('génère les placements et garde la sélection TileLayer stable', () {
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

      notifier.generateEnvironmentAreaPlacementsForActiveTileLayer();

      final state = notifier.state;
      expect(state.activeMap, isNot(same(map)));
      expect(state.activeLayerId, 'tiles');
      expect(state.selectedEnvironmentAreaId, 'area');
      expect(state.environmentMaskEditMode, isNull);
      expect(state.errorMessage, isNull);
      expect(state.statusMessage, contains('placement'));
      expect(state.isDirty, isTrue);
      expect(
          state.activeMap!.placedElements.any((e) => e.id == 'manual'), isTrue);
      final area = _areaById(state.activeMap!, 'area');
      expect(area.generatedPlacementIds, isNotEmpty);
      for (final id in area.generatedPlacementIds) {
        final placed =
            state.activeMap!.placedElements.singleWhere((e) => e.id == id);
        expect(placed.layerId, 'tiles');
        expect(placed.elementId, 'tree');
      }
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

      notifier.generateEnvironmentAreaPlacementsForActiveTileLayer();

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
      final map = _map();
      notifier.state = EditorState(
        project: _manifest(),
        activeMap: map,
        activeLayerId: 'tiles',
      );

      notifier.generateEnvironmentAreaPlacementsForActiveTileLayer();

      final state = notifier.state;
      expect(state.activeMap, same(map));
      expect(state.activeLayerId, 'tiles');
      expect(state.selectedEnvironmentAreaId, isNull);
      expect(state.errorMessage, contains('zone'));
    });

    test('refuse masque vide et preset manquant sans mutation', () {
      final emptyContainer = ProviderContainer();
      addTearDown(emptyContainer.dispose);
      final emptyNotifier =
          emptyContainer.read(editorNotifierProvider.notifier);
      final emptyMap = _map(cells: List<bool>.filled(4, false));
      emptyNotifier.state = EditorState(
        project: _manifest(),
        activeMap: emptyMap,
        activeLayerId: 'tiles',
        selectedEnvironmentAreaId: 'area',
      );

      emptyNotifier.generateEnvironmentAreaPlacementsForActiveTileLayer();

      expect(emptyNotifier.state.activeMap, same(emptyMap));
      expect(emptyNotifier.state.errorMessage, contains('Masque'));

      final missingPresetContainer = ProviderContainer();
      addTearDown(missingPresetContainer.dispose);
      final missingPresetNotifier =
          missingPresetContainer.read(editorNotifierProvider.notifier);
      final missingPresetMap = _map(areaPresetId: 'missing');
      missingPresetNotifier.state = EditorState(
        project: _manifest(),
        activeMap: missingPresetMap,
        activeLayerId: 'tiles',
        selectedEnvironmentAreaId: 'area',
      );

      missingPresetNotifier
          .generateEnvironmentAreaPlacementsForActiveTileLayer();

      expect(missingPresetNotifier.state.activeMap, same(missingPresetMap));
      expect(missingPresetNotifier.state.errorMessage, contains('preset'));
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
  List<bool>? cells,
  String areaPresetId = 'forest',
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
              presetId: areaPresetId,
              mask: EnvironmentAreaMask(
                width: 2,
                height: 2,
                cells: cells ?? List<bool>.filled(4, true),
              ),
              seed: 3,
              paramsOverride: _params,
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
