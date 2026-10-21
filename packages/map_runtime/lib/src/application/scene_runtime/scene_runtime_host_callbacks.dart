import 'package:map_core/map_core.dart';

import 'scene_interactive_pokemon_gift.dart';
import 'scene_interactive_text_input.dart';

final class SceneRuntimeHostCallbacks {
  const SceneRuntimeHostCallbacks({
    required this.evaluateCondition,
    required this.showDialogue,
    required this.startBattle,
    required this.playCinematic,
    this.playPresentationCinematic,
    this.executeInteractiveCommand,
    this.requestStructuredInteraction,
    this.presentPokemonGift,
    this.presentTextInput,
    this.presentPlayerAvatar,
  });

  final SceneRuntimeIntentCallback evaluateCondition;
  final SceneRuntimeIntentCallback showDialogue;
  final SceneRuntimeIntentCallback startBattle;
  final SceneRuntimeIntentCallback playCinematic;
  final SceneRuntimeIntentCallback? playPresentationCinematic;
  final SceneRuntimeIntentCallback? executeInteractiveCommand;
  final SceneRuntimeIntentCallback? requestStructuredInteraction;
  final ScenePokemonGiftPresenter? presentPokemonGift;
  final SceneTextInputPresenter? presentTextInput;
  final Future<void> Function(String? characterId)? presentPlayerAvatar;

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
