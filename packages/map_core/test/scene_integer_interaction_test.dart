import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  final prompt = SceneInteractionPrompt(localizationKey: 'number');
  SceneIntegerInteractionRequest request({bool allowCancel = true}) => SceneIntegerInteractionRequest(
    requestId: 'number', revision: 4, prompt: prompt, digits: 3,
    minimum: -50, maximum: 200, initialValue: 7, allowCancel: allowCancel,
  );
  SceneIntegerSubmittedInteractionResult submit(int value, {int revision = 4}) => SceneIntegerSubmittedInteractionResult(
    requestId: 'number', revision: revision, value: value,
  );
  test('integer modal round trips as typed numbers and enforces range/revision', () {
    final modal = request();
    expect(SceneInteractionRequest.fromJson(modal.toJson()), modal);
    expect(SceneInteractionResult.fromJson(submit(50).toJson()), submit(50));
    expect(modal.validateResult(submit(50)), isEmpty);
    expect(modal.validateResult(submit(201)), isNotEmpty);
    expect(modal.validateResult(submit(-51)), isNotEmpty);
    expect(modal.validateResult(submit(50, revision: 3)), isNotEmpty);
    expect(modal.validateResult(SceneInteractionResult.textSubmitted(requestId: 'number', revision: 4, value: '50')), isNotEmpty);
  });
  test('integer modal enforces cancellation in core', () {
    final cancel = SceneInteractionResult.cancelled(requestId: 'number', revision: 4, reason: SceneInteractionCancellationReason.user);
    expect(request().validateResult(cancel), isEmpty);
    expect(request(allowCancel: false).validateResult(cancel), isNotEmpty);
    expect(request(allowCancel: false).validateResult(SceneInteractionResult.cancelled(
      requestId: 'number', revision: 4, reason: SceneInteractionCancellationReason.disposed)), isEmpty);
  });
  test('integer request and response reject unknown fields', () {
    expect(() => SceneInteractionRequest.fromJson({...request().toJson(), 'expression': 'x'}), throwsFormatException);
    expect(() => SceneInteractionResult.fromJson({...submit(3).toJson(), 'expression': 'x'}), throwsFormatException);
  });
  test('integer contracts reject invalid digit/range/initial combinations', () {
    for (final digits in [0, 10]) {
      expect(() => SceneIntegerInteractionRequest(requestId: 'x', revision: 0, prompt: prompt,
        digits: digits, minimum: 0, maximum: 9, initialValue: 0), throwsArgumentError);
    }
    expect(() => SceneIntegerInteractionRequest(requestId: 'x', revision: 0, prompt: prompt,
      digits: 1, minimum: 0, maximum: 100, initialValue: 0), throwsArgumentError);
    final command = SceneInputIntegerToFactInteractiveCommand(factId: 'a', prompt: prompt,
      digits: 3, minimum: 0, maximum: 999, initialValue: 0, allowCancel: false);
    expect(SceneInteractiveCommand.fromJson(command.toJson()), command);
    final payment = SceneTryPayMoneyInteractiveCommand(amount: SceneIntegerOperand.literal(30));
    expect(SceneInteractiveCommand.fromJson(payment.toJson()), payment);
  });
}
