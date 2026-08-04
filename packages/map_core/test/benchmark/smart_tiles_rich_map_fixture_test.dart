import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../../../tools/performance/smart_tiles_rich_map_fixture.dart';

void main() {
  test('builds the deterministic rich Smart Tiles scaling fixture', () {
    final first = generateSmartTilesRichMapFixture(extent: 128);
    final second = generateSmartTilesRichMapFixture(extent: 128);

    expect(first.extent, 128);
    expect(first.map.size, const GridSize(width: 128, height: 128));
    expect(first.structuralChecksum, second.structuralChecksum);
    expect(first.structuralChecksum, isNotEmpty);
    expect(
      first.map.layers.whereType<SmartTileLayer>().map((layer) => layer.usage),
      containsAll(<SmartTileUsage>[
        SmartTileUsage.terrain,
        SmartTileUsage.path,
        SmartTileUsage.forestSurface,
      ]),
    );
    expect(
        first.map.layers.whereType<TileLayer>().single.palette, hasLength(3));
    expect(first.map.layers.whereType<ObjectLayer>().single.tileObjects,
        isNotEmpty);
    expect(
      first.map.layers.whereType<CollisionLayer>().single.collisions,
      contains(true),
    );
    expect(first.map.placedElements, isNotEmpty);
    expect(first.manifest.smartTileCatalog.patterns, isNotEmpty);
    expect(
      first.manifest.smartTileCatalog.animations.map((value) => value.sync),
      containsAll(<SmartTileAnimationSync>[
        SmartTileAnimationSync.global,
        SmartTileAnimationSync.perCell,
      ]),
    );
    expect(
      first.renderChannels,
      containsAll(SmartTileRenderChannel.values),
    );
    expect(first.workCounts.totalCells, 128 * 128);
    expect(first.workCounts.smartLayerCount, 3);
    expect(first.workCounts.literalLayerCount, 1);

    expect(() => MapValidator.validate(first.map), returnsNormally);
    expect(() => ProjectValidator.validate(first.manifest), returnsNormally);
  });

  test('supports the complete 128² to 1024² benchmark range', () {
    final largest = generateSmartTilesRichMapFixture(extent: 1024);

    expect(largest.workCounts.totalCells, 1024 * 1024);
    expect(largest.map.layers.whereType<TileLayer>().single.cells,
        hasLength(1024 * 1024));
    expect(largest.structuralChecksum, isNotEmpty);
    expect(
      () => generateSmartTilesRichMapFixture(extent: 64),
      throwsFormatException,
    );
    expect(
      () => generateSmartTilesRichMapFixture(extent: 2048),
      throwsFormatException,
    );
  });
}
