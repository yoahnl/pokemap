import 'package:avelune_studio/features/resources/application/atlas_selection_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

const source = ProjectRegularAtlasTilesetSource(
  assetId: 'atlas',
  pixelWidth: 64,
  pixelHeight: 100,
  tileWidth: 16,
  tileHeight: 24,
  marginX: 2,
  marginY: 3,
  spacingX: 2,
  spacingY: 4,
  pixelOffsetX: 7,
  pixelOffsetY: -9,
);

void main() {
  test('non-square source selection uses canonical crop and rejects margins and gaps', () {
    final controller = AtlasSelectionController(source: source);
    expect(
      controller.select(3, 4, begin: true),
      const TilesetSourceRect(x: 0, y: 0),
    );
    controller.end();
    final selection = controller.select(21, 32, begin: true)!;
    expect(selection, const TilesetSourceRect(x: 1, y: 1));
    final resolved = const ProjectTilesetVisualResolver().resolve(
      source: source,
      selection: ProjectTilesetVisualSelection.regularAtlas(source: selection),
      cellWidth: 16,
      cellHeight: 24,
    );
    expect(resolved.frames.single.slices.single.sourceRect.x, 20);
    expect(resolved.frames.single.slices.single.sourceRect.y, 31);
    for (final (x, y) in [
      (1.0, 4.0),
      (3.0, 2.0),
      (18.0, 4.0),
      (3.0, 27.0),
      (55.0, 4.0),
      (3.0, 83.0),
    ]) {
      controller.end();
      expect(controller.select(x, y, begin: true), isNull);
    }
  });

  test(
    'rectangle drag selects across spacing and a cancelled drag cannot leak',
    () {
      final controller = AtlasSelectionController(source: source);
      expect(
        controller.select(3, 4, begin: true),
        const TilesetSourceRect(x: 0, y: 0),
      );
      expect(
        controller.select(53, 82),
        const TilesetSourceRect(x: 0, y: 0, width: 3, height: 3),
      );
      controller.end();
      expect(controller.select(21, 32), isNull);
      expect(controller.select(18, 4, begin: true), isNull);
      expect(controller.select(21, 32), isNull);
      controller.end();
      controller.select(53, 82, begin: true);
      expect(
        controller.select(3, 4),
        const TilesetSourceRect(x: 0, y: 0, width: 3, height: 3),
      );
    },
  );

  test('terrain selection stays one cell and a source change cancels its old gesture', () {
    final controller = AtlasSelectionController(
      source: source,
      singleCell: true,
    );
    expect(
      controller.select(3, 4, begin: true),
      const TilesetSourceRect(x: 0, y: 0),
    );
    expect(controller.select(53, 82), const TilesetSourceRect(x: 2, y: 2));
    expect(controller.select(53, 82), isNull);
    controller.update(
      source: ProjectRegularAtlasTilesetSource(
        assetId: 'other',
        pixelWidth: source.pixelWidth,
        pixelHeight: source.pixelHeight,
        tileWidth: source.tileWidth,
        tileHeight: source.tileHeight,
        marginX: source.marginX,
        marginY: source.marginY,
        spacingX: source.spacingX,
        spacingY: source.spacingY,
        pixelOffsetX: source.pixelOffsetX,
        pixelOffsetY: source.pixelOffsetY,
      ),
      singleCell: true,
    );
    expect(controller.select(21, 32), isNull);
    expect(
      controller.select(21, 32, begin: true),
      const TilesetSourceRect(x: 1, y: 1),
    );
  });
}
