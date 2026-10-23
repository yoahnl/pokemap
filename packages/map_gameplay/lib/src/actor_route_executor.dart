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
  Future<ActorRouteMoveOutcome> moveDiagonal(
      SceneActorTarget target, EntityFacing horizontal, EntityFacing vertical,
      {required int durationMs, required bool through});
  bool get renderAboveMap;
  Future<void> setRenderAboveMap(SceneActorTarget target,
      {required bool enabled});
  Future<void> wait(int durationMs);
  Future<void> sound(String mediaAssetId, {required double gain});
  Future<void> setVisibility(SceneActorTarget target, {required bool visible});
  bool get isVisible;
  void restoreVisibility(SceneActorTarget target, {required bool visible});
  Object captureAppearance(SceneActorTarget target);
  Future<void> setAppearance(SceneActorTarget target, String characterId);
  void restoreAppearance(SceneActorTarget target, Object snapshot);
}

final class ActorRouteTransientState {
  ActorRouteTransientState({this.through = false, this.renderAboveMap = false});
  bool through, renderAboveMap;
}

final class ActorRouteExecutor {
  const ActorRouteExecutor();

  Future<ActorRouteExecutionOutcome> execute(
    SceneActorRouteInteractiveCommand command, {
    required ActorRouteExecutionPort port,
    ActorRouteTransientState? sceneState,
  }) async {
    final sceneScope = command.transientScope == ActorRouteTransientScope.scene;
    if (sceneScope && sceneState == null)
      return ActorRouteExecutionOutcome.blocked;
    final state = sceneScope
        ? sceneState!
        : ActorRouteTransientState(renderAboveMap: port.renderAboveMap);
    final beforeThrough = state.through;
    final beforeAbove = port.renderAboveMap;
    final beforeVisible = port.isVisible;
    final beforeAppearance = port.captureAppearance(command.target);
    var appearanceChanged = false;
    var completed = false;
    try {
      for (final step in command.steps) {
        if (!port.isCurrent) {
          return ActorRouteExecutionOutcome.interrupted;
        }
        switch (step) {
          case SceneActorAppearanceStep():
            appearanceChanged = true;
            await port.setAppearance(command.target, step.characterId);
          case SceneActorRenderAboveMapStep():
            state.renderAboveMap = step.enabled;
            await port.setRenderAboveMap(command.target, enabled: step.enabled);
          case SceneActorDiagonalMoveStep():
            final outcome = await port.moveDiagonal(
                command.target, step.horizontal, step.vertical,
                durationMs: step.durationMs, through: state.through);
            if (!port.isCurrent) return ActorRouteExecutionOutcome.interrupted;
            if (outcome == ActorRouteMoveOutcome.obstructed) {
              if (!command.skippable) return ActorRouteExecutionOutcome.blocked;
              await port.nextUpdate();
              if (!port.isCurrent)
                return ActorRouteExecutionOutcome.interrupted;
            }
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
            if (state.through && step.initialCollisionOwnerEntityId != null) {
              return ActorRouteExecutionOutcome.blocked;
            }
            final outcome = await port.move(
              command.target,
              step.direction,
              durationMs: step.durationMs,
              through: state.through,
              initialCollisionOwnerEntityId: step.initialCollisionOwnerEntityId,
            );
            if (!port.isCurrent) {
              return ActorRouteExecutionOutcome.interrupted;
            }
            if (outcome == ActorRouteMoveOutcome.obstructed) {
              if (!command.skippable) {
                return ActorRouteExecutionOutcome.blocked;
              }
              await port.nextUpdate();
              if (!port.isCurrent) {
                return ActorRouteExecutionOutcome.interrupted;
              }
            }
          case SceneActorWaitStep():
            await port.wait(step.durationMs);
          case SceneActorThroughStep():
            state.through = step.enabled;
          case SceneActorVisibilityStep():
            await port.setVisibility(command.target, visible: step.visible);
          case SceneActorSoundStep():
            await port.sound(step.mediaAssetId, gain: step.gain);
        }
        if (!port.isCurrent) {
          return ActorRouteExecutionOutcome.interrupted;
        }
      }
      completed = port.isCurrent;
      return completed
          ? ActorRouteExecutionOutcome.completed
          : ActorRouteExecutionOutcome.interrupted;
    } finally {
      if (!sceneScope || !completed) {
        if (appearanceChanged) port.restoreAppearance(command.target, beforeAppearance);
        if (port.isVisible != beforeVisible) {
          port.restoreVisibility(command.target, visible: beforeVisible);
        }
        state.through = beforeThrough;
        state.renderAboveMap = beforeAbove;
        if (port.renderAboveMap != beforeAbove) {
          await port.setRenderAboveMap(command.target, enabled: beforeAbove);
        }
      }
    }
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
