import 'package:map_core/map_core.dart';

import 'movement_block_reason.dart';
import 'gameplay_world_state.dart';

class TriggeredWarp {
  const TriggeredWarp({
    required this.warpId,
    required this.targetMapId,
    required this.targetPos,
    required this.triggerMode,
  });

  final String warpId;
  final String targetMapId;
  final GridPos targetPos;
  final MapWarpTriggerMode triggerMode;
}

class TriggeredConnection {
  const TriggeredConnection({
    required this.direction,
    required this.targetMapId,
    required this.offset,
    required this.sourcePos,
  });

  final MapConnectionDirection direction;
  final String targetMapId;
  final int offset;
  final GridPos sourcePos;
}

enum PathAnimationSignalKind {
  trigger,
  setActive,
}

class PathAnimationSignal {
  const PathAnimationSignal({
    required this.kind,
    required this.layerId,
    required this.presetId,
    required this.ruleId,
    required this.trigger,
    required this.mode,
    required this.sourcePos,
    this.scope = PathAnimationActivationScope.wholeLayer,
    this.active,
  });

  final PathAnimationSignalKind kind;
  final String layerId;
  final String presetId;
  final String ruleId;
  final PathAnimationTriggerType trigger;
  final PathAnimationPlaybackMode mode;
  final GridPos sourcePos;
  final PathAnimationActivationScope scope;
  final bool? active;
}

sealed class GameplayStepResult {
  const GameplayStepResult(
    this.world, {
    this.pathAnimationSignals = const <PathAnimationSignal>[],
  });
  final GameplayWorldState world;
  final List<PathAnimationSignal> pathAnimationSignals;
}

final class Moved extends GameplayStepResult {
  const Moved(
    super.world, {
    super.pathAnimationSignals,
  });
}

final class Blocked extends GameplayStepResult {
  const Blocked(
    super.world, {
    this.reason = GameplayMovementBlockReason.solid,
    super.pathAnimationSignals,
  });

  final GameplayMovementBlockReason reason;
}

final class WarpTriggered extends GameplayStepResult {
  const WarpTriggered(
    super.world,
    this.warp, {
    super.pathAnimationSignals,
  });
  final TriggeredWarp warp;
}

final class ConnectionTriggered extends GameplayStepResult {
  const ConnectionTriggered(
    super.world,
    this.connection, {
    super.pathAnimationSignals,
  });
  final TriggeredConnection connection;
}

final class NothingToInteract extends GameplayStepResult {
  const NothingToInteract(
    super.world, {
    super.pathAnimationSignals,
  });
}

final class NpcInteracted extends GameplayStepResult {
  const NpcInteracted(
    super.world,
    this.entity, {
    super.pathAnimationSignals,
  });
  final MapEntity entity;
}

final class SignInteracted extends GameplayStepResult {
  const SignInteracted(
    super.world,
    this.entity, {
    super.pathAnimationSignals,
  });
  final MapEntity entity;
}

final class ItemInteracted extends GameplayStepResult {
  const ItemInteracted(
    super.world,
    this.entity, {
    super.pathAnimationSignals,
  });
  final MapEntity entity;
}

final class EntityInteracted extends GameplayStepResult {
  const EntityInteracted(
    super.world,
    this.entity, {
    super.pathAnimationSignals,
  });
  final MapEntity entity;
}

final class PlacedElementInteracted extends GameplayStepResult {
  const PlacedElementInteracted(
    super.world,
    this.element,
    this.behavior,
    this.trigger, {
    super.pathAnimationSignals,
  });
  final MapPlacedElement element;
  final MapPlacedElementBehavior behavior;
  final MapPlacedElementTriggerType trigger;
}
