import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

void main() {
  group('EditorNotifier.deletePlacedElementInstance ownership', () {
    for (final properties in <Map<String, String>>[
      const {},
      const {'pokemapPlacementOrigin': 'authored'},
      const {'pokemapPlacementOrigin': 'future_editor'},
    ]) {
      test('removes authored $properties without erasing its tile', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final notifier = container.read(editorNotifierProvider.notifier);
        notifier.state = EditorState(
          project: _manifest,
          activeMap: _map(properties: properties),
          activeLayerId: 'decor',
        );

        notifier.deletePlacedElementInstance(instanceId: 'placement');

        expect(notifier.state.activeMap!.placedElements, isEmpty);
        expect(
          (notifier.state.activeMap!.layers.single as TileLayer).tiles,
          const [1],
        );
        expect(notifier.state.errorMessage, isNull);
      });
    }

    test('erases the source tile for a tile_index placement', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        project: _manifest,
        activeMap: _map(
          properties: const {'pokemapPlacementOrigin': 'tile_index'},
        ),
        activeLayerId: 'decor',
      );

      notifier.deletePlacedElementInstance(instanceId: 'placement');

      expect(notifier.state.activeMap!.placedElements, isEmpty);
      expect(
        (notifier.state.activeMap!.layers.single as TileLayer).tiles,
        const [0],
      );
    });
  });
}

MapData _map({required Map<String, String> properties}) => MapData(
      id: 'map',
      name: 'Map',
      size: const GridSize(width: 1, height: 1),
      layers: const [
        TileLayer(
          id: 'decor',
          name: 'Decor',
          tilesetId: 'nature',
          tiles: [1],
        ),
      ],
      placedElements: [
        MapPlacedElement(
          id: 'placement',
          layerId: 'decor',
          elementId: 'tree',
          pos: const GridPos(x: 0, y: 0),
          properties: properties,
        ),
      ],
    );

const _manifest = ProjectManifest(
  name: 'Project',
  maps: [],
  tilesets: [
    ProjectTilesetEntry(
      id: 'nature',
      name: 'Nature',
      relativePath: 'tilesets/nature.png',
    ),
  ],
  surfaceCatalog: ProjectSurfaceCatalog.empty(),
  elements: [
    ProjectElementEntry(
      id: 'tree',
      name: 'Tree',
      tilesetId: 'nature',
      categoryId: 'nature',
      frames: [
        TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
      ],
    ),
  ],
);
