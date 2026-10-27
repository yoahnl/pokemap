import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/spatial/spatial_smart_tile_animation_controller.dart';

import 'support/spatial_smart_tile_fixture.dart';

void main() {
  for (final foreignLayerCount in [10, 1000]) {
    test(
      'occlusion queries do not reread $foreignLayerCount foreign layers',
      () {
        final fixture = spatialGrassFixture(
          activation: SmartTileAnimationActivation.always,
        );
        final target = fixture.map.layers.single;
        final layers = _CountingLayerList([
          for (var index = 0; index < foreignLayerCount; index++)
            TileLayer(id: 'foreign-$index', name: 'Foreign'),
          target,
        ]);
        final map = fixture.map.copyWith(layers: layers);
        expect(map.layers[foreignLayerCount], same(target));
        expect(layers.elementReads, 1);
        layers.resetReads();
        final controller = SpatialSmartTileAnimationController(
          map: map,
          project: fixture.project,
        );
        expect(layers.elementReads, greaterThan(0));
        layers.resetReads();

        expect(
          controller.actorOcclusionStateForCell(
            layerId: 'grass',
            cellX: 4,
            cellY: 5,
            globalElapsedMs: 12000,
          ),
          (active: true, elapsedMs: 12000),
        );
        final firstReads = (
          elements: layers.elementReads,
          lengths: layers.lengthReads,
        );
        layers.resetReads();
        for (var query = 1; query < 300; query++) {
          expect(
            controller.actorOcclusionStateForCell(
              layerId: 'grass',
              cellX: 4,
              cellY: 5,
              globalElapsedMs: 12000 + query,
            ),
            (active: true, elapsedMs: 12000 + query),
          );
        }
        expect(
          (
            first: firstReads,
            repeated: (
              elements: layers.elementReads,
              lengths: layers.lengthReads,
            ),
          ),
          (
            first: (elements: 0, lengths: 0),
            repeated: (elements: 0, lengths: 0),
          ),
        );
      },
    );
  }

  test(
    'occlusion lookup keeps the first SmartTile among mixed duplicate IDs',
    () {
      final fixture = spatialGrassFixture();
      final layer = fixture.map.layers.single as SmartTileLayer;
      for (final firstActivation in SmartTileAnimationActivation.values) {
        final first = layer.copyWith(animationActivation: firstActivation);
        final second = layer.copyWith(
          animationActivation:
              firstActivation == SmartTileAnimationActivation.always
              ? SmartTileAnimationActivation.onEnter
              : SmartTileAnimationActivation.always,
        );
        final controller = SpatialSmartTileAnimationController(
          map: fixture.map.copyWith(
            layers: [
              const TileLayer(id: 'grass', name: 'Tile'),
              first,
              const EnvironmentLayer(id: 'grass', name: 'Environment'),
              second,
              const CollisionLayer(id: 'grass', name: 'Collision'),
            ],
          ),
          project: fixture.project,
        );
        expect(
          controller.actorOcclusionStateForCell(
            layerId: 'grass',
            cellX: 4,
            cellY: 5,
            globalElapsedMs: 7231,
          ),
          firstActivation == SmartTileAnimationActivation.always
              ? (active: true, elapsedMs: 7231)
              : (active: false, elapsedMs: 0),
        );
      }
    },
  );

  test('invisible and transparent always layers retain occlusion clocks', () {
    final fixture = spatialGrassFixture(
      activation: SmartTileAnimationActivation.always,
    );
    final layer = fixture.map.layers.single as SmartTileLayer;
    for (final replacement in [
      layer.copyWith(isVisible: false),
      layer.copyWith(opacity: 0),
    ]) {
      final controller = SpatialSmartTileAnimationController(
        map: fixture.map.copyWith(layers: [replacement]),
        project: fixture.project,
      );
      expect(
        controller.actorOcclusionStateForCell(
          layerId: 'grass',
          cellX: 4,
          cellY: 5,
          globalElapsedMs: 9123,
        ),
        (active: true, elapsedMs: 9123),
      );
    }
  });

  test('onEnter and unknown layers retain the occupied-cell fallback', () {
    final fixture = spatialRasterGrassFixture();
    final controller = SpatialSmartTileAnimationController(
      map: fixture.map,
      project: fixture.project,
    );
    ({bool active, int elapsedMs}) at(String layerId, {int x = 4}) =>
        controller.actorOcclusionStateForCell(
          layerId: layerId,
          cellX: x,
          cellY: 5,
          globalElapsedMs: 8237,
        );

    expect(at('grass'), (active: false, elapsedMs: 0));
    expect(at('missing'), (active: false, elapsedMs: 0));
    controller.synchronizeActorOccupancy({'hero': const GridPos(x: 3, y: 5)});
    controller.synchronizeActorOccupancy({'hero': const GridPos(x: 4, y: 5)});
    controller.update(.125);
    expect(at('grass'), (active: true, elapsedMs: 125));
    expect(at('grass', x: 5), (active: false, elapsedMs: 0));
    expect(at('missing'), (active: true, elapsedMs: 8237));
    expect(at('missing', x: 5), (active: false, elapsedMs: 0));
    controller.synchronizeActorOccupancy({});
    expect(at('grass'), (active: false, elapsedMs: 0));
    expect(at('missing'), (active: false, elapsedMs: 0));
  });

  test('replacement map controllers compile their own layer snapshot', () {
    final fixture = spatialGrassFixture(
      activation: SmartTileAnimationActivation.always,
    );
    final layer = fixture.map.layers.single as SmartTileLayer;
    final originalLayers = _CountingLayerList([layer]);
    final originalMap = fixture.map.copyWith(layers: originalLayers);
    final original = SpatialSmartTileAnimationController(
      map: originalMap,
      project: fixture.project,
    );
    final replacementLayers = _CountingLayerList([
      layer.copyWith(animationActivation: SmartTileAnimationActivation.onEnter),
      layer.copyWith(id: 'new-layer'),
    ]);
    final replacement = SpatialSmartTileAnimationController(
      map: originalMap.copyWith(layers: replacementLayers),
      project: fixture.project,
    );
    expect(originalLayers.elementReads, greaterThan(0));
    expect(replacementLayers.elementReads, greaterThan(0));
    originalLayers.resetReads();
    replacementLayers.resetReads();
    for (final entry in [
      (controller: original, layerId: 'grass', active: true, elapsedMs: 6317),
      (controller: original, layerId: 'new-layer', active: false, elapsedMs: 0),
      (controller: replacement, layerId: 'grass', active: false, elapsedMs: 0),
      (
        controller: replacement,
        layerId: 'new-layer',
        active: true,
        elapsedMs: 6317,
      ),
    ]) {
      expect(
        entry.controller.actorOcclusionStateForCell(
          layerId: entry.layerId,
          cellX: 4,
          cellY: 5,
          globalElapsedMs: 6317,
        ),
        (active: entry.active, elapsedMs: entry.elapsedMs),
      );
    }
    expect(originalLayers.elementReads, 0);
    expect(originalLayers.lengthReads, 0);
    expect(replacementLayers.elementReads, 0);
    expect(replacementLayers.lengthReads, 0);
  });

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

final class _CountingLayerList extends ListBase<MapLayer> {
  _CountingLayerList(List<MapLayer> layers)
    : _layers = List<MapLayer>.unmodifiable(layers);

  final List<MapLayer> _layers;
  int elementReads = 0;
  int lengthReads = 0;

  @override
  int get length {
    lengthReads++;
    return _layers.length;
  }

  @override
  set length(int value) => throw UnsupportedError('Immutable layers');

  @override
  MapLayer operator [](int index) {
    elementReads++;
    return _layers[index];
  }

  @override
  void operator []=(int index, MapLayer value) =>
      throw UnsupportedError('Immutable layers');

  void resetReads() {
    elementReads = 0;
    lengthReads = 0;
  }
}
