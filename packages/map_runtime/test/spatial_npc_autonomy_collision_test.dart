import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/spatial/spatial_npc_fixed_route_runtime.dart';

void main() {
  for (final obstacle in [
    'object',
    'player',
    'npc',
    'relief',
    'collisionLayer',
  ]) {
    test('autonomous steps use real spatial collisions for $obstacle', () {
      final host = _Host(obstacle);
      host.runtime.update(.001);
      host.runtime.update(.1);
      expect(host.saved['actor']!.x, 2.5);
      expect(host.runtime.poseFor('actor'), isNull);
      host.runtime.dispose();
    });
  }

  test(
    'interpolation stays transient until flush and is persisted once per flush',
    () {
      final host = _Host('none');
      host.runtime.update(.001);
      final initialWrites = host.commits;
      for (var tick = 0; tick < 4; tick++) {
        host.runtime.update(.01);
      }
      expect(host.commits, initialWrites);
      expect(host.runtime.poseFor('actor')!.x, closeTo(2.9, .00001));
      host.runtime.flush();
      expect(host.commits, initialWrites + 1);
      expect(host.saved['actor']!.x, closeTo(2.9, .00001));
      host.runtime.flush();
      expect(host.commits, initialWrites + 1);
      host.runtime.update(.06);
      expect(host.saved['actor']!.x, 3.5);
      host.runtime.dispose();
    },
  );
}

final class _Host {
  _Host(String obstacle) {
    final map = MapData(
      id: 'map',
      name: 'Map',
      size: const GridSize(width: 8, height: 8),
      spatialScene: MapSpatialScene(
        width: 8,
        depth: 8,
        heightLevels: [
          for (var z = 0; z < 8; z++)
            for (var x = 0; x < 8; x++) obstacle == 'relief' && x == 3 ? 1 : 0,
        ],
        navigation: SpatialNavigationProfile(
          spawn: SpatialSpawn(
            x: obstacle == 'player' ? 3.5 : .5,
            z: obstacle == 'player' ? 2.5 : .5,
          ),
        ),
        instances: [
          if (obstacle == 'object')
            SpatialModelInstance(
              id: 'box',
              modelId: 'box',
              position: Model3dVector3(x: 3, y: 0, z: 2),
            ),
        ],
      ),
      entities: [
        const MapEntity(
          id: 'actor',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 2, y: 2),
          npc: MapEntityNpcData(
            movement: MapEntityNpcMovementConfig(
              mode: MapEntityNpcMovementMode.fixedRoute,
              routeSteps: [
                MapEntityNpcRouteStep.move(direction: EntityFacing.east),
              ],
              pauseDurationMs: 1,
              stepDurationMs: 100,
              movementArea: MapRect(
                pos: GridPos(x: 1, y: 1),
                size: GridSize(width: 3, height: 3),
              ),
            ),
          ),
        ),
        if (obstacle == 'npc')
          const MapEntity(
            id: 'blocker',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 3, y: 2),
            npc: MapEntityNpcData(),
          ),
      ],
      layers: [
        if (obstacle == 'collisionLayer')
          CollisionLayer(
            id: 'collision',
            name: 'Collision',
            collisions: [
              for (var z = 0; z < 8; z++)
                for (var x = 0; x < 8; x++) x == 3 && z == 2,
            ],
          ),
      ],
    );
    final models = [
      if (obstacle == 'object')
        ProjectModel3dEntry(
          id: 'box',
          name: 'Box',
          sourceAssetId: 'box-source',
          relativePath: 'assets/models3d/box.glb',
          inspection: Model3dInspection(
            bounds: Model3dBounds(
              min: Model3dVector3(x: 0, y: 0, z: 0),
              max: Model3dVector3(x: 1, y: 1, z: 1),
            ),
            meshCount: 1,
            triangleCount: 12,
          ),
        ),
    ];
    final collision = SpatialMovementController.fromMap(
      map: map,
      models: models,
      actorStateProvider: (id) => saved[id],
    );
    runtime = SpatialNpcFixedRouteRuntime(
      readMap: () => map,
      readActor: (entity) => saved[entity.id],
      isPresent: (_) => true,
      canTraverse: (entity, x, z, nx, nz, reservations) =>
          collision.canTraverseActor(
            x,
            z,
            nx,
            nz,
            ignoredEntityId: entity.id,
            collideWithPlayer: true,
            actorStateProvider: (id) => reservations[id] ?? saved[id],
          ),
      commitActor: (id, pose) {
        saved[id] = pose;
        commits++;
      },
      random: Random(3),
    );
  }
  final saved = <String, SpatialActorRuntimeState>{};
  late final SpatialNpcFixedRouteRuntime runtime;
  int commits = 0;
}
