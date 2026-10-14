import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/scripted_entity_movement_controller.dart';
import 'package:map_runtime/src/application/scripted_entity_movement_models.dart';

// Ces tests valident la fondation runtime demandée par le lot:
// - déplacement scripté ponctuel,
// - progression d'état (moving -> completed / failed),
// - patrouille waypoint en boucle.

void main() {
  group('ScriptedEntityMovementController', () {
    group('forced movement ownership', () {
      test(
        'advances every forced move while leaving a planned patrol frozen',
        () {
          final f = _MovementFixture(const {
            'a': GridPos(x: 1, y: 1),
            'z': GridPos(x: 1, y: 3),
            'patrol': GridPos(x: 1, y: 5),
          });
          f.patrol('patrol');
          f.controller.update(0);
          for (final id in ['a', 'z']) {
            f.controller.moveEntityTo(
              entityId: id,
              destination: GridPos(x: 2, y: id == 'a' ? 1 : 3),
            );
          }

          _advanceForcedMoves(f.controller);

          expect(f.started, ['a', 'z']);
          expect(
            f.controller.trackedPositionOf('patrol'),
            const GridPos(x: 1, y: 5),
          );
          expect(f.positions['patrol'], const GridPos(x: 1, y: 5));
          f.stepping.clear();
          _advanceForcedMoves(f.controller);
          expect(f.positions['a'], const GridPos(x: 2, y: 1));
          expect(f.positions['z'], const GridPos(x: 2, y: 3));
          expect(
            f.controller.statusOf('a').state,
            ScriptedEntityMovementState.completed,
          );
          expect(
            f.controller.statusOf('z').state,
            ScriptedEntityMovementState.completed,
          );
          expect(f.started, ['a', 'z']);
        },
      );

      test('does not schedule a patrol when there are no forced moves', () {
        final f = _MovementFixture(const {'patrol': GridPos(x: 1, y: 1)});
        f.patrol('patrol');

        _advanceForcedMoves(f.controller);
        _advanceForcedMoves(f.controller);

        expect(f.started, isEmpty);
        expect(
          f.controller.statusOf('patrol').state,
          ScriptedEntityMovementState.idle,
        );
        f.controller.update(0);
        f.controller.update(0);
        expect(f.started, ['patrol']);
      });

      test('does not commit a completed physical patrol step', () {
        final f = _MovementFixture(const {
          'forced': GridPos(x: 1, y: 1),
          'patrol': GridPos(x: 1, y: 3),
        });
        f.patrol('patrol');
        f.controller.update(0);
        f.controller.update(0);
        expect(f.started, ['patrol']);
        f.stepping.clear();
        f.controller.moveEntityTo(
          entityId: 'forced',
          destination: const GridPos(x: 2, y: 1),
        );

        _advanceForcedMoves(f.controller);

        expect(f.positions['patrol'], const GridPos(x: 1, y: 3));
        expect(f.committed, isEmpty);
        f.stepping.clear();
        _advanceForcedMoves(f.controller);
        expect(f.committed, ['forced']);
        f.controller.update(0);
        expect(f.positions['patrol'], const GridPos(x: 2, y: 3));
      });

      test(
        'finishes the forced runtime commit without restarting its patrol',
        () {
          final f = _MovementFixture(const {'actor': GridPos(x: 1, y: 1)});
          f.patrol('actor');
          f.controller.moveEntityTo(
            entityId: 'actor',
            destination: const GridPos(x: 2, y: 1),
          );
          _advanceForcedMoves(f.controller);
          expect(f.positions['actor'], const GridPos(x: 1, y: 1));
          _advanceForcedMoves(f.controller);
          expect(f.positions['actor'], const GridPos(x: 1, y: 1));
          f.stepping.clear();

          _advanceForcedMoves(f.controller);

          expect(f.positions['actor'], const GridPos(x: 2, y: 1));
          expect(
            f.controller.statusOf('actor').state,
            ScriptedEntityMovementState.completed,
          );
          expect(f.controller.isPatrolling('actor'), isTrue);
          f.controller.update(0);
          f.controller.update(0);
          expect(f.started, ['actor', 'actor']);
        },
      );

      test('returns an immutable detached snapshot through the final forced commit', () {
        final f = _MovementFixture(const {
          'b': GridPos(x: 1, y: 1),
          'a': GridPos(x: 1, y: 3),
          'patrol': GridPos(x: 1, y: 5),
        });
        f.patrol('patrol');
        f.controller.update(0);
        final api = f.controller;
        expect(() => api.activeForcedMoveEntityIds, returnsNormally);
        expect(api.activeForcedMoveEntityIds, isEmpty);
        expect(api.hasActiveForcedMoves, isFalse);
        for (final id in ['b', 'a']) {
          f.controller.moveEntityTo(
            entityId: id,
            destination: GridPos(x: 2, y: id == 'b' ? 1 : 3),
          );
        }
        final Set<String> snapshot = api.activeForcedMoveEntityIds;
        expect(snapshot, unorderedEquals(['a', 'b']));
        expect(() => snapshot.add('other'), throwsUnsupportedError);
        expect(api.hasActiveForcedMoves, isTrue);
        _advanceForcedMoves(f.controller);
        expect(api.activeForcedMoveEntityIds, unorderedEquals(['a', 'b']));
        f.stepping.clear();
        _advanceForcedMoves(f.controller);
        expect(api.activeForcedMoveEntityIds, isEmpty);
        expect(api.hasActiveForcedMoves, isFalse);
        expect(snapshot, unorderedEquals(['a', 'b']));
      });

      test(
        'accepted replacement takes ownership of a patrol pending commit',
        () {
          final f = _MovementFixture(const {'actor': GridPos(x: 1, y: 1)});
          f.patrol('actor');
          f.controller.update(0);
          f.controller.update(0);
          expect(f.controller.activeForcedMoveEntityIds, isEmpty);
          expect(f.positions['actor'], const GridPos(x: 1, y: 1));

          final replacement = f.controller.moveEntityTo(
            entityId: 'actor',
            destination: const GridPos(x: 3, y: 1),
          );
          expect(replacement.state, ScriptedEntityMovementState.moving);
          expect(f.controller.activeForcedMoveEntityIds, {'actor'});
          f.controller.updateForcedMoves(0);
          expect(f.committed, isEmpty);
          f.stepping.clear();
          f.controller.updateForcedMoves(0);
          expect(f.positions['actor'], const GridPos(x: 2, y: 1));
          expect(f.started, ['actor', 'actor']);
          expect(f.controller.hasActiveForcedMoves, isTrue);
          f.stepping.clear();
          f.controller.updateForcedMoves(0);
          expect(f.positions['actor'], const GridPos(x: 3, y: 1));
          expect(f.controller.hasActiveForcedMoves, isFalse);
          expect(f.controller.isPatrolling('actor'), isTrue);
        },
      );

      test(
        'rejected replacement keeps patrol ownership and its pending commit',
        () {
          final f = _MovementFixture(const {'actor': GridPos(x: 1, y: 1)});
          f.patrol('actor');
          f.controller.update(0);
          f.controller.update(0);
          final before = f.controller.statusOf('actor');
          f.blocked.add(const GridPos(x: 7, y: 7));

          final rejected = f.controller.moveEntityTo(
            entityId: 'actor',
            destination: const GridPos(x: 7, y: 7),
          );
          expect(rejected.state, ScriptedEntityMovementState.failed);
          expect(identical(f.controller.statusOf('actor'), before), isTrue);
          expect(f.controller.activeForcedMoveEntityIds, isEmpty);
          f.stepping.clear();
          f.controller.updateForcedMoves(0);
          expect(f.committed, isEmpty);
          f.controller.update(0);
          expect(f.positions['actor'], const GridPos(x: 2, y: 1));
        },
      );

      test(
        'current-cell replacement remains forced until the inherited commit',
        () {
          final f = _MovementFixture(const {'actor': GridPos(x: 1, y: 1)});
          f.patrol('actor');
          f.controller.update(0);
          f.controller.update(0);
          f.controller.moveEntityTo(
            entityId: 'actor',
            destination: const GridPos(x: 2, y: 1),
          );
          expect(f.controller.activeForcedMoveEntityIds, {'actor'});
          f.controller.updateForcedMoves(0);
          expect(f.positions['actor'], const GridPos(x: 1, y: 1));
          expect(f.controller.hasActiveForcedMoves, isTrue);
          f.stepping.clear();
          f.controller.updateForcedMoves(0);
          expect(f.positions['actor'], const GridPos(x: 2, y: 1));
          expect(f.controller.hasActiveForcedMoves, isFalse);
          expect(f.started, ['actor']);
        },
      );

      test(
        'immediate completion and rejected first moves leave no forced owner',
        () {
          final f = _MovementFixture(const {'actor': GridPos(x: 1, y: 1)});
          expect(
            f.controller
                .moveEntityTo(
                  entityId: 'actor',
                  destination: const GridPos(x: 1, y: 1),
                )
                .state,
            ScriptedEntityMovementState.completed,
          );
          expect(f.controller.hasActiveForcedMoves, isFalse);
          f.blocked.add(const GridPos(x: 7, y: 7));
          expect(
            f.controller
                .moveEntityTo(
                  entityId: 'actor',
                  destination: const GridPos(x: 7, y: 7),
                )
                .state,
            ScriptedEntityMovementState.failed,
          );
          expect(
            f.controller
                .moveEntityTo(
                  entityId: 'missing',
                  destination: const GridPos(x: 2, y: 1),
                )
                .state,
            ScriptedEntityMovementState.failed,
          );
          expect(f.controller.activeForcedMoveEntityIds, isEmpty);
        },
      );

      test('a runtime path failure releases its forced owner', () {
        final f = _MovementFixture(const {'actor': GridPos(x: 1, y: 1)});
        f.controller.moveEntityTo(
          entityId: 'actor',
          destination: const GridPos(x: 2, y: 1),
        );
        f.blocked.add(const GridPos(x: 2, y: 1));
        f.controller.updateForcedMoves(0);
        expect(
          f.controller.statusOf('actor').state,
          ScriptedEntityMovementState.failed,
        );
        expect(f.controller.hasActiveForcedMoves, isFalse);
        expect(f.started, isEmpty);
      });

      test('forced updates do not consume a patrol pause', () {
        final f = _MovementFixture(const {'actor': GridPos(x: 1, y: 1)});
        f.patrol('actor', pauseDurationMs: 500);
        f.controller.update(0);
        f.controller.updateForcedMoves(10);
        expect(f.controller.hasActiveForcedMoves, isFalse);
        f.controller.update(.25);
        expect(
          f.controller.statusOf('actor').state,
          ScriptedEntityMovementState.idle,
        );
        f.controller.update(.25);
        expect(f.started, isEmpty);
        f.controller.update(0);
        expect(f.started, ['actor']);
      });

      test(
        'stopping a patrol does not reclassify its already active segment',
        () {
          final f = _MovementFixture(const {'actor': GridPos(x: 1, y: 1)});
          f.patrol('actor');
          f.controller.update(0);
          f.controller.stopPatrol('actor');
          f.controller.updateForcedMoves(0);
          expect(f.controller.hasActiveForcedMoves, isFalse);
          expect(f.started, isEmpty);
          f.controller.update(0);
          f.stepping.clear();
          f.controller.update(0);
          expect(f.positions['actor'], const GridPos(x: 2, y: 1));
          expect(
            f.controller.statusOf('actor').state,
            ScriptedEntityMovementState.completed,
          );
          expect(f.controller.isPatrolling('actor'), isFalse);
        },
      );

      test('untrack retrack and hard reset release forced ownership', () {
        final f = _MovementFixture(const {
          'a': GridPos(x: 1, y: 1),
          'b': GridPos(x: 1, y: 3),
        });
        for (final id in ['a', 'b']) {
          f.controller.moveEntityTo(
            entityId: id,
            destination: GridPos(x: 2, y: id == 'a' ? 1 : 3),
          );
        }
        final snapshot = f.controller.activeForcedMoveEntityIds;
        f.controller.untrackEntity('a');
        expect(f.controller.activeForcedMoveEntityIds, {'b'});
        f.controller.trackEntity('b', const GridPos(x: 4, y: 4));
        expect(f.controller.hasActiveForcedMoves, isFalse);
        f.controller.moveEntityTo(
          entityId: 'b',
          destination: const GridPos(x: 5, y: 4),
        );
        f.controller.replaceTrackedEntities(const {'b': GridPos(x: 1, y: 3)});
        expect(f.controller.activeForcedMoveEntityIds, isEmpty);
        f.controller.updateForcedMoves(0);
        expect(f.started, isEmpty);
        expect(snapshot, unorderedEquals(['a', 'b']));
      });

      test(
        'owned updates still advance exactly their selected move and commit',
        () {
          final f = _MovementFixture(const {
            'forced': GridPos(x: 1, y: 1),
            'patrol': GridPos(x: 1, y: 3),
          });
          f.patrol('patrol');
          f.controller.update(0);
          f.controller.moveEntityTo(
            entityId: 'forced',
            destination: const GridPos(x: 2, y: 1),
          );
          f.controller.updateOwnedMove(0, 'forced');
          expect(f.started, ['forced']);
          f.stepping.clear();
          f.controller.updateOwnedMove(0, 'forced');
          expect(f.committed, ['forced']);
          expect(f.controller.hasActiveForcedMoves, isFalse);
          f.controller.updateOwnedMove(0, 'patrol');
          expect(f.started, ['forced', 'patrol']);
          expect(f.controller.activeForcedMoveEntityIds, isEmpty);
        },
      );
    });

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
      expect(runtimePositions['npc_1'], const GridPos(x: 1, y: 1));

      controller.update(0.016);
      expect(runtimePositions['npc_1'], const GridPos(x: 2, y: 1));

      controller.update(0.016);
      expect(runtimePositions['npc_1'], const GridPos(x: 3, y: 1));

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

    test(
      'rejected unreachable replacement preserves the active move atomically',
      () {
        final blockedCells = <GridPos>{};
        final runtimePositions = <String, GridPos>{
          'npc_1': const GridPos(x: 1, y: 1),
        };
        final startedSteps = <GridPos>[];
        final controller = ScriptedEntityMovementController(
          mapSize: const GridSize(width: 6, height: 6),
          isCellBlocked: (x, y, {ignoreEntityId}) =>
              blockedCells.contains(GridPos(x: x, y: y)),
          startEntityStep: ({
            required entityId,
            required from,
            required to,
            required facing,
            double? durationSeconds,
          }) {
            startedSteps.add(to);
            return true;
          },
          isEntityStepping: (_) => false,
          onEntityPositionCommitted: (entityId, pos) {
            runtimePositions[entityId] = pos;
          },
        );
        controller.replaceTrackedEntities(runtimePositions);

        final original = controller.moveEntityTo(
          entityId: 'npc_1',
          destination: const GridPos(x: 4, y: 1),
        );
        expect(original.state, ScriptedEntityMovementState.moving);
        blockedCells.add(const GridPos(x: 3, y: 3));

        final rejected = controller.moveEntityTo(
          entityId: 'npc_1',
          destination: const GridPos(x: 3, y: 3),
        );

        expect(rejected.state, ScriptedEntityMovementState.failed);
        expect(controller.statusOf('npc_1').state,
            ScriptedEntityMovementState.moving);
        expect(
          controller.statusOf('npc_1').targetPos,
          const GridPos(x: 4, y: 1),
        );

        for (var i = 0; i < 5; i++) {
          controller.update(0.016);
        }
        expect(runtimePositions['npc_1'], const GridPos(x: 4, y: 1));
        expect(
          controller.statusOf('npc_1').state,
          ScriptedEntityMovementState.completed,
        );
        expect(startedSteps, hasLength(3));
      },
    );

    test('current-cell replacement terminalizes the previous active move', () {
      final runtimePositions = <String, GridPos>{
        'npc_1': const GridPos(x: 1, y: 1),
      };
      final startedSteps = <GridPos>[];
      final controller = ScriptedEntityMovementController(
        mapSize: const GridSize(width: 6, height: 6),
        isCellBlocked: (x, y, {ignoreEntityId}) => false,
        startEntityStep: ({
          required entityId,
          required from,
          required to,
          required facing,
          double? durationSeconds,
        }) {
          startedSteps.add(to);
          return true;
        },
        isEntityStepping: (_) => false,
        onEntityPositionCommitted: (entityId, pos) {
          runtimePositions[entityId] = pos;
        },
      );
      controller.replaceTrackedEntities(runtimePositions);

      expect(
        controller
            .moveEntityTo(
              entityId: 'npc_1',
              destination: const GridPos(x: 4, y: 1),
            )
            .state,
        ScriptedEntityMovementState.moving,
      );
      final replacement = controller.moveEntityTo(
        entityId: 'npc_1',
        destination: const GridPos(x: 1, y: 1),
      );

      expect(replacement.state, ScriptedEntityMovementState.completed);
      for (var i = 0; i < 5; i++) {
        controller.update(0.016);
      }
      expect(startedSteps, isEmpty);
      expect(runtimePositions['npc_1'], const GridPos(x: 1, y: 1));
      expect(
        controller.statusOf('npc_1').targetPos,
        const GridPos(x: 1, y: 1),
      );
    });

    test('current-cell replacement preserves an in-flight step commit', () {
      final runtimePositions = <String, GridPos>{
        'npc_1': const GridPos(x: 1, y: 1),
      };
      final startedSteps = <GridPos>[];
      var isStepping = false;
      final controller = ScriptedEntityMovementController(
        mapSize: const GridSize(width: 6, height: 6),
        isCellBlocked: (x, y, {ignoreEntityId}) => false,
        startEntityStep: ({
          required entityId,
          required from,
          required to,
          required facing,
          double? durationSeconds,
        }) {
          startedSteps.add(to);
          isStepping = true;
          return true;
        },
        isEntityStepping: (_) => isStepping,
        onEntityPositionCommitted: (entityId, pos) {
          runtimePositions[entityId] = pos;
        },
      );
      controller.replaceTrackedEntities(runtimePositions);
      controller.moveEntityTo(
        entityId: 'npc_1',
        destination: const GridPos(x: 4, y: 1),
      );
      controller.update(0.016);
      expect(
        controller.trackedPositionOf('npc_1'),
        const GridPos(x: 2, y: 1),
      );
      expect(runtimePositions['npc_1'], const GridPos(x: 1, y: 1));

      final replacement = controller.moveEntityTo(
        entityId: 'npc_1',
        destination: const GridPos(x: 2, y: 1),
      );
      expect(replacement.state, ScriptedEntityMovementState.moving);

      controller.update(0.016);
      expect(runtimePositions['npc_1'], const GridPos(x: 1, y: 1));
      isStepping = false;
      controller.update(0.016);

      expect(runtimePositions['npc_1'], const GridPos(x: 2, y: 1));
      expect(startedSteps, <GridPos>[const GridPos(x: 2, y: 1)]);
      expect(
        controller.statusOf('npc_1').state,
        ScriptedEntityMovementState.completed,
      );
      expect(
        controller.statusOf('npc_1').targetPos,
        const GridPos(x: 2, y: 1),
      );
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
      expect(runtimePositions['npc_1'], const GridPos(x: 1, y: 1));
      controller.update(0.016);
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
      expect(runtimePositions['npc_1'], const GridPos(x: 1, y: 1));
      // 3e tick: commit du premier pas.
      controller.update(0.016);
      expect(runtimePositions['npc_1'], const GridPos(x: 2, y: 1));

      // Override cutscene/script: force une destination différente.
      controller.moveEntityTo(
        entityId: 'npc_1',
        destination: const GridPos(x: 5, y: 1),
      );
      controller.update(0.016);
      // Le commit différé du pas de patrouille déjà lancé reste la première
      // opération du remplacement accepté.
      expect(runtimePositions['npc_1'], const GridPos(x: 3, y: 1));
      controller.update(0.016);
      expect(runtimePositions['npc_1'], const GridPos(x: 4, y: 1));
      controller.update(0.016);
      expect(runtimePositions['npc_1'], const GridPos(x: 5, y: 1));

      // Après completion, la patrouille reprend automatiquement.
      controller.update(0.016);
      expect(controller.isPatrolling('npc_1'), isTrue);
      controller.update(0.016);
      expect(runtimePositions['npc_1'], isNot(const GridPos(x: 5, y: 1)));
    });

    test('patrol stops explicitly when next waypoint is unreachable', () {
      final runtimePositions = <String, GridPos>{
        'npc_1': const GridPos(x: 1, y: 1),
      };

      final blocked = <GridPos>{
        const GridPos(x: 2, y: 1),
      };

      final controller = ScriptedEntityMovementController(
        mapSize: const GridSize(width: 8, height: 8),
        isCellBlocked: (x, y, {ignoreEntityId}) =>
            blocked.contains(GridPos(x: x, y: y)),
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
            GridPos(x: 2, y: 1),
          ],
          loop: true,
        ),
      );

      // Tick 1: waypoint courant = position actuelle, passe au suivant.
      controller.update(0.016);
      // Tick 2: tentative de move vers waypoint bloqué => échec explicite.
      controller.update(0.016);

      final status = controller.statusOf('npc_1');
      expect(status.state, ScriptedEntityMovementState.failed);
      expect(status.failureReason, isNotEmpty);
      expect(controller.isPatrolling('npc_1'), isFalse);
    });

    test('syncTrackedEntityPosition updates anchor when idle', () {
      final runtimePositions = <String, GridPos>{
        'player': const GridPos(x: 1, y: 1),
      };
      final controller = ScriptedEntityMovementController(
        mapSize: const GridSize(width: 6, height: 6),
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
        onEntityPositionCommitted: (entityId, pos) {},
      );
      controller.replaceTrackedEntities(runtimePositions);
      controller.syncTrackedEntityPosition('player', const GridPos(x: 2, y: 2));
      expect(
        controller.trackedPositionOf('player'),
        const GridPos(x: 2, y: 2),
      );
      expect(
        controller.statusOf('player').state,
        ScriptedEntityMovementState.idle,
      );
    });

    test('trackEntity reactivates a newly present NPC without a hard reset',
        () {
      final controller = ScriptedEntityMovementController(
        mapSize: const GridSize(width: 6, height: 6),
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
        onEntityPositionCommitted: (_, __) {},
      );
      controller.replaceTrackedEntities(const {
        'player': GridPos(x: 1, y: 1),
      });

      controller.trackEntity('npc_guide', const GridPos(x: 3, y: 2));

      expect(
        controller.trackedPositionOf('npc_guide'),
        const GridPos(x: 3, y: 2),
      );
      expect(
        controller.statusOf('npc_guide').state,
        ScriptedEntityMovementState.idle,
      );
      expect(
        controller.trackedPositionOf('player'),
        const GridPos(x: 1, y: 1),
      );
    });
  });
}

void _advanceForcedMoves(ScriptedEntityMovementController controller) {
  controller.updateForcedMoves(0);
}

final class _MovementFixture {
  _MovementFixture(Map<String, GridPos> initial) : positions = Map.of(initial) {
    controller = ScriptedEntityMovementController(
      mapSize: const GridSize(width: 8, height: 8),
      isCellBlocked: (x, y, {ignoreEntityId}) =>
          blocked.contains(GridPos(x: x, y: y)),
      startEntityStep:
          ({
            required entityId,
            required from,
            required to,
            required facing,
            double? durationSeconds,
          }) {
            started.add(entityId);
            stepping.add(entityId);
            return true;
          },
      isEntityStepping: stepping.contains,
      onEntityPositionCommitted: (id, pos) {
        committed.add(id);
        positions[id] = pos;
      },
    );
    controller.replaceTrackedEntities(positions);
  }

  late final ScriptedEntityMovementController controller;
  final Map<String, GridPos> positions;
  final blocked = <GridPos>{};
  final stepping = <String>{};
  final started = <String>[];
  final committed = <String>[];

  void patrol(String id, {int pauseDurationMs = 0}) {
    final pos = positions[id]!;
    controller.startPatrol(
      ScriptedEntityPatrolRoute(
        entityId: id,
        waypoints: [
          pos,
          GridPos(x: pos.x + 1, y: pos.y),
        ],
        loop: true,
        pauseDurationMs: pauseDurationMs,
      ),
    );
  }
}
