import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';

void main() {
  group('EditorNotifier.startEnvironmentMaskPaintingForActiveTileLayer', () {
    test('active le mode paint sans changer le TileLayer sélectionné', () {
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

      notifier.startEnvironmentMaskPaintingForActiveTileLayer();

      final state = notifier.state;
      expect(state.activeMap, same(map));
      expect(state.activeLayerId, 'tiles');
      expect(state.selectedEnvironmentAreaId, 'area_forest');
      expect(state.environmentMaskEditMode, EnvironmentMaskEditMode.paint);
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
        environmentMaskEditMode: EnvironmentMaskEditMode.paint,
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

      notifier.startEnvironmentMaskPaintingForActiveTileLayer();

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

      notifier.startEnvironmentMaskPaintingForActiveTileLayer();

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
        activeMap: _mapWithTwoAttachedAreas(),
        activeLayerId: 'tiles',
      );

      notifier.startEnvironmentMaskPaintingForActiveTileLayer();

      final state = notifier.state;
      expect(state.environmentMaskEditMode, isNull);
      expect(state.errorMessage, contains('zone'));
    });

    test('utilise l’unique area effective sans sélection explicite', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _mapWithAttachedArea();
      notifier.state = EditorState(
        project: _manifest(),
        activeMap: map,
        activeLayerId: 'tiles',
      );

      notifier.startEnvironmentMaskPaintingForActiveTileLayer();

      final state = notifier.state;
      expect(state.activeMap, same(map));
      expect(state.activeLayerId, 'tiles');
      expect(state.selectedEnvironmentAreaId, 'area_forest');
      expect(state.environmentMaskEditMode, EnvironmentMaskEditMode.paint);
      expect(state.errorMessage, isNull);
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

      notifier.startEnvironmentMaskPaintingForActiveTileLayer();

      final state = notifier.state;
      expect(state.environmentMaskEditMode, isNull);
      expect(state.errorMessage, contains('introuvable'));
    });

    test('peint le masque attaché en gardant le TileLayer actif', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _mapWithAttachedArea();
      notifier.state = EditorState(
        project: _manifest(),
        activeMap: map,
        activeLayerId: 'tiles',
        selectedEnvironmentAreaId: 'area_forest',
        environmentMaskEditMode: EnvironmentMaskEditMode.paint,
      );

      notifier.paintEnvironmentAreaMaskAt(const GridPos(x: 1, y: 1));

      final state = notifier.state;
      final envLayer =
          state.activeMap!.layers.whereType<EnvironmentLayer>().single;
      final area = envLayer.content.areas.single;
      expect(state.activeLayerId, 'tiles');
      expect(state.selectedEnvironmentAreaId, 'area_forest');
      expect(state.environmentMaskEditMode, EnvironmentMaskEditMode.paint);
      expect(envLayer.content.targetTileLayerId, 'tiles');
      expect(area.mask.isActiveAt(1, 1), isTrue);
      expect(state.activeMap!.placedElements, isEmpty);
    });
  });
}

MapData _mapWithTwoAttachedAreas() {
  final map = _mapWithAttachedArea();
  final env = map.layers.whereType<EnvironmentLayer>().single;
  final first = env.content.areas.single;
  final updatedEnv = env.copyWith(
    content: EnvironmentLayerContent(
      targetTileLayerId: env.content.targetTileLayerId,
      areas: [
        first,
        EnvironmentArea(
          id: 'area_meadow',
          name: 'Prairie',
          presetId: 'forest',
          mask: EnvironmentAreaMask(
            width: 3,
            height: 3,
            cells: List<bool>.filled(9, false),
          ),
          seed: 1,
        ),
      ],
    ),
  );
  return map.copyWith(
    layers: [
      for (final layer in map.layers)
        if (layer.id == env.id) updatedEnv else layer,
    ],
  );
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
                cells: List<bool>.filled(9, false),
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
