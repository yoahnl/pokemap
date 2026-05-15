import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('setMapPlacedElementShadowOverride', () {
    test('updates only the targeted placed element', () {
      final override = MapPlacedElementShadowOverride(
        mode: ShadowOverrideMode.disabled,
      );

      final updated = setMapPlacedElementShadowOverride(
        _baseMap(),
        instanceId: 'layer::1::1',
        shadowOverride: override,
      );

      expect(updated.placedElements.first.shadowOverride, override);
      expect(updated.placedElements.last.shadowOverride, isNull);
    });

    test('reset with null clears only the targeted override', () {
      final map = _baseMap().copyWith(
        placedElements: [
          _baseMap().placedElements.first.copyWith(
                shadowOverride: MapPlacedElementShadowOverride(
                  mode: ShadowOverrideMode.custom,
                  offsetX: 3,
                ),
              ),
          _baseMap().placedElements.last.copyWith(
                shadowOverride: MapPlacedElementShadowOverride(
                  mode: ShadowOverrideMode.disabled,
                ),
              ),
        ],
      );

      final updated = setMapPlacedElementShadowOverride(
        map,
        instanceId: 'layer::1::1',
        shadowOverride: null,
      );

      expect(updated.placedElements.first.shadowOverride, isNull);
      expect(
        updated.placedElements.last.shadowOverride,
        MapPlacedElementShadowOverride(mode: ShadowOverrideMode.disabled),
      );
    });

    test('rejects empty instance id', () {
      expect(
        () => setMapPlacedElementShadowOverride(
          _baseMap(),
          instanceId: ' ',
          shadowOverride: null,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects unknown instance id', () {
      expect(
        () => setMapPlacedElementShadowOverride(
          _baseMap(),
          instanceId: 'missing',
          shadowOverride: null,
        ),
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
