import 'package:map_core/map_core.dart';

enum ActorRouteMoveOutcome { moved, obstructed }

enum ActorRouteExecutionOutcome { completed, blocked, interrupted }

abstract interface class ActorRouteExecutionPort {
  bool get isCurrent;
  Future<void> face(SceneActorTarget target, EntityFacing direction);
  Future<void> nextUpdate();
  Future<ActorRouteMoveOutcome> move(
      SceneActorTarget target, EntityFacing direction,
      {required int durationMs,
      required bool through,
      String? initialCollisionOwnerEntityId});
  Future<void> wait(int durationMs);
  Future<void> sound(String mediaAssetId, {required double gain});
  Future<void> setVisibility(SceneActorTarget target, {required bool visible});
}

final class ActorRouteExecutor {
  const ActorRouteExecutor();

  Future<ActorRouteExecutionOutcome> execute(
    SceneActorRouteInteractiveCommand command, {
    required ActorRouteExecutionPort port,
  }) async {
    var through = false;
    for (final step in command.steps) {
      if (!port.isCurrent) {
        return ActorRouteExecutionOutcome.interrupted;
      }
      switch (step) {
        case SceneActorFaceStep():
          await port.face(command.target, step.direction);
          if (!port.isCurrent) {
            return ActorRouteExecutionOutcome.interrupted;
          }
          if (step.yieldAfter) {
            await port.nextUpdate();
            if (!port.isCurrent) {
              return ActorRouteExecutionOutcome.interrupted;
            }
          }
          if (step.durationMs > 0) {
            await port.wait(step.durationMs);
          }
        case SceneActorMoveStep():
          final outcome = await port.move(
            command.target,
            step.direction,
            durationMs: step.durationMs,
            through: through,
            initialCollisionOwnerEntityId: step.initialCollisionOwnerEntityId,
          );
          if (!port.isCurrent) {
            return ActorRouteExecutionOutcome.interrupted;
          }
          if (outcome == ActorRouteMoveOutcome.obstructed &&
              !command.skippable) {
            return ActorRouteExecutionOutcome.blocked;
          }
        case SceneActorWaitStep():
          await port.wait(step.durationMs);
        case SceneActorThroughStep():
          through = step.enabled;
        case SceneActorSoundStep():
          await port.sound(step.mediaAssetId, gain: step.gain);
      }
      if (!port.isCurrent) {
        return ActorRouteExecutionOutcome.interrupted;
      }
    }
    return port.isCurrent
        ? ActorRouteExecutionOutcome.completed
        : ActorRouteExecutionOutcome.interrupted;
  }

  Future<ActorRouteExecutionOutcome> executeVisibility(
    SceneActorVisibilityInteractiveCommand command, {
    required ActorRouteExecutionPort port,
  }) async {
    if (!port.isCurrent) {
      return ActorRouteExecutionOutcome.interrupted;
    }
    await port.setVisibility(command.target, visible: command.visible);
    return port.isCurrent
        ? ActorRouteExecutionOutcome.completed
        : ActorRouteExecutionOutcome.interrupted;
  }
}
