import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('MapPlacedElement opacity', () {
    test('defaults to fully opaque and round-trips through json', () {
      const defaultInstance = MapPlacedElement(
        id: 'layer::1::1',
        layerId: 'layer',
        elementId: 'lamp',
        pos: GridPos(x: 1, y: 1),
      );

      expect(defaultInstance.opacity, 1.0);

      const translucentInstance = MapPlacedElement(
        id: 'layer::1::1',
        layerId: 'layer',
        elementId: 'lamp',
        pos: GridPos(x: 1, y: 1),
        opacity: 0.35,
      );
      final json = translucentInstance.toJson();
      final decoded = MapPlacedElement.fromJson(json);

      expect(json['opacity'], 0.35);
      expect(decoded.opacity, 0.35);
    });

    test('legacy instance without opacity still deserializes as opaque', () {
      final decoded = MapPlacedElement.fromJson({
        'id': 'layer::1::1',
        'layerId': 'layer',
        'elementId': 'lamp',
        'pos': {'x': 1, 'y': 1},
      });

      expect(decoded.opacity, 1.0);
    });

    test('setMapPlacedElementOpacity updates only the targeted instance', () {
      final updated = setMapPlacedElementOpacity(
        _baseMap(),
        instanceId: 'layer::1::1',
        opacity: 0.42,
      );

      expect(updated.placedElements.first.opacity, 0.42);
      expect(updated.placedElements.last.opacity, 1.0);
    });

    test('setMapPlacedElementOpacity rejects values outside 0..1', () {
      expect(
        () => setMapPlacedElementOpacity(
          _baseMap(),
          instanceId: 'layer::1::1',
          opacity: 1.2,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => setMapPlacedElementOpacity(
          _baseMap(),
          instanceId: 'layer::1::1',
          opacity: -0.1,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('MapValidator rejects invalid placed element opacity', () {
      final map = _baseMap().copyWith(
        placedElements: [
          _baseMap().placedElements.first.copyWith(opacity: 1.4),
        ],
      );

      expect(
        () => MapValidator.validate(map, projectDialogueContext: _project()),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}

MapData _baseMap() {
  return const MapData(
    id: 'map',
    name: 'Map',
    size: GridSize(width: 4, height: 4),
    layers: [
      MapLayer.tile(
        id: 'layer',
        name: 'Layer',
        tilesetId: 'ts',
        tiles: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      ),
    ],
    placedElements: [
      MapPlacedElement(
        id: 'layer::1::1',
        layerId: 'layer',
        elementId: 'lamp',
        pos: GridPos(x: 1, y: 1),
      ),
      MapPlacedElement(
        id: 'layer::2::2',
        layerId: 'layer',
        elementId: 'lamp',
        pos: GridPos(x: 2, y: 2),
      ),
    ],
  );
}

ProjectManifest _project() {
  return ProjectManifest(
    name: 'Project',
    maps: const [],
    tilesets: const [
      ProjectTilesetEntry(id: 'ts', name: 'TS', relativePath: 'ts.png'),
    ],
    elementCategories: const [
      ProjectElementCategory(id: 'cat', name: 'Cat'),
    ],
    elements: const [
      ProjectElementEntry(
        id: 'lamp',
        name: 'Lamp',
        tilesetId: 'ts',
        categoryId: 'cat',
        frames: [
          TilesetVisualFrame(
            source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
          ),
        ],
      ),
    ],
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
}
