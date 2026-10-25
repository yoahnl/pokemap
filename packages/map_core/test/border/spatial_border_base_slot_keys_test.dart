import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../support/spatial_border_ground_surface_fixture.dart';

void main() {
  test('logical spatial slots include straights reserved by wide corners', () {
    final fixture = spatialBorderFixture();
    final raw = encodeBorderBlueprintRecordJson(
      fixture.project.borderCatalog.records.single,
      formatVersion: 13,
    );
    for (final key in ['draft', 'latestPublished']) {
      for (final primitive
          in ((raw[key] as Map)['definition'] as Map)['primitives'] as List) {
        if (primitive['role'] == 'lineCorner') primitive['cornerJoinCells'] = 1;
      }
    }
    final project = fixture.project.copyWith(
      borderCatalog: ProjectBorderCatalog(
        formatVersion: 13,
        records: [decodeBorderBlueprintRecordJson(raw, formatVersion: 13)],
      ),
    );
    final result = resolveSpatialBorderFeature(
      manifest: project,
      map: fixture.map,
      layerId: 'border',
      featureId: 'fence',
    );
    expect(result.result.canApply, true);
    expect(result.result.materialization!.spatialPlacements.length, 3);
    final slots = resolveSpatialBorderFeatureBaseSlotKeys(
      manifest: project,
      map: fixture.map,
      layerId: 'border',
      featureId: 'fence',
    );
    expect(slots, hasLength(5));
    expect(
      slots,
      containsAll(
        result.result.materialization!.spatialPlacements.map(
          (placement) => placement.slotKey,
        ),
      ),
    );
    expect(() => slots.add('invented'), throwsUnsupportedError);
  });

  test(
    'logical spatial slots reject a missing feature and mismatched region size',
    () {
      final fixture = spatialBorderFixture();
      expect(
        () => resolveSpatialBorderFeatureBaseSlotKeys(
          manifest: fixture.project,
          map: fixture.map,
          layerId: 'border',
          featureId: 'missing',
        ),
        throwsA(isA<ValidationException>()),
      );
      final map = updateBorderFeatureGeometry(
        fixture.map,
        layerId: 'border',
        featureId: 'fence',
        geometry: BorderRegionGeometry(
          width: 2,
          height: 2,
          cells: [true, true, true, true],
        ),
      );
      expect(
        () => resolveSpatialBorderFeatureBaseSlotKeys(
          manifest: fixture.project,
          map: map,
          layerId: 'border',
          featureId: 'fence',
        ),
        throwsA(isA<ValidationException>()),
      );
    },
  );

  test(
    'logical region identities survive persistence without depending on output',
    () {
      final fixture = spatialBorderFixture();
      final map = updateBorderFeatureGeometry(
        fixture.map,
        layerId: 'border',
        featureId: 'fence',
        geometry: BorderRegionGeometry(
          width: 6,
          height: 6,
          cells: [
            for (var z = 0; z < 6; z++)
              for (var x = 0; x < 6; x++) x >= 1 && x < 4 && z >= 1 && z < 4,
          ],
        ),
      );
      final slots = resolveSpatialBorderFeatureBaseSlotKeys(
        manifest: fixture.project,
        map: map,
        layerId: 'border',
        featureId: 'fence',
      );
      expect(slots, hasLength(12));
      expect(
        resolveSpatialBorderFeatureBaseSlotKeys(
          manifest: ProjectManifest.fromJson(
            jsonDecode(jsonEncode(fixture.project.toJson())),
          ),
          map: MapData.fromJson(jsonDecode(jsonEncode(map.toJson()))),
          layerId: 'border',
          featureId: 'fence',
        ),
        slots,
      );
    },
  );
}
