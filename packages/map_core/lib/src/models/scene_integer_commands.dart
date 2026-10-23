part of 'scene_interactive_command.dart';

@immutable
final class SceneInputIntegerToFactInteractiveCommand
    extends SceneInteractiveCommand {
  SceneInputIntegerToFactInteractiveCommand({
    required String factId,
    required this.prompt,
    required this.digits,
    required this.minimum,
    required this.maximum,
    this.initialValue,
    this.allowCancel = true,
    this.cancellationPolicy = SceneIntegerCancellationPolicy.leaveUnchanged,
  }) : factId = sceneIntegerIdentity(factId, 'factId') {
    validateSceneIntegerInput(
      digits: digits,
      minimum: minimum,
      maximum: maximum,
      initialValue: initialValue,
    );
  }
  factory SceneInputIntegerToFactInteractiveCommand.fromJson(
    Map<String, dynamic> json,
  ) {
    if (json['kind'] != 'inputIntegerToFact')
      throw const FormatException('Invalid integer input kind.');
    sceneIntegerFields(json, {
      'kind',
      'factId',
      'prompt',
      'digits',
      'minimum',
      'maximum',
      'initialValue',
      'allowCancel',
      'cancellationPolicy',
    });
    if (json['allowCancel'] != null && json['allowCancel'] is! bool)
      throw const FormatException('allowCancel must be boolean.');
    try {
      return SceneInputIntegerToFactInteractiveCommand(
        factId: _required(json, 'factId'),
        prompt: SceneInteractionPrompt.fromJson(
          _requiredObject(json, 'prompt'),
        ),
        digits: sceneIntegerInt(json, 'digits'),
        minimum: sceneIntegerInt(json, 'minimum'),
        maximum: sceneIntegerInt(json, 'maximum'),
        initialValue: json['initialValue'] == null
            ? null
            : sceneIntegerInt(json, 'initialValue'),
        allowCancel: json['allowCancel'] as bool? ?? true,
        cancellationPolicy: json['cancellationPolicy'] == null ? SceneIntegerCancellationPolicy.leaveUnchanged : sceneIntegerEnum(SceneIntegerCancellationPolicy.values, json['cancellationPolicy']),
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }
  final String factId;
  final SceneInteractionPrompt prompt;
  final int digits, minimum, maximum;
  final int? initialValue;
  final bool allowCancel;
  final SceneIntegerCancellationPolicy cancellationPolicy;
  @override
  SceneInteractiveCommandKind get kind =>
      SceneInteractiveCommandKind.inputIntegerToFact;
  @override
  List<String> get outputPortIds => const ['completed', 'cancelled'];
  @override
  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'factId': factId,
    'prompt': prompt.toJson(),
    'digits': digits,
    'minimum': minimum,
    'maximum': maximum,
    if (initialValue != null) 'initialValue': initialValue,
    'allowCancel': allowCancel,
    'cancellationPolicy': cancellationPolicy.name,
  };
  @override
  bool operator ==(Object other) =>
      other is SceneInputIntegerToFactInteractiveCommand &&
      other.factId == factId &&
      other.prompt == prompt &&
      other.digits == digits &&
      other.minimum == minimum &&
      other.maximum == maximum &&
      other.initialValue == initialValue &&
      other.allowCancel == allowCancel && other.cancellationPolicy == cancellationPolicy;
  @override
  int get hashCode => Object.hash(
    factId,
    prompt,
    digits,
    minimum,
    maximum,
    initialValue,
    allowCancel, cancellationPolicy,
  );
}

@immutable
final class SceneTryPayMoneyInteractiveCommand extends SceneInteractiveCommand {
  SceneTryPayMoneyInteractiveCommand({
    required this.amount,
    this.confirmationPrompt,
  }) {
    if (amount.kind == SceneIntegerOperandKind.random ||
        amount.kind == SceneIntegerOperandKind.literal && amount.value! <= 0) {
      throw ArgumentError('Payment requires a positive deterministic amount.');
    }
  }
  factory SceneTryPayMoneyInteractiveCommand.fromJson(
    Map<String, dynamic> json,
  ) {
    if (json['kind'] != 'tryPayMoney')
      throw const FormatException('Invalid payment kind.');
    sceneIntegerFields(json, {'kind', 'amount', 'confirmationPrompt'});
    try {
      return SceneTryPayMoneyInteractiveCommand(
        amount: SceneIntegerOperand.fromJson(_requiredObject(json, 'amount')),
        confirmationPrompt: json['confirmationPrompt'] == null
            ? null
            : SceneInteractionPrompt.fromJson(
                _requiredObject(json, 'confirmationPrompt'),
              ),
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }
  final SceneIntegerOperand amount;
  final SceneInteractionPrompt? confirmationPrompt;
  @override
  SceneInteractiveCommandKind get kind =>
      SceneInteractiveCommandKind.tryPayMoney;
  @override
  List<String> get outputPortIds => const [
    'completed',
    'insufficientFunds',
    'cancelled',
  ];
  @override
  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'amount': amount.toJson(),
    if (confirmationPrompt != null)
      'confirmationPrompt': confirmationPrompt!.toJson(),
  };
  @override
  bool operator ==(Object other) =>
      other is SceneTryPayMoneyInteractiveCommand &&
      other.amount == amount &&
      other.confirmationPrompt == confirmationPrompt;
  @override
  int get hashCode => Object.hash(amount, confirmationPrompt);
}
