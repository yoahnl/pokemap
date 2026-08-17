import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

const _mapId = 'npc_patrol_map';
const _npcId = 'patrolling_npc';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a patrol authored on the map actually walks the npc in game', () async {
    final game = _PatrolGame(
      bundle: _bundle(
        _npc(
          mode: MapEntityNpcMovementMode.patrol,
          waypoints: const <GridPos>[GridPos(x: 1, y: 0), GridPos(x: 3, y: 0)],
        ),
      ),
      projectFilePath: '/tmp/npc_patrol/project.json',
    );

    await _load(game);
    expect(
      game.debugRuntimeNpcPositions[_npcId],
      const GridPos(x: 1, y: 0),
      reason: 'the npc starts on its authored tile',
    );

    await _pumpUntil(
      game,
      () => game.debugRuntimeNpcPositions[_npcId] != const GridPos(x: 1, y: 0),
    );

    expect(
      game.debugRuntimeNpcPositions[_npcId]!.y,
      0,
      reason: 'the patrol must stay on the authored row',
    );
    expect(
      game.debugRuntimeNpcPositions[_npcId]!.x,
      greaterThan(1),
      reason: 'the npc must advance toward its second waypoint',
    );
  });

  test('an idle npc never leaves its authored tile', () async {
    final game = _PatrolGame(
      bundle: _bundle(
        _npc(
          mode: MapEntityNpcMovementMode.idle,
          waypoints: const <GridPos>[GridPos(x: 1, y: 0), GridPos(x: 3, y: 0)],
        ),
      ),
      projectFilePath: '/tmp/npc_idle/project.json',
    );

    await _load(game);
    await _pump(game, ticks: 120);

    expect(
      game.debugRuntimeNpcPositions[_npcId],
      const GridPos(x: 1, y: 0),
      reason: 'idle must ignore waypoints even when they are authored',
    );
  });

  test('a patrol with a single waypoint stays put instead of drifting',
      () async {
    final game = _PatrolGame(
      bundle: _bundle(
        _npc(
          mode: MapEntityNpcMovementMode.patrol,
          waypoints: const <GridPos>[GridPos(x: 3, y: 0)],
        ),
      ),
      projectFilePath: '/tmp/npc_patrol_single/project.json',
    );

    await _load(game);
    await _pump(game, ticks: 120);

    expect(
      game.debugRuntimeNpcPositions[_npcId],
      const GridPos(x: 1, y: 0),
      reason: 'a route needs at least two waypoints to exist',
    );
  });
}

MapEntity _npc({
  required MapEntityNpcMovementMode mode,
  required List<GridPos> waypoints,
}) =>
    MapEntity(
      id: _npcId,
      name: 'Patrolling npc',
      kind: MapEntityKind.npc,
      pos: const GridPos(x: 1, y: 0),
      blocksMovement: false,
      npc: MapEntityNpcData(
        characterId: 'patrol_character',
        movement: MapEntityNpcMovementConfig(
          mode: mode,
          waypoints: waypoints,
          stepDurationMs: 16,
          pauseDurationMs: 0,
        ),
      ),
    );

RuntimeMapBundle _bundle(MapEntity npc) {
  final project = ProjectManifest(
    name: 'Npc patrol runtime integration',
    maps: const <ProjectMapEntry>[
      ProjectMapEntry(
        id: _mapId,
        name: 'Npc Patrol Map',
        relativePath: 'maps/npc_patrol.json',
      ),
    ],
    tilesets: const <ProjectTilesetEntry>[
      ProjectTilesetEntry(
        id: 'patrol_sheet',
        name: 'Patrol sheet',
        relativePath: 'tilesets/patrol.png',
      ),
    ],
    characters: const <ProjectCharacterEntry>[
      ProjectCharacterEntry(
        id: 'patrol_character',
        name: 'Patrol character',
        tilesetId: 'patrol_sheet',
        frameWidth: 1,
        frameHeight: 1,
      ),
    ],
  );
  return RuntimeMapBundle(
    manifest: project,
    map: MapData(
      id: _mapId,
      name: 'Npc Patrol Map',
      size: const GridSize(width: 5, height: 2),
      layers: const <MapLayer>[MapLayer.object(id: 'objects', name: 'Objects')],
      entities: <MapEntity>[
        const MapEntity(
          id: 'spawn_start',
          name: 'Player start',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 0, y: 1),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.east,
          ),
        ),
        npc,
      ],
      mapMetadata: const MapMetadata(defaultSpawnId: 'spawn_start'),
    ),
    projectRootDirectory: '/tmp/npc_patrol',
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

final class _PatrolGame extends PlayableMapGame {
  _PatrolGame({required super.bundle, required super.projectFilePath});

  @override
  bool get isLoaded => true;
}

Future<void> _load(PlayableMapGame game) async {
  game.onGameResize(Vector2(320, 240));
  await game.onLoad();
  await _pumpUntil(game, () => !game.debugIsMapActivationDispatchInFlight);
}

Future<void> _pump(PlayableMapGame game, {int ticks = 60}) async {
  for (var i = 0; i < ticks; i++) {
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }
}

Future<void> _pumpUntil(
  PlayableMapGame game,
  bool Function() done, {
  int maxTicks = 480,
}) async {
  for (var i = 0; i < maxTicks; i++) {
    if (done()) return;
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }
  fail('the npc patrol runtime never reached the expected state');
}
