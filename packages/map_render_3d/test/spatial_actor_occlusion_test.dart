import 'dart:typed_data';

import 'package:flame_3d/core.dart';
import 'package:flame_3d/resources.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/spatial_actor_occlusion.dart';

void main() {
  test('actor occlusion uses authored geometry, local clock and terrain without replacing ground', () {
    final fixture = _fixture();
    final plan = SpatialActorOcclusionPlan(fixture.map, fixture.project);
    expect(plan.resolve(5000), isEmpty);
    final entered = plan.resolve(
      5000,
      stateForCell: (layer, x, y, global) => (active: x == 0, elapsedMs: 0),
    );
    expect(entered, hasLength(1));
    expect(
      (entered.single.x, entered.single.y, entered.single.z),
      (.5, 3.0, 1.125),
    );
    expect((entered.single.width, entered.single.height), (2.0, 2.0));
    expect(entered.single.visual.sourceRect.x, 0);
    final held = plan.resolve(
      5000,
      stateForCell: (layer, x, y, global) => (active: x == 0, elapsedMs: 500),
    );
    expect(held.single.visual.sourceRect.x, 96);
    expect(held.single.id, entered.single.id);
    expect(
      plan.resolve(
        5000,
        stateForCell: (layer, x, y, global) => (active: false, elapsedMs: 0),
      ),
      isEmpty,
    );
    expect(fixture.map.spatialScene!.instances, isEmpty);
    expect(fixture.map.spatialScene!.heightLevels, [12, 12]);
  });

  test('contact remains anchored to its authored cell on sloped ground', () {
    final fixture = _fixture();
    final map = fixture.map.copyWith(
      spatialScene: fixture.map.spatialScene!.copyWith(
        terrainSurfaces: SpatialTerrainSurfaceSet(
          surfaces: [
            SpatialTerrainSurface(
              id: 'slope',
              x: 0,
              z: 0,
              height: 1,
              gradientX: .25,
              gradientZ: .5,
              footprints: [
                BorderGroundFootprint(
                  points: [
                    BorderGroundPoint(x: 0, z: 0),
                    BorderGroundPoint(x: 2, z: 0),
                    BorderGroundPoint(x: 2, z: 1),
                    BorderGroundPoint(x: 0, z: 1),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
    final plan = SpatialActorOcclusionPlan(map, fixture.project);
    final centered = plan
        .resolve(
          5000,
          stateForCell: (layer, x, y, global) =>
              (active: x == 0, elapsedMs: 200),
        )
        .single;
    expect((centered.x, centered.y, centered.z), (.5, 1.375, 1.125));
    final nextFrame = plan
        .resolve(
          5000,
          stateForCell: (layer, x, y, global) => (active: x == 0, elapsedMs: 0),
        )
        .single;
    expect((nextFrame.x, nextFrame.y, nextFrame.z), (.5, 1.375, 1.125));
    expect(nextFrame.z, centered.z);
    expect(nextFrame.id, centered.id);
    expect(nextFrame.visual.sourceRect, isNot(centered.visual.sourceRect));
  });

  test('billboard cache updates frames and camera without recreating meshes, then removes departed cells', () {
    final fixture = _fixture();
    final plan = SpatialActorOcclusionPlan(fixture.map, fixture.project);
    final texture = Texture(ByteData(128 * 32 * 4), width: 128, height: 32);
    final cache = SpatialActorOcclusionBillboards();
    List<SpatialActorOcclusionVisual> frame(int time) => plan.resolve(
      time,
      stateForCell: (layer, x, y, global) => (active: x == 0, elapsedMs: time),
    );
    final first = cache.sync(
      frame(0),
      {'tiles': texture},
      camera: SpatialCameraProfile(pitchDegrees: 45),
      offset: const Offset(10, -4),
    );
    expect(first.added, hasLength(1));
    final component = cache.components.values.single;
    expect(component.position, Vector3(10.5, 3, -2.875));
    expect(component.scale.y, closeTo(1.41421356, 1e-7));
    final next = cache.sync(frame(70), {
      'tiles': texture,
    }, camera: SpatialCameraProfile(pitchDegrees: 60));
    expect(next.added, isEmpty);
    expect(next.removed, isEmpty);
    expect(cache.components.values.single, same(component));
    expect(component.scale.y, closeTo(2, 1e-7));
    expect(cache.materials.values.single.uvRect.x, .25);
    final removed = cache.sync([], {
      'tiles': texture,
    }, camera: SpatialCameraProfile());
    expect(removed.removed.single, same(component));
    expect(cache.components, isEmpty);
  });
}

({MapData map, ProjectManifest project}) _fixture() {
  final layer = SmartTileLayer(
    id: 'grass',
    name: 'Grass',
    presetId: 'grass',
    usage: SmartTileUsage.path,
    animationActivation: SmartTileAnimationActivation.onEnter,
    materialPalette: const ['', 'grass'],
    field: const SmartTileField.cell(semanticCells: [1, 1]),
  );
  final map = MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 2, height: 1),
    layers: [layer],
    spatialScene: MapSpatialScene(
      width: 2,
      depth: 1,
      heightLevels: [12, 12],
      levelHeight: .25,
    ),
  );
  final project = ProjectManifest(
    name: 'Test',
    settings: const ProjectSettings(
      tileWidth: 32,
      tileHeight: 32,
      dimension: ProjectDimension.threeD,
    ),
    maps: const [],
    tilesets: const [],
    smartTileCatalog: ProjectSmartTileCatalog(
      materials: const [
        ProjectSmartTileMaterial(
          id: 'grass',
          name: 'Grass',
          connectionGroupId: 'grass',
          pathSurfaceKind: PathSurfaceKind.tallGrass,
        ),
      ],
      atlases: const [
        ProjectSmartTileAtlas(
          id: 'atlas',
          name: 'Atlas',
          tilesetId: 'tiles',
          columns: 4,
          rows: 1,
        ),
      ],
      animations: [
        ProjectSmartTileAnimation(
          id: 'rustle',
          name: 'Rustle',
          loop: SmartTileAnimationLoop.once,
          sync: SmartTileAnimationSync.perCell,
          frames: [
            for (var i = 0; i < 4; i++)
              ProjectSmartTileAnimationFrame(
                frame: SmartTileFrameRef(atlasId: 'atlas', column: i, row: 0),
                durationMs: 67,
              ),
          ],
        ),
      ],
      presets: [
        ProjectSmartTilePreset(
          id: 'grass',
          name: 'Grass',
          usage: SmartTileUsage.path,
          topology: SmartTileTopology.uniform,
          coveragePolicy: SmartTileCoveragePolicy.complete,
          coverageProfile: const SmartTileCoverageProfile(
            mode: SmartTileCoverageMode.template,
          ),
          transformPolicy: const SmartTileTransformPolicy(),
          defaultMaterialId: 'grass',
          allowedMaterialIds: const ['grass'],
          rules: [
            SmartTileRule(
              id: 'fill',
              centerMatch: const SmartTileSlotMatch.material('grass'),
              candidates: const [
                SmartTileCandidate(
                  id: 'fill',
                  parts: [
                    SmartTileVisualPart(
                      channel: SmartTileRenderChannel.actorOcclusion,
                      offsetUnit: SmartTileOffsetUnit.pixel,
                      offsetX: -16,
                      offsetY: 20,
                      footprintWidth: 2,
                      footprintHeight: 2,
                      source: SmartTileVisualSource.animation(
                        animationId: 'rustle',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );
  return (map: map, project: project);
}
