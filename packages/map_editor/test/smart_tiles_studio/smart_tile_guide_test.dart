import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_guide.dart';

void main() {
  test('ERW guide exposes sixteen cells for twelve path signatures', () {
    final guide = smartTileGuideById(SmartTileGuideId.erwCorner16);

    expect(guide.supportedUsages, contains(SmartTileUsage.path));
    expect(guide.templateHint, SmartTileTemplateHint.corner12);
    expect(guide.topology, SmartTileTopology.wangCorner4);
    expect(guide.columns, 5);
    expect(guide.rows, 5);
    expect(guide.cells, hasLength(16));
    expect(guide.anchorCell.number, 1);
    expect(
      guide.requiredMasks,
      smartTileCanonicalMasks(SmartTileTemplateHint.corner12).toSet(),
    );
    expect(
      guide.cellsForMask(0x10).map((cell) => cell.number),
      <int>[1, 3],
    );
    expect(
      <int, int>{for (final cell in guide.cells) cell.number: cell.mask},
      <int, int>{
        1: 0x10,
        2: 0xB0,
        3: 0x10,
        4: 0x90,
        5: 0x80,
        6: 0xD0,
        7: 0x80,
        8: 0xC0,
        9: 0x40,
        10: 0xE0,
        11: 0x40,
        12: 0x60,
        13: 0x20,
        14: 0x70,
        15: 0x20,
        16: 0x30,
      },
    );
  });

  test('only offers guides that really support the selected usage', () {
    expect(
      smartTileGuidesForUsage(SmartTileUsage.path),
      contains(erwCorner16Guide),
    );
    expect(smartTileGuidesForUsage(SmartTileUsage.terrain), isEmpty);
    expect(smartTileGuidesForUsage(SmartTileUsage.forestSurface), isEmpty);
  });
}
