import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_atlas_selection.dart';

void main() {
  test('rectangular atlas selection is inclusive and direction independent',
      () {
    const start = GridPos(x: 4, y: 5);
    const end = GridPos(x: 2, y: 3);

    final forward = selectSmartTileAtlasFrame(
      atlasId: 'atlas',
      start: start,
      end: end,
      columns: 8,
      rows: 8,
    );
    final reverse = selectSmartTileAtlasFrame(
      atlasId: 'atlas',
      start: end,
      end: start,
      columns: 8,
      rows: 8,
    );

    expect(forward, reverse);
    expect(forward.column, 2);
    expect(forward.row, 3);
    expect(forward.columnSpan, 3);
    expect(forward.rowSpan, 3);
  });

  test('rectangular atlas selection rejects cells outside the grid', () {
    expect(
      () => selectSmartTileAtlasFrame(
        atlasId: 'atlas',
        start: const GridPos(x: 0, y: 0),
        end: const GridPos(x: 8, y: 0),
        columns: 8,
        rows: 8,
      ),
      throwsRangeError,
    );
  });
}
