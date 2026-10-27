import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/spatial_ground.dart';

void main() {
  for (final singleImage in [true, false]) {
    test('300 UV changes reuse paint ranks, single image=$singleImage', () {
      final fixture = _Fixture(singleImage: singleImage);
      final plan = SpatialGroundPlan(fixture.map, fixture.project);
      final first = plan.resolve(0);
      _expectGroundHeights(fixture.map, first);
      final cold = plan.debugPaintRankWork;
      expect(cold.rankBuilds, 1);
      expect(cold.occupiedCells, 10);
      expect(cold.overlapComparisons, 12);
      final frames = <int>{first.first.visual.sourceRect.x};
      final images = <String>{first.first.visual.tilesetId};
      for (var sample = 1; sample <= 300; sample++) {
        final parts = plan.resolve(sample * 33);
        frames.add(parts.first.visual.sourceRect.x);
        images.add(parts.first.visual.tilesetId);
        _expectGroundHeights(fixture.map, parts);
      }
      expect(frames, {0, 32, 64, 96});
      expect(
        images,
        singleImage
            ? {'ground'}
            : {'ground-0', 'ground-1', 'ground-2', 'ground-3'},
      );
      expect(plan.debugPaintRankWork, cold);
    });
  }

  test('backward and on-enter clocks at the same time keep UVs live', () {
    final fixture = _Fixture();
    final layer = (fixture.map.layers.single as SmartTileLayer).copyWith(
      animationActivation: SmartTileAnimationActivation.onEnter,
    );
    final map = fixture.map.copyWith(layers: [layer]);
    final plan = SpatialGroundPlan(map, fixture.project);
    var cellTime = 0;
    var clockCalls = 0;
    int clock(String layer, int x, int y, int time) {
      expect(layer, 'animated');
      expect(time, 1000);
      clockCalls++;
      return cellTime;
    }

    plan.resolve(1000, animationElapsedMsForCell: clock);
    final cold = plan.debugPaintRankWork;
    for (final sample in [(66, 64), (-10, 0), (33, 32), (99, 96)]) {
      cellTime = sample.$1;
      final parts = plan.resolve(1000, animationElapsedMsForCell: clock);
      expect(parts.first.visual.sourceRect.x, sample.$2);
      _expectGroundHeights(map, parts);
    }
    expect(clockCalls, 10);
    expect(plan.debugPaintRankWork, cold);
  });

  test(
    'bounds changes rebuild only their layer and preserve exact heights',
    () {
      final fixture = _Fixture(
        pixelOffsets: [0, 8, -8, 8],
        withStaticLayer: true,
      );
      final plan = SpatialGroundPlan(fixture.map, fixture.project);
      final first = plan.resolve(0);
      final fixed = first
          .where((part) => part.visual.candidateId == 'fixed')
          .toList();
      expect(plan.debugPaintRankWork.rankBuilds, 2);
      var builds = 2;
      for (final time in [33, 66, 99, 0]) {
        final parts = plan.resolve(time);
        _expectGroundHeights(fixture.map, parts);
        expect(
          parts.where((part) => part.visual.candidateId == 'fixed'),
          orderedEquals(fixed),
        );
        expect(plan.debugPaintRankWork.rankBuilds, ++builds);
      }
    },
  );

  test('empty and restored sequences invalidate only the affected layer', () {
    final fixture = _Fixture(withStaticLayer: true, invalidFrames: {2});
    final plan = SpatialGroundPlan(fixture.map, fixture.project);
    expect(plan.resolve(0), hasLength(8));
    expect(plan.debugPaintRankWork.rankBuilds, 2);
    final empty = plan.resolve(66);
    expect(empty, hasLength(2));
    expect(empty.every((part) => part.visual.candidateId == 'fixed'), isTrue);
    _expectGroundHeights(fixture.map, empty);
    expect(plan.debugPaintRankWork.rankBuilds, 3);
    final restored = plan.resolve(99);
    expect(restored, hasLength(8));
    _expectGroundHeights(fixture.map, restored);
    expect(plan.debugPaintRankWork.rankBuilds, 4);
    plan.resolve(132);
    expect(plan.debugPaintRankWork.rankBuilds, 4);
  });

  test('reordering equal bounds invalidates ranks in their exact sequence', () {
    final fixture = _Fixture(
      pixelOffsets: [0, 16, 32],
      animations: [
        _animation('left', [0, 1]),
        _animation('middle', [1, 0]),
      ],
      parts: const [
        SmartTileVisualPart(
          source: SmartTileVisualSource.animation(animationId: 'left'),
        ),
        SmartTileVisualPart(
          source: SmartTileVisualSource.animation(animationId: 'middle'),
        ),
        SmartTileVisualPart(
          source: SmartTileVisualSource.frame(
            frame: SmartTileFrameRef(atlasId: 'frame-2', column: 0, row: 0),
          ),
        ),
      ],
    );
    final plan = SpatialGroundPlan(fixture.map, fixture.project);
    final first = plan.resolve(0);
    final next = plan.resolve(33);
    expect(
      first.map((part) => part.visual.geometry.visualBounds).toSet(),
      next.map((part) => part.visual.geometry.visualBounds).toSet(),
    );
    expect(
      first.map((part) => part.visual.geometry.visualBounds),
      isNot(
        orderedEquals(next.map((part) => part.visual.geometry.visualBounds)),
      ),
    );
    expect(
      first.map((part) => part.height),
      isNot(orderedEquals(next.map((part) => part.height))),
    );
    _expectGroundHeights(fixture.map, first);
    _expectGroundHeights(fixture.map, next);
    expect(plan.debugPaintRankWork.rankBuilds, 2);
  });

  test('subpixel negative and edge-exclusive bounds retain overlap ranks', () {
    final fixture = _Fixture(
      parts: [
        for (final offset in [-24, -8, 8, 24])
          SmartTileVisualPart(
            offsetX: offset,
            source: const SmartTileVisualSource.animation(animationId: 'wave'),
          ),
      ],
    );
    final plan = SpatialGroundPlan(fixture.map, fixture.project);
    final first = plan.resolve(0);
    expect(first.first.visual.geometry.visualBounds.left, -.75);
    expect(first[2].visual.geometry.visualBounds.left, .25);
    expect(
      first.first.visual.geometry.visualBounds.intersects(
        first[2].visual.geometry.visualBounds,
      ),
      isFalse,
    );
    expect(_referenceRanks(first.take(4).map((part) => part.visual).toList()), [
      0,
      1,
      2,
      3,
    ]);
    _expectGroundHeights(fixture.map, first);
    final cold = plan.debugPaintRankWork;
    for (final time in [33, 66, 99, -10]) {
      _expectGroundHeights(fixture.map, plan.resolve(time));
    }
    expect(plan.debugPaintRankWork, cold);
  });

  test('flat animated and static groups retain independent paint ranks', () {
    final fixture = _Fixture();
    final plan = SpatialGroundPlan(
      fixture.map.copyWith(layers: const []),
      fixture.project,
      additionalBorders: SpatialGroundBorderInputs(
        surfaces: [_borderSurface('animated'), _borderSurface('fixed')],
      ),
    );
    final first = plan.resolve(0);
    final cold = plan.debugPaintRankWork;
    expect(cold.rankBuilds, 2);
    final frames = <int>{};
    for (var sample = 0; sample < 300; sample++) {
      final parts = plan.resolve(sample * 33);
      frames.add(parts.first.visual.sourceRect.x);
      expect(parts, hasLength(first.length));
      for (final (id, base) in [('animated', 1), ('fixed', 2)]) {
        final group = parts
            .where((part) => part.visual.candidateId == id)
            .toList();
        final ranks = _referenceRanks(
          group.map((part) => part.visual).toList(),
        );
        final maximum = ranks.fold(0, (a, b) => a > b ? a : b);
        for (var index = 0; index < group.length; index++) {
          expect(
            group[index].height,
            .0001 * (base + ranks[index] / (maximum + 1)) / 3,
          );
          expect(plan.flatSurfaceFor(group[index].visual), isNotNull);
          expect(group[index].opacity, .75);
        }
      }
    }
    expect(frames, {0, 32, 64, 96});
    expect(plan.debugPaintRankWork, cold);
  });

  test(
    'visibility order and independently selected plans own their rank cache',
    () {
      final fixture = _Fixture(withStaticLayer: true);
      final source = SpatialGroundPlan(fixture.map, fixture.project);
      source.resolve(0);
      final cold = source.debugPaintRankWork;
      final filtered = source.withLayerVisibility((id) => id == 'animated');
      expect(filtered.debugPaintRankWork.rankBuilds, 0);
      final visible = filtered.resolve(33);
      expect(visible, hasLength(6));
      _expectGroundHeights(fixture.map, visible);
      expect(filtered.debugPaintRankWork.rankBuilds, 1);
      final reorderedMap = fixture.map.copyWith(
        layers: fixture.map.layers.reversed.toList(),
      );
      final reordered = source.reordered(reorderedMap);
      expect(reordered.debugPaintRankWork.rankBuilds, 0);
      _expectGroundHeights(reorderedMap, reordered.resolve(66));
      expect(reordered.debugPaintRankWork.rankBuilds, 2);
      final selectedMap = fixture.map.copyWith(
        size: const GridSize(width: 1, height: 1),
        spatialScene: MapSpatialScene(width: 1, depth: 1),
        layers: [
          (fixture.map.layers.first as SmartTileLayer).copyWith(
            field: const SmartTileField.cell(semanticCells: [1]),
          ),
        ],
      );
      final selected = SpatialGroundPlan(selectedMap, fixture.project);
      expect(selected.resolve(99), hasLength(3));
      expect(selected.debugPaintRankWork.rankBuilds, 1);
      final hidden = source.withLayerVisibility((_) => false);
      expect(hidden.resolve(99), isEmpty);
      expect(hidden.debugPaintRankWork.rankBuilds, 0);
      _expectGroundHeights(fixture.map, source.resolve(99));
      expect(source.debugPaintRankWork, cold);
      expect(filtered.resolve(99), hasLength(6));
      expect(filtered.debugPaintRankWork.rankBuilds, 1);
    },
  );

  test(
    'dynamic neighbor clocks leave static plan ranks and results unchanged',
    () {
      final fixture = _Fixture();
      final layer = fixture.map.layers.single as SmartTileLayer;
      final staticPlan = SpatialGroundPlan(
        fixture.map.copyWith(layers: [_layer('fixed')]),
        fixture.project,
      );
      final dynamicPlan = SpatialGroundPlan(
        fixture.map.copyWith(id: 'neighbor', layers: [layer]),
        fixture.project,
      );
      final fixed = staticPlan.resolve(0);
      final fixedWork = staticPlan.debugPaintRankWork;
      dynamicPlan.resolve(0);
      final dynamicWork = dynamicPlan.debugPaintRankWork;
      for (var sample = 0; sample < 300; sample++) {
        expect(staticPlan.resolve(sample * 33), same(fixed));
        dynamicPlan.resolve(
          0,
          animationElapsedMsForCell: (_, x, _, _) => sample * 33 + x * 66,
        );
      }
      expect(staticPlan.debugPaintRankWork, fixedWork);
      expect(dynamicPlan.debugPaintRankWork, dynamicWork);
    },
  );
}

final class _Fixture {
  _Fixture({
    List<int> pixelOffsets = const [0, 0, 0, 0],
    List<SmartTileVisualPart>? parts,
    List<ProjectSmartTileAnimation>? animations,
    bool withStaticLayer = false,
    bool singleImage = true,
    Set<int> invalidFrames = const {},
  }) {
    map = MapData(
      id: 'map',
      name: 'Map',
      size: const GridSize(width: 2, height: 1),
      spatialScene: MapSpatialScene(width: 2, depth: 1),
      layers: [_layer('animated'), if (withStaticLayer) _layer('fixed')],
    );
    project = ProjectManifest(
      name: 'Ground ranks',
      maps: const [],
      tilesets: const [],
      settings: const ProjectSettings(tileWidth: 32, tileHeight: 32),
      smartTileCatalog: ProjectSmartTileCatalog(
        materials: const [
          ProjectSmartTileMaterial(
            id: 'ground',
            name: 'Ground',
            connectionGroupId: 'ground',
          ),
        ],
        atlases: [
          for (var frame = 0; frame < pixelOffsets.length; frame++)
            ProjectSmartTileAtlas(
              id: 'frame-$frame',
              name: 'Frame $frame',
              tilesetId: singleImage ? 'ground' : 'ground-$frame',
              originX: frame * 32,
              pixelOffsetX: pixelOffsets[frame],
              columns: 1,
              rows: 1,
            ),
        ],
        animations:
            animations ??
            [
              ProjectSmartTileAnimation(
                id: 'wave',
                name: 'Wave',
                frames: [
                  for (var frame = 0; frame < pixelOffsets.length; frame++)
                    ProjectSmartTileAnimationFrame(
                      frame: SmartTileFrameRef(
                        atlasId: 'frame-$frame',
                        column: invalidFrames.contains(frame) ? 1 : 0,
                        row: 0,
                      ),
                      durationMs: 33,
                    ),
                ],
              ),
            ],
        presets: [
          _preset(
            'animated',
            parts ??
                [
                  for (final offset in [-16, 0, 16])
                    SmartTileVisualPart(
                      offsetX: offset,
                      source: const SmartTileVisualSource.animation(
                        animationId: 'wave',
                      ),
                    ),
                ],
          ),
          _preset('fixed', const [
            SmartTileVisualPart(
              source: SmartTileVisualSource.frame(
                frame: SmartTileFrameRef(atlasId: 'frame-0', column: 0, row: 0),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  late final MapData map;
  late final ProjectManifest project;
}

ProjectSmartTileAnimation _animation(String id, List<int> frames) =>
    ProjectSmartTileAnimation(
      id: id,
      name: id,
      frames: [
        for (final frame in frames)
          ProjectSmartTileAnimationFrame(
            frame: SmartTileFrameRef(
              atlasId: 'frame-$frame',
              column: 0,
              row: 0,
            ),
            durationMs: 33,
          ),
      ],
    );

SpatialBorderGroundSurface _borderSurface(String presetId) =>
    SpatialBorderGroundSurface(
      layerId: 'border-$presetId',
      sourceSmartTilePresetId: presetId,
      materialId: 'ground',
      height: 1,
      opacity: .75,
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
    );

SmartTileLayer _layer(String id) => SmartTileLayer(
  id: id,
  name: id,
  presetId: id,
  usage: SmartTileUsage.terrain,
  materialPalette: const ['', 'ground'],
  field: const SmartTileField.cell(semanticCells: [1, 1]),
);

ProjectSmartTilePreset _preset(String id, List<SmartTileVisualPart> parts) =>
    ProjectSmartTilePreset(
      id: id,
      name: id,
      usage: SmartTileUsage.terrain,
      topology: SmartTileTopology.uniform,
      templateHint: SmartTileTemplateHint.simple,
      coveragePolicy: SmartTileCoveragePolicy.sparse,
      coverageProfile: const SmartTileCoverageProfile(
        mode: SmartTileCoverageMode.template,
      ),
      transformPolicy: const SmartTileTransformPolicy(),
      defaultMaterialId: 'ground',
      allowedMaterialIds: const ['ground'],
      rules: [
        SmartTileRule(
          id: id,
          centerMatch: const SmartTileSlotMatch.material('ground'),
          candidates: [SmartTileCandidate(id: id, parts: parts)],
        ),
      ],
    );

void _expectGroundHeights(MapData map, List<SpatialGroundVisual> parts) {
  final layerRanks = spatialSmartTileLayerPaintRanks(map);
  for (final layerId in layerRanks.keys) {
    final layer = parts
        .where((part) => part.visual.candidateId == layerId)
        .toList();
    final ranks = _referenceRanks(layer.map((part) => part.visual).toList());
    final maximum = ranks.fold(0, (a, b) => a > b ? a : b);
    for (var index = 0; index < layer.length; index++) {
      expect(
        layer[index].height,
        spatialSmartTileLayerPaintStep *
            (layerRanks[layerId]! + 1 + ranks[index] / (maximum + 1)),
      );
    }
  }
}

List<int> _referenceRanks(List<SmartTileLayerVisual> visuals) {
  final ranks = <int>[];
  for (var current = 0; current < visuals.length; current++) {
    var rank = 0;
    final bounds = visuals[current].geometry.visualBounds;
    for (var previous = 0; previous < current; previous++) {
      if (bounds.intersects(visuals[previous].geometry.visualBounds) &&
          rank <= ranks[previous]) {
        rank = ranks[previous] + 1;
      }
    }
    ranks.add(rank);
  }
  return ranks;
}
