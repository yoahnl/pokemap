import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_path_pattern.dart';

void main() {
  test('offers only the two no-code path patterns', () {
    expect(
      smartTilePathPatterns.map((pattern) => pattern.id),
      <SmartTilePathPatternId>[
        SmartTilePathPatternId.classic,
        SmartTilePathPatternId.closedContour,
      ],
    );
  });

  test('classic path projects the sixteen cardinal forms', () {
    final pattern = smartTilePathPatternById(SmartTilePathPatternId.classic);

    expect(pattern.configuration.topology, SmartTileTopology.cardinal4);
    expect(pattern.configuration.templateHint, SmartTileTemplateHint.edge16);
    expect(pattern.primaryColumns, 4);
    expect(pattern.primaryRows, 4);
    expect(pattern.primarySlots, hasLength(16));
    expect(
      pattern.requiredMasks,
      smartTileCanonicalMasks(SmartTileTemplateHint.edge16).toSet(),
    );
    expect(pattern.cornerSlots, isEmpty);
  });

  test(
    'closed contour keeps the 3 by 3 pattern and adds four inner corners',
    () {
      final pattern = smartTilePathPatternById(
        SmartTilePathPatternId.closedContour,
      );

      expect(pattern.configuration.topology, SmartTileTopology.wangCorner4);
      expect(
        pattern.configuration.templateHint,
        SmartTileTemplateHint.corner12,
      );
      expect(pattern.primaryColumns, 3);
      expect(pattern.primaryRows, 3);
      expect(pattern.primarySlots, hasLength(9));
      expect(pattern.cornerColumns, 2);
      expect(pattern.cornerRows, 2);
      expect(pattern.cornerSlots, hasLength(4));
      expect(pattern.slots, hasLength(13));
      expect(pattern.requiredMasks, <int>{
        ...smartTileCanonicalMasks(SmartTileTemplateHint.corner12),
        smartTileCornerMask,
      });
      expect(
        pattern.primarySlots.map((slot) => (slot.column, slot.row, slot.mask)),
        <(int, int, int)>[
          (0, 0, smartTileSouthEastBit),
          (1, 0, smartTileSouthWestBit | smartTileSouthEastBit),
          (2, 0, smartTileSouthWestBit),
          (0, 1, smartTileNorthEastBit | smartTileSouthEastBit),
          (1, 1, smartTileCornerMask),
          (2, 1, smartTileNorthWestBit | smartTileSouthWestBit),
          (0, 2, smartTileNorthEastBit),
          (1, 2, smartTileNorthWestBit | smartTileNorthEastBit),
          (2, 2, smartTileNorthWestBit),
        ],
      );
      expect(pattern.cornerSlots.map((slot) => slot.mask).toSet(), <int>{
        0x70,
        0xB0,
        0xD0,
        0xE0,
      });
    },
  );
}
