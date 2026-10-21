import 'package:map_core/map_core.dart';

import '../../player/runtime_world_service_models.dart';

typedef SceneTextInputPresenter = Future<SceneInteractionResult> Function(
  OpenSceneTextInteractionService request,
);

Future<({String outputPortId, SceneSetFactConsequence? consequence})>
inputSceneTextToFact({
  required SceneInputTextToFactInteractiveCommand command,
  required String operationId,
  required ProjectManifest project,
  required GameState Function() readProjectedState,
  required SceneTextInputPresenter present,
}) async {
  if (operationId.trim().isEmpty) {
    throw StateError('The text input Scene identity is missing.');
  }
  final resolver = NarrativeFactRuntimeResolver.fromFacts(project.facts);
  NarrativeValue readValue() {
    final state = readProjectedState();
    final result = resolver.resolve(
      factId: command.factId,
      runtimeState: state.narrativeFactRuntimeState,
      storyFlags: state.storyFlags,
    );
    if (result is! NarrativeFactRuntimeResolved ||
        result.fact.valueKind != NarrativeValueKind.string ||
        result.narrativeValue.kind != NarrativeValueKind.string) {
      throw StateError('Text input requires a unique string Fact.');
    }
    return result.narrativeValue;
  }

  final previous = readValue();
  var candidate = previous.stringValue;
  var revision = 0;
  Future<SceneInteractionResult> ask(SceneInteractionRequest request) async {
    final result = await present(
      OpenSceneTextInteractionService(
        interactionId: request.requestId,
        interaction: request,
      ),
    );
    if (request.validateResult(result).isNotEmpty) {
      throw StateError('The Scene text response is invalid or stale.');
    }
    if (readValue() != previous) {
      throw StateError('The text Fact changed during its interaction.');
    }
    return result;
  }

  while (true) {
    var custom = true;
    if (command.presetValues.isNotEmpty) {
      final answer = await ask(
        SceneChoiceInteractionRequest(
          requestId: '$operationId:choice',
          revision: revision++,
          prompt: command.presetChoicePrompt!,
          options: [
            SceneInteractionOption(
              id: 'custom',
              label: SceneInteractionPrompt(
                localizationKey: 'scene.inputTextToFact.custom',
                fallbackText: command.customChoiceLabel,
              ),
            ),
            for (final (index, value) in command.presetValues.indexed)
              SceneInteractionOption(
                id: 'preset:$index',
                label: SceneInteractionPrompt(
                  localizationKey: 'scene.inputTextToFact.preset.$index',
                  fallbackText: value,
                ),
              ),
          ],
        ),
      );
      if (answer is SceneCancelledInteractionResult) {
        return (outputPortId: 'cancelled', consequence: null);
      }
      final selected =
          (answer as SceneChoiceSelectedInteractionResult).selectedOptionId;
      custom = selected == 'custom';
      if (!custom) {
        candidate = command
            .presetValues[int.parse(selected.substring('preset:'.length))];
      }
    }
    if (custom) {
      final answer = await ask(
        SceneTextInteractionRequest(
          requestId: '$operationId:text',
          revision: revision++,
          prompt: command.prompt,
          initialValue: candidate,
          constraints: command.constraints,
        ),
      );
      if (answer is SceneCancelledInteractionResult) {
        if (answer.reason == SceneInteractionCancellationReason.user &&
            command.presetValues.isNotEmpty) {
          continue;
        }
        return (outputPortId: 'cancelled', consequence: null);
      }
      candidate = (answer as SceneTextSubmittedInteractionResult).value;
    }
    final answer = await ask(
      SceneConfirmationInteractionRequest(
        requestId: '$operationId:confirm',
        revision: revision++,
        prompt: SceneInteractionPrompt(
          localizationKey: command.confirmationPrompt.localizationKey,
          fallbackText: command.confirmationPrompt.fallbackText,
          arguments: {
            ...command.confirmationPrompt.arguments,
            'value': candidate,
          },
        ),
      ),
    );
    if (answer is SceneCancelledInteractionResult) {
      if (answer.reason == SceneInteractionCancellationReason.user) continue;
      return (outputPortId: 'cancelled', consequence: null);
    }
    if ((answer as SceneConfirmedInteractionResult).value) {
      return (
        outputPortId: 'completed',
        consequence: SceneConsequence.setFactValue(
          factId: command.factId,
          value: NarrativeValue.string(candidate),
        ) as SceneSetFactConsequence,
      );
    }
  }
}
