import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../../../tools/performance/smart_tiles_rich_map_fixture.dart';

/// The plan is a pure preparation of [resolveSmartTileLayerVisualBatch]:
/// for any elapsed time and viewport, both paths must emit identical visuals
/// in identical order. The rich fixture covers Wang rules, per-cell-synced
/// animations, ping-pong loops, and pattern strokes.
void main() {
  final fixture = generateSmartTilesRichMapFixture(extent: 128);
  final map = fixture.map;
  final catalog = fixture.manifest.smartTileCatalog;
  final smartLayers = map.layers.whereType<SmartTileLayer>().toList();

  test('static layers do not revisit cells or call animation clocks', () {
    final layer = smartLayers.singleWhere((layer) => layer.id == 'paths');
    final plan = buildSmartTileLayerVisualPlan(
      map: map,
      layer: layer,
      catalog: catalog,
      pass: SmartTileVisualPass.background,
    );
    final first = plan.resolveBatch();
    var clockCalls = 0;
    final repeated = plan.resolveBatch(
      elapsedMs: 16,
      animationElapsedMsForCell:
          ({required cellX, required cellY, required elapsedMs}) {
            clockCalls++;
            return elapsedMs;
          },
    );
    expect(first.visuals, isNotEmpty);
    expect(repeated.visuals, same(first.visuals));
    expect(repeated.work.ownerCellVisits, 0);
    expect(clockCalls, 0);
  });

  test('prepared plans preserve the bounded native context resolver', () {
    final layer = smartLayers.singleWhere((layer) => layer.id == 'paths');
    var calls = 0;
    final plan = buildSmartTileLayerVisualPlan(map: map, layer: layer, catalog: catalog,
      pass: SmartTileVisualPass.background, cellContextResolver: ({required preset, required x, required y}) {
        calls++;
        return smartTileCellContextForLayerCell(layer: layer, map: map, preset: preset, x: x, y: y);
      });
    expect(plan.resolveBatch().visuals, isNotEmpty);
    expect(calls, greaterThan(0));
    final firstCalls = calls;
    plan.resolveBatch(elapsedMs: 16);
    expect(calls, firstCalls);
  });

  test('fixture exposes smart tile layers to compare', () {
    expect(smartLayers, isNotEmpty);
  });

  for (final frames in [4, 97, 360]) {
    test(
      'render-only viewport motion skips proof visits for $frames frames',
      () {
        final f = _imageFixture(
          width: 20,
          height: 18,
          frames: [
            for (var frame = 0; frame < frames; frame++)
              SmartTileFrameRef(atlasId: 'a', column: frame % 4, row: 0),
          ],
        );
        final plan = f.plan();
        plan.resolveBatch(
          viewportBounds: const SmartTileGeometryRect(
            left: 0,
            top: 0,
            width: 20,
            height: 18,
          ),
        );
        expect(plan.debugWork.compiledAnimationVariants, 360 * frames);
        final before = plan.debugImageIdVariantVisits;
        for (var movement = 0; movement < 300; movement++) {
          plan.resolveBatch(
            elapsedMs: movement * 17,
            viewportBounds: SmartTileGeometryRect(
              left: (movement + 1) / 10000,
              top: 0,
              width: 20,
              height: 18,
            ),
          );
        }
        expect(plan.debugImageIdVariantVisits - before, 0);
      },
    );
  }

  test(
    'invariant IDs use selected compiled parts and preserve live rendering',
    () {
      final f = _imageFixture();
      final plan = f.plan();
      expect(plan.debugWork.compiledAnimationVariants, 0);
      final images = plan.invariantImageIds();
      expect(images, {'image-a'});
      expect(plan.debugWork, (
        resolveBatchCalls: 0,
        animationVariantVisits: 0,
        compiledAnimationVariants: 2,
        selectedCellVisits: 1,
      ));
      final firstWork = plan.debugWork;
      for (var query = 0; query < 300; query++) {
        expect(plan.invariantImageIds(), same(images));
      }
      expect(plan.debugWork, firstWork);
      var clockCalls = 0;
      var cellTime = 0;
      SmartTileLayerVisualBatch render() => plan.resolveBatch(
        elapsedMs: 1000,
        animationElapsedMsForCell:
            ({required cellX, required cellY, required elapsedMs}) {
              clockCalls++;
              return cellTime;
            },
      );
      expect(render().visuals.single.sourceRect.x, 0);
      cellTime = 20;
      expect(render().visuals.single.sourceRect.x, 32);
      cellTime = -50;
      expect(render().visuals.single.sourceRect.x, 0);
      expect(clockCalls, 3);
      expect(plan.debugWork.animationVariantVisits, 3);
      expect(plan.invariantImageIds(), same(images));
      expect(() => images!.add('other'), throwsUnsupportedError);
    },
  );

  test('image proof is lazy and caches a nullable result per selection', () {
    final f = _imageFixture(
      frames: const [
        SmartTileFrameRef(atlasId: 'a', column: 0, row: 0),
        SmartTileFrameRef(atlasId: 'b', column: 0, row: 0),
      ],
    );
    final plan = f.plan();
    const viewport = SmartTileGeometryRect(
      left: 0,
      top: 0,
      width: 3,
      height: 1,
    );
    plan.resolveBatch(viewportBounds: viewport);
    expect(plan.debugImageIdVariantVisits, 0);
    expect(plan.invariantImageIds(viewportBounds: viewport), isNull);
    expect(plan.debugImageIdVariantVisits, 2);
    for (var query = 0; query < 300; query++) {
      expect(plan.invariantImageIds(viewportBounds: viewport), isNull);
      plan.resolveBatch(elapsedMs: query, viewportBounds: viewport);
    }
    expect(plan.debugImageIdVariantVisits, 2);
    const moved = SmartTileGeometryRect(
      left: .001,
      top: 0,
      width: 3,
      height: 1,
    );
    plan.resolveBatch(viewportBounds: moved);
    expect(plan.debugImageIdVariantVisits, 2);
    expect(plan.invariantImageIds(viewportBounds: moved), isNull);
    expect(plan.debugImageIdVariantVisits, 4);
    expect(plan.invariantImageIds(), isNull);
    expect(plan.debugImageIdVariantVisits, 4);
  });

  test('multi-atlas and nullable variants require dynamic selection', () {
    for (final last in [
      const SmartTileFrameRef(atlasId: 'b', column: 0, row: 0),
      const SmartTileFrameRef(atlasId: 'a', column: 4, row: 0),
    ]) {
      final f = _imageFixture(
        frames: [
          const SmartTileFrameRef(atlasId: 'a', column: 0, row: 0),
          last,
        ],
      );
      final plan = f.plan();
      expect(plan.invariantImageIds(), isNull);
      expect(
        plan.resolveBatch(elapsedMs: 0).visuals.single.tilesetId,
        'image-a',
      );
      final next = plan.resolveBatch(elapsedMs: 20).visuals;
      expect(
        next.map((visual) => visual.tilesetId).toSet(),
        last.atlasId == 'b' ? {'image-b'} : isEmpty,
      );
    }
  });

  test('fixed parts can guarantee images despite nullable animated parts', () {
    final f = _imageFixture(
      frames: const [
        SmartTileFrameRef(atlasId: 'a', column: 0, row: 0),
        SmartTileFrameRef(atlasId: 'a', column: 4, row: 0),
      ],
      fixed: true,
    );
    final plan = f.plan();
    expect(plan.invariantImageIds(), {'image-a'});
    expect(plan.resolveBatch().visuals, hasLength(2));
    expect(plan.resolveBatch(elapsedMs: 20).visuals, hasLength(1));
  });

  test('all-null, inert and empty selections have an immutable empty set', () {
    final f = _imageFixture(
      frames: const [
        SmartTileFrameRef(atlasId: 'a', column: 4, row: 0),
        SmartTileFrameRef(atlasId: 'a', column: 5, row: 0),
      ],
    );
    final plans = [
      f.plan(),
      buildSmartTileLayerVisualPlan(
        map: f.map,
        layer: f.layer,
        catalog: const ProjectSmartTileCatalog.empty(),
        pass: SmartTileVisualPass.background,
      ),
      buildSmartTileLayerVisualPlan(
        map: f.map,
        layer: f.layer.copyWith(
          field: const SmartTileField.cell(semanticCells: [0]),
        ),
        catalog: f.catalog,
        pass: SmartTileVisualPass.background,
      ),
    ];
    for (final plan in plans) {
      final images = plan.invariantImageIds();
      expect(images, isEmpty);
      expect(plan.resolveBatch(elapsedMs: 20).visuals, isEmpty);
      expect(() => images!.add('other'), throwsUnsupportedError);
    }
  });

  test('proof follows sampled frames rather than unsampled source spans', () {
    const frames = [
      SmartTileFrameRef(atlasId: 'a', column: 3, row: 0, columnSpan: 2),
      SmartTileFrameRef(atlasId: 'a', column: 3, row: 0, columnSpan: 2),
    ];
    final full = _imageFixture(frames: frames).plan();
    final sampled = _imageFixture(
      frames: frames,
      sampling: SmartTileFrameSampling.tessellated,
    ).plan();
    expect(full.invariantImageIds(), isEmpty);
    expect(sampled.invariantImageIds(), {'image-a'});
    expect(sampled.resolveBatch().visuals.single.sourceRect.x, 96);
  });

  test('viewport changes recompute guarantees after clipping each variant', () {
    final f = _imageFixture(
      frames: const [
        SmartTileFrameRef(atlasId: 'a', column: 0, row: 0),
        SmartTileFrameRef(atlasId: 'b', column: 0, row: 0),
      ],
      fixed: true,
    );
    final plan = f.plan();
    const left = SmartTileGeometryRect(left: 0, top: 0, width: 1, height: 1);
    const empty = SmartTileGeometryRect(left: 10, top: 0, width: 1, height: 1);
    expect(plan.invariantImageIds(), isNull);
    final clipped = plan.invariantImageIds(viewportBounds: left);
    expect(clipped, {'image-a'});
    expect(
      plan.resolveBatch(elapsedMs: 20, viewportBounds: left).visuals,
      hasLength(1),
    );
    expect(plan.invariantImageIds(viewportBounds: empty), isEmpty);
    expect(plan.invariantImageIds(), isNull);
    expect(clipped, {'image-a'});
  });

  const elapsedSamples = <int>[0, 130, 250, 999, 5000, 123456];
  final viewports = <SmartTileGeometryRect?>[
    null,
    const SmartTileGeometryRect(left: 0, top: 0, width: 8 * 32, height: 8 * 32),
    const SmartTileGeometryRect(
      left: 20 * 32,
      top: 20 * 32,
      width: 5 * 32,
      height: 5 * 32,
    ),
  ];

  ({
    int cellX,
    int cellY,
    String ruleId,
    String candidateId,
    SmartTileRenderChannel channel,
    String tilesetId,
    int srcX,
    int srcY,
    int srcW,
    int srcH,
    int quarterTurns,
    bool flipX,
    double dstLeft,
    double dstTop,
    double dstW,
    double dstH,
    int drawOrder,
  })
  key(SmartTileLayerVisual visual) => (
    cellX: visual.cellX,
    cellY: visual.cellY,
    ruleId: visual.ruleId,
    candidateId: visual.candidateId,
    channel: visual.channel,
    tilesetId: visual.tilesetId,
    srcX: visual.sourceRect.x,
    srcY: visual.sourceRect.y,
    srcW: visual.sourceRect.width,
    srcH: visual.sourceRect.height,
    quarterTurns: visual.transform.quarterTurns,
    flipX: visual.transform.flipX,
    dstLeft: visual.geometry.destinationRect.left,
    dstTop: visual.geometry.destinationRect.top,
    dstW: visual.geometry.destinationRect.width,
    dstH: visual.geometry.destinationRect.height,
    drawOrder: visual.drawOrder,
  );

  for (final pass in SmartTileVisualPass.values) {
    test(
      'plan emits identical visuals to the batch resolver (${pass.name})',
      () {
        for (final layer in smartLayers) {
          final ownerIndex = SmartTilePatternOwnerIndex.build(
            map: map,
            layer: layer,
            catalog: catalog,
          );
          final plan = buildSmartTileLayerVisualPlan(
            map: map,
            layer: layer,
            catalog: catalog,
            pass: pass,
            destinationCellWidth: 32,
            destinationCellHeight: 32,
            patternOwnerIndex: ownerIndex,
          );
          for (final viewport in viewports) {
            for (final elapsedMs in elapsedSamples) {
              final batch = resolveSmartTileLayerVisualBatch(
                map: map,
                layer: layer,
                catalog: catalog,
                pass: pass,
                elapsedMs: elapsedMs,
                destinationCellWidth: 32,
                destinationCellHeight: 32,
                viewportBounds: viewport,
                patternOwnerIndex: ownerIndex,
              );
              final planned = plan.resolveBatch(
                elapsedMs: elapsedMs,
                viewportBounds: viewport,
              );
              expect(
                planned.visuals.map(key).toList(),
                batch.visuals.map(key).toList(),
                reason:
                    'layer=${layer.id} pass=$pass '
                    'elapsedMs=$elapsedMs viewport=$viewport',
              );
              expect(
                planned.work.ownerCellVisits,
                lessThanOrEqualTo(batch.work.ownerCellVisits),
                reason:
                    'ownerCellVisits layer=${layer.id} '
                    'elapsedMs=$elapsedMs viewport=$viewport',
              );
            }
          }
        }
      },
    );
  }
}

({
  MapData map,
  SmartTileLayer layer,
  ProjectSmartTileCatalog catalog,
  SmartTileLayerVisualPlan Function() plan,
})
_imageFixture({
  List<SmartTileFrameRef> frames = const [
    SmartTileFrameRef(atlasId: 'a', column: 0, row: 0),
    SmartTileFrameRef(atlasId: 'a', column: 1, row: 0),
  ],
  bool fixed = false,
  int width = 1,
  int height = 1,
  SmartTileFrameSampling sampling = SmartTileFrameSampling.fullFrame,
}) {
  final layer = SmartTileLayer(
    id: 'ground',
    name: 'Ground',
    presetId: 'ground',
    usage: SmartTileUsage.terrain,
    animationActivation: SmartTileAnimationActivation.onEnter,
    materialPalette: ['', 'water'],
    field: SmartTileField.cell(semanticCells: List.filled(width * height, 1)),
  );
  final map = MapData(
    id: 'room',
    name: 'Room',
    size: GridSize(width: width, height: height),
    layers: [layer],
  );
  final catalog = ProjectSmartTileCatalog(
    materials: const [
      ProjectSmartTileMaterial(
        id: 'water',
        name: 'Water',
        connectionGroupId: 'water',
      ),
      ProjectSmartTileMaterial(
        id: 'other',
        name: 'Other',
        connectionGroupId: 'other',
      ),
    ],
    atlases: const [
      ProjectSmartTileAtlas(
        id: 'a',
        name: 'A',
        tilesetId: 'image-a',
        columns: 4,
        rows: 1,
      ),
      ProjectSmartTileAtlas(
        id: 'b',
        name: 'B',
        tilesetId: 'image-b',
        columns: 4,
        rows: 1,
        pixelOffsetX: 64,
      ),
    ],
    animations: [
      ProjectSmartTileAnimation(
        id: 'wave',
        name: 'Wave',
        sync: SmartTileAnimationSync.perCell,
        frames: [
          for (final frame in frames)
            ProjectSmartTileAnimationFrame(frame: frame, durationMs: 20),
        ],
      ),
    ],
    presets: [
      ProjectSmartTilePreset(
        id: 'ground',
        name: 'Ground',
        usage: SmartTileUsage.terrain,
        topology: SmartTileTopology.uniform,
        templateHint: SmartTileTemplateHint.simple,
        coveragePolicy: SmartTileCoveragePolicy.sparse,
        coverageProfile: const SmartTileCoverageProfile(
          mode: SmartTileCoverageMode.template,
        ),
        transformPolicy: const SmartTileTransformPolicy(),
        defaultMaterialId: 'water',
        allowedMaterialIds: ['water', 'other'],
        rules: [
          SmartTileRule(
            id: 'fill',
            centerMatch: const SmartTileSlotMatch.material('water'),
            candidates: [
              SmartTileCandidate(
                id: 'wave',
                parts: [
                  SmartTileVisualPart(
                    source: const SmartTileVisualSource.animation(
                      animationId: 'wave',
                    ),
                    frameSampling: sampling,
                    spatialClip: SmartTileSpatialClip(
                      left: 0,
                      top: 0,
                      right: 1,
                      bottom: 1,
                    ),
                  ),
                  if (fixed)
                    const SmartTileVisualPart(
                      source: SmartTileVisualSource.frame(
                        frame: SmartTileFrameRef(
                          atlasId: 'a',
                          column: 0,
                          row: 0,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SmartTileRule(
            id: 'unused',
            centerMatch: SmartTileSlotMatch.material('other'),
            candidates: [
              SmartTileCandidate(
                id: 'other',
                parts: [
                  SmartTileVisualPart(
                    source: SmartTileVisualSource.frame(
                      frame: SmartTileFrameRef(atlasId: 'b', column: 0, row: 0),
                    ),
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
    map: map,
    layer: layer,
    catalog: catalog,
    plan: () => buildSmartTileLayerVisualPlan(
      map: map,
      layer: layer,
      catalog: catalog,
      pass: SmartTileVisualPass.background,
    ),
  );
}
