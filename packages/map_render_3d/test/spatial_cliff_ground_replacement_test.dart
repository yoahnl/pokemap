import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/spatial_ground.dart';
import 'package:map_render_3d/src/spatial_terrain_geometry.dart';

void main() {
  test('a measured cliff contact restores its source floor independently', () {
    final fixture = cliffFixture();
    final raw = fixture.project.toJson();
    final record = (raw['borderCatalog']['records'] as List).single as Map;
    for (final key in ['draft', 'latestPublished']) {
      (record[key] as Map)['definition']['groundBaseOffset'] = -.0625;
    }
    final project = ProjectManifest.fromJson(raw);
    final plan = SpatialGroundPlan(fixture.map, project);
    final scene = fixture.map.spatialScene!;
    final patches = spatialSurfacePatches(
      scene,
      groundReplacements: plan.borderGroundReplacements,
    ).where((patch) => patch.cell == (1, 1)).toList();
    expect(patches, isNotEmpty);
    expect(
      patches.expand((patch) => patch.corners).map((point) => point.y),
      everyElement(closeTo(1, .000001)),
    );
    expect(scene.heightAt(1, 1), 8.75);
    expect(fixture.map.spatialScene!.instances, scene.instances);
  });

  test('an applied cliff keeps its fractional native ground at the foot', () {
    final fixture = cliffFixture();
    final plan = SpatialGroundPlan(fixture.map, fixture.project);
    final scene = fixture.map.spatialScene!;
    final patches = spatialSurfacePatches(
      scene,
      groundReplacements: plan.borderGroundReplacements,
    ).where((patch) => patch.cell == (1, 1)).toList();
    expect(patches, isNotEmpty);
    expect(
      patches.expand((patch) => patch.corners).map((point) => point.y),
      everyElement(closeTo(1.0625, .000001)),
    );
    expect(
      patches.fold<double>(
        0,
        (area, patch) =>
            area + (patch.right - patch.left) * (patch.bottom - patch.top),
      ),
      closeTo(1, .000001),
    );
    expect(scene.heightAt(1, 1), 8.75);
    expect(
      spatialSurfacePatches(
            scene,
            groundReplacements: plan.borderGroundReplacements,
          )
          .where((patch) => patch.cell == (0, 1))
          .single
          .corners
          .map((point) => point.y),
      everyElement(1),
    );
  });

  test('a cliff footprint preserves lower land and unrelated upper land', () {
    final scene = MapSpatialScene(
      width: 3,
      depth: 1,
      heightLevels: [1, 5, 10],
      generateCliffs: false,
    );
    final index = indexSpatialBorderGroundReplacements(
      scene: scene,
      replacements: [
        (
          left: .5,
          top: 0.0,
          right: 2.5,
          bottom: 1.0,
          lowerHeight: 2.0,
          upperHeight: 9.0,
        ),
      ],
    );
    final patches = spatialSurfacePatches(
      scene,
      groundReplacements: index,
    ).toList();
    for (final patch in patches) {
      expect(
        patch.corners.map((point) => point.y),
        everyElement(switch (patch.cell.$1) {
          0 => 1,
          1 => 2,
          _ => 10,
        }),
      );
    }
    expect(
      patches.fold<double>(
        0,
        (area, patch) =>
            area + (patch.right - patch.left) * (patch.bottom - patch.top),
      ),
      3,
    );
  });

  test('stacked cliff profiles resolve the same floor in either order', () {
    final scene = MapSpatialScene(
      width: 1,
      depth: 1,
      heightLevels: [8],
      generateCliffs: false,
    );
    final replacements = [
      (
        left: 0.0,
        top: 0.0,
        right: 1.0,
        bottom: 1.0,
        lowerHeight: 4.0,
        upperHeight: 9.0,
      ),
      (
        left: 0.0,
        top: 0.0,
        right: 1.0,
        bottom: 1.0,
        lowerHeight: 1.0,
        upperHeight: 4.0,
      ),
    ];
    for (final order in [replacements, replacements.reversed.toList()]) {
      final index = indexSpatialBorderGroundReplacements(
        scene: scene,
        replacements: order,
      );
      expect(
        spatialSurfacePatches(
          scene,
          groundReplacements: index,
        ).single.corners.map((point) => point.y),
        everyElement(1),
      );
    }
  });

  test('generated neighbors end at the rendered foot of a cliff profile', () {
    final scene = MapSpatialScene(width: 2, depth: 1, heightLevels: [9, 9]);
    final index = indexSpatialBorderGroundReplacements(
      scene: scene,
      replacements: [
        (
          left: 0.0,
          top: 0.0,
          right: 1.0,
          bottom: 1.0,
          lowerHeight: 2.0,
          upperHeight: 9.0,
        ),
      ],
    );
    final wall =
        spatialTerrainFaces(
              scene,
              groundReplacements: index,
              repeatWalls: false,
            )
            .where(
              (face) =>
                  !face.isTop &&
                  face.cell == (1, 0) &&
                  face.positions.every((point) => point.x == 1),
            )
            .single;
    expect(
      wall.positions.map((point) => point.y),
      unorderedEquals([2, 2, 9, 9]),
    );
  });
}

({ProjectManifest project, MapData map}) cliffFixture() {
  final seed = BorderSignedInt64.fromInt(17);
  final defaults = BorderGenerationParams(
    irregularityPermille: 0,
    detailDensityPermille: 0,
    variationPermille: 1000,
    maxOverlapPx: 0,
    gapTolerancePx: 0,
    depthRows: 1,
  );
  final transforms = BorderTransformPolicy(
    allowFlipX: false,
    allowedQuarterTurns: const [0, 1, 2, 3],
  );
  final anchor = Model3dVector3(x: 0, y: 7.6875, z: 0);
  final roles = [
    BorderPrimitiveRole.lineCap,
    BorderPrimitiveRole.lineStraight,
    BorderPrimitiveRole.lineCorner,
  ];
  final project = ProjectManifest(
    name: 'Fractional cliff',
    version: ProjectVersion.v9,
    maps: const [
      ProjectMapEntry(id: 'map', name: 'Map', relativePath: 'maps/map.json'),
    ],
    tilesets: const [],
    settings: ProjectSettings(dimension: ProjectDimension.threeD),
    models3d: [
      ProjectModel3dEntry(
        id: 'cliff',
        name: 'Cliff',
        sourceAssetId: 'cliff-source',
        relativePath: 'assets/models3d/cliff.glb',
        inspection: Model3dInspection(
          bounds: Model3dBounds(
            min: Model3dVector3(x: -.5, y: 0, z: -.5),
            max: Model3dVector3(x: .5, y: 7.9375, z: .5),
          ),
          meshCount: 1,
          triangleCount: 16,
        ),
      ),
    ],
    borderCatalog: ProjectBorderCatalog(
      formatVersion: 5,
      records: [
        BorderBlueprintRecord(
          id: 'cliff',
          draft: BorderBlueprintDraft(
            baseRevision: 1,
            definition: BorderBlueprintDraftDefinition(
              name: 'Cliff',
              previewSeed: seed,
              template: BorderBlueprintTemplate.connectedLine,
              replacesGround: true,
              primitives: [
                for (final role in roles)
                  BorderPrimitiveDraft(
                    id: role.name,
                    sourceModelId: 'cliff',
                    role: role,
                    weight: 1,
                    transforms: transforms,
                    anchorWorld: anchor,
                  ),
              ],
              defaults: defaults,
              sortOrder: 0,
            ),
          ),
          latestPublished: BorderBlueprintRevision(
            revision: 1,
            definition: BorderBlueprintPublishedDefinition(
              name: 'Cliff',
              previewSeed: seed,
              template: BorderBlueprintTemplate.connectedLine,
              replacesGround: true,
              primitives: [
                for (final role in roles)
                  BorderPublishedPrimitive(
                    id: role.name,
                    sourceModelId: 'cliff',
                    role: role,
                    weight: 1,
                    transforms: transforms,
                    anchorWorld: anchor,
                  ),
              ],
              defaults: defaults,
              sortOrder: 0,
            ),
          ),
        ),
      ],
    ),
  );
  final map = MapData(
    version: ProjectVersion.v9,
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 4, height: 3),
    spatialScene: MapSpatialScene(
      width: 4,
      depth: 3,
      levelHeight: .25,
      heightLevels: [4, 4, 4, 4, 4, 35, 35, 4, 4, 4, 4, 4],
      generateCliffs: false,
    ),
    layers: [
      MapLayer.border(
        id: 'border',
        name: 'Cliff',
        content: BorderLayerContent(
          features: [
            BorderFeature(
              id: 'cliff',
              name: 'Cliff',
              blueprintId: 'cliff',
              seed: seed,
              geometry: BorderStrokeGeometry(
                strokes: [
                  BorderStroke(
                    id: 'line',
                    points: const [GridPos(x: 1, y: 1), GridPos(x: 2, y: 1)],
                    closed: false,
                  ),
                ],
              ),
              overrides: const [],
              keepOutRegions: const [],
            ),
          ],
        ),
      ),
    ],
  );
  final resolved = resolveSpatialBorderFeature(
    manifest: project,
    map: map,
    layerId: 'border',
    featureId: 'cliff',
  );
  expect(
    resolved.result.canApply,
    isTrue,
    reason: resolved.result.diagnostics.map((entry) => entry.code).join(', '),
  );
  return (
    project: project,
    map: applySpatialBorderFeaturePreview(
      map,
      manifest: project,
      proposedResult: resolved,
    ),
  );
}
