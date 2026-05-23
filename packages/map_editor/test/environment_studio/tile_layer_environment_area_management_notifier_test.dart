import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/state/environment_generated_placement_add_element_provider.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';

void main() {
  group('EditorNotifier TileLayer environment area management', () {
    test('rename garde TileLayer, area sélectionnée et mode actifs', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _map();
      notifier.state = EditorState(
        project: _manifest(),
        activeMap: map,
        activeLayerId: 'tiles',
        selectedEnvironmentAreaId: 'area_a',
        environmentMaskEditMode: EnvironmentMaskEditMode.paint,
        savedMapSnapshot: map,
      );

      notifier.renameEnvironmentAreaForActiveTileLayer('  Bosquet plage  ');

      final state = notifier.state;
      final area = _areaById(state.activeMap!, 'area_a');

      expect(state.activeLayerId, 'tiles');
      expect(state.selectedEnvironmentAreaId, 'area_a');
      expect(state.environmentMaskEditMode, EnvironmentMaskEditMode.paint);
      expect(area.name, 'Bosquet plage');
      expect(area.id, 'area_a');
      expect(area.generatedPlacementIds, ['generated_a']);
      expect(state.activeMap!.placedElements.map((placement) => placement.id),
          ['manual', 'generated_a', 'other_generated']);
      expect(state.statusMessage, contains('Zone renommée'));
      expect(state.errorMessage, isNull);
      expect(state.isDirty, isTrue);
    });

    test(
        'delete nettoie la sélection active et le mode sans changer le TileLayer',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _map();
      notifier.state = EditorState(
        project: _manifest(),
        activeMap: map,
        activeLayerId: 'tiles',
        selectedEnvironmentAreaId: 'area_a',
        selectedPlacedElementInstanceId: 'generated_a',
        environmentMaskEditMode: EnvironmentMaskEditMode.generatedAdd,
        savedMapSnapshot: map,
      );
      container
          .read(environmentGeneratedPlacementAddElementProvider.notifier)
          .state = 'tree';

      notifier.deleteEnvironmentAreaForActiveTileLayer();

      final state = notifier.state;
      final environmentLayer = _environmentLayer(state.activeMap!);

      expect(state.activeLayerId, 'tiles');
      expect(state.selectedEnvironmentAreaId, isNull);
      expect(state.environmentMaskEditMode, isNull);
      expect(state.selectedPlacedElementInstanceId, isNull);
      expect(container.read(environmentGeneratedPlacementAddElementProvider),
          isNull);
      expect(environmentLayer.content.areaById('area_a'), isNull);
      expect(environmentLayer.content.areaById('area_b'), isNotNull);
      expect(state.activeMap!.placedElements.map((placement) => placement.id),
          ['manual', 'other_generated']);
      expect(state.statusMessage, contains('Zone supprimée'));
      expect(state.errorMessage, isNull);
      expect(state.isDirty, isTrue);
    });

    test('delete préserve les placements manuels', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _map();
      notifier.state = EditorState(
        project: _manifest(),
        activeMap: map,
        activeLayerId: 'tiles',
        selectedEnvironmentAreaId: 'area_a',
      );

      notifier.deleteEnvironmentAreaForActiveTileLayer();

      final manual = notifier.state.activeMap!.placedElements.singleWhere(
        (placement) => placement.id == 'manual',
      );
      final otherGenerated =
          notifier.state.activeMap!.placedElements.singleWhere(
        (placement) => placement.id == 'other_generated',
      );

      expect(manual.elementId, 'tree');
      expect(otherGenerated.elementId, 'rock');
      expect(
          _areaById(notifier.state.activeMap!, 'area_b').generatedPlacementIds,
          ['other_generated']);
    });

    test('refuse sans TileLayer actif', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _map();
      notifier.state = EditorState(
        project: _manifest(),
        activeMap: map,
        activeLayerId: 'environment',
        selectedEnvironmentAreaId: 'area_a',
      );

      notifier.renameEnvironmentAreaForActiveTileLayer('Bosquet plage');

      expect(notifier.state.activeMap, same(map));
      expect(notifier.state.activeLayerId, 'environment');
      expect(notifier.state.selectedEnvironmentAreaId, 'area_a');
      expect(notifier.state.errorMessage, contains('TileLayer'));
    });

    test('refuse sans area sélectionnée', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _map();
      notifier.state = EditorState(
        project: _manifest(),
        activeMap: map,
        activeLayerId: 'tiles',
      );

      notifier.deleteEnvironmentAreaForActiveTileLayer();

      expect(notifier.state.activeMap, same(map));
      expect(notifier.state.activeLayerId, 'tiles');
      expect(notifier.state.selectedEnvironmentAreaId, isNull);
      expect(notifier.state.errorMessage, contains('zone'));
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
        id: 'environment',
        name: 'Environment',
        content: EnvironmentLayerContent(
          targetTileLayerId: 'tiles',
          areas: [
            _area('area_a', 'Zone A', ['generated_a']),
            _area('area_b', 'Zone B', ['other_generated']),
          ],
        ),
      ),
    ],
    placedElements: const [
      MapPlacedElement(
        id: 'manual',
        layerId: 'tiles',
        elementId: 'tree',
        pos: GridPos(x: 1, y: 1),
      ),
      MapPlacedElement(
        id: 'generated_a',
        layerId: 'tiles',
        elementId: 'tree',
        pos: GridPos(x: 2, y: 2),
      ),
      MapPlacedElement(
        id: 'other_generated',
        layerId: 'tiles',
        elementId: 'rock',
        pos: GridPos(x: 3, y: 3),
      ),
    ],
  );
}

EnvironmentArea _area(
  String id,
  String name,
  List<String> generatedPlacementIds,
) {
  return EnvironmentArea(
    id: id,
    name: name,
    presetId: 'forest',
    mask: EnvironmentAreaMask(
      width: 5,
      height: 5,
      cells: List<bool>.filled(25, false),
    ),
    seed: 7,
    paramsOverride: EnvironmentGenerationParams.standard(),
    generatedPlacementIds: generatedPlacementIds,
  );
}

EnvironmentLayer _environmentLayer(MapData map) {
  return map.layers.whereType<EnvironmentLayer>().single;
}

EnvironmentArea _areaById(MapData map, String id) {
  return _environmentLayer(map).content.areaById(id)!;
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
        id: 'rock',
        name: 'Rock',
        tilesetId: 'nature',
        categoryId: 'rocks',
        frames: [
          TilesetVisualFrame(source: TilesetSourceRect(x: 1, y: 0)),
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
          EnvironmentPaletteItem(elementId: 'rock', weight: 1),
        ],
        defaultParams: EnvironmentGenerationParams.standard(),
        sortOrder: 0,
      ),
    ],
  );
}
