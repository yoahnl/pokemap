import 'dart:ui';

import 'package:flame_3d/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/spatial_ground.dart';
import 'package:map_render_3d/src/spatial_scene_view.dart';
import 'package:map_render_3d/src/spatial_terrain_geometry.dart';

void main() {
  test('fallback remains below every physical ground plane', () {
    final fixture = _fixture(offsets: [-.75, -.091796875]);
    final plan = SpatialGroundPlan(fixture.map, fixture.project);
    final positions =
        terrainMeshes(
          fixture.map.spatialScene!,
          const Color(0xff125588),
          const Color(0xff113344),
          paintedCells: plan.paintedCells,
          underlaySupports: plan.underlaySupportsFor(plan.resolve(0)),
          replacedGroundCells: plan.groundReplacementCells,
        ).expand((mesh) => mesh.surfaces).expand((surface) sync* {
          for (var index = 0; index < surface.positions.length; index += 3) {
            yield surface.positions.sublist(index, index + 3);
          }
        }).toList();
    expect(positions, hasLength(4));
    expect(positions.map((point) => point[1]), everyElement(5.75));
    expect(fixture.map.spatialScene!.heightLevels, [26]);
    expect(fixture.map.spatialScene!.heightAt(0, 0), 6.5);
  });

  test('ordinary and raised paint support their physical surface', () {
    for (final offsets in [
      [0.0],
      [.25],
    ]) {
      final fixture = _fixture(offsets: offsets);
      final plan = SpatialGroundPlan(fixture.map, fixture.project);
      expect(
        plan
            .underlaySupportsFor(plan.resolve(0))[(0, 0)]!
            .map((r) => r.heightOffset),
        everyElement(offsets.single),
      );
    }
  });

  test('a raised clipped raster does not leave a lower floating fallback', () {
    final fixture = _fixture(
      offsets: [.25],
      clip: SmartTileSpatialClip(left: 0, top: 0, right: 1, bottom: .25),
    );
    final plan = SpatialGroundPlan(fixture.map, fixture.project);
    final faces = spatialTerrainFaces(fixture.map.spatialScene!)
        .expand(
          (face) => spatialTerrainUnderlayFaces(
            face,
            plan.underlaySupportsFor(plan.resolve(0)),
          ),
        )
        .toList();
    expect(
      faces.expand((face) => face.positions).map((p) => p.y),
      everyElement(6.75),
    );
    expect(faces.map(_area).reduce((a, b) => a + b), closeTo(.25, 1e-12));
  });

  test('hidden paint does not lower the fallback', () {
    final fixture = _fixture(offsets: [-.75]);
    final layer = fixture.map.layers.single as SmartTileLayer;
    for (final hidden in [
      layer.copyWith(isVisible: false),
      layer.copyWith(opacity: 0),
    ]) {
      final plan = SpatialGroundPlan(
        fixture.map.copyWith(layers: [hidden]),
        fixture.project,
      );
      expect(plan.underlaySupportsFor(plan.resolve(0)), isEmpty);
    }
  });

  test('clipped wide paint lowers only the cells it actually covers', () {
    final fixture = _fixture(
      offsets: [-.75],
      width: 2,
      footprintWidth: 2,
      clip: SmartTileSpatialClip(left: .5, top: 0, right: 1, bottom: 1),
    );
    final plan = SpatialGroundPlan(fixture.map, fixture.project);
    expect(plan.underlaySupportsFor(plan.resolve(0)).keys, [(1, 0)]);
    expect(
      plan.underlaySupportsFor(plan.resolve(0))[(1, 0)]!.single.heightOffset,
      -.75,
    );
  });

  test('ground model masks do not lower the fallback beneath other cells', () {
    final fixture = _fixture(offsets: [-.75]);
    final preset = fixture.project.smartTileCatalog.presets.single.copyWith(
      id: 'replacement',
      rules: [
        SmartTileRule(
          id: 'replacement',
          centerMatch: const SmartTileSlotMatch.material('grass'),
          candidates: const [
            SmartTileCandidate(
              id: 'replacement',
              parts: [
                SmartTileVisualPart(
                  source: SmartTileVisualSource.model3d(
                    modelId: 'rock',
                    replacesGround: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
    final plan = SpatialGroundPlan(
      fixture.map.copyWith(
        layers: [
          (fixture.map.layers.single as SmartTileLayer).copyWith(
            id: 'replacement',
            presetId: preset.id,
          ),
          ...fixture.map.layers,
        ],
      ),
      fixture.project.copyWith(
        smartTileCatalog: ProjectSmartTileCatalog(
          atlases: fixture.project.smartTileCatalog.atlases,
          materials: fixture.project.smartTileCatalog.materials,
          presets: [...fixture.project.smartTileCatalog.presets, preset],
        ),
      ),
    );
    expect(plan.groundReplacementCells, {(0, 0)});
    expect(plan.underlaySupportsFor(plan.resolve(0)), isEmpty);
  });

  test(
    'a half-cell raster leaves the other half of the fallback unchanged',
    () {
      final fixture = _fixture(
        offsets: [-.75],
        includeFullBase: true,
        clip: SmartTileSpatialClip(left: 0, top: 0, right: .5, bottom: 1),
      );
      final plan = SpatialGroundPlan(fixture.map, fixture.project);
      final faces = spatialTerrainFaces(fixture.map.spatialScene!)
          .expand(
            (face) => spatialTerrainUnderlayFaces(
              face,
              plan.underlaySupportsFor(plan.resolve(0)),
            ),
          )
          .toList();
      expect(faces, hasLength(2));
      expect(
        faces
            .expand((face) => face.positions)
            .where((p) => p.x < .5)
            .map((p) => p.y),
        everyElement(5.75),
      );
      expect(
        faces
            .expand((face) => face.positions)
            .where((p) => p.x > .5)
            .map((p) => p.y),
        everyElement(6.5),
      );
      expect(faces.map(_area).reduce((a, b) => a + b), closeTo(1, 1e-12));
    },
  );

  test('overlapping footprints take the lowest offset without adding them', () {
    final face = spatialTerrainFaces(_fixture(offsets: [0]).map.spatialScene!)
        .single;
    final faces = spatialTerrainUnderlayFaces(face, {
      (0, 0): [_support(0, .75, -.25), _support(.5, 1, -.75)],
    }).toList();
    expect(faces.map(_area).reduce((a, b) => a + b), closeTo(1, 1e-12));
    for (final part in faces) {
      final x =
          part.positions.map((p) => p.x).reduce((a, b) => a + b) /
          part.positions.length;
      expect(
        part.positions.map((p) => p.y),
        everyElement(x < .5 ? 6.25 : 5.75),
      );
    }
  });

  test(
    'clipped raster does not add fallback outside its painted footprint',
    () {
      final fixture = _fixture(
        offsets: [-.75],
        clip: SmartTileSpatialClip(left: 0, top: 0, right: .5, bottom: 1),
      );
      final plan = SpatialGroundPlan(fixture.map, fixture.project);
      final faces = spatialTerrainFaces(fixture.map.spatialScene!)
          .expand(
            (face) => spatialTerrainUnderlayFaces(
              face,
              plan.underlaySupportsFor(plan.resolve(0)),
            ),
          )
          .toList();
      expect(faces.map(_area).reduce((a, b) => a + b), closeTo(.5, 1e-12));
      expect(
        faces.expand((face) => face.positions).map((p) => p.x),
        everyElement(lessThanOrEqualTo(.5)),
      );
    },
  );

  test(
    'fallback clipping interpolates a slope and preserves cliff geometry',
    () {
      final positions = [
        Vector3(0, 0, 0),
        Vector3(0, 1, .5),
        Vector3(0, 2, 1),
        Vector3(1, 3, 1),
        Vector3(1, 1, 0),
      ];
      final face = (
        cell: (0, 0),
        isTop: true,
        positions: positions,
        uvs: <Vector2>[],
      );
      final supports = {
        (0, 0): [_support(0, 1, 0), _support(0, .5, -.75)],
      };
      final faces = spatialTerrainUnderlayFaces(face, supports).toList();
      expect(faces.map(_area).reduce((a, b) => a + b), closeTo(1, 1e-12));
      for (final part in faces) {
        final x =
            part.positions.map((p) => p.x).reduce((a, b) => a + b) /
            part.positions.length;
        for (final point in part.positions) {
          expect(
            point.y,
            closeTo(point.x + 2 * point.z + (x < .5 ? -.75 : 0), 1e-12),
          );
        }
      }
      final wall = (
        cell: (0, 0),
        isTop: false,
        positions: positions,
        uvs: <Vector2>[],
      );
      expect(
        spatialTerrainUnderlayFaces(wall, supports).single.positions,
        same(positions),
      );
    },
  );

  test(
    'animated ground follows its current footprint instead of a fixed union',
    () {
      final fixture = _fixture(offsets: [-.75], width: 2, animated: true);
      final plan = SpatialGroundPlan(fixture.map, fixture.project);
      for (final (time, cell) in [(0, (0, 0)), (100, (1, 0)), (200, (0, 0))]) {
        final visuals = plan.resolve(time);
        expect(plan.underlaySupportsFor(visuals).keys, [cell]);
        expect(plan.paintedCellsFor(visuals), {cell});
      }
    },
  );
}

SpatialGroundUnderlay _support(double left, double right, double offset) => (
  footprint: [
    BorderGroundPoint(x: left, z: 0),
    BorderGroundPoint(x: left, z: 1),
    BorderGroundPoint(x: right, z: 1),
    BorderGroundPoint(x: right, z: 0),
  ],
  heightOffset: offset,
);

double _area(SpatialTerrainFace face) {
  var sum = 0.0;
  for (var i = 0; i < face.positions.length; i++) {
    final a = face.positions[i],
        b = face.positions[(i + 1) % face.positions.length];
    sum += a.x * b.z - b.x * a.z;
  }
  return sum.abs() / 2;
}

({MapData map, ProjectManifest project}) _fixture({
  required List<double> offsets,
  int width = 1,
  int footprintWidth = 1,
  SmartTileSpatialClip? clip,
  bool animated = false,
  bool includeFullBase = false,
}) {
  final catalog = ProjectSmartTileCatalog(
    atlases: [
      const ProjectSmartTileAtlas(
        id: 'atlas',
        name: 'Grass',
        tilesetId: 'grass',
        cellWidth: 16,
        cellHeight: 16,
        columns: 1,
        rows: 1,
      ),
      if (animated)
        const ProjectSmartTileAtlas(
          id: 'shifted',
          name: 'Shifted',
          tilesetId: 'grass',
          cellWidth: 16,
          cellHeight: 16,
          columns: 1,
          rows: 1,
          pixelOffsetX: 16,
        ),
    ],
    animations: [
      if (animated)
        const ProjectSmartTileAnimation(
          id: 'moving',
          name: 'Moving',
          frames: [
            ProjectSmartTileAnimationFrame(
              frame: SmartTileFrameRef(atlasId: 'atlas', column: 0, row: 0),
              durationMs: 100,
            ),
            ProjectSmartTileAnimationFrame(
              frame: SmartTileFrameRef(atlasId: 'shifted', column: 0, row: 0),
              durationMs: 100,
            ),
          ],
        ),
    ],
    materials: const [
      ProjectSmartTileMaterial(
        id: 'grass',
        name: 'Grass',
        connectionGroupId: 'grass',
      ),
    ],
    presets: [
      ProjectSmartTilePreset(
        id: 'grass',
        name: 'Grass',
        usage: SmartTileUsage.terrain,
        topology: SmartTileTopology.uniform,
        templateHint: SmartTileTemplateHint.simple,
        defaultMaterialId: 'grass',
        allowedMaterialIds: ['grass'],
        coveragePolicy: SmartTileCoveragePolicy.complete,
        coverageProfile: const SmartTileCoverageProfile(
          mode: SmartTileCoverageMode.template,
        ),
        transformPolicy: const SmartTileTransformPolicy(),
        rules: [
          SmartTileRule(
            id: 'grass',
            centerMatch: const SmartTileSlotMatch.material('grass'),
            candidates: [
              SmartTileCandidate(
                id: 'grass',
                parts: [
                  if (includeFullBase)
                    const SmartTileVisualPart(
                      source: SmartTileVisualSource.frame(
                        frame: SmartTileFrameRef(
                          atlasId: 'atlas',
                          column: 0,
                          row: 0,
                        ),
                      ),
                    ),
                  for (final offset in offsets)
                    SmartTileVisualPart(
                      source: animated
                          ? const SmartTileVisualSource.animation(
                              animationId: 'moving',
                            )
                          : const SmartTileVisualSource.frame(
                              frame: SmartTileFrameRef(
                                atlasId: 'atlas',
                                column: 0,
                                row: 0,
                              ),
                            ),
                      spatialHeightOffset: offset,
                      footprintWidth: footprintWidth,
                      spatialClip: clip,
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
  return (
    map: MapData(
      id: 'map',
      name: 'Map',
      version: ProjectVersion.v9,
      size: GridSize(width: width, height: 1),
      spatialScene: MapSpatialScene(
        width: width,
        depth: 1,
        heightLevels: List.filled(width, 26),
        levelHeight: .25,
        generateCliffs: false,
      ),
      layers: [
        SmartTileLayer(
          id: 'terrain',
          name: 'Terrain',
          presetId: 'grass',
          usage: SmartTileUsage.terrain,
          materialPalette: ['', 'grass'],
          field: SmartTileField.cell(
            semanticCells: [1, ...List.filled(width - 1, 0)],
          ),
        ),
      ],
    ),
    project: ProjectManifest(
      name: 'Project',
      version: ProjectVersion.v9,
      maps: const [],
      tilesets: const [],
      smartTileCatalog: catalog,
      settings: ProjectSettings(
        dimension: ProjectDimension.threeD,
        spatialCamera: SpatialCameraProfile(),
      ),
    ),
  );
}
