import 'package:map_core/map_core.dart';

import 'scene_interactive_text_input.dart';
import '../../player/runtime_world_service_models.dart';

typedef SceneIntegerInteractionOutcome = ({
  String outputPortId,
  SceneConsequence? consequence,
});

Future<SceneIntegerInteractionOutcome> inputSceneIntegerToFact({
  required SceneInputIntegerToFactInteractiveCommand command,
  required String operationId,
  required ProjectManifest project,
  required GameState Function() readProjectedState,
  required SceneTextInputPresenter present,
}) async {
  if (operationId.trim().isEmpty)
    throw StateError('Numeric input requires a Scene identity.');
  final evaluator = SceneIntegerOperations(
    NarrativeFactRuntimeResolver.fromFacts(project.facts),
  );
  final operand = SceneIntegerOperand.integerFact(command.factId);
  final previous = evaluator.read(readProjectedState(), operand);
  final request = SceneIntegerInteractionRequest(
    requestId: '$operationId:integer',
    revision: 0,
    prompt: command.prompt,
    digits: command.digits,
    minimum: command.minimum,
    maximum: command.maximum,
    initialValue:
        command.initialValue ??
        previous.clamp(command.minimum, command.maximum),
    allowCancel: command.allowCancel,
  );
  final result = await present(
    OpenSceneTextInteractionService(
      interactionId: request.requestId,
      interaction: request,
    ),
  );
  if (request.validateResult(result).isNotEmpty ||
      evaluator.read(readProjectedState(), operand) != previous) {
    throw StateError(
      'The numeric response or its target Fact is stale or invalid.',
    );
  }
  if (result is SceneCancelledInteractionResult) {
    if (result.reason != SceneInteractionCancellationReason.user) throw StateError('The numeric interaction owner was cancelled.');
    if (result.reason == SceneInteractionCancellationReason.user && command.cancellationPolicy == SceneIntegerCancellationPolicy.restoreInitialAndComplete) {
      return (outputPortId: 'completed', consequence: SceneSetFactConsequence.typed(factId: command.factId, value: NarrativeValue.integer(request.initialValue)));
    }
    return (outputPortId: 'cancelled', consequence: null);
  }
  return (
    outputPortId: 'completed',
    consequence: SceneSetFactConsequence.typed(
      factId: command.factId,
      value: NarrativeValue.integer(
        (result as SceneIntegerSubmittedInteractionResult).value,
      ),
    ),
  );
}

Future<SceneIntegerInteractionOutcome> tryScenePayMoney({
  required SceneTryPayMoneyInteractiveCommand command,
  required String operationId,
  required ProjectManifest project,
  required GameState Function() readProjectedState,
  required SceneTextInputPresenter present,
}) async {
  if (operationId.trim().isEmpty)
    throw StateError('Payment requires a Scene identity.');
  final evaluator = SceneIntegerOperations(
    NarrativeFactRuntimeResolver.fromFacts(project.facts),
  );
  final state = readProjectedState();
  final amount = evaluator.read(state, command.amount),
      balance = state.trainerProfile.money;
  if (amount <= 0) throw StateError('Payment requires a positive amount.');
  if (balance < amount)
    return (outputPortId: 'insufficientFunds', consequence: null);
  if (command.confirmationPrompt case final prompt?) {
    final request = SceneConfirmationInteractionRequest(
      requestId: '$operationId:payment',
      revision: 0,
      prompt: SceneInteractionPrompt(
        localizationKey: prompt.localizationKey,
        fallbackText: prompt.fallbackText,
        arguments: {...prompt.arguments, 'amount': '$amount'},
      ),
    );
    final result = await present(
      OpenSceneTextInteractionService(
        interactionId: request.requestId,
        interaction: request,
      ),
    );
    if (request.validateResult(result).isNotEmpty)
      throw StateError('The payment response is stale or invalid.');
    if (result is SceneCancelledInteractionResult && result.reason != SceneInteractionCancellationReason.user) throw StateError('The payment interaction owner was cancelled.');
    final current = readProjectedState();
    if (current.trainerProfile.money != balance ||
        evaluator.read(current, command.amount) != amount)
      throw StateError(
        'The payment balance or amount changed during confirmation.',
      );
    if (result is SceneCancelledInteractionResult ||
        !(result as SceneConfirmedInteractionResult).value) {
      return (outputPortId: 'cancelled', consequence: null);
    }
  }
  return (
    outputPortId: 'completed',
    consequence: SceneAdjustMoneyConsequence(
      operation: SceneMoneyOperation.subtract,
      amount: SceneIntegerOperand.literal(amount),
      minimum: 0,
      maximum: 9007199254740991,
      expectedBalance: balance,
    ),
  );
}
