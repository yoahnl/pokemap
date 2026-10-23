part of 'scene_structured_interaction.dart';

@immutable
final class SceneIntegerInteractionRequest extends SceneInteractionRequest {
  SceneIntegerInteractionRequest({
    required super.requestId,
    required super.revision,
    required super.prompt,
    required this.digits,
    required this.minimum,
    required this.maximum,
    required this.initialValue,
    this.allowCancel = true,
    super.timeout,
  }) {
    validateSceneIntegerInput(
      digits: digits,
      minimum: minimum,
      maximum: maximum,
      initialValue: initialValue,
    );
  }
  factory SceneIntegerInteractionRequest.fromJson(Map<String, dynamic> json) {
    sceneIntegerFields(json, {
      'kind',
      'requestId',
      'revision',
      'prompt',
      'timeoutMs',
      'digits',
      'minimum',
      'maximum',
      'initialValue',
      'allowCancel',
    });
    try {
      return SceneIntegerInteractionRequest(
        requestId: _readRequiredString(json, 'requestId'),
        revision: _readRequiredNonNegativeInt(json, 'revision'),
        prompt: SceneInteractionPrompt.fromJson(
          _readRequiredObject(json, 'prompt'),
        ),
        digits: sceneIntegerInt(json, 'digits'),
        minimum: sceneIntegerInt(json, 'minimum'),
        maximum: sceneIntegerInt(json, 'maximum'),
        initialValue: sceneIntegerInt(json, 'initialValue'),
        allowCancel: _readOptionalBool(json, 'allowCancel') ?? true,
        timeout: _readTimeout(json),
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }
  final int digits, minimum, maximum, initialValue;
  final bool allowCancel;
  @override
  SceneInteractionRequestKind get kind => SceneInteractionRequestKind.integer;
  @override
  List<SceneInteractionValidationIssue> validateResult(
    SceneInteractionResult result,
  ) {
    final issues = super.validateResult(result);
    if (issues.isNotEmpty) return issues;
    if (!allowCancel &&
        result is SceneCancelledInteractionResult &&
        result.reason == SceneInteractionCancellationReason.user) {
      return [
        SceneInteractionValidationIssue(
          code: SceneInteractionValidationIssueCode.cancellationForbidden,
        ),
      ];
    }
    return issues;
  }

  @override
  List<SceneInteractionValidationIssue> validateSubmittedResult(
    SceneInteractionResult result,
  ) {
    if (result is! SceneIntegerSubmittedInteractionResult)
      return _expectResultKind(
        result,
        SceneInteractionResultKind.integerSubmitted,
      );
    if (result.value < minimum || result.value > maximum)
      return [
        SceneInteractionValidationIssue(
          code: SceneInteractionValidationIssueCode.integerOutOfRange,
          arguments: {'minimum': '$minimum', 'maximum': '$maximum'},
        ),
      ];
    return const [];
  }

  @override
  Map<String, dynamic> toJson() => {
    ...baseJson(),
    'digits': digits,
    'minimum': minimum,
    'maximum': maximum,
    'initialValue': initialValue,
    'allowCancel': allowCancel,
  };
  @override
  bool operator ==(Object other) =>
      other is SceneIntegerInteractionRequest &&
      baseEquals(other) &&
      other.digits == digits &&
      other.minimum == minimum &&
      other.maximum == maximum &&
      other.initialValue == initialValue &&
      other.allowCancel == allowCancel;
  @override
  int get hashCode => Object.hash(
    baseHashCode,
    digits,
    minimum,
    maximum,
    initialValue,
    allowCancel,
  );
}

@immutable
final class SceneIntegerSubmittedInteractionResult
    extends SceneInteractionResult {
  SceneIntegerSubmittedInteractionResult({
    required super.requestId,
    required super.revision,
    required this.value,
  });
  final int value;
  @override
  SceneInteractionResultKind get kind =>
      SceneInteractionResultKind.integerSubmitted;
  @override
  Map<String, dynamic> toJson() => {...baseJson(), 'value': value};
  @override
  bool operator ==(Object other) =>
      other is SceneIntegerSubmittedInteractionResult &&
      baseEquals(other) &&
      other.value == value;
  @override
  int get hashCode => Object.hash(baseHashCode, value);
}

void validateSceneIntegerInput({
  required int digits,
  required int minimum,
  required int maximum,
  int? initialValue,
}) {
  sceneIntegerBounds(minimum, maximum);
  if (digits < 1 || digits > 9)
    throw ArgumentError('Numeric input requires 1 to 9 digits.');
  final limit = int.parse(List.filled(digits, '9').join());
  if (minimum < -limit ||
      maximum > limit ||
      initialValue != null &&
          (initialValue < minimum || initialValue > maximum)) {
    throw ArgumentError(
      'Numeric input bounds and initial value must fit its digits and range.',
    );
  }
}
