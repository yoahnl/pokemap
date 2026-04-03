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

    test('npc 2x2 defaults to full-size collision (2x2)', () {
      const entity = MapEntity(
        id: 'npc_big',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 26, y: 12),
        size: GridSize(width: 2, height: 2),
        npc: MapEntityNpcData(),
      );

      final footprint = resolveEntityCollisionFootprint(entity);
      // Anchor is top-left of the entity; default collision now covers the
      // entire logical NPC size to avoid visual pass-through.
      expect(footprint.pos, const GridPos(x: 26, y: 12));
      expect(footprint.size, const GridSize(width: 2, height: 2));
      expect(
        resolveEntityCollisionCells(entity).toList(growable: false),
        const <GridPos>[
          GridPos(x: 26, y: 12),
          GridPos(x: 27, y: 12),
          GridPos(x: 26, y: 13),
          GridPos(x: 27, y: 13),
        ],
      );
    });
  });
}
