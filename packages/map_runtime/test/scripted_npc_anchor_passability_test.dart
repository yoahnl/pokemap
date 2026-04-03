import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

MapEntity _npc({
  required String id,
  required GridPos pos,
  GridSize size = const GridSize(width: 1, height: 1),
}) {
  return MapEntity(
    id: id,
    kind: MapEntityKind.npc,
    pos: pos,
    size: size,
    npc: const MapEntityNpcData(),
  );
}

MapEntity _blockingNpc({
  required String id,
  required GridPos pos,
}) {
  return MapEntity(
    id: id,
    kind: MapEntityKind.npc,
    pos: pos,
    size: const GridSize(width: 1, height: 1),
    blocksMovement: true,
    npc: const MapEntityNpcData(),
  );
}

GameplayWorldState _worldWithEntities(List<MapEntity> entities) {
  final map = MapData(
    id: 'map_test',
    name: 'Map Test',
    size: const GridSize(width: 10, height: 10),
    entities: entities,
  );
  return GameplayWorldState.initial(
    map: map,
    playerPos: const GridPos(x: 0, y: 0),
  );
}

void main() {
  group('evaluateScriptedNpcAnchorPassability', () {
    test('1x1 NPC: reachable and blocked anchors are distinguished', () {
      final world = _worldWithEntities(<MapEntity>[
        _npc(id: 'npc_1', pos: const GridPos(x: 1, y: 1)),
        _blockingNpc(id: 'npc_block', pos: const GridPos(x: 3, y: 1)),
      ]);

      final reachable = evaluateScriptedNpcAnchorPassability(
        world: world,
        entityId: 'npc_1',
        anchorPos: const GridPos(x: 2, y: 1),
      );
      expect(reachable.passable, isTrue);

      final blocked = evaluateScriptedNpcAnchorPassability(
        world: world,
        entityId: 'npc_1',
        anchorPos: const GridPos(x: 3, y: 1),
      );
      expect(blocked.passable, isFalse);
      expect(blocked.reason, contains('Blocked collision cell'));
    });

    test('2x2 NPC: collision footprint is evaluated, not only top-left', () {
      // NPC 2x2 => collision default 1x1 sur les "pieds" (offset Y=+1).
      final world = _worldWithEntities(<MapEntity>[
        _npc(
          id: 'npc_big',
          pos: const GridPos(x: 5, y: 5),
          size: const GridSize(width: 2, height: 2),
        ),
        // Bloque la cellule collision attendue pour l'ancrage (5,6):
        // collision cell = (5,7).
        _blockingNpc(id: 'npc_block', pos: const GridPos(x: 5, y: 7)),
      ]);

      final sameAnchor = evaluateScriptedNpcAnchorPassability(
        world: world,
        entityId: 'npc_big',
        anchorPos: const GridPos(x: 5, y: 5),
      );
      expect(sameAnchor.passable, isTrue);

      final blockedDown = evaluateScriptedNpcAnchorPassability(
        world: world,
        entityId: 'npc_big',
        anchorPos: const GridPos(x: 5, y: 6),
      );
      expect(blockedDown.passable, isFalse);
      expect(blockedDown.reason, contains('(5, 7)'));
    });

    test('returns explicit failure on out-of-bounds footprint', () {
      final world = _worldWithEntities(<MapEntity>[
        _npc(
          id: 'npc_big',
          pos: const GridPos(x: 8, y: 8),
          size: const GridSize(width: 2, height: 2),
        ),
      ]);

      final result = evaluateScriptedNpcAnchorPassability(
        world: world,
        entityId: 'npc_big',
        anchorPos: const GridPos(x: 9, y: 9),
      );
      expect(result.passable, isFalse);
      expect(result.reason, contains('out of bounds'));
    });
  });
}
