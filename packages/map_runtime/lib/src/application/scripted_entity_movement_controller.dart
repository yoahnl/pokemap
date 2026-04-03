import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import 'scripted_entity_movement_models.dart';

/// Callback de vérification de blocage cellule.
///
/// [ignoreEntityId] permet d'ignorer le bloqueur "courant" (cas classique:
/// l'entité qui planifie depuis sa propre case).
typedef ScriptedMovementCellBlocked = bool Function(
  int x,
  int y, {
  String? ignoreEntityId,
});

/// Callback d'animation/lancement de pas sur l'acteur runtime.
///
/// Retourne `false` si le pas ne peut pas être lancé (acteur introuvable, etc).
typedef ScriptedEntityStepStarter = bool Function({
  required String entityId,
  required GridPos from,
  required GridPos to,
  required EntityFacing facing,
  double? durationSeconds,
});

/// Callback qui indique si l'acteur visuel est encore en mouvement.
typedef ScriptedEntityStepInProgressReader = bool Function(String entityId);

/// Callback appelé dès qu'une nouvelle cellule est "réservée/atteinte" côté
/// simulation grille (permet de synchroniser le GameplayWorldState externe).
typedef ScriptedEntityPositionCommitted = void Function(
  String entityId,
  GridPos position,
);

/// Contrôleur runtime de déplacement scripté d'entités.
///
/// Objectifs:
/// - fournir une API simple `moveTo` (commande ponctuelle),
/// - exposer un statut clair (`idle/moving/completed/failed`),
/// - supporter une patrouille waypoint simple (boucle),
/// - rester pur/testable (aucune dépendance Flame/UI).
///
/// Ce contrôleur est pensé comme future fondation Cutscene:
/// - "start movement",
/// - "tick/update",
/// - "wait until completed/failed".
class ScriptedEntityMovementController {
  ScriptedEntityMovementController({
    required this.mapSize,
    required ScriptedMovementCellBlocked isCellBlocked,
    required ScriptedEntityStepStarter startEntityStep,
    required ScriptedEntityStepInProgressReader isEntityStepping,
    required ScriptedEntityPositionCommitted onEntityPositionCommitted,
    GridPathfinder pathfinder = const GridPathfinder(),
  })  : _isCellBlocked = isCellBlocked,
        _startEntityStep = startEntityStep,
        _isEntityStepping = isEntityStepping,
        _onEntityPositionCommitted = onEntityPositionCommitted,
        _pathfinder = pathfinder;

  final GridSize mapSize;
  final ScriptedMovementCellBlocked _isCellBlocked;
  final ScriptedEntityStepStarter _startEntityStep;
  final ScriptedEntityStepInProgressReader _isEntityStepping;
  final ScriptedEntityPositionCommitted _onEntityPositionCommitted;
  final GridPathfinder _pathfinder;

  // Source de vérité interne des positions entité->cellule pour ce contrôleur.
  final Map<String, GridPos> _trackedPositions = <String, GridPos>{};

  // Commandes de déplacement actives.
  final Map<String, _MoveTask> _activeTasks = <String, _MoveTask>{};

  // Statut le plus récent (observable) par entité.
  final Map<String, ScriptedEntityMovementStatus> _statusByEntityId =
      <String, ScriptedEntityMovementStatus>{};

  // Patrouilles actives (waypoints).
  final Map<String, _PatrolRuntime> _patrols = <String, _PatrolRuntime>{};

  /// Remplace entièrement le set d'entités suivies.
  ///
  /// Appelé à l'initialisation et lors de changements de map runtime.
  void replaceTrackedEntities(Map<String, GridPos> entityPositions) {
    _trackedPositions
      ..clear()
      ..addAll(entityPositions);

    // Toute commande active devient invalide après un "hard reset" des entités.
    _activeTasks.clear();
    _patrols
        .removeWhere((entityId, _) => !_trackedPositions.containsKey(entityId));

    _statusByEntityId.clear();
    for (final entry in _trackedPositions.entries) {
      _statusByEntityId[entry.key] = ScriptedEntityMovementStatus.idle(
        entityId: entry.key,
        currentPos: entry.value,
      );
    }
  }

  /// Position actuelle connue pour une entité (ou `null` si non suivie).
  GridPos? trackedPositionOf(String entityId) {
    return _trackedPositions[entityId];
  }

  /// Statut courant d'une entité.
  ///
  /// Si l'entité est connue mais sans commande active, on renvoie `idle`.
  /// Si l'entité est inconnue, on renvoie un statut `failed` explicite.
  ScriptedEntityMovementStatus statusOf(String entityId) {
    final existing = _statusByEntityId[entityId];
    if (existing != null) {
      return existing;
    }
    final current = _trackedPositions[entityId];
    if (current != null) {
      return ScriptedEntityMovementStatus.idle(
        entityId: entityId,
        currentPos: current,
      );
    }
    return ScriptedEntityMovementStatus(
      entityId: entityId,
      state: ScriptedEntityMovementState.failed,
      currentPos: const GridPos(x: 0, y: 0),
      failureReason: 'Unknown entity "$entityId".',
    );
  }

  /// Lance un déplacement ponctuel vers [destination].
  ///
  /// - remplace une éventuelle commande de déplacement déjà active;
  /// - ne supprime PAS la patrouille: celle-ci reprendra ensuite.
  ScriptedEntityMovementStatus moveEntityTo({
    required String entityId,
    required GridPos destination,
    double? stepDurationSeconds,
  }) {
    final current = _trackedPositions[entityId];
    if (current == null) {
      return _fail(
        entityId: entityId,
        currentPos: const GridPos(x: 0, y: 0),
        reason: 'Entity "$entityId" is not tracked.',
      );
    }

    final pathResult = _pathfinder.findPath(
      bounds: mapSize,
      start: current,
      goal: destination,
      isPassable: (x, y) {
        // On autorise explicitement la case de départ.
        if (x == current.x && y == current.y) {
          return true;
        }
        return !_isCellBlocked(x, y, ignoreEntityId: entityId);
      },
    );
    if (!pathResult.foundPath) {
      return _fail(
        entityId: entityId,
        currentPos: current,
        targetPos: destination,
        reason: pathResult.failureReason ?? 'No path found.',
      );
    }

    final steps = pathResult.path.skip(1).toList(growable: false);
    if (steps.isEmpty) {
      return _complete(
        entityId: entityId,
        currentPos: current,
        targetPos: destination,
      );
    }

    _activeTasks[entityId] = _MoveTask(
      destination: destination,
      steps: steps,
      nextStepIndex: 0,
      stepDurationSeconds: stepDurationSeconds,
    );

    final status = ScriptedEntityMovementStatus(
      entityId: entityId,
      state: ScriptedEntityMovementState.moving,
      currentPos: current,
      targetPos: destination,
    );
    _statusByEntityId[entityId] = status;
    return status;
  }

  /// Active/écrase une patrouille waypoint pour une entité.
  ScriptedEntityMovementStatus startPatrol(ScriptedEntityPatrolRoute route) {
    final entityId = route.entityId.trim();
    final current = _trackedPositions[entityId];
    if (entityId.isEmpty || current == null) {
      return _fail(
        entityId: entityId,
        currentPos: current ?? const GridPos(x: 0, y: 0),
        reason: 'Cannot start patrol: unknown entity "$entityId".',
      );
    }
    if (route.waypoints.isEmpty) {
      return _fail(
        entityId: entityId,
        currentPos: current,
        reason: 'Cannot start patrol with empty waypoint list.',
      );
    }

    _patrols[entityId] = _PatrolRuntime(
      route: route,
      nextWaypointIndex: 0,
    );
    return statusOf(entityId);
  }

  void stopPatrol(String entityId) {
    _patrols.remove(entityId);
  }

  bool isPatrolling(String entityId) => _patrols.containsKey(entityId);

  /// Tick principal du contrôleur.
  ///
  /// `dt` n'est pas utilisé dans ce MVP (pas de vitesse variable côté logique),
  /// mais il est conservé dans la signature pour compatibilité future cutscene.
  void update(double dt) {
    // `dt` est conservé volontairement pour l'évolution cutscene (vitesses
    // configurables, waits, easing). Le MVP utilise un pas logique par tick.
    assert(dt >= 0);
    _tickActiveMoves();
    _tickPatrols(dt);
  }

  void _tickActiveMoves() {
    final entityIds = _activeTasks.keys.toList(growable: false)..sort();
    for (final entityId in entityIds) {
      final task = _activeTasks[entityId];
      if (task == null) {
        continue;
      }

      // Tant que l'animation de pas est en cours, on attend le prochain tick.
      if (_isEntityStepping(entityId)) {
        continue;
      }

      final current = _trackedPositions[entityId];
      if (current == null) {
        _fail(
          entityId: entityId,
          currentPos: const GridPos(x: 0, y: 0),
          targetPos: task.destination,
          reason: 'Tracked position missing during move execution.',
        );
        _activeTasks.remove(entityId);
        continue;
      }

      if (task.nextStepIndex >= task.steps.length) {
        _activeTasks.remove(entityId);
        _complete(
          entityId: entityId,
          currentPos: current,
          targetPos: task.destination,
        );
        continue;
      }

      var next = task.steps[task.nextStepIndex];
      // Si la cellule prévue est devenue bloquée (collision dynamique), on
      // tente un re-path propre depuis la position courante.
      if (_isCellBlocked(next.x, next.y, ignoreEntityId: entityId)) {
        final replanned = _pathfinder.findPath(
          bounds: mapSize,
          start: current,
          goal: task.destination,
          isPassable: (x, y) {
            if (x == current.x && y == current.y) {
              return true;
            }
            return !_isCellBlocked(x, y, ignoreEntityId: entityId);
          },
        );
        if (!replanned.foundPath) {
          _activeTasks.remove(entityId);
          _fail(
            entityId: entityId,
            currentPos: current,
            targetPos: task.destination,
            reason: replanned.failureReason ??
                'Path invalidated and replanning failed.',
          );
          continue;
        }
        final replannedSteps = replanned.path.skip(1).toList(growable: false);
        task
          ..steps = replannedSteps
          ..nextStepIndex = 0;
        if (task.steps.isEmpty) {
          _activeTasks.remove(entityId);
          _complete(
            entityId: entityId,
            currentPos: current,
            targetPos: task.destination,
          );
          continue;
        }
        next = task.steps[task.nextStepIndex];
      }

      final facing = _facingBetween(current, next);
      if (facing == null) {
        _activeTasks.remove(entityId);
        _fail(
          entityId: entityId,
          currentPos: current,
          targetPos: task.destination,
          reason: 'Non-cardinal or non-adjacent step detected.',
        );
        continue;
      }

      final started = _startEntityStep(
        entityId: entityId,
        from: current,
        to: next,
        facing: facing,
        durationSeconds: task.stepDurationSeconds,
      );
      if (!started) {
        _activeTasks.remove(entityId);
        _fail(
          entityId: entityId,
          currentPos: current,
          targetPos: task.destination,
          reason: 'Runtime actor refused scripted step start.',
        );
        continue;
      }

      // Commit logique immédiat de la nouvelle cellule.
      // Le rendu termine l'animation visuelle, mais la simulation grille est
      // déjà alignée, ce qui évite les collisions incohérentes.
      _trackedPositions[entityId] = next;
      _onEntityPositionCommitted(entityId, next);
      task.nextStepIndex += 1;

      _statusByEntityId[entityId] = ScriptedEntityMovementStatus(
        entityId: entityId,
        state: ScriptedEntityMovementState.moving,
        currentPos: next,
        targetPos: task.destination,
      );
    }
  }

  void _tickPatrols(double dt) {
    final entityIds = _patrols.keys.toList(growable: false)..sort();
    for (final entityId in entityIds) {
      final patrol = _patrols[entityId];
      if (patrol == null) {
        continue;
      }
      if (_activeTasks.containsKey(entityId)) {
        continue;
      }
      if (_isEntityStepping(entityId)) {
        continue;
      }
      final current = _trackedPositions[entityId];
      if (current == null) {
        continue;
      }
      final waypoints = patrol.route.waypoints;
      if (waypoints.isEmpty) {
        continue;
      }

      if (patrol.pauseRemainingMs > 0) {
        patrol.pauseRemainingMs =
            (patrol.pauseRemainingMs - (dt * 1000)).round();
        if (patrol.pauseRemainingMs > 0) {
          continue;
        }
        patrol.pauseRemainingMs = 0;
      }

      // On avance l'index tant que l'entité est déjà sur le waypoint courant.
      var nextIndex = patrol.nextWaypointIndex;
      var guard = 0;
      while (guard < waypoints.length &&
          waypoints[nextIndex].x == current.x &&
          waypoints[nextIndex].y == current.y) {
        if (!patrol.pauseConsumedAtWaypoint &&
            patrol.route.pauseDurationMs > 0) {
          patrol.pauseRemainingMs = patrol.route.pauseDurationMs;
          patrol.pauseConsumedAtWaypoint = true;
          break;
        }
        nextIndex += 1;
        if (nextIndex >= waypoints.length) {
          if (!patrol.route.loop) {
            _patrols.remove(entityId);
            return;
          }
          nextIndex = 0;
        }
        patrol.pauseConsumedAtWaypoint = false;
        guard += 1;
      }
      if (patrol.pauseRemainingMs > 0) {
        continue;
      }
      patrol.nextWaypointIndex = nextIndex;

      final target = waypoints[nextIndex];
      moveEntityTo(
        entityId: entityId,
        destination: target,
        stepDurationSeconds: patrol.route.stepDurationMs / 1000.0,
      );
    }
  }

  EntityFacing? _facingBetween(GridPos from, GridPos to) {
    final dx = to.x - from.x;
    final dy = to.y - from.y;
    if (dx == 0 && dy == -1) return EntityFacing.north;
    if (dx == 1 && dy == 0) return EntityFacing.east;
    if (dx == 0 && dy == 1) return EntityFacing.south;
    if (dx == -1 && dy == 0) return EntityFacing.west;
    return null;
  }

  ScriptedEntityMovementStatus _complete({
    required String entityId,
    required GridPos currentPos,
    GridPos? targetPos,
  }) {
    final status = ScriptedEntityMovementStatus(
      entityId: entityId,
      state: ScriptedEntityMovementState.completed,
      currentPos: currentPos,
      targetPos: targetPos,
    );
    _statusByEntityId[entityId] = status;
    return status;
  }

  ScriptedEntityMovementStatus _fail({
    required String entityId,
    required GridPos currentPos,
    GridPos? targetPos,
    required String reason,
  }) {
    final status = ScriptedEntityMovementStatus(
      entityId: entityId,
      state: ScriptedEntityMovementState.failed,
      currentPos: currentPos,
      targetPos: targetPos,
      failureReason: reason,
    );
    _statusByEntityId[entityId] = status;
    return status;
  }
}

class _MoveTask {
  _MoveTask({
    required this.destination,
    required this.steps,
    required this.nextStepIndex,
    required this.stepDurationSeconds,
  });

  final GridPos destination;
  List<GridPos> steps;
  int nextStepIndex;
  final double? stepDurationSeconds;
}

class _PatrolRuntime {
  _PatrolRuntime({
    required this.route,
    required this.nextWaypointIndex,
  });

  final ScriptedEntityPatrolRoute route;
  int nextWaypointIndex;
  int pauseRemainingMs = 0;
  bool pauseConsumedAtWaypoint = false;
}
