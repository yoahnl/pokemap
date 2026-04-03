import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

// Ces tests valident la fondation runtime demandée par le lot:
// - déplacement scripté ponctuel,
// - progression d'état (moving -> completed / failed),
// - patrouille waypoint en boucle.

void main() {
  group('ScriptedEntityMovementController', () {
    test('scripted move progresses and reaches completed state', () {
      final blockedCells = <GridPos>{};
      final runtimePositions = <String, GridPos>{
        'npc_1': const GridPos(x: 1, y: 1),
      };
      final startedSteps = <({GridPos from, GridPos to})>[];

      final controller = ScriptedEntityMovementController(
        mapSize: const GridSize(width: 6, height: 6),
        isCellBlocked: (x, y, {ignoreEntityId}) {
          if (x < 0 || y < 0 || x >= 6 || y >= 6) {
            return true;
          }
          final pos = GridPos(x: x, y: y);
          if (blockedCells.contains(pos)) {
            return true;
          }
          for (final entry in runtimePositions.entries) {
            if (entry.key == ignoreEntityId) {
              continue;
            }
            if (entry.value.x == x && entry.value.y == y) {
              return true;
            }
          }
          return false;
        },
        startEntityStep: ({
          required entityId,
          required from,
          required to,
          required facing,
          double? durationSeconds,
        }) {
          startedSteps.add((from: from, to: to));
          return true;
        },
        isEntityStepping: (_) => false,
        onEntityPositionCommitted: (entityId, pos) {
          runtimePositions[entityId] = pos;
        },
      );
      controller.replaceTrackedEntities(runtimePositions);

      final start = controller.moveEntityTo(
        entityId: 'npc_1',
        destination: const GridPos(x: 3, y: 1),
      );
      expect(start.state, ScriptedEntityMovementState.moving);

      controller.update(0.016);
      expect(
        controller.statusOf('npc_1').state,
        ScriptedEntityMovementState.moving,
      );
      expect(runtimePositions['npc_1'], const GridPos(x: 2, y: 1));

      controller.update(0.016);
      expect(runtimePositions['npc_1'], const GridPos(x: 3, y: 1));

      // Tick de finalisation (aucune étape restante -> completed).
      controller.update(0.016);
      final done = controller.statusOf('npc_1');
      expect(done.state, ScriptedEntityMovementState.completed);
      expect(done.currentPos, const GridPos(x: 3, y: 1));
      expect(startedSteps.length, 2);
    });

    test('fails when no path exists', () {
      final blockedCells = <GridPos>{
        for (var y = 0; y < 5; y++) GridPos(x: 2, y: y),
      };
      final runtimePositions = <String, GridPos>{
        'npc_1': const GridPos(x: 1, y: 2),
      };

      final controller = ScriptedEntityMovementController(
        mapSize: const GridSize(width: 5, height: 5),
        isCellBlocked: (x, y, {ignoreEntityId}) {
          if (x < 0 || y < 0 || x >= 5 || y >= 5) {
            return true;
          }
          if (blockedCells.contains(GridPos(x: x, y: y))) {
            return true;
          }
          for (final entry in runtimePositions.entries) {
            if (entry.key == ignoreEntityId) {
              continue;
            }
            if (entry.value.x == x && entry.value.y == y) {
              return true;
            }
          }
          return false;
        },
        startEntityStep: ({
          required entityId,
          required from,
          required to,
          required facing,
          double? durationSeconds,
        }) =>
            true,
        isEntityStepping: (_) => false,
        onEntityPositionCommitted: (entityId, pos) {
          runtimePositions[entityId] = pos;
        },
      );
      controller.replaceTrackedEntities(runtimePositions);

      final result = controller.moveEntityTo(
        entityId: 'npc_1',
        destination: const GridPos(x: 3, y: 2),
      );
      expect(result.state, ScriptedEntityMovementState.failed);
      expect(result.failureReason, isNotEmpty);
    });

    test('patrol alternates between waypoints in loop', () {
      final blockedCells = <GridPos>{};
      final runtimePositions = <String, GridPos>{
        'npc_1': const GridPos(x: 1, y: 1),
      };
      final committedPositions = <GridPos>[];

      final controller = ScriptedEntityMovementController(
        mapSize: const GridSize(width: 6, height: 6),
        isCellBlocked: (x, y, {ignoreEntityId}) {
          if (x < 0 || y < 0 || x >= 6 || y >= 6) {
            return true;
          }
          if (blockedCells.contains(GridPos(x: x, y: y))) {
            return true;
          }
          for (final entry in runtimePositions.entries) {
            if (entry.key == ignoreEntityId) {
              continue;
            }
            if (entry.value.x == x && entry.value.y == y) {
              return true;
            }
          }
          return false;
        },
        startEntityStep: ({
          required entityId,
          required from,
          required to,
          required facing,
          double? durationSeconds,
        }) =>
            true,
        isEntityStepping: (_) => false,
        onEntityPositionCommitted: (entityId, pos) {
          runtimePositions[entityId] = pos;
          committedPositions.add(pos);
        },
      );
      controller.replaceTrackedEntities(runtimePositions);

      controller.startPatrol(
        const ScriptedEntityPatrolRoute(
          entityId: 'npc_1',
          waypoints: <GridPos>[
            GridPos(x: 1, y: 1),
            GridPos(x: 3, y: 1),
          ],
          loop: true,
        ),
      );

      for (var i = 0; i < 10; i++) {
        controller.update(0.016);
      }

      // Le PNJ doit avoir alterné entre les 2 extrémités.
      expect(committedPositions, isNotEmpty);
      expect(committedPositions, contains(const GridPos(x: 3, y: 1)));
      expect(committedPositions, contains(const GridPos(x: 1, y: 1)));

      final current = runtimePositions['npc_1'];
      expect(current, isNotNull);
      expect(current!.y, 1);
      expect(current.x, anyOf(1, 2, 3));
    });

    test('patrol with loop false stops at last waypoint', () {
      final runtimePositions = <String, GridPos>{
        'npc_1': const GridPos(x: 1, y: 1),
      };

      final controller = ScriptedEntityMovementController(
        mapSize: const GridSize(width: 8, height: 8),
        isCellBlocked: (x, y, {ignoreEntityId}) => false,
        startEntityStep: ({
          required entityId,
          required from,
          required to,
          required facing,
          double? durationSeconds,
        }) =>
            true,
        isEntityStepping: (_) => false,
        onEntityPositionCommitted: (entityId, pos) {
          runtimePositions[entityId] = pos;
        },
      );
      controller.replaceTrackedEntities(runtimePositions);

      controller.startPatrol(
        const ScriptedEntityPatrolRoute(
          entityId: 'npc_1',
          waypoints: <GridPos>[
            GridPos(x: 1, y: 1),
            GridPos(x: 3, y: 1),
          ],
          loop: false,
        ),
      );

      for (var i = 0; i < 10; i++) {
        controller.update(0.016);
      }

      expect(runtimePositions['npc_1'], const GridPos(x: 3, y: 1));
      expect(controller.isPatrolling('npc_1'), isFalse);
    });

    test('patrol pause delays the next segment start', () {
      final runtimePositions = <String, GridPos>{
        'npc_1': const GridPos(x: 1, y: 1),
      };
      var startedSteps = 0;

      final controller = ScriptedEntityMovementController(
        mapSize: const GridSize(width: 8, height: 8),
        isCellBlocked: (x, y, {ignoreEntityId}) => false,
        startEntityStep: ({
          required entityId,
          required from,
          required to,
          required facing,
          double? durationSeconds,
        }) {
          startedSteps += 1;
          return true;
        },
        isEntityStepping: (_) => false,
        onEntityPositionCommitted: (entityId, pos) {
          runtimePositions[entityId] = pos;
        },
      );
      controller.replaceTrackedEntities(runtimePositions);

      controller.startPatrol(
        const ScriptedEntityPatrolRoute(
          entityId: 'npc_1',
          waypoints: <GridPos>[
            GridPos(x: 1, y: 1),
            GridPos(x: 2, y: 1),
          ],
          loop: true,
          pauseDurationMs: 500,
        ),
      );

      // Tick 1: l'entité démarre déjà sur le waypoint initial, donc la pause
      // configurée est consommée avant tout déplacement.
      controller.update(0.016);
      expect(startedSteps, 0);
      expect(runtimePositions['npc_1'], const GridPos(x: 1, y: 1));

      // Pendant la pause, aucun nouveau segment ne démarre.
      controller.update(0.20);
      controller.update(0.20);
      expect(startedSteps, 0);

      // Après la pause, la patrouille repart.
      controller.update(0.20);
      expect(startedSteps, 0);
      expect(runtimePositions['npc_1'], const GridPos(x: 1, y: 1));

      // Le segment est planifié à la fin de la pause; le pas est exécuté et
      // commité au tick suivant (découplage planification/exécution).
      controller.update(0.016);
      expect(startedSteps, 1);
      expect(runtimePositions['npc_1'], const GridPos(x: 2, y: 1));
    });

    test('scripted move temporarily overrides patrol then patrol resumes', () {
      final runtimePositions = <String, GridPos>{
        'npc_1': const GridPos(x: 1, y: 1),
      };

      final controller = ScriptedEntityMovementController(
        mapSize: const GridSize(width: 10, height: 10),
        isCellBlocked: (x, y, {ignoreEntityId}) => false,
        startEntityStep: ({
          required entityId,
          required from,
          required to,
          required facing,
          double? durationSeconds,
        }) =>
            true,
        isEntityStepping: (_) => false,
        onEntityPositionCommitted: (entityId, pos) {
          runtimePositions[entityId] = pos;
        },
      );
      controller.replaceTrackedEntities(runtimePositions);

      controller.startPatrol(
        const ScriptedEntityPatrolRoute(
          entityId: 'npc_1',
          waypoints: <GridPos>[
            GridPos(x: 1, y: 1),
            GridPos(x: 3, y: 1),
          ],
          loop: true,
        ),
      );

      // 1er tick: planification du segment de patrouille.
      controller.update(0.016);
      expect(runtimePositions['npc_1'], const GridPos(x: 1, y: 1));
      // 2e tick: exécution du premier pas.
      controller.update(0.016);
      expect(runtimePositions['npc_1'], const GridPos(x: 2, y: 1));

      // Override cutscene/script: force une destination différente.
      controller.moveEntityTo(
        entityId: 'npc_1',
        destination: const GridPos(x: 5, y: 1),
      );
      controller.update(0.016);
      expect(runtimePositions['npc_1'], const GridPos(x: 3, y: 1));
      controller.update(0.016);
      expect(runtimePositions['npc_1'], const GridPos(x: 4, y: 1));
      controller.update(0.016);
      expect(runtimePositions['npc_1'], const GridPos(x: 5, y: 1));
      controller.update(0.016); // completion

      // Après completion, la patrouille reprend automatiquement.
      controller.update(0.016);
      expect(runtimePositions['npc_1'], isNot(const GridPos(x: 5, y: 1)));
      expect(controller.isPatrolling('npc_1'), isTrue);
    });
  });
}
