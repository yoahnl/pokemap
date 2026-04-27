import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('MapPlacedElementAnimation serialization', () {
    test('serializes and deserializes on placed element', () {
      final instance = MapPlacedElement(
        id: 'layer::1::1',
        layerId: 'layer',
        elementId: 'lamp',
        pos: const GridPos(x: 1, y: 1),
        animation: const MapPlacedElementAnimation(
          enabled: true,
          mode: MapPlacedElementAnimationMode.pingPong,
          autoplay: true,
          speed: 1.5,
          startOffsetMs: 250,
          randomStart: true,
        ),
      );
      final json = instance.toJson();
      final decoded = MapPlacedElement.fromJson(json);
      expect(decoded.animation, isNotNull);
      expect(decoded.animation!.enabled, isTrue);
      expect(decoded.animation!.mode, MapPlacedElementAnimationMode.pingPong);
      expect(decoded.animation!.speed, 1.5);
      expect(decoded.animation!.startOffsetMs, 250);
      expect(decoded.animation!.randomStart, isTrue);
    });

    test('legacy instance without animation still deserializes', () {
      final json = <String, dynamic>{
        'id': 'layer::1::1',
        'layerId': 'layer',
        'elementId': 'lamp',
        'pos': {'x': 1, 'y': 1},
        'applyCollision': true,
        'properties': <String, String>{},
      };
      final decoded = MapPlacedElement.fromJson(json);
      expect(decoded.animation, isNull);
    });
  });

  group('MapPlacedElementAnimation validation', () {
    test('rejects non-positive speed', () {
      final map = _buildMapWithAnimation(
        const MapPlacedElementAnimation(
          enabled: true,
          mode: MapPlacedElementAnimationMode.loop,
          speed: 0,
        ),
      );
      expect(
        () => MapValidator.validate(map, projectDialogueContext: _project()),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects negative start offset', () {
      final map = _buildMapWithAnimation(
        const MapPlacedElementAnimation(
          enabled: true,
          mode: MapPlacedElementAnimationMode.loop,
          speed: 1,
          startOffsetMs: -10,
        ),
      );
      expect(
        () => MapValidator.validate(map, projectDialogueContext: _project()),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('MapPlacedElementAnimation operations', () {
    test('set and reset animation config', () {
      final map = _buildMapWithAnimation(null);
      final configured = setMapPlacedElementAnimation(
        map,
        instanceId: 'layer::1::1',
        animation: const MapPlacedElementAnimation(
          enabled: true,
          mode: MapPlacedElementAnimationMode.loop,
          speed: 2,
        ),
      );
      expect(configured.placedElements.first.animation, isNotNull);
      final reset = resetMapPlacedElementAnimation(
        configured,
        instanceId: 'layer::1::1',
      );
      expect(reset.placedElements.first.animation, isNull);
    });
  });
}

MapData _buildMapWithAnimation(MapPlacedElementAnimation? animation) {
  return MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 4, height: 4),
    layers: const [
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
        pos: const GridPos(x: 1, y: 1),
        animation: animation,
      ),
    ],
  );
}

ProjectManifest _project() {
  return ProjectManifest(
    name: 'project',
    maps: const [],
    tilesets: const [
      ProjectTilesetEntry(id: 'ts', name: 'ts', relativePath: 'ts.png'),
    ],
    elementCategories: const [
      ProjectElementCategory(id: 'cat', name: 'cat'),
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
          TilesetVisualFrame(
            source: TilesetSourceRect(x: 1, y: 0, width: 1, height: 1),
          ),
        ],
      ),
    ],
        surfaceCatalog: ProjectSurfaceCatalog(),);
}
