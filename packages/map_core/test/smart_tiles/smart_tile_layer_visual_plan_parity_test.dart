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
