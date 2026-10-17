import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'spatial_border_ground_footprint_test.dart' as fixtures;
import 'spatial_border_resolution_test.dart' as spatial;
import '../support/spatial_border_ground_surface_fixture.dart';

void main() {
  for (final field in [
    'height',
    'materialId',
    'sourceSmartTilePresetId',
    'footprints',
  ]) {
    test('publication identity includes ground surface $field', () {
      String fingerprint(Map<String, Object?> raw) =>
          computeBorderPublicationCandidateFingerprint(
            blueprintId: 'cliff',
            definition: decodeBorderBlueprintRecordJson(
              raw,
              formatVersion: 9,
            ).latestPublished!.definition,
            resolverVersion: 1,
          );
      final before = record();
      final changed = record();
      final primitive =
          (((changed['latestPublished'] as Map)['definition']
                          as Map)['primitives']
                      as List)
                  .single
              as Map;
      final surface = (primitive['groundSurfaces'] as List).first as Map;
      switch (field) {
        case 'height':
          surface['height'] = .25;
        case 'materialId':
          surface['materialId'] = 'sand';
        case 'sourceSmartTilePresetId':
          surface['sourceSmartTilePresetId'] = 'sand-terrain';
        case 'footprints':
          ((surface['footprints'] as List).first as List).first['x'] = -.25;
      }
      expect(fingerprint(changed), isNot(fingerprint(before)));
      expect(fingerprint(record()), fingerprint(before));
    });
  }

  test(
    'a reusable cliff retains two local ground planes in both revisions',
    () {
      final raw = record();
      final decoded = decodeBorderBlueprintRecordJson(raw, formatVersion: 9);
      expect(encodeBorderBlueprintRecordJson(decoded, formatVersion: 9), raw);
      expect(minimumBorderCatalogFormatVersionForRecord(decoded), 9);
    },
  );

  test(
    'local ground planes follow the primitive pose without following ramps',
    () {
      final own = surfaceFixture();
      final applied = applySpatialBorderFeaturePreview(
        own.map,
        manifest: own.project,
        proposedResult: spatial.resolve(own.project, own.map),
      );
      final surfaces = resolveSpatialBorderGroundSurfaces(
        manifest: own.project,
        map: applied,
      );
      expect(surfaces.length, applied.spatialScene!.instances.length * 2);
      for (var i = 0; i < applied.spatialScene!.instances.length; i++) {
        final instance = applied.spatialScene!.instances[i];
        expect(surfaces[i * 2].height, instance.position.y);
        expect(surfaces[i * 2 + 1].height, instance.position.y + .5);
      }
      final project = own.project.copyWith(
        models3d: [
          own.project.models3d.single.copyWith(
            scale: .5,
            pivot: Model3dVector3(x: .05, y: .2, z: -.02),
          ),
        ],
      );
      final map = applied.copyWith(
        spatialScene: applied.spatialScene!.copyWith(
          instances: [
            for (final instance in applied.spatialScene!.instances)
              instance.copyWith(
                position: Model3dVector3(x: 2, y: 3, z: 2),
                rotationDegrees: 90,
                scale: .5,
              ),
          ],
        ),
      );
      final changed = resolveSpatialBorderGroundSurfaces(
        manifest: project,
        map: map,
      );
      expect(changed.first.height, 2.95);
      expect(changed[1].height, 3.075);
      final points = changed.first.footprints.single.points;
      for (final (index, x, z) in [
        (0, 1.98, 2.0375),
        (1, 1.98, 1.9875),
        (2, 2.03, 2.0375),
      ]) {
        expect(points[index].x, closeTo(x, 1e-10));
        expect(points[index].z, closeTo(z, 1e-10));
      }
      expect(map.spatialScene!.navigation, applied.spatialScene!.navigation);
      expect(
        map.spatialScene!.heightLevels,
        applied.spatialScene!.heightLevels,
      );
    },
  );

  test('publication requires an existing allowed raster terrain material', () {
    final own = surfaceFixture();
    final definition =
        own.project.borderCatalog.records.single.latestPublished!.definition;
    expect(
      validateSpatialBorderBlueprint(
        blueprintId: 'fence',
        definition: definition,
        manifest: own.project,
      ).hasErrors,
      false,
    );
    final missing = validateSpatialBorderBlueprint(
      blueprintId: 'fence',
      definition: definition,
      manifest: own.project.copyWith(
        smartTileCatalog: const ProjectSmartTileCatalog.empty(),
      ),
    );
    expect(
      missing.diagnostics.map((d) => d.code),
      contains('border.spatial.ground_surface_preset_invalid'),
    );
    expect(
      missing.diagnostics.map((d) => d.code),
      contains('border.spatial.ground_surface_material_missing'),
    );
  });

  test('a Border surface rejects a source that already forces a world height', () {
    final own = surfaceFixture();
    final catalog = own.project.smartTileCatalog;
    final changed = own.project.copyWith(smartTileCatalog: ProjectSmartTileCatalog(
      atlases: catalog.atlases, materials: catalog.materials,
      presets: [for (final preset in catalog.presets) preset.copyWith(rules: [
        for (final rule in preset.rules) rule.copyWith(candidates: [
          for (final candidate in rule.candidates) candidate.copyWith(parts: [
            for (final part in candidate.parts) part.copyWith(spatialFollowTerrain: false),
          ]),
        ]),
      ])],
    ));
    final result = validateSpatialBorderBlueprint(blueprintId: 'fence',
      definition: own.project.borderCatalog.records.single.latestPublished!.definition,
      manifest: changed);
    expect(result.diagnostics.map((diagnostic) => diagnostic.code),
      contains('border.spatial.ground_surface_raster_terrain_required'));
  });

  test('project validation protects plateau sources after publication', () {
    final own = surfaceFixture();
    expect(() => ProjectValidator.validate(own.project), returnsNormally);
    expect(
      () => ProjectValidator.validate(
        own.project.copyWith(
          smartTileCatalog: const ProjectSmartTileCatalog.empty(),
        ),
      ),
      throwsA(
        isA<ValidationException>().having(
          (e) => e.code,
          'code',
          'border.spatial.ground_surface_preset_invalid',
        ),
      ),
    );
  });

  test('ground planes cannot silently enter an older border format', () {
    expect(
      () => decodeBorderBlueprintRecordJson(record(), formatVersion: 8),
      throwsA(isA<FormatException>()),
    );
  });

  for (final invalid in <String, Object?>{
    'height': double.nan,
    'sourceSmartTilePresetId': '',
    'materialId': '',
    'footprints': <Object?>[],
    'unexpected': true,
  }.entries) {
    test('ground planes reject invalid ${invalid.key}', () {
      final raw = record();
      for (final key in ['draft', 'latestPublished']) {
        final primitive =
            ((((raw[key] as Map)['definition'] as Map)['primitives'] as List)
                    .single
                as Map);
        (primitive['groundSurfaces'] as List).first[invalid.key] =
            invalid.value;
      }
      expect(
        () => decodeBorderBlueprintRecordJson(raw, formatVersion: 9),
        throwsA(isA<FormatException>()),
      );
    });
  }
}

Map<String, Object?> record() {
  final raw = fixtures.record();
  for (final key in ['draft', 'latestPublished']) {
    final primitive =
        ((((raw[key] as Map)['definition'] as Map)['primitives'] as List).single
            as Map);
    primitive['groundSurfaces'] = [
      for (final height in [0.0, 1.0])
        <String, Object?>{
          'sourceSmartTilePresetId': 'grass-terrain',
          'materialId': 'grass',
          'height': height,
          'footprints': [
            [
              {'x': -0.5, 'z': -0.5},
              {'x': 0.5, 'z': -0.5},
              {'x': -0.5, 'z': 0.5},
            ],
          ],
        },
    ];
  }
  return raw;
}
