import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../../../tools/performance/smart_tiles_rich_map_fixture.dart';

void main() {
  test('viewport work is independent from total dense field size', () {
    final small = generateSmartTilesRichMapFixture(extent: 128);
    final large = generateSmartTilesRichMapFixture(extent: 1024);

    SmartTileLayerVisualBatch resolve(SmartTilesRichMapFixture fixture) {
      final layer = fixture.map.layers.whereType<SmartTileLayer>().first;
      final startX = (fixture.extent - 24) ~/ 2;
      final startY = (fixture.extent - 18) ~/ 2;
      return resolveSmartTileLayerVisualBatch(
        map: fixture.map,
        layer: layer,
        catalog: fixture.manifest.smartTileCatalog,
        pass: SmartTileVisualPass.background,
        startX: startX,
        startY: startY,
        endX: startX + 24,
        endY: startY + 18,
      );
    }

    final smallBatch = resolve(small);
    final largeBatch = resolve(large);

    expect(smallBatch.work.requestedCellCount, 24 * 18);
    expect(largeBatch.work.requestedCellCount, 24 * 18);
    expect(
      largeBatch.work.ownerCellVisits,
      smallBatch.work.ownerCellVisits,
    );
    expect(
      largeBatch.work.ownerCellVisits,
      lessThan(large.workCounts.totalCells),
    );
    expect(largeBatch.work.resolvedVisualCount, largeBatch.visuals.length);
    expect(largeBatch.work.patternStrokeCellVisits, isNonNegative);
  });

  test('legacy list API is an exact projection of the profiled batch', () {
    final fixture = generateSmartTilesRichMapFixture(extent: 128);
    final layer = fixture.map.layers.whereType<SmartTileLayer>().first;
    final batch = resolveSmartTileLayerVisualBatch(
      map: fixture.map,
      layer: layer,
      catalog: fixture.manifest.smartTileCatalog,
      pass: SmartTileVisualPass.background,
      startX: 0,
      startY: 0,
      endX: 8,
      endY: 8,
    );
    final legacy = resolveSmartTileLayerVisuals(
      map: fixture.map,
      layer: layer,
      catalog: fixture.manifest.smartTileCatalog,
      pass: SmartTileVisualPass.background,
      startX: 0,
      startY: 0,
      endX: 8,
      endY: 8,
    );

    List<Object?> signature(SmartTileLayerVisual visual) => <Object?>[
          visual.cellX,
          visual.cellY,
          visual.ruleId,
          visual.candidateId,
          visual.channel,
          visual.tilesetId,
          visual.sourceRect,
          visual.transform,
          visual.geometry.destinationRect.left,
          visual.geometry.destinationRect.top,
          visual.geometry.destinationRect.width,
          visual.geometry.destinationRect.height,
          visual.geometry.visualBounds.left,
          visual.geometry.visualBounds.top,
          visual.geometry.visualBounds.width,
          visual.geometry.visualBounds.height,
          visual.drawOrder,
        ];
    expect(legacy.map(signature), batch.visuals.map(signature));
    expect(batch.work.requestedCellCount, 64);
    expect(batch.work.ownerCellVisits, greaterThanOrEqualTo(64));
  });

  test('reused pattern owner index removes stroke scans from frame work', () {
    final fixture = generateSmartTilesRichMapFixture(extent: 128);
    final layer = fixture.map.layers
        .whereType<SmartTileLayer>()
        .firstWhere((layer) => layer.patternStrokes.isNotEmpty);
    final index = SmartTilePatternOwnerIndex.build(
      map: fixture.map,
      layer: layer,
      catalog: fixture.manifest.smartTileCatalog,
    );
    final indexed = resolveSmartTileLayerVisualBatch(
      map: fixture.map,
      layer: layer,
      catalog: fixture.manifest.smartTileCatalog,
      pass: SmartTileVisualPass.foreground,
      startX: 0,
      startY: 0,
      endX: 24,
      endY: 18,
      patternOwnerIndex: index,
    );
    final uncached = resolveSmartTileLayerVisualBatch(
      map: fixture.map,
      layer: layer,
      catalog: fixture.manifest.smartTileCatalog,
      pass: SmartTileVisualPass.foreground,
      startX: 0,
      startY: 0,
      endX: 24,
      endY: 18,
    );

    expect(index.entryCount, layer.patternStrokes.single.cells.length);
    expect(index.entryCount, lessThan(fixture.workCounts.totalCells));
    expect(indexed.work.patternStrokeCellVisits, 0);
    expect(indexed.work.ownerCellVisits, uncached.work.ownerCellVisits);
    expect(indexed.visuals.length, uncached.visuals.length);
  });
}
