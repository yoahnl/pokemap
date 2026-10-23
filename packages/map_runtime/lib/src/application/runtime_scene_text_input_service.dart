part of 'player_service_runtime_controller.dart';

Future<SceneInteractionResult> _openSceneTextInteraction(
  PlayerServiceRuntimeController controller,
  OpenSceneTextInteractionService request,
) async {
  if (controller._disposed || controller._active) {
    throw StateError('The Scene text modal is unavailable.');
  }
  final reason = controller._worldRequestUnavailableReason(
    request,
    controller._currentGameState(),
  );
  if (reason != null) throw StateError(reason);
  final port = HeadlessSceneInteractionPort();
  controller._active = true;
  controller._sceneTextPort = port;
  var locked = false;
  try {
    controller._setInputLocked(true);
    locked = true;
    final result = port.request(request.interaction);
    controller._textRevision =
        ((controller._worldServiceSnapshot?.revision ?? -1) >
                controller._textRevision
            ? controller._worldServiceSnapshot!.revision
            : controller._textRevision) +
        1;
    controller._publishWorldService(
      RuntimeWorldServiceSnapshot(
        revision: controller._textRevision,
        request: request,
        stage: RuntimeWorldServiceStage.active,
        content: request.interaction,
        actions: [
          RuntimeWorldServiceActionAvailability.enabled(
            RuntimeWorldServiceAction.confirm,
          ),
          if (request.interaction is! SceneIntegerInteractionRequest || (request.interaction as SceneIntegerInteractionRequest).allowCancel)
            const RuntimeWorldServiceActionAvailability.enabled(RuntimeWorldServiceAction.cancel),
        ],
      ),
    );
    return await result;
  } finally {
    port.close();
    if (identical(controller._sceneTextPort, port)) {
      controller._sceneTextPort = null;
      controller._publishWorldService(null);
    }
    if (locked) controller._setInputLocked(false);
    controller._active = false;
  }
}

RuntimeWorldServiceCommandResult _dispatchSceneTextInteraction(
  PlayerServiceRuntimeController controller,
  RuntimeWorldServiceCommand command,
) {
  final snapshot = controller._worldServiceSnapshot!;
  final request = snapshot.content! as SceneInteractionRequest;
  final result =
      command.interactionResult ??
      (command.action == RuntimeWorldServiceAction.cancel ||
              command.action == RuntimeWorldServiceAction.close
          ? SceneInteractionResult.cancelled(
              requestId: request.requestId,
              revision: request.revision,
              reason: SceneInteractionCancellationReason.user,
            )
          : null);
  if (result == null) {
    return const RuntimeWorldServiceCommandResult(
      status: RuntimeWorldServiceCommandStatus.unavailable,
    );
  }
  final resolution = controller._sceneTextPort!.resolve(result);
  return RuntimeWorldServiceCommandResult(
    status: switch (resolution.status) {
      SceneInteractionResolutionStatus.accepted =>
        RuntimeWorldServiceCommandStatus.accepted,
      SceneInteractionResolutionStatus.invalidResult ||
      SceneInteractionResolutionStatus.kindMismatch =>
        RuntimeWorldServiceCommandStatus.unavailable,
      _ => RuntimeWorldServiceCommandStatus.stale,
    },
  );
}
