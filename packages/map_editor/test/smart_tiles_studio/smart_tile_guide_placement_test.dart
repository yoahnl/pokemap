import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_grid_detector.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_guide.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_guide_placement.dart';

void main() {
  const geometry = SmartTileGridGeometry(
    imageWidth: 1760,
    imageHeight: 2304,
    cellWidth: 32,
    cellHeight: 32,
  );

  test('places every ERW cell relative to the clicked number 1', () {
    final result = placeSmartTileGuide(
      guide: erwCorner16Guide,
      geometry: geometry,
      anchorColumn: 20,
      anchorRow: 20,
    );

    expect(result.isValid, isTrue);
    expect(result.frames, hasLength(16));
    expect(result.frameForNumber(1), (column: 20, row: 20));
    expect(result.frameForNumber(9), (column: 18, row: 16));
    expect(result.frameForNumber(3), (column: 21, row: 19));
  });

  test('rejects the whole placement when one guide cell leaves the atlas', () {
    final result = placeSmartTileGuide(
      guide: erwCorner16Guide,
      geometry: geometry,
      anchorColumn: 1,
      anchorRow: 2,
    );

    expect(result.isValid, isFalse);
    expect(result.frames, isEmpty);
    expect(result.outOfBoundsNumbers, isNotEmpty);
    expect(result.outOfBoundsNumbers, containsAll(<int>[7, 8, 9, 11, 12]));
  });
}
