import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('map entity collision footprint defaults', () {
    test('npc 1x1 keeps 1x1 collision at anchor', () {
      const entity = MapEntity(
        id: 'npc_small',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 10, y: 8),
        size: GridSize(width: 1, height: 1),
        npc: MapEntityNpcData(),
      );

      final footprint = resolveEntityCollisionFootprint(entity);
      expect(footprint.pos, const GridPos(x: 10, y: 8));
      expect(footprint.size, const GridSize(width: 1, height: 1));
      expect(
        resolveEntityCollisionCells(entity).toList(growable: false),
        const <GridPos>[GridPos(x: 10, y: 8)],
      );
    });

    test('npc 2x2 indexes only the bottom row for grid systems', () {
      const entity = MapEntity(
        id: 'npc_big',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 26, y: 12),
        size: GridSize(width: 2, height: 2),
        npc: MapEntityNpcData(),
      );

      final footprint = resolveEntityCollisionFootprint(entity);
      expect(footprint.pos, const GridPos(x: 26, y: 13));
      expect(footprint.size, const GridSize(width: 2, height: 1));
      expect(
        resolveEntityCollisionCells(entity).toList(growable: false),
        const <GridPos>[GridPos(x: 26, y: 13), GridPos(x: 27, y: 13)],
      );
    });
    for (final tileSize in [16, 32]) {
      test('npc contact scales with $tileSize px tiles', () {
        const entity = MapEntity(
          id: 'npc',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 5, y: 5),
          size: GridSize(width: 2, height: 2),
          npc: MapEntityNpcData(),
        );
        final rect = resolveEntityCollisionRectPx(
          entity,
          tileWidthPx: tileSize,
          tileHeightPx: tileSize,
        );
        final scale = tileSize ~/ 16;
        expect(rect.leftPx, 6 * tileSize - 6 * scale);
        expect(rect.topPx, 7 * tileSize - 8 * scale);
        expect(rect.widthPx, 12 * scale);
        expect(rect.heightPx, 8 * scale);
        expect(entity.size, const GridSize(width: 2, height: 2));
      });
    }
    test('explicit collision retains authored dimensions and offset', () {
      const entity = MapEntity(
        id: 'npc',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 5, y: 5),
        size: GridSize(width: 2, height: 2),
        properties: {
          'collision.width': '1',
          'collision.height': '2',
          'collision.offsetX': '1',
          'collision.offsetY': '0',
        },
      );
      final rect = resolveEntityCollisionRectPx(
        entity,
        tileWidthPx: 16,
        tileHeightPx: 16,
      );
      expect(rect.leftPx, 96);
      expect(rect.topPx, 80);
      expect(rect.widthPx, 16);
      expect(rect.heightPx, 32);
    });
  });
}
