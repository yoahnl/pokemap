import 'dart:math';

import 'package:map_core/map_core.dart';

import 'actor_route_motion.dart';
import 'gameplay_world_state.dart';

enum NpcFixedRouteStepOutcome { completed, blocked, interrupted }

typedef NpcRouteInstanceBooleanReader = bool Function(String key);

final class NpcFixedRouteController {
  NpcFixedRouteController({
    required this.target,
    required MapEntityNpcMovementConfig movement,
    required Random random,
    NpcRouteInstanceBooleanReader? readInstanceBoolean,
  })  : movement = movement.copyWith(
          routeSteps: List.unmodifiable(movement.routeSteps),
          waypoints: List.unmodifiable(movement.waypoints),
        ),
        _random = random,
        _readInstanceBoolean = readInstanceBoolean {
    if (target.kind != SceneActorTargetKind.entity ||
        movement.mode != MapEntityNpcMovementMode.fixedRoute) {
      throw ArgumentError('A fixed NPC route requires an entity target.');
    }
    assertValidMapEntityNpcMovementConfig(this.movement);
    if (movement.suspendWhenInstanceBoolean != null &&
        readInstanceBoolean == null) {
      throw ArgumentError(
          'An instance-bound NPC route requires its state reader.');
    }
    _pauseRemaining = Duration(milliseconds: movement.pauseDurationMs);
  }

  final SceneActorTarget target;
  final MapEntityNpcMovementConfig movement;
  final Random _random;
  final NpcRouteInstanceBooleanReader? _readInstanceBoolean;
  late Duration _pauseRemaining;
  NpcFixedRouteAttempt? _pending;
  var _stepIndex = 0;
  var _disposed = false;

  int get stepIndex => _stepIndex;
  bool get isComplete => _stepIndex >= movement.routeSteps.length;

  NpcFixedRouteAttempt? nextStep(Duration elapsed, {bool paused = false}) {
    if (elapsed.isNegative) {
      throw ArgumentError.value(elapsed, 'elapsed', 'Must not be negative.');
    }
    if (_disposed || isComplete) {
      return null;
    }
    if (_suspendedByInstanceBoolean) {
      interrupt();
      return null;
    }
    if (paused || _pending != null) {
      return null;
    }
    _pauseRemaining -= elapsed;
    if (_pauseRemaining > Duration.zero) {
      return null;
    }
    final step = movement.routeSteps[_stepIndex];
    final direction = switch (step) {
      MapEntityNpcMoveStep(:final direction) => direction,
      MapEntityNpcFaceStep(:final direction) => direction,
      MapEntityNpcRandomFacingStep() || MapEntityNpcRandomMoveStep() => const [
          EntityFacing.north,
          EntityFacing.east,
          EntityFacing.west,
          EntityFacing.south,
        ][_random.nextInt(4)],
    };
    final attempt = NpcFixedRouteAttempt._(
      owner: this,
      target: target,
      step: step,
      direction: direction,
      stepDurationMs: movement.stepDurationMs,
      stepIndex: _stepIndex,
    );
    _pending = attempt;
    return attempt;
  }

  bool resolveStep(
    NpcFixedRouteAttempt attempt,
    NpcFixedRouteStepOutcome outcome,
  ) {
    if (!_owns(attempt)) {
      return false;
    }
    _pending = null;
    if (outcome == NpcFixedRouteStepOutcome.completed) {
      _stepIndex++;
      if (isComplete && movement.loop) {
        _stepIndex = 0;
      }
    }
    _pauseRemaining = Duration(milliseconds: movement.pauseDurationMs);
    return true;
  }

  void interrupt() {
    if (_disposed) {
      return;
    }
    _pending = null;
    _pauseRemaining = Duration(milliseconds: movement.pauseDurationMs);
  }

  void dispose() {
    _disposed = true;
    _pending = null;
  }

  bool get _suspendedByInstanceBoolean {
    final binding = movement.suspendWhenInstanceBoolean;
    return binding != null &&
        _readInstanceBoolean!(binding.key) == binding.value;
  }

  bool _owns(NpcFixedRouteAttempt attempt) =>
      !_disposed &&
      identical(_pending, attempt) &&
      !_suspendedByInstanceBoolean;
}

final class NpcFixedRouteAttempt {
  const NpcFixedRouteAttempt._({
    required NpcFixedRouteController owner,
    required this.target,
    required this.step,
    required this.direction,
    required this.stepDurationMs,
    required this.stepIndex,
  }) : _owner = owner;

  final NpcFixedRouteController _owner;
  final SceneActorTarget target;
  final MapEntityNpcRouteStep step;
  final EntityFacing direction;
  final int stepDurationMs;
  final int stepIndex;
}

final class NpcFixedRouteStepPlan {
  const NpcFixedRouteStepPlan._({
    required this.world,
    required this.motion,
    required this.isBlocked,
  });

  final GameplayWorldState world;
  final ActorRouteMotionPlan? motion;
  final bool isBlocked;
}

NpcFixedRouteStepPlan planNpcFixedRouteStep({
  required GameplayWorldState world,
  required NpcFixedRouteAttempt attempt,
  Iterable<GridPos> dynamicBlockedCells = const [],
  Iterable<PixelRect> characterReservations = const [],
}) {
  final owner = attempt._owner;
  if (!owner._owns(attempt) ||
      attempt.target.mapId != world.map.id ||
      world.map.spatialScene != null ||
      world.map.version == ProjectVersion.v9) {
    throw StateError(
        'A fixed NPC route requires its active 2D map and request.');
  }
  final actors = world.map.entities.where(
    (entity) => entity.id == attempt.target.entityId,
  );
  if (actors.length != 1 ||
      actors.single.kind != MapEntityKind.npc ||
      actors.single.npc?.movement != owner.movement) {
    throw StateError(
        'A fixed NPC route requires its unchanged NPC configuration.');
  }
  final actor = actors.single;
  if (!(world.npcMapPresencePredicate?.call(world.map.id, actor) ?? true) ||
      !(world.mapEntityPresencePredicate?.call(world.map.id, actor) ?? true)) {
    throw StateError('A fixed NPC route requires a present NPC.');
  }
  final faced =
      world.withEntityFacing(attempt.target.entityId!, attempt.direction);
  if (attempt.step is! MapEntityNpcMoveStep &&
      attempt.step is! MapEntityNpcRandomMoveStep) {
    return NpcFixedRouteStepPlan._(
        world: faced, motion: null, isBlocked: false);
  }
  final motion = planActorRouteMove(
    world: faced,
    target: attempt.target,
    direction: attempt.direction,
    through: false,
    dynamicBlockedCells: dynamicBlockedCells,
    characterReservations: characterReservations,
  );
  return NpcFixedRouteStepPlan._(
    world: faced,
    motion: motion,
    isBlocked: motion == null,
  );
}
