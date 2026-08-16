import 'package:map_core/map_core.dart';

final class SceneRuntimeHostCallbacks {
  const SceneRuntimeHostCallbacks({
    required this.evaluateCondition,
    required this.showDialogue,
    required this.startBattle,
    required this.playCinematic,
    this.playPresentationCinematic,
    this.executeInteractiveCommand,
    this.requestStructuredInteraction,
  });

  final SceneRuntimeIntentCallback evaluateCondition;
  final SceneRuntimeIntentCallback showDialogue;
  final SceneRuntimeIntentCallback startBattle;
  final SceneRuntimeIntentCallback playCinematic;
  final SceneRuntimeIntentCallback? playPresentationCinematic;
  final SceneRuntimeIntentCallback? executeInteractiveCommand;
  final SceneRuntimeIntentCallback? requestStructuredInteraction;

  SceneRuntimeExecutionCallbacks toExecutionCallbacks({
    required SceneRuntimeConsequenceCallback applyConsequence,
    SceneRuntimeNodeConsequenceCallback? applyConsequenceWithNodeId,
  }) {
    return SceneRuntimeExecutionCallbacks(
      evaluateCondition: evaluateCondition,
      showDialogue: showDialogue,
      startBattle: startBattle,
      playCinematic: playCinematic,
      playPresentationCinematic: playPresentationCinematic,
      applyConsequence: applyConsequence,
      applyConsequenceWithNodeId: applyConsequenceWithNodeId,
      executeInteractiveCommand: executeInteractiveCommand,
      requestStructuredInteraction: requestStructuredInteraction,
    );
  }
}
