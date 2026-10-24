import 'dart:math';

import 'package:map_core/map_core.dart';

import 'actor_route_motion.dart';
import 'gameplay_world_state.dart';
import 'direction.dart';
import 'movement_terrain_policy.dart';

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
          pauseDurationsMs: List.unmodifiable(movement.pauseDurationsMs),
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
    _pauseRemaining = _nextPause();
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
    _pauseRemaining = _nextPause();
    return true;
  }

  void interrupt() {
    if (_disposed) {
      return;
    }
    _pending = null;
    _pauseRemaining = _nextPause();
  }

  void dispose() {
    _disposed = true;
    _pending = null;
  }

  Duration _nextPause() => Duration(milliseconds: movement.pauseDurationsMs.isEmpty
      ? movement.pauseDurationMs
      : movement.pauseDurationsMs[_random.nextInt(movement.pauseDurationsMs.length)]);

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
    this.playerContact = false,
  });

  final GameplayWorldState world;
  final ActorRouteMotionPlan? motion;
  final bool isBlocked;
  final bool playerContact;
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
  final area = owner.movement.movementArea;
  final delta = attempt.direction.asDirection;
  if (area != null &&
      (actor.pos.x + delta.dx < area.pos.x ||
          actor.pos.y + delta.dy < area.pos.y ||
          actor.pos.x + delta.dx + actor.size.width > area.pos.x + area.size.width ||
          actor.pos.y + delta.dy + actor.size.height > area.pos.y + area.size.height)) {
    return NpcFixedRouteStepPlan._(world: faced, motion: null, isBlocked: true);
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
    playerContact: motion == null &&
        npcFixedRouteTouchesPlayer(
            world: faced,
            entityId: actor.id,
            direction: attempt.direction,
            dynamicBlockedCells: dynamicBlockedCells,
            characterReservations: characterReservations),
  );
}

bool npcFixedRouteTouchesPlayer({
  required GameplayWorldState world,
  required String entityId,
  required EntityFacing direction,
  Iterable<GridPos> dynamicBlockedCells = const [],
  Iterable<PixelRect> characterReservations = const [],
}) {
  if (world.map.spatialScene != null || world.map.version == ProjectVersion.v9)
    return false;
  final actors = world.map.entities.where((entity) => entity.id == entityId);
  if (actors.length != 1) return false;
  final actor = actors.single;
  if (actor.kind != MapEntityKind.npc ||
      actor.npc == null ||
      !actor.blocksMovement ||
      !(world.npcMapPresencePredicate?.call(world.map.id, actor) ?? true) ||
      !(world.mapEntityPresencePredicate?.call(world.map.id, actor) ?? true))
    return false;
  final source = resolveEntityCollisionRectPx(actor,
      tileWidthPx: world.tileWidthPx, tileHeightPx: world.tileHeightPx);
  final player =
      world.playerCharacterContactRect(world.player.playerCollisionRectPx);
  bool intersects(PixelRect first, PixelRect second) =>
      first.leftPx < second.leftPx + second.widthPx &&
      first.leftPx + first.widthPx > second.leftPx &&
      first.topPx < second.topPx + second.heightPx &&
      first.topPx + first.heightPx > second.topPx;
  if (intersects(source, player)) return false;
  final delta = direction.asDirection;
  final distance = delta.dx == 0 ? world.tileHeightPx : world.tileWidthPx;
  final reservations = characterReservations.toList(growable: false);
  final blockedCells = dynamicBlockedCells
      .where((cell) => cell != world.player.pos)
      .toList(growable: false);
  for (var pixel = 1; pixel <= distance; pixel++) {
    final rect = PixelRect(
        leftPx: source.leftPx + delta.dx * pixel,
        topPx: source.topPx + delta.dy * pixel,
        widthPx: source.widthPx,
        heightPx: source.heightPx);
    if (rect.leftPx < 0 ||
        rect.topPx < 0 ||
        rect.leftPx + rect.widthPx > world.map.size.width * world.tileWidthPx ||
        rect.topPx + rect.heightPx >
            world.map.size.height * world.tileHeightPx ||
        !movementTerrainAllowsRect(
            map: world.map,
            rect: rect,
            tileWidth: world.tileWidthPx,
            tileHeight: world.tileHeightPx,
            mode: MovementMode.walk) ||
        world.worldStaticObstaclesCollidePixelRect(rect,
            ignoredEntityId: actor.id) ||
        reservations.any((reservation) => intersects(rect, reservation)) ||
        blockedCells.any((cell) => intersects(
            rect,
            PixelRect(
                leftPx: cell.x * world.tileWidthPx,
                topPx: cell.y * world.tileHeightPx,
                widthPx: world.tileWidthPx,
                heightPx: world.tileHeightPx)))) return false;
    if (intersects(rect, player)) return true;
  }
  return false;
}
