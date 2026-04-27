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

GameplayWorldState _worldWithEntities(
  List<MapEntity> entities, {
  Set<GridPos> collisionBlocked = const <GridPos>{},
  List<MapLayer> extraLayers = const <MapLayer>[],
  ProjectManifest? project,
}) {
  const mapSize = GridSize(width: 10, height: 10);
  final collisionCells = List<bool>.filled(
    mapSize.width * mapSize.height,
    false,
  );
  for (final pos in collisionBlocked) {
    if (pos.x < 0 ||
        pos.y < 0 ||
        pos.x >= mapSize.width ||
        pos.y >= mapSize.height) {
      continue;
    }
    collisionCells[pos.y * mapSize.width + pos.x] = true;
  }
  final map = MapData(
    id: 'map_test',
    name: 'Map Test',
    size: mapSize,
    layers: <MapLayer>[
      CollisionLayer(
        id: 'collision',
        name: 'Collision',
        collisions: collisionCells,
      ),
      ...extraLayers,
    ],
    entities: entities,
  );
  return GameplayWorldState.initial(
    map: map,
    playerPos: const GridPos(x: 0, y: 0),
    project: project,
  );
}

void main() {
  group('evaluateScriptedNpcAnchorPassability', () {
    test('scripted NPC cannot traverse player cell', () {
      final world = _worldWithEntities(<MapEntity>[
        _npc(id: 'npc_1', pos: const GridPos(x: 1, y: 1)),
      ]);

      final blockedByPlayer = evaluateScriptedNpcAnchorPassability(
        world: world,
        entityId: 'npc_1',
        anchorPos: const GridPos(x: 0, y: 0),
        dynamicBlockedCells: <GridPos>[world.player.pos],
      );
      expect(blockedByPlayer.passable, isFalse);
      expect(blockedByPlayer.reason, contains('Dynamic blocker'));
    });

    test('self occupancy is ignored for current anchor (no self-block)', () {
      final world = _worldWithEntities(<MapEntity>[
        _npc(id: 'npc_1', pos: const GridPos(x: 4, y: 4)),
      ]);

      final sameAnchor = evaluateScriptedNpcAnchorPassability(
        world: world,
        entityId: 'npc_1',
        anchorPos: const GridPos(x: 4, y: 4),
      );
      expect(sameAnchor.passable, isTrue);
    });

    test('scripted NPC cannot traverse another blocking NPC', () {
      final world = _worldWithEntities(<MapEntity>[
        _npc(id: 'npc_1', pos: const GridPos(x: 1, y: 1)),
        _blockingNpc(id: 'npc_block', pos: const GridPos(x: 3, y: 1)),
      ]);

      final reachableBeforeNpc = evaluateScriptedNpcAnchorPassability(
        world: world,
        entityId: 'npc_1',
        anchorPos: const GridPos(x: 2, y: 1),
      );
      expect(reachableBeforeNpc.passable, isTrue);

      final blocked = evaluateScriptedNpcAnchorPassability(
        world: world,
        entityId: 'npc_1',
        anchorPos: const GridPos(x: 3, y: 1),
      );
      expect(blocked.passable, isFalse);
      expect(blocked.reason, contains('Blocked collision cell'));
    });

    test('scripted NPC 2x2 cannot traverse blocked obstacle cells', () {
      // NPC 2x2 => collision par défaut alignée sur tout le footprint 2x2.
      final world = _worldWithEntities(<MapEntity>[
        _npc(
          id: 'npc_big',
          pos: const GridPos(x: 5, y: 5),
          size: const GridSize(width: 2, height: 2),
        ),
      ], collisionBlocked: <GridPos>{
        // Pour l'ancrage (5,6), le footprint inclut (5,7).
        const GridPos(x: 5, y: 7),
      });

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

    test('walk movement blocks water surface cells for scripted NPC', () {
      final waterCells = List<bool>.filled(10 * 10, false);
      waterCells[1 * 10 + 2] = true;
      final world = _worldWithEntities(
        <MapEntity>[
          _npc(id: 'npc_1', pos: const GridPos(x: 1, y: 1)),
        ],
        extraLayers: <MapLayer>[
          MapLayer.path(
            id: 'water_path_layer',
            name: 'Water Path',
            presetId: 'water_path',
            cells: waterCells,
          ),
        ],
        project: ProjectManifest(
          name: 'project',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[
            ProjectTilesetEntry(
              id: 'ts',
              name: 'Tileset',
              relativePath: 'tileset.png',
            ),
          ],
          surfaceCatalog: ProjectSurfaceCatalog(),
          pathPresets: <ProjectPathPreset>[
            ProjectPathPreset(
              id: 'water_path',
              name: 'Water',
              surfaceKind: PathSurfaceKind.water,
              tilesetId: 'ts',
            ),
          ],
        ),
      );

      final result = evaluateScriptedNpcAnchorPassability(
        world: world,
        entityId: 'npc_1',
        anchorPos: const GridPos(x: 2, y: 1),
        movementMode: MovementMode.walk,
      );
      expect(result.passable, isFalse);
      expect(result.reason, contains('waterRequiresSurf'));
    });
  });
}
