import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/scene_runtime/scene_interactive_integer.dart';

void main() {
  final project = ProjectManifest(name: 'Numbers', maps: [], tilesets: [], facts: [
    NarrativeFactDefinition(id: 'number', label: 'Number', initialValue: NarrativeValue.integer(4)),
  ]);
  const state = GameState(saveId: 'integer', trainerProfile: TrainerProfile(name: 'Player', money: 50));
  test('canonical runtime condition resolver evaluates typed integer operands', () {
    expect(evaluateCanonicalNarrativeFactSceneCondition(source: SceneConditionSource.integerComparison(
      left: SceneIntegerOperand.gameRead(SceneIntegerGameRead.money), comparison: NarrativeFactOperator.greaterThan,
      right: SceneIntegerOperand.integerFact('number')), gameState: state,
      resolver: NarrativeFactRuntimeResolver.fromFacts(project.facts)), isTrue);
  });
  test('numeric input returns one integer literal consequence after valid response', () async {
    final result = await inputSceneIntegerToFact(
      command: SceneInputIntegerToFactInteractiveCommand(factId: 'number',
        prompt: SceneInteractionPrompt(localizationKey: 'number'), digits: 2, minimum: 0, maximum: 99),
      operationId: 'input', project: project, readProjectedState: () => state,
      present: (request) async {
        final input = request.interaction as SceneIntegerInteractionRequest;
        expect(input.initialValue, 4);
        return SceneIntegerSubmittedInteractionResult(requestId: input.requestId, revision: input.revision, value: 23);
      },
    );
    expect(result.outputPortId, 'completed');
    expect((result.consequence as SceneSetFactConsequence).narrativeValue, NarrativeValue.integer(23));
    expect(state.narrativeFactRuntimeState.valuesByFactId, isEmpty);
  });
  test('numeric cancellation can restore the clamped initial value and complete', () async {
    final before = state.copyWith(narrativeFactRuntimeState: NarrativeFactRuntimeState.typed(valuesByFactId: {'number': NarrativeValue.integer(1000)}));
    final result = await inputSceneIntegerToFact(command: SceneInputIntegerToFactInteractiveCommand(
      factId: 'number', prompt: SceneInteractionPrompt(localizationKey: 'number'), digits: 2, minimum: 0, maximum: 99,
      cancellationPolicy: SceneIntegerCancellationPolicy.restoreInitialAndComplete),
      operationId: 'input', project: project, readProjectedState: () => before,
      present: (request) async => SceneInteractionResult.cancelled(requestId: request.interaction.requestId,
        revision: request.interaction.revision, reason: SceneInteractionCancellationReason.user));
    expect(result.outputPortId, 'completed');
    expect((result.consequence as SceneSetFactConsequence).narrativeValue, NarrativeValue.integer(99));
  });
  test('payment rejects insufficient funds and snapshots an atomic exact debit', () async {
    Future<SceneInteractionResult> noPrompt(OpenSceneTextInteractionService _) async => throw StateError('Unexpected prompt');
    final insufficient = await tryScenePayMoney(command: SceneTryPayMoneyInteractiveCommand(
      amount: SceneIntegerOperand.literal(51)), operationId: 'pay', project: project,
      readProjectedState: () => state, present: noPrompt);
    expect(insufficient.outputPortId, 'insufficientFunds');
    expect(insufficient.consequence, isNull);
    final paid = await tryScenePayMoney(command: SceneTryPayMoneyInteractiveCommand(
      amount: SceneIntegerOperand.literal(30)), operationId: 'pay', project: project,
      readProjectedState: () => state, present: noPrompt);
    expect(paid.outputPortId, 'completed');
    final writer = SceneConsequenceRuntimeWriter(project: project);
    expect(writer.applyOne(state, paid.consequence!).gameState.trainerProfile.money, 20);
    final stale = state.copyWith(trainerProfile: state.trainerProfile.copyWith(money: 40));
    expect(writer.applyOne(stale, paid.consequence!).success, isFalse);
  });
  test('payment lifecycle cancellation aborts rather than routing user cancellation', () async {
    for (final reason in [SceneInteractionCancellationReason.disposed, SceneInteractionCancellationReason.superseded, SceneInteractionCancellationReason.timeout]) {
      await expectLater(() => tryScenePayMoney(command: SceneTryPayMoneyInteractiveCommand(
        amount: SceneIntegerOperand.literal(10), confirmationPrompt: SceneInteractionPrompt(localizationKey: 'confirm')),
        operationId: 'pay', project: project, readProjectedState: () => state,
        present: (request) async => SceneInteractionResult.cancelled(requestId: request.interaction.requestId,
          revision: request.interaction.revision, reason: reason)), throwsStateError);
    }
  });
  test('confirmation cancellation and stale numeric fact leave no effect', () async {
    final cancelled = await tryScenePayMoney(command: SceneTryPayMoneyInteractiveCommand(
      amount: SceneIntegerOperand.literal(10), confirmationPrompt: SceneInteractionPrompt(localizationKey: 'confirm')),
      operationId: 'pay', project: project, readProjectedState: () => state,
      present: (request) async => SceneInteractionResult.confirmed(
        requestId: request.interaction.requestId, revision: request.interaction.revision, value: false));
    expect(cancelled.outputPortId, 'cancelled');
    expect(cancelled.consequence, isNull);
    var current = state;
    expect(() => inputSceneIntegerToFact(command: SceneInputIntegerToFactInteractiveCommand(
      factId: 'number', prompt: SceneInteractionPrompt(localizationKey: 'number'), digits: 2, minimum: 0, maximum: 99),
      operationId: 'input', project: project, readProjectedState: () => current,
      present: (request) async {
        current = state.copyWith(narrativeFactRuntimeState: NarrativeFactRuntimeState.typed(valuesByFactId: {'number': NarrativeValue.integer(5)}));
        return SceneIntegerSubmittedInteractionResult(requestId: request.interaction.requestId, revision: request.interaction.revision, value: 9);
      }), throwsStateError);
  });
}
