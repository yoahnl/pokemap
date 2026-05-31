import 'package:map_core/map_core.dart';

final class SceneRuntimeHostCallbacks {
  const SceneRuntimeHostCallbacks({
    required this.evaluateCondition,
    required this.showDialogue,
    required this.startBattle,
    required this.playCinematic,
  });

  final SceneRuntimeIntentCallback evaluateCondition;
  final SceneRuntimeIntentCallback showDialogue;
  final SceneRuntimeIntentCallback startBattle;
  final SceneRuntimeIntentCallback playCinematic;

  SceneRuntimeExecutionCallbacks toExecutionCallbacks({
    required SceneRuntimeConsequenceCallback applyConsequence,
  }) {
    return SceneRuntimeExecutionCallbacks(
      evaluateCondition: evaluateCondition,
      showDialogue: showDialogue,
      startBattle: startBattle,
      playCinematic: playCinematic,
      applyConsequence: applyConsequence,
    );
  }
}
