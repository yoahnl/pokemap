import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('validates transformed geometry without loading project definitions', () {
    final map = _map(const PixelOffset(x: 31, y: 15));

    MapValidator.validate(
      map,
      projectTileSize: const PixelSize(width: 32, height: 16),
    );
  });

  test('uses both project tile dimensions for normalized offsets', () {
    expect(
      () => MapValidator.validate(
        _map(const PixelOffset(x: 0, y: 16)),
        projectTileSize: const PixelSize(width: 32, height: 16),
      ),
      throwsA(isA<ValidationException>().having(
        (error) => error.message,
        'message',
        contains('offsets must be normalized'),
      )),
    );
  });

  test('still refuses transformed geometry without tile dimensions', () {
    expect(
      () => MapValidator.validate(_map(const PixelOffset(x: 1, y: 0))),
      throwsA(isA<ValidationException>().having(
        (error) => error.message,
        'message',
        contains('requires project tile dimensions'),
      )),
    );
  });

  test('refuses tile dimensions that conflict with a supplied project', () {
    expect(
      () => MapValidator.validate(
        _map(const PixelOffset(x: 1, y: 0)),
        projectDialogueContext: const ProjectManifest(
          name: 'Project',
          maps: [],
          tilesets: [],
          settings: ProjectSettings(tileWidth: 32, tileHeight: 32),
        ),
        projectTileSize: const PixelSize(width: 16, height: 16),
      ),
      throwsA(isA<ValidationException>().having(
        (error) => error.message,
        'message',
        contains('conflict with the project'),
      )),
    );
  });
}

MapData _map(PixelOffset offset) => MapData(
  id: 'map',
  name: 'Map',
  size: const GridSize(width: 3, height: 3),
  layers: [MapLayer.tile(id: 'decor', name: 'Decor', cells: List.filled(9, 0))],
  placedElements: [MapPlacedElement(
    id: 'placed',
    layerId: 'decor',
    elementId: 'not-hydrated',
    pos: const GridPos(x: 0, y: 0),
    pixelOffset: offset,
    pixelSize: const PixelSize(width: 8, height: 8),
    properties: const {'pokemapPlacementOrigin': 'authored'},
  )],
);
