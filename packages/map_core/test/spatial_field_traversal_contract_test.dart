import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

MapGameplayZone routeZone(FieldActionZoneKind kind) => MapGameplayZone(
  id: 'route',
  kind: GameplayZoneKind.fieldAction,
  area: const MapRect(
    pos: GridPos(x: 1, y: 1),
    size: GridSize(width: 3, height: 1),
  ),
  fieldAction: FieldActionZonePayload(
    actionKind: kind,
    waterfall: kind == FieldActionZoneKind.waterfall
        ? const WaterfallZonePayload(
            entry: GridPos(x: 0, y: 0),
            path: [GridPos(x: 1, y: 0)],
            exit: GridPos(x: 2, y: 0),
            direction: MapConnectionDirection.east,
          )
        : null,
    whirlpool: kind == FieldActionZoneKind.whirlpool
        ? const WhirlpoolZonePayload(
            entry: GridPos(x: 0, y: 0),
            path: [GridPos(x: 1, y: 0)],
            exit: GridPos(x: 2, y: 0),
            direction: MapConnectionDirection.east,
          )
        : null,
  ),
);

MapData spatialMap(MapGameplayZone zone) => MapData(
  id: 'map',
  name: 'Map',
  version: ProjectVersion.v9,
  size: const GridSize(width: 5, height: 4),
  spatialScene: MapSpatialScene(width: 5, depth: 4),
  gameplayZones: [zone],
);

void main() {
  for (final kind in [
    FieldActionZoneKind.waterfall,
    FieldActionZoneKind.whirlpool,
  ]) {
    test('3D ${kind.name} retains its canonical closed route payload', () {
      final zone = routeZone(kind), map = spatialMap(routeZone(kind));
      expect(() => validateFieldActionZone(map, zone), returnsNormally);
      expect(MapGameplayZone.fromJson(zone.toJson()), zone);
      expect(
        () => validateFieldActionZone(
          map,
          zone.copyWith(
            fieldAction: kind == FieldActionZoneKind.waterfall
                ? zone.fieldAction!.copyWith(
                    waterfall: zone.fieldAction!.waterfall!.copyWith(
                      path: const [GridPos(x: 2, y: 0)],
                    ),
                  )
                : zone.fieldAction!.copyWith(
                    whirlpool: zone.fieldAction!.whirlpool!.copyWith(
                      path: const [GridPos(x: 2, y: 0)],
                    ),
                  ),
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  }

  test('3D darkness and Dive remain unsupported', () {
    for (final field in [
      const FieldActionZonePayload(
        actionKind: FieldActionZoneKind.darkness,
        darkness: DarknessZonePayload(opacity: .7),
      ),
      const FieldActionZonePayload(
        actionKind: FieldActionZoneKind.dive,
        dive: DiveZonePayload(role: DiveZoneRole.surface),
      ),
    ]) {
      final zone = routeZone(
        FieldActionZoneKind.waterfall,
      ).copyWith(fieldAction: field);
      expect(
        () => validateFieldActionZone(spatialMap(zone), zone),
        throwsA(isA<ValidationException>()),
      );
    }
  });

  test('only spatial traversal routes request the additive capability', () {
    final map = spatialMap(routeZone(FieldActionZoneKind.waterfall));
    expect(
      SpatialGameplayCapabilities.fieldTraversalCapabilityId,
      'map3d.field-traversal@1',
    );
    expect(SpatialGameplayCapabilities.requiresFieldTraversals([map]), isTrue);
    expect(
      SpatialGameplayCapabilities.requiresFieldTraversals([
        map.copyWith(spatialScene: null, version: ProjectVersion.v8),
      ]),
      isFalse,
    );
    expect(
      SpatialGameplayCapabilities.requiresFieldTraversals([
        map.copyWith(gameplayZones: const []),
      ]),
      isFalse,
    );
    expect(
      SpatialGameplayCapabilities.requiresFieldTraversals([
        spatialMap(routeZone(FieldActionZoneKind.whirlpool)),
      ]),
      isTrue,
    );
  });
}
