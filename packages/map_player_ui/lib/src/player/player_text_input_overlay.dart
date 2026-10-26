import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import 'player_scene_interaction_surface.dart';

class PlayerTextInputOverlay extends StatelessWidget {
  const PlayerTextInputOverlay({
    super.key,
    required this.snapshot,
    required this.onCommand,
  });

  final RuntimeWorldServiceSnapshot snapshot;
  final ValueChanged<RuntimeWorldServiceCommand> onCommand;

  @override
  Widget build(BuildContext context) {
    final request = snapshot.content;
    if (request is! SceneIntegerInteractionRequest && request is! SceneTextInteractionRequest && request is! SceneConfirmationInteractionRequest && request is! SceneChoiceInteractionRequest && request is! SceneMessageInteractionRequest) {
      throw StateError('Scene input requires a typed numeric, text, choice, confirmation or message request.');
    }
    return PlayerSceneInteractionSurface(
      request: request as SceneInteractionRequest,
      errorMessage: snapshot.safeMessage,
      interactionEnabled:
          snapshot.isActionEnabled(RuntimeWorldServiceAction.confirm),
      allowCancellation:
          snapshot.isActionEnabled(RuntimeWorldServiceAction.cancel),
      onResult: (result) => onCommand(
        RuntimeWorldServiceCommand(
          action: result is SceneCancelledInteractionResult
              ? RuntimeWorldServiceAction.cancel
              : RuntimeWorldServiceAction.confirm,
          snapshotRevision: snapshot.revision,
          interactionResult: result,
        ),
      ),
    );
  }
}
