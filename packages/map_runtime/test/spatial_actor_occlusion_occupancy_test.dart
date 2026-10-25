import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/spatial/spatial_smart_tile_animation_controller.dart';

import 'support/spatial_smart_tile_fixture.dart';

void main() {
  test('review pattern-only occlusion animation uses the contact clock', () {
    final fixture = spatialRasterGrassFixture();
    final catalog = fixture.project.smartTileCatalog;
    final preset = catalog.presets.single;
    final rule = preset.rules.single;
    final candidate = rule.candidates.single;
    final animatedPart = candidate.parts.single.copyWith(
      channel: SmartTileRenderChannel.actorOcclusion,
    );
    final map = fixture.map.copyWith(
      layers: [
        (fixture.map.layers.single as SmartTileLayer).copyWith(
          patternStrokes: [
            SmartTilePatternStroke(
              id: 'contact',
              patternId: 'contact',
              cells: [GridPos(x: 4, y: 5)],
            ),
          ],
        ),
      ],
    );
    final project = fixture.project.copyWith(
      smartTileCatalog: ProjectSmartTileCatalog(
        atlases: catalog.atlases,
        animations: catalog.animations,
        materials: [
          catalog.materials.single.copyWith(
            pathSurfaceKind: PathSurfaceKind.tallGrass,
          ),
        ],
        presets: [
          preset.copyWith(
            rules: [
              rule.copyWith(
                candidates: [
                  candidate.copyWith(
                    parts: [
                      candidate.parts.single.copyWith(
                        source: SmartTileVisualSource.frame(
                          frame: SmartTileFrameRef(
                            atlasId: 'raster-atlas',
                            column: 0,
                            row: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
        patterns: [
          ProjectSmartTilePattern(
            id: 'contact',
            name: 'Contact',
            usage: SmartTileUsage.path,
            width: 1,
            height: 1,
            cells: [
              SmartTilePatternCell(x: 0, y: 0, parts: [animatedPart]),
            ],
          ),
        ],
      ),
    );
    final controller = SpatialSmartTileAnimationController(
      map: map,
      project: project,
    );
    controller.synchronizeActorOccupancy({'hero': GridPos(x: 3, y: 5)});
    controller.synchronizeActorOccupancy({'hero': GridPos(x: 4, y: 5)});
    controller.update(.1);
    final state = controller.actorOcclusionStateForCell(
      layerId: 'grass',
      cellX: 4,
      cellY: 5,
      globalElapsedMs: 5000,
    );
    expect(state, (active: true, elapsedMs: 100));
  });
  test(
    'occupants initialize at rest, enter at zero, hold and leave independently',
    () {
      final fixture = spatialRasterGrassFixture();
      final catalog = fixture.project.smartTileCatalog;
      final preset = catalog.presets.single;
      final rule = preset.rules.single;
      final candidate = rule.candidates.single;
      final project = fixture.project.copyWith(
        smartTileCatalog: ProjectSmartTileCatalog(
          atlases: catalog.atlases,
          animations: catalog.animations,
          materials: [
            catalog.materials.single.copyWith(
              pathSurfaceKind: PathSurfaceKind.tallGrass,
            ),
          ],
          presets: [
            preset.copyWith(
              rules: [
                rule.copyWith(
                  candidates: [
                    candidate.copyWith(
                      parts: [
                        candidate.parts.single.copyWith(
                          channel: SmartTileRenderChannel.actorOcclusion,
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
      final controller = SpatialSmartTileAnimationController(
        map: fixture.map,
        project: project,
      );
      ({bool active, int elapsedMs}) at(int x) =>
          controller.actorOcclusionStateForCell(
            layerId: 'grass',
            cellX: x,
            cellY: 5,
            globalElapsedMs: 5000,
          );
      expect(at(4).active, isFalse);
      controller.synchronizeActorOccupancy({
        'hero': const GridPos(x: 4, y: 5),
        'companion:one': const GridPos(x: 5, y: 5),
      });
      expect(at(4), (active: true, elapsedMs: 200));
      expect(at(5), (active: true, elapsedMs: 200));
      controller.synchronizeActorOccupancy({
        'hero': const GridPos(x: 5, y: 5),
        'companion:one': const GridPos(x: 5, y: 5),
      });
      expect(at(4).active, isFalse);
      expect(at(5), (active: true, elapsedMs: 0));
      controller.update(.1);
      expect(at(5).elapsedMs, 100);
      controller.synchronizeActorOccupancy({
        'hero': const GridPos(x: 5, y: 5),
        'companion:one': const GridPos(x: 5, y: 5),
      });
      expect(at(5).elapsedMs, 100);
      controller.synchronizeActorOccupancy({
        'hero': const GridPos(x: 5, y: 5),
        'companion:one': const GridPos(x: 5, y: 5),
      });
      expect(at(5), (active: true, elapsedMs: 100));
      controller.update(.5);
      expect(at(5).active, isTrue);
      expect(at(5).elapsedMs, 600);
      controller.synchronizeActorOccupancy({
        'companion:one': const GridPos(x: 5, y: 5),
      });
      expect(at(5), (active: true, elapsedMs: 800));
      controller.synchronizeActorOccupancy({'companion:one': null});
      expect(at(5).active, isFalse);
      controller.synchronizeActorOccupancy({
        'companion:one': const GridPos(x: 5, y: 5),
      });
      expect(at(5), (active: true, elapsedMs: 0));
      controller.synchronizeActorOccupancy({});
      expect(at(5).active, isFalse);
      final other = SpatialSmartTileAnimationController(
        map: fixture.map.copyWith(id: 'other'),
        project: project,
      );
      expect(
        other
            .actorOcclusionStateForCell(
              layerId: 'grass',
              cellX: 5,
              cellY: 5,
              globalElapsedMs: 5000,
            )
            .active,
        isFalse,
      );
    },
  );
}
