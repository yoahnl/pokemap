import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  test('an automatic bump warp intercepts contact at the same door anchor', () {
    final world = _doorWorld('on_bump');
    final result = stepGameplayWorld(
        world, const MoveIntent(Direction.north, pixelsPerStep: 16));
    expect(result, isA<WarpTriggered>());
    expect((result as WarpTriggered).warp.warpId, 'door-arrival');
  });

  test('a Scene-only arrival leaves the next door contact available', () {
    final world = _doorWorld('scene_only');
    final result = stepGameplayWorld(
        world, const MoveIntent(Direction.north, pixelsPerStep: 16));
    expect(result, isA<Blocked>());
    expect((result as Blocked).entityBumpContact?.entityId, 'door');
    expect(result.world.player.pos, const GridPos(x: 1, y: 1));
  });
}

GameplayWorldState _doorWorld(String mode) => GameplayWorldState.initial(
      map: MapData(
        id: 'map',
        name: 'Map',
        size: const GridSize(width: 3, height: 3),
        layers: const [MapLayer.object(id: 'objects', name: 'Objects')],
        entities: const [
          MapEntity(
            id: 'door',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 1, y: 0),
            blocksMovement: true,
            npc: MapEntityNpcData(characterId: 'door-character'),
            properties: {'collision.width': '1', 'collision.height': '1'},
          ),
        ],
        warps: [
          MapWarp.fromJson({
            'id': 'door-arrival',
            'pos': {'x': 1, 'y': 0},
            'targetMapId': 'map',
            'targetPos': {'x': 1, 'y': 0},
            'triggerMode': mode,
          }),
        ],
      ),
      playerPos: const GridPos(x: 1, y: 1),
    );
