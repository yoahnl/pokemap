import 'package:characters/characters.dart';
import 'package:meta/meta.dart' show immutable;

enum SceneInteractionRequestKind {
  message,
  choice,
  text,
  confirmation,
  selection,
}

enum SceneInteractionResultKind {
  acknowledged,
  choiceSelected,
  textSubmitted,
  confirmed,
  selectionSubmitted,
  cancelled,
}

enum SceneInteractionCancellationReason { user, timeout, superseded, disposed }

enum SceneInteractionValidationIssueCode {
  requestMismatch,
  resultKindMismatch,
  textTooShort,
  textTooLong,
  optionUnknown,
  optionDisabled,
  duplicateSelection,
  tooFewSelections,
  tooManySelections,
}

@immutable
final class SceneInteractionPrompt {
  SceneInteractionPrompt({
    required String localizationKey,
    String? fallbackText,
    Map<String, String> arguments = const <String, String>{},
  }) : localizationKey = _requiredString(localizationKey, 'localizationKey'),
       fallbackText = _optionalString(fallbackText, 'fallbackText'),
       arguments = Map<String, String>.unmodifiable(arguments);

  factory SceneInteractionPrompt.fromJson(Map<String, dynamic> json) {
    return SceneInteractionPrompt(
      localizationKey: _readRequiredString(json, 'localizationKey'),
      fallbackText: _readOptionalString(json, 'fallbackText'),
      arguments: _readStringMap(json, 'arguments'),
    );
  }

  final String localizationKey;
  final String? fallbackText;
  final Map<String, String> arguments;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'localizationKey': localizationKey,
    if (fallbackText != null) 'fallbackText': fallbackText,
    if (arguments.isNotEmpty) 'arguments': arguments,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneInteractionPrompt &&
          other.localizationKey == localizationKey &&
          other.fallbackText == fallbackText &&
          _mapEquals(other.arguments, arguments);

  @override
  int get hashCode =>
      Object.hash(localizationKey, fallbackText, _mapHash(arguments));
}

@immutable
final class SceneInteractionOption {
  SceneInteractionOption({
    required String id,
    required this.label,
    this.enabled = true,
  }) : id = _requiredString(id, 'id');

  factory SceneInteractionOption.fromJson(Map<String, dynamic> json) {
    return SceneInteractionOption(
      id: _readRequiredString(json, 'id'),
      label: SceneInteractionPrompt.fromJson(
        _readRequiredObject(json, 'label'),
      ),
      enabled: _readOptionalBool(json, 'enabled') ?? true,
    );
  }

  final String id;
  final SceneInteractionPrompt label;
  final bool enabled;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'label': label.toJson(),
    if (!enabled) 'enabled': false,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneInteractionOption &&
          other.id == id &&
          other.label == label &&
          other.enabled == enabled;

  @override
  int get hashCode => Object.hash(id, label, enabled);
}

@immutable
final class SceneTextInputConstraints {
  SceneTextInputConstraints({this.minGraphemes = 0, this.maxGraphemes}) {
    if (minGraphemes < 0) {
      throw ArgumentError.value(minGraphemes, 'minGraphemes');
    }
    if (maxGraphemes != null && maxGraphemes! < minGraphemes) {
      throw ArgumentError.value(maxGraphemes, 'maxGraphemes');
    }
  }

  factory SceneTextInputConstraints.fromJson(Map<String, dynamic> json) {
    return SceneTextInputConstraints(
      minGraphemes: _readOptionalNonNegativeInt(json, 'minGraphemes') ?? 0,
      maxGraphemes: _readOptionalNonNegativeInt(json, 'maxGraphemes'),
    );
  }

  final int minGraphemes;
  final int? maxGraphemes;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'minGraphemes': minGraphemes,
    if (maxGraphemes != null) 'maxGraphemes': maxGraphemes,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneTextInputConstraints &&
          other.minGraphemes == minGraphemes &&
          other.maxGraphemes == maxGraphemes;

  @override
  int get hashCode => Object.hash(minGraphemes, maxGraphemes);
}

@immutable
final class SceneSelectionConstraints {
  SceneSelectionConstraints({this.minSelections = 1, this.maxSelections = 1}) {
    if (minSelections < 0) {
      throw ArgumentError.value(minSelections, 'minSelections');
    }
    if (maxSelections < minSelections) {
      throw ArgumentError.value(maxSelections, 'maxSelections');
    }
  }

  factory SceneSelectionConstraints.fromJson(Map<String, dynamic> json) {
    return SceneSelectionConstraints(
      minSelections: _readOptionalNonNegativeInt(json, 'minSelections') ?? 1,
      maxSelections: _readOptionalNonNegativeInt(json, 'maxSelections') ?? 1,
    );
  }

  final int minSelections;
  final int maxSelections;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'minSelections': minSelections,
    'maxSelections': maxSelections,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneSelectionConstraints &&
          other.minSelections == minSelections &&
          other.maxSelections == maxSelections;

  @override
  int get hashCode => Object.hash(minSelections, maxSelections);
}

@immutable
final class SceneInteractionValidationIssue {
  SceneInteractionValidationIssue({
    required this.code,
    Map<String, String> arguments = const <String, String>{},
  }) : arguments = Map<String, String>.unmodifiable(arguments);

  factory SceneInteractionValidationIssue.fromJson(Map<String, dynamic> json) {
    return SceneInteractionValidationIssue(
      code: _readEnum(
        SceneInteractionValidationIssueCode.values,
        json['code'],
        'code',
      ),
      arguments: _readStringMap(json, 'arguments'),
    );
  }

  final SceneInteractionValidationIssueCode code;
  final Map<String, String> arguments;

  String get localizationKey => 'scene.interaction.validation.${code.name}';

  Map<String, dynamic> toJson() => <String, dynamic>{
    'code': code.name,
    'localizationKey': localizationKey,
    if (arguments.isNotEmpty) 'arguments': arguments,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneInteractionValidationIssue &&
          other.code == code &&
          _mapEquals(other.arguments, arguments);

  @override
  int get hashCode => Object.hash(code, _mapHash(arguments));
}

@immutable
abstract base class SceneInteractionRequest {
  SceneInteractionRequest({
    required String requestId,
    required this.revision,
    required this.prompt,
    this.timeout,
  }) : requestId = _requiredString(requestId, 'requestId') {
    if (revision < 0) {
      throw ArgumentError.value(revision, 'revision');
    }
    if (timeout != null &&
        (timeout!.inMilliseconds < 1 ||
            timeout != Duration(milliseconds: timeout!.inMilliseconds))) {
      throw ArgumentError.value(
        timeout,
        'timeout',
        'must use positive whole milliseconds',
      );
    }
  }

  factory SceneInteractionRequest.message({
    required String requestId,
    required int revision,
    required SceneInteractionPrompt prompt,
    String? speakerName,
    Duration? timeout,
  }) = SceneMessageInteractionRequest;

  factory SceneInteractionRequest.choice({
    required String requestId,
    required int revision,
    required SceneInteractionPrompt prompt,
    required List<SceneInteractionOption> options,
    Duration? timeout,
  }) = SceneChoiceInteractionRequest;

  factory SceneInteractionRequest.text({
    required String requestId,
    required int revision,
    required SceneInteractionPrompt prompt,
    SceneTextInputConstraints? constraints,
    Duration? timeout,
  }) = SceneTextInteractionRequest;

  factory SceneInteractionRequest.confirmation({
    required String requestId,
    required int revision,
    required SceneInteractionPrompt prompt,
    Duration? timeout,
  }) = SceneConfirmationInteractionRequest;

  factory SceneInteractionRequest.selection({
    required String requestId,
    required int revision,
    required SceneInteractionPrompt prompt,
    required List<SceneInteractionOption> options,
    SceneSelectionConstraints? constraints,
    Duration? timeout,
  }) = SceneSelectionInteractionRequest;

  factory SceneInteractionRequest.fromJson(Map<String, dynamic> json) {
    final kind = _readEnum(
      SceneInteractionRequestKind.values,
      json['kind'],
      'kind',
    );
    final requestId = _readRequiredString(json, 'requestId');
    final revision = _readRequiredNonNegativeInt(json, 'revision');
    final prompt = SceneInteractionPrompt.fromJson(
      _readRequiredObject(json, 'prompt'),
    );
    final timeout = _readTimeout(json);
    return switch (kind) {
      SceneInteractionRequestKind.message => SceneInteractionRequest.message(
        requestId: requestId,
        revision: revision,
        prompt: prompt,
        speakerName: _readOptionalString(json, 'speakerName'),
        timeout: timeout,
      ),
      SceneInteractionRequestKind.choice => SceneInteractionRequest.choice(
        requestId: requestId,
        revision: revision,
        prompt: prompt,
        options: _readObjectList(
          json,
          'options',
          SceneInteractionOption.fromJson,
        ),
        timeout: timeout,
      ),
      SceneInteractionRequestKind.text => SceneInteractionRequest.text(
        requestId: requestId,
        revision: revision,
        prompt: prompt,
        constraints: json['constraints'] == null
            ? SceneTextInputConstraints()
            : SceneTextInputConstraints.fromJson(
                _readRequiredObject(json, 'constraints'),
              ),
        timeout: timeout,
      ),
      SceneInteractionRequestKind.confirmation =>
        SceneInteractionRequest.confirmation(
          requestId: requestId,
          revision: revision,
          prompt: prompt,
          timeout: timeout,
        ),
      SceneInteractionRequestKind.selection =>
        SceneInteractionRequest.selection(
          requestId: requestId,
          revision: revision,
          prompt: prompt,
          options: _readObjectList(
            json,
            'options',
            SceneInteractionOption.fromJson,
          ),
          constraints: json['constraints'] == null
              ? SceneSelectionConstraints()
              : SceneSelectionConstraints.fromJson(
                  _readRequiredObject(json, 'constraints'),
                ),
          timeout: timeout,
        ),
    };
  }

  final String requestId;
  final int revision;
  final SceneInteractionPrompt prompt;
  final Duration? timeout;

  SceneInteractionRequestKind get kind;

  List<SceneInteractionValidationIssue> validateResult(
    SceneInteractionResult result,
  ) {
    if (result.requestId != requestId || result.revision != revision) {
      return [
        SceneInteractionValidationIssue(
          code: SceneInteractionValidationIssueCode.requestMismatch,
        ),
      ];
    }
    if (result.kind == SceneInteractionResultKind.cancelled) {
      return const <SceneInteractionValidationIssue>[];
    }
    return validateSubmittedResult(result);
  }

  List<SceneInteractionValidationIssue> validateSubmittedResult(
    SceneInteractionResult result,
  );

  Map<String, dynamic> toJson();

  Map<String, dynamic> baseJson() => <String, dynamic>{
    'kind': kind.name,
    'requestId': requestId,
    'revision': revision,
    'prompt': prompt.toJson(),
    if (timeout != null) 'timeoutMs': timeout!.inMilliseconds,
  };

  bool baseEquals(SceneInteractionRequest other) =>
      other.requestId == requestId &&
      other.revision == revision &&
      other.prompt == prompt &&
      other.timeout == timeout;

  int get baseHashCode => Object.hash(requestId, revision, prompt, timeout);
}

@immutable
final class SceneMessageInteractionRequest extends SceneInteractionRequest {
  SceneMessageInteractionRequest({
    required super.requestId,
    required super.revision,
    required super.prompt,
    String? speakerName,
    super.timeout,
  }) : speakerName = _optionalString(speakerName, 'speakerName');

  /// Display name of the line's speaker, resolved by the narrative side
  /// (yarn character or "Name:" prefix) — optional, never an identifier
  /// (BETA-CIN-074).
  final String? speakerName;

  @override
  SceneInteractionRequestKind get kind => SceneInteractionRequestKind.message;

  @override
  List<SceneInteractionValidationIssue> validateSubmittedResult(
    SceneInteractionResult result,
  ) => _expectResultKind(result, SceneInteractionResultKind.acknowledged);

  @override
  Map<String, dynamic> toJson() => {
        ...baseJson(),
        if (speakerName != null) 'speakerName': speakerName,
      };

  @override
  bool operator ==(Object other) =>
      other is SceneMessageInteractionRequest &&
      baseEquals(other) &&
      other.speakerName == speakerName;

  @override
  int get hashCode => Object.hash(kind, baseHashCode);
}

@immutable
final class SceneChoiceInteractionRequest extends SceneInteractionRequest {
  SceneChoiceInteractionRequest({
    required super.requestId,
    required super.revision,
    required super.prompt,
    required List<SceneInteractionOption> options,
    super.timeout,
  }) : options = _validatedOptions(options);

  final List<SceneInteractionOption> options;

  @override
  SceneInteractionRequestKind get kind => SceneInteractionRequestKind.choice;

  @override
  List<SceneInteractionValidationIssue> validateSubmittedResult(
    SceneInteractionResult result,
  ) {
    if (result is! SceneChoiceSelectedInteractionResult) {
      return _expectResultKind(
        result,
        SceneInteractionResultKind.choiceSelected,
      );
    }
    return _validateOption(result.selectedOptionId, options);
  }

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...baseJson(),
    'options': options.map((option) => option.toJson()).toList(),
  };

  @override
  bool operator ==(Object other) =>
      other is SceneChoiceInteractionRequest &&
      baseEquals(other) &&
      _listEquals(other.options, options);

  @override
  int get hashCode => Object.hash(kind, baseHashCode, Object.hashAll(options));
}

@immutable
final class SceneTextInteractionRequest extends SceneInteractionRequest {
  SceneTextInteractionRequest({
    required super.requestId,
    required super.revision,
    required super.prompt,
    SceneTextInputConstraints? constraints,
    super.timeout,
  }) : constraints = constraints ?? SceneTextInputConstraints();

  final SceneTextInputConstraints constraints;

  @override
  SceneInteractionRequestKind get kind => SceneInteractionRequestKind.text;

  @override
  List<SceneInteractionValidationIssue> validateSubmittedResult(
    SceneInteractionResult result,
  ) {
    if (result is! SceneTextSubmittedInteractionResult) {
      return _expectResultKind(
        result,
        SceneInteractionResultKind.textSubmitted,
      );
    }
    final length = result.value.characters.length;
    if (length < constraints.minGraphemes) {
      return [
        SceneInteractionValidationIssue(
          code: SceneInteractionValidationIssueCode.textTooShort,
          arguments: {
            'minimum': '${constraints.minGraphemes}',
            'actual': '$length',
          },
        ),
      ];
    }
    final maximum = constraints.maxGraphemes;
    if (maximum != null && length > maximum) {
      return [
        SceneInteractionValidationIssue(
          code: SceneInteractionValidationIssueCode.textTooLong,
          arguments: {'maximum': '$maximum', 'actual': '$length'},
        ),
      ];
    }
    return const <SceneInteractionValidationIssue>[];
  }

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...baseJson(),
    'constraints': constraints.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      other is SceneTextInteractionRequest &&
      baseEquals(other) &&
      other.constraints == constraints;

  @override
  int get hashCode => Object.hash(kind, baseHashCode, constraints);
}

@immutable
final class SceneConfirmationInteractionRequest
    extends SceneInteractionRequest {
  SceneConfirmationInteractionRequest({
    required super.requestId,
    required super.revision,
    required super.prompt,
    super.timeout,
  });

  @override
  SceneInteractionRequestKind get kind =>
      SceneInteractionRequestKind.confirmation;

  @override
  List<SceneInteractionValidationIssue> validateSubmittedResult(
    SceneInteractionResult result,
  ) => _expectResultKind(result, SceneInteractionResultKind.confirmed);

  @override
  Map<String, dynamic> toJson() => baseJson();

  @override
  bool operator ==(Object other) =>
      other is SceneConfirmationInteractionRequest && baseEquals(other);

  @override
  int get hashCode => Object.hash(kind, baseHashCode);
}

@immutable
final class SceneSelectionInteractionRequest extends SceneInteractionRequest {
  SceneSelectionInteractionRequest({
    required super.requestId,
    required super.revision,
    required super.prompt,
    required List<SceneInteractionOption> options,
    SceneSelectionConstraints? constraints,
    super.timeout,
  }) : constraints = constraints ?? SceneSelectionConstraints(),
       options = _validatedOptions(options) {
    if (this.constraints.maxSelections > this.options.length) {
      throw ArgumentError.value(
        this.constraints.maxSelections,
        'constraints.maxSelections',
      );
    }
  }

  final List<SceneInteractionOption> options;
  final SceneSelectionConstraints constraints;

  @override
  SceneInteractionRequestKind get kind => SceneInteractionRequestKind.selection;

  @override
  List<SceneInteractionValidationIssue> validateSubmittedResult(
    SceneInteractionResult result,
  ) {
    if (result is! SceneSelectionSubmittedInteractionResult) {
      return _expectResultKind(
        result,
        SceneInteractionResultKind.selectionSubmitted,
      );
    }
    final issues = <SceneInteractionValidationIssue>[];
    final selectedIds = result.selectedOptionIds;
    if (selectedIds.toSet().length != selectedIds.length) {
      issues.add(
        SceneInteractionValidationIssue(
          code: SceneInteractionValidationIssueCode.duplicateSelection,
        ),
      );
    }
    if (selectedIds.length < constraints.minSelections) {
      issues.add(
        SceneInteractionValidationIssue(
          code: SceneInteractionValidationIssueCode.tooFewSelections,
          arguments: {
            'minimum': '${constraints.minSelections}',
            'actual': '${selectedIds.length}',
          },
        ),
      );
    }
    if (selectedIds.length > constraints.maxSelections) {
      issues.add(
        SceneInteractionValidationIssue(
          code: SceneInteractionValidationIssueCode.tooManySelections,
          arguments: {
            'maximum': '${constraints.maxSelections}',
            'actual': '${selectedIds.length}',
          },
        ),
      );
    }
    for (final optionId in selectedIds.toSet()) {
      issues.addAll(_validateOption(optionId, options));
    }
    return List<SceneInteractionValidationIssue>.unmodifiable(issues);
  }

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...baseJson(),
    'options': options.map((option) => option.toJson()).toList(),
    'constraints': constraints.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      other is SceneSelectionInteractionRequest &&
      baseEquals(other) &&
      _listEquals(other.options, options) &&
      other.constraints == constraints;

  @override
  int get hashCode =>
      Object.hash(kind, baseHashCode, Object.hashAll(options), constraints);
}

@immutable
abstract base class SceneInteractionResult {
  SceneInteractionResult({required String requestId, required this.revision})
    : requestId = _requiredString(requestId, 'requestId') {
    if (revision < 0) throw ArgumentError.value(revision, 'revision');
  }

  factory SceneInteractionResult.acknowledged({
    required String requestId,
    required int revision,
  }) = SceneAcknowledgedInteractionResult;

  factory SceneInteractionResult.choiceSelected({
    required String requestId,
    required int revision,
    required String selectedOptionId,
  }) = SceneChoiceSelectedInteractionResult;

  factory SceneInteractionResult.textSubmitted({
    required String requestId,
    required int revision,
    required String value,
  }) = SceneTextSubmittedInteractionResult;

  factory SceneInteractionResult.confirmed({
    required String requestId,
    required int revision,
    required bool value,
  }) = SceneConfirmedInteractionResult;

  factory SceneInteractionResult.selectionSubmitted({
    required String requestId,
    required int revision,
    required List<String> selectedOptionIds,
  }) = SceneSelectionSubmittedInteractionResult;

  factory SceneInteractionResult.cancelled({
    required String requestId,
    required int revision,
    required SceneInteractionCancellationReason reason,
  }) = SceneCancelledInteractionResult;

  factory SceneInteractionResult.fromJson(Map<String, dynamic> json) {
    final kind = _readEnum(
      SceneInteractionResultKind.values,
      json['kind'],
      'kind',
    );
    final requestId = _readRequiredString(json, 'requestId');
    final revision = _readRequiredNonNegativeInt(json, 'revision');
    return switch (kind) {
      SceneInteractionResultKind.acknowledged =>
        SceneInteractionResult.acknowledged(
          requestId: requestId,
          revision: revision,
        ),
      SceneInteractionResultKind.choiceSelected =>
        SceneInteractionResult.choiceSelected(
          requestId: requestId,
          revision: revision,
          selectedOptionId: _readRequiredString(json, 'selectedOptionId'),
        ),
      SceneInteractionResultKind.textSubmitted =>
        SceneInteractionResult.textSubmitted(
          requestId: requestId,
          revision: revision,
          value: _readString(json, 'value'),
        ),
      SceneInteractionResultKind.confirmed => SceneInteractionResult.confirmed(
        requestId: requestId,
        revision: revision,
        value: _readRequiredBool(json, 'value'),
      ),
      SceneInteractionResultKind.selectionSubmitted =>
        SceneInteractionResult.selectionSubmitted(
          requestId: requestId,
          revision: revision,
          selectedOptionIds: _readStringList(json, 'selectedOptionIds'),
        ),
      SceneInteractionResultKind.cancelled => SceneInteractionResult.cancelled(
        requestId: requestId,
        revision: revision,
        reason: _readEnum(
          SceneInteractionCancellationReason.values,
          json['reason'],
          'reason',
        ),
      ),
    };
  }

  final String requestId;
  final int revision;

  SceneInteractionResultKind get kind;

  Map<String, dynamic> toJson();

  Map<String, dynamic> baseJson() => <String, dynamic>{
    'kind': kind.name,
    'requestId': requestId,
    'revision': revision,
  };

  bool baseEquals(SceneInteractionResult other) =>
      other.requestId == requestId && other.revision == revision;

  int get baseHashCode => Object.hash(requestId, revision);
}

@immutable
final class SceneAcknowledgedInteractionResult extends SceneInteractionResult {
  SceneAcknowledgedInteractionResult({
    required super.requestId,
    required super.revision,
  });

  @override
  SceneInteractionResultKind get kind =>
      SceneInteractionResultKind.acknowledged;

  @override
  Map<String, dynamic> toJson() => baseJson();

  @override
  bool operator ==(Object other) =>
      other is SceneAcknowledgedInteractionResult && baseEquals(other);

  @override
  int get hashCode => Object.hash(kind, baseHashCode);
}

@immutable
final class SceneChoiceSelectedInteractionResult
    extends SceneInteractionResult {
  SceneChoiceSelectedInteractionResult({
    required super.requestId,
    required super.revision,
    required String selectedOptionId,
  }) : selectedOptionId = _requiredString(selectedOptionId, 'selectedOptionId');

  final String selectedOptionId;

  @override
  SceneInteractionResultKind get kind =>
      SceneInteractionResultKind.choiceSelected;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...baseJson(),
    'selectedOptionId': selectedOptionId,
  };

  @override
  bool operator ==(Object other) =>
      other is SceneChoiceSelectedInteractionResult &&
      baseEquals(other) &&
      other.selectedOptionId == selectedOptionId;

  @override
  int get hashCode => Object.hash(kind, baseHashCode, selectedOptionId);
}

@immutable
final class SceneTextSubmittedInteractionResult extends SceneInteractionResult {
  SceneTextSubmittedInteractionResult({
    required super.requestId,
    required super.revision,
    required this.value,
  });

  final String value;

  @override
  SceneInteractionResultKind get kind =>
      SceneInteractionResultKind.textSubmitted;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...baseJson(),
    'value': value,
  };

  @override
  bool operator ==(Object other) =>
      other is SceneTextSubmittedInteractionResult &&
      baseEquals(other) &&
      other.value == value;

  @override
  int get hashCode => Object.hash(kind, baseHashCode, value);
}

@immutable
final class SceneConfirmedInteractionResult extends SceneInteractionResult {
  SceneConfirmedInteractionResult({
    required super.requestId,
    required super.revision,
    required this.value,
  });

  final bool value;

  @override
  SceneInteractionResultKind get kind => SceneInteractionResultKind.confirmed;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...baseJson(),
    'value': value,
  };

  @override
  bool operator ==(Object other) =>
      other is SceneConfirmedInteractionResult &&
      baseEquals(other) &&
      other.value == value;

  @override
  int get hashCode => Object.hash(kind, baseHashCode, value);
}

@immutable
final class SceneSelectionSubmittedInteractionResult
    extends SceneInteractionResult {
  SceneSelectionSubmittedInteractionResult({
    required super.requestId,
    required super.revision,
    required List<String> selectedOptionIds,
  }) : selectedOptionIds = List<String>.unmodifiable(
         selectedOptionIds.map(
           (id) => _requiredString(id, 'selectedOptionIds'),
         ),
       );

  final List<String> selectedOptionIds;

  @override
  SceneInteractionResultKind get kind =>
      SceneInteractionResultKind.selectionSubmitted;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...baseJson(),
    'selectedOptionIds': selectedOptionIds,
  };

  @override
  bool operator ==(Object other) =>
      other is SceneSelectionSubmittedInteractionResult &&
      baseEquals(other) &&
      _listEquals(other.selectedOptionIds, selectedOptionIds);

  @override
  int get hashCode =>
      Object.hash(kind, baseHashCode, Object.hashAll(selectedOptionIds));
}

@immutable
final class SceneCancelledInteractionResult extends SceneInteractionResult {
  SceneCancelledInteractionResult({
    required super.requestId,
    required super.revision,
    required this.reason,
  });

  final SceneInteractionCancellationReason reason;

  @override
  SceneInteractionResultKind get kind => SceneInteractionResultKind.cancelled;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...baseJson(),
    'reason': reason.name,
  };

  @override
  bool operator ==(Object other) =>
      other is SceneCancelledInteractionResult &&
      baseEquals(other) &&
      other.reason == reason;

  @override
  int get hashCode => Object.hash(kind, baseHashCode, reason);
}

List<SceneInteractionOption> _validatedOptions(
  List<SceneInteractionOption> options,
) {
  if (options.isEmpty) throw ArgumentError.value(options, 'options');
  final ids = <String>{};
  for (final option in options) {
    if (!ids.add(option.id)) {
      throw ArgumentError.value(option.id, 'options', 'Duplicate option id.');
    }
  }
  return List<SceneInteractionOption>.unmodifiable(options);
}

List<SceneInteractionValidationIssue> _expectResultKind(
  SceneInteractionResult result,
  SceneInteractionResultKind expected,
) {
  if (result.kind == expected) {
    return const <SceneInteractionValidationIssue>[];
  }
  return [
    SceneInteractionValidationIssue(
      code: SceneInteractionValidationIssueCode.resultKindMismatch,
      arguments: {'expected': expected.name, 'actual': result.kind.name},
    ),
  ];
}

List<SceneInteractionValidationIssue> _validateOption(
  String optionId,
  List<SceneInteractionOption> options,
) {
  final matching = options.where((option) => option.id == optionId);
  if (matching.isEmpty) {
    return [
      SceneInteractionValidationIssue(
        code: SceneInteractionValidationIssueCode.optionUnknown,
        arguments: {'optionId': optionId},
      ),
    ];
  }
  if (!matching.single.enabled) {
    return [
      SceneInteractionValidationIssue(
        code: SceneInteractionValidationIssueCode.optionDisabled,
        arguments: {'optionId': optionId},
      ),
    ];
  }
  return const <SceneInteractionValidationIssue>[];
}

Duration? _readTimeout(Map<String, dynamic> json) {
  final milliseconds = _readOptionalNonNegativeInt(json, 'timeoutMs');
  if (milliseconds == null) return null;
  if (milliseconds == 0) {
    throw const FormatException('timeoutMs must be greater than zero.');
  }
  return Duration(milliseconds: milliseconds);
}

String _requiredString(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty) throw ArgumentError.value(value, field);
  return normalized;
}

String? _optionalString(String? value, String field) {
  if (value == null) return null;
  return _requiredString(value, field);
}

String _readString(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is! String) throw FormatException('$field must be a string.');
  return value;
}

String _readRequiredString(Map<String, dynamic> json, String field) =>
    _requiredString(_readString(json, field), field);

String? _readOptionalString(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value == null) return null;
  if (value is! String) throw FormatException('$field must be a string.');
  return _optionalString(value, field);
}

bool _readRequiredBool(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is! bool) throw FormatException('$field must be a boolean.');
  return value;
}

bool? _readOptionalBool(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value == null) return null;
  if (value is! bool) throw FormatException('$field must be a boolean.');
  return value;
}

int _readRequiredNonNegativeInt(Map<String, dynamic> json, String field) {
  final value = _readOptionalNonNegativeInt(json, field);
  if (value == null) throw FormatException('$field must be an integer.');
  return value;
}

int? _readOptionalNonNegativeInt(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value == null) return null;
  if (value is! int || value < 0) {
    throw FormatException('$field must be a non-negative integer.');
  }
  return value;
}

Map<String, dynamic> _readRequiredObject(
  Map<String, dynamic> json,
  String field,
) {
  final value = json[field];
  if (value is! Map) throw FormatException('$field must be an object.');
  return Map<String, dynamic>.from(value);
}

Map<String, String> _readStringMap(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value == null) return const <String, String>{};
  if (value is! Map) throw FormatException('$field must be an object.');
  return value.map((key, value) {
    if (key is! String || value is! String) {
      throw FormatException('$field values must be strings.');
    }
    return MapEntry(key, value);
  });
}

List<T> _readObjectList<T>(
  Map<String, dynamic> json,
  String field,
  T Function(Map<String, dynamic>) decode,
) {
  final value = json[field];
  if (value is! List) throw FormatException('$field must be a list.');
  return value
      .map((entry) {
        if (entry is! Map) {
          throw FormatException('$field entries must be objects.');
        }
        return decode(Map<String, dynamic>.from(entry));
      })
      .toList(growable: false);
}

List<String> _readStringList(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is! List || value.any((entry) => entry is! String)) {
    throw FormatException('$field must be a string list.');
  }
  return value.cast<String>().toList(growable: false);
}

T _readEnum<T extends Enum>(List<T> values, Object? raw, String field) {
  if (raw is! String) throw FormatException('$field must be a string.');
  for (final value in values) {
    if (value.name == raw) return value;
  }
  throw FormatException('Unknown $field: $raw.');
}

bool _listEquals<T>(List<T> left, List<T> right) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

bool _mapEquals<K, V>(Map<K, V> left, Map<K, V> right) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;
  for (final entry in left.entries) {
    if (!right.containsKey(entry.key) || right[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}

int _mapHash<K, V>(Map<K, V> value) => Object.hashAllUnordered(
  value.entries.map((entry) => Object.hash(entry.key, entry.value)),
);
