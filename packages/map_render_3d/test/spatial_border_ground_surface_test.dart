import 'dart:typed_data';

import 'package:flame_3d/resources.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/spatial_ground.dart';
import 'package:map_render_3d/src/spatial_terrain_geometry.dart';

import '../../map_core/test/support/spatial_border_ground_surface_fixture.dart';

void main() {
  test('a border terrain preserves the order of overlapping raster parts', () {
    final own = layeredSurfaces(['a'], frontFirst: false);
    final catalog = own.project.smartTileCatalog;
    final base = catalog.presets.first;
    final overlay =
        catalog.presets.last.rules.single.candidates.single.parts.single;
    final project = own.project.copyWith(
      smartTileCatalog: ProjectSmartTileCatalog(
        atlases: catalog.atlases,
        materials: catalog.materials,
        presets: [
          base.copyWith(
            rules: [
              for (final rule in base.rules)
                rule.copyWith(
                  candidates: [
                    for (final candidate in rule.candidates)
                      candidate.copyWith(
                        parts: [
                          candidate.parts.single,
                          overlay.copyWith(drawOrder: 1),
                        ],
                      ),
                  ],
                ),
            ],
          ),
          ...catalog.presets.skip(1),
        ],
      ),
    );
    ProjectValidator.validate(project);
    final plan = SpatialGroundPlan(own.map, project);
    final visuals = plan.resolve(0);
    final cells = <(int, int), List<SpatialGroundVisual>>{};
    for (final visual in visuals) {
      cells
          .putIfAbsent((visual.visual.cellX, visual.visual.cellY), () => [])
          .add(visual);
    }
    expect(cells, isNotEmpty);
    for (final parts in cells.values) {
      expect(parts.map((p) => p.visual.sourceRect.x), [0, 16]);
      expect(parts.last.height, greaterThan(parts.first.height));
    }
  });

  for (final labels in [
    ['a', 'b'],
    ['a', 'b', 'a'],
  ]) {
    for (final frontFirst in [false, true]) {
      test(
        'coplanar Border composition keeps $labels (front first: $frontFirst)',
        () {
          final own = layeredSurfaces(labels, frontFirst: frontFirst);
          final plan = SpatialGroundPlan(own.map, own.project);
          final visuals = plan.resolve(0);
          final colors = <int>[];
          final priorities = <double>[];
          for (final item in visuals) {
            if (colors.isEmpty || colors.last != item.visual.sourceRect.x) {
              colors.add(item.visual.sourceRect.x);
              priorities.add(item.height);
            }
          }
          final expected = (frontFirst ? labels.reversed : labels)
              .map((label) => label == 'a' ? 0 : 16)
              .toList();
          expect(colors, expected);
          expect(priorities, orderedEquals(priorities.toList()..sort()));
        },
      );
    }
  }

  test('a cliff ground plane crosses a ramp without becoming a slope', () {
    final scene = MapSpatialScene(
      width: 3,
      depth: 1,
      heightLevels: [0, 0, 4],
      navigation: SpatialNavigationProfile(
        ramps: [
          SpatialRamp(
            id: 'ramp',
            x: 1,
            z: 0,
            width: 1,
            depth: 1,
            lowLevel: 0,
            highLevel: 4,
            direction: SpatialRampDirection.east,
          ),
        ],
      ),
    );
    final triangle = BorderGroundFootprint(
      points: [
        BorderGroundPoint(x: 1, z: 0),
        BorderGroundPoint(x: 2, z: 0),
        BorderGroundPoint(x: 1, z: 1),
      ],
    );
    final patches = spatialFlatGroundPatches(
      scene,
      surface: SpatialFlatGroundSurface(
        height: 2,
        footprints: [triangle, triangle],
      ),
    ).toList();
    expect(patches, isNotEmpty);
    var area = 0.0;
    for (final patch in patches) {
      final points = patch.corners;
      var sum = 0.0;
      for (var i = 0; i < points.length; i++) {
        final a = points[i], b = points[(i + 1) % points.length];
        sum += a.x * b.z - b.x * a.z;
        expect(a.y, 2);
      }
      area += sum.abs() / 2;
      expect(patch.ramp, isNull);
    }
    expect(area, .5);
    expect(scene.navigation.ramps, hasLength(1));
  });

  test(
    'border plateaus reuse terrain frames batching and unchanged navigation',
    () {
      final own = surfaceFixture();
      final map = applySpatialBorderFeaturePreview(
        own.map,
        manifest: own.project,
        proposedResult: resolveSpatialBorderFeature(
          manifest: own.project,
          map: own.map,
          layerId: 'border',
          featureId: 'fence',
        ),
      );
      final plan = SpatialGroundPlan(map, own.project);
      final visuals = plan.resolve(0);
      expect(visuals, isNotEmpty);
      expect(plan.imageIds, {'grass'});
      expect(plan.resolve(0), same(visuals));
      var totalArea = 0.0;
      for (final item in visuals) {
        final flat = plan.flatSurfaceFor(item.visual);
        expect(flat, isNotNull);
        final vertices = spatialGroundVertices(
          item.visual.geometry,
          scene: map.spatialScene,
          flatSurface: flat,
        );
        expect(vertices, isNotEmpty);
        for (var start = 0; start < vertices.length; start += 4) {
          var sum = 0.0;
          for (var i = 0; i < 4; i++) {
            final a = vertices[start + i].position;
            final b = vertices[start + (i + 1) % 4].position;
            sum += a.x * b.z - b.x * a.z;
          }
          totalArea += sum.abs() / 2;
        }
        for (final vertex in vertices) {
          expect(vertex.position.y, flat!.height);
          expect(
            vertex.texCoord.x,
            closeTo(vertex.position.x - item.visual.cellX, 1e-6),
          );
          expect(
            vertex.texCoord.y,
            closeTo(vertex.position.z - item.visual.cellY, 1e-6),
          );
        }
      }
      expect(
        totalArea,
        closeTo(map.spatialScene!.instances.length * 2 * .02, 1e-6),
      );
      final meshes = spatialGroundMeshes(
        visuals,
        {'grass': Texture(ByteData(16 * 16 * 4), width: 16, height: 16)},
        scene: map.spatialScene,
        flatSurfaceFor: plan.flatSurfaceFor,
      ).toList();
      expect(meshes, hasLength(1));
      expect(meshes.single.surfaces, hasLength(1));
      expect(plan.underlaySupportsFor(visuals), isEmpty);
      expect(map.spatialScene!.navigation, own.map.spatialScene!.navigation);
    },
  );
}

({MapData map, ProjectManifest project}) layeredSurfaces(
  List<String> labels, {
  required bool frontFirst,
}) {
  final own = surfaceFixture();
  final base = own.project.smartTileCatalog;
  final other = base.presets.single.copyWith(
    id: 'other-terrain',
    defaultMaterialId: 'other',
    allowedMaterialIds: ['other'],
    rules: [
      for (final rule in base.presets.single.rules)
        rule.copyWith(
          id: 'other',
          centerMatch: SmartTileSlotMatch.material('other'),
          candidates: [
            for (final candidate in rule.candidates)
              candidate.copyWith(
                parts: [
                  for (final part in candidate.parts)
                    part.copyWith(
                      source: SmartTileVisualSource.frame(
                        frame: SmartTileFrameRef(
                          atlasId: 'grass-atlas',
                          column: 1,
                          row: 0,
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
    ],
  );
  final records = <BorderBlueprintRecord>[];
  for (final label in ['a', 'b']) {
    final raw = encodeBorderBlueprintRecordJson(
      own.project.borderCatalog.records.single,
      formatVersion: 9,
    );
    raw['id'] = 'cliff-$label';
    for (final state in ['draft', 'latestPublished']) {
      for (final primitive
          in ((raw[state] as Map)['definition'] as Map)['primitives'] as List) {
        final surface = (primitive['groundSurfaces'] as List).first as Map;
        surface['sourceSmartTilePresetId'] = label == 'a'
            ? 'grass-terrain'
            : 'other-terrain';
        surface['materialId'] = label == 'a' ? 'grass' : 'other';
        primitive['groundSurfaces'] = [surface];
      }
    }
    records.add(decodeBorderBlueprintRecordJson(raw, formatVersion: 9));
  }
  final project = own.project.copyWith(
    borderCatalog: ProjectBorderCatalog(formatVersion: 9, records: records),
    smartTileCatalog: ProjectSmartTileCatalog(
      atlases: [base.atlases.single.copyWith(columns: 2)],
      materials: [
        ...base.materials,
        ProjectSmartTileMaterial(
          id: 'other',
          name: 'Other',
          connectionGroupId: 'other',
        ),
      ],
      presets: [...base.presets, other],
    ),
  );
  final original =
      (own.map.layers.single as BorderLayer).content.features.single;
  var map = own.map.copyWith(
    properties: {
      'tileLayerOrder': frontFirst ? 'front_to_back' : 'bottom_to_top',
    },
    layers: [
      for (var i = 0; i < labels.length; i++)
        MapLayer.border(
          id: 'layer-$i',
          name: 'Layer $i',
          content: BorderLayerContent(
            features: [
              BorderFeature(
                id: 'feature-$i',
                name: 'Feature $i',
                blueprintId: 'cliff-${labels[i]}',
                seed: original.seed,
                geometry: original.geometry,
                overrides: [],
                keepOutRegions: [],
              ),
            ],
          ),
        ),
    ],
  );
  for (var i = 0; i < labels.length; i++) {
    map = applySpatialBorderFeaturePreview(
      map,
      manifest: project,
      proposedResult: resolveSpatialBorderFeature(
        manifest: project,
        map: map,
        layerId: 'layer-$i',
        featureId: 'feature-$i',
      ),
    );
  }
  return (map: map, project: project);
}
