import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/spatial/spatial_smart_tile_animation_controller.dart';

import 'support/spatial_smart_tile_fixture.dart';

void main() {
  test('raster reactions use local cell time and reset after the existing cycle', () {
    final fixture = spatialRasterGrassFixture();
    final controller = SpatialSmartTileAnimationController(
      map: fixture.map,
      project: fixture.project,
    );
    int elapsed(int x, int y) => controller.rasterElapsedMsForCell(
      layerId: 'grass',
      cellX: x,
      cellY: y,
      globalElapsedMs: 5000,
    );
    expect(elapsed(4, 5), 0);
    controller.update(.4);
    expect(elapsed(4, 5), 0);
    controller.onPlayerEnteredCell(const GridPos(x: 4, y: 5));
    controller.update(.125);
    expect(elapsed(4, 5), 125);
    expect(elapsed(5, 5), 0);
    controller.onPlayerEnteredCell(const GridPos(x: 3, y: 5));
    controller.update(.025);
    expect(elapsed(3, 5), 0);
    expect(elapsed(4, 5), 150);
    for (final dt in [double.nan, double.infinity, 0.0, -1.0]) {
      controller.update(dt);
    }
    expect(elapsed(4, 5), 150);
    controller.update(.051);
    expect(elapsed(4, 5), 0);
    controller.onPlayerEnteredCell(const GridPos(x: 4, y: 5));
    controller.update(.05);
    expect(elapsed(4, 5), 50);
    expect(elapsed(-1, 5), 0);
  });

  test('actor entries replay authored model grass and keep new maps at rest', () {
    final fixture = spatialGrassFixture();
    final projection = resolveSpatialSmartTileModelProjection(
      map: fixture.map, catalog: fixture.project.smartTileCatalog);
    final first = projection.instances.first;
    final neighbor = projection.instances.last;
    final controller = SpatialSmartTileAnimationController(
      map: fixture.map, project: fixture.project);
    controller.onPlayerEnteredCell(const GridPos(x: 4, y: 5));
    controller.update(.5);
    expect(controller.stateFor(first.id)!.normalizedTime, 0);
    controller.onActorEnteredCell(const GridPos(x: 4, y: 5));
    controller.update(.1);
    expect(controller.stateFor(first.id)!.normalizedTime, closeTo(.25, 1e-9));
    expect(controller.stateFor(neighbor.id)!.normalizedTime, 0);
    final otherMap = fixture.map.copyWith(id: 'other');
    final replacement = SpatialSmartTileAnimationController(
      map: otherMap, project: fixture.project);
    final otherId = resolveSpatialSmartTileModelProjection(
      map: otherMap, catalog: fixture.project.smartTileCatalog).instances.first.id;
    expect(replacement.stateFor(otherId)!.normalizedTime, 0);
    controller.update(.301);
    expect(controller.stateFor(first.id)!.normalizedTime, 0);
  });

  test('raster always layers retain the supplied global clock', () {
    final fixture = spatialRasterGrassFixture(
      activation: SmartTileAnimationActivation.always,
    );
    final controller = SpatialSmartTileAnimationController(
      map: fixture.map,
      project: fixture.project,
    );
    controller.onPlayerEnteredCell(const GridPos(x: 4, y: 5));
    controller.update(.1);
    expect(controller.rasterElapsedMsForCell(
      layerId: 'grass', cellX: 4, cellY: 5, globalElapsedMs: 5000,
    ), 5000);
  });

  test(
    'only the entered authored cell plays once, including offset models',
    () {
      final fixture = spatialGrassFixture();
      final projection = resolveSpatialSmartTileModelProjection(
        map: fixture.map,
        catalog: fixture.project.smartTileCatalog,
      );
      final first = projection.instances.first;
      final neighbor = projection.instances.last;
      expect(first.position.x.floor(), 5);
      final controller = SpatialSmartTileAnimationController(
        map: fixture.map,
        project: fixture.project,
      );
      final resting = controller.stateFor(first.id)!;
      expect(resting.normalizedTime, 0);
      controller.update(.2);
      expect(controller.stateFor(first.id), same(resting));
      controller.onPlayerEnteredCell(const GridPos(x: 4, y: 5));
      controller.update(.1);
      expect(controller.stateFor(first.id)!.normalizedTime, closeTo(.25, 1e-9));
      expect(controller.stateFor(neighbor.id)!.normalizedTime, 0);
      controller.update(.3);
      expect(controller.stateFor(first.id), same(resting));
      controller.onPlayerEnteredCell(const GridPos(x: 4, y: 5));
      expect(controller.stateFor(first.id)!.normalizedTime, 0);
      controller.update(.2);
      expect(controller.stateFor(first.id)!.normalizedTime, closeTo(.5, 1e-9));
      for (final dt in [double.nan, double.infinity, 0.0, -1.0]) {
        controller.update(dt);
      }
      expect(controller.stateFor(first.id)!.normalizedTime, closeTo(.5, 1e-9));
      expect(controller.stateFor('missing'), isNull);
    },
  );

  test('global, invisible and transparent layers retain ordinary playback', () {
    final fixture = spatialGrassFixture();
    final layer = fixture.map.layers.single as SmartTileLayer;
    for (final replacement in [
      layer.copyWith(animationActivation: SmartTileAnimationActivation.always),
      layer.copyWith(isVisible: false),
      layer.copyWith(opacity: 0),
    ]) {
      final controller = SpatialSmartTileAnimationController(
        map: fixture.map.copyWith(layers: [replacement]),
        project: fixture.project,
      );
      controller.onPlayerEnteredCell(const GridPos(x: 4, y: 5));
      controller.update(.1);
      for (final instance in resolveSpatialSmartTileInstances(
        map: fixture.map,
        catalog: fixture.project.smartTileCatalog,
      )) {
        expect(controller.stateFor(instance.id), isNull);
      }
    }
  });

  test('unanimated sources do not acquire a fabricated clip', () {
    final fixture = spatialGrassFixture();
    final catalog = fixture.project.smartTileCatalog;
    final preset = catalog.presets.single;
    final rule = preset.rules.single;
    final candidate = rule.candidates.single;
    final project = fixture.project.copyWith(
      smartTileCatalog: ProjectSmartTileCatalog(
        materials: catalog.materials,
        presets: [
          preset.copyWith(
            rules: [
              rule.copyWith(
                candidates: [
                  candidate.copyWith(
                    parts: const [
                      SmartTileVisualPart(
                        source: SmartTileVisualSource.model3d(
                          modelId: 'grass-model',
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
    final controller = SpatialSmartTileAnimationController(
      map: fixture.map,
      project: project,
    );
    controller.onPlayerEnteredCell(const GridPos(x: 4, y: 5));
    controller.update(.1);
    for (final instance in resolveSpatialSmartTileInstances(
      map: fixture.map,
      catalog: project.smartTileCatalog,
    )) {
      expect(controller.stateFor(instance.id), isNull);
    }
  });

  test(
    'pattern contours use resolved ownership and do not animate erased cells',
    () {
      final fixture = spatialGrassFixture(
        patterns: const [
          ProjectSmartTilePattern(
            id: 'contour',
            name: 'Contour',
            usage: SmartTileUsage.path,
            width: 1,
            height: 1,
            cells: [
              SmartTilePatternCell(
                x: 0,
                y: 0,
                parts: [
                  SmartTileVisualPart(
                    source: SmartTileVisualSource.model3d(
                      modelId: 'grass-model',
                      animationIndex: 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
        strokes: const [
          SmartTilePatternStroke(
            id: 'edge',
            patternId: 'contour',
            cells: [GridPos(x: 3, y: 5)],
          ),
        ],
      );
      final controller = SpatialSmartTileAnimationController(
        map: fixture.map,
        project: fixture.project,
      );
      final projection = resolveSpatialSmartTileModelProjection(
        map: fixture.map,
        catalog: fixture.project.smartTileCatalog,
      );
      final edge = projection.instances.singleWhere(
        (instance) =>
            projection.cellOrigins[instance.id]!.cell ==
            const GridPos(x: 3, y: 5),
      );
      controller.onPlayerEnteredCell(const GridPos(x: 3, y: 5));
      controller.update(.1);
      expect(controller.stateFor(edge.id)!.normalizedTime, closeTo(.25, 1e-9));
      final layer = fixture.map.layers.single as SmartTileLayer;
      final erased = eraseSmartTilePatternCells(
        layer,
        mapSize: fixture.map.size,
        cells: const [GridPos(x: 3, y: 5)],
      );
      final after = SpatialSmartTileAnimationController(
        map: fixture.map.copyWith(layers: [erased]),
        project: fixture.project,
      );
      after.onPlayerEnteredCell(const GridPos(x: 3, y: 5));
      after.update(.1);
      expect(after.stateFor(edge.id), isNull);
    },
  );
}
