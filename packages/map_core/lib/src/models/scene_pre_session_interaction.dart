import 'package:meta/meta.dart' show immutable;

import 'scene_structured_interaction.dart';

enum ScenePreSessionDraftField {
  playerName,
  avatarCharacterId,
  starterOptionId,
}

@immutable
final class ScenePreSessionResultBinding {
  const ScenePreSessionResultBinding({required this.field});

  factory ScenePreSessionResultBinding.fromJson(Map<String, dynamic> json) {
    return ScenePreSessionResultBinding(
      field: _readEnum(
        ScenePreSessionDraftField.values,
        json['field'],
        'resultBinding.field',
      ),
    );
  }

  final ScenePreSessionDraftField field;

  Map<String, dynamic> toJson() => <String, dynamic>{'field': field.name};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScenePreSessionResultBinding && other.field == field;

  @override
  int get hashCode => field.hashCode;
}

@immutable
final class ScenePreSessionInteractionSpec {
  ScenePreSessionInteractionSpec._({
    required this.kind,
    required this.prompt,
    List<SceneInteractionOption> options = const <SceneInteractionOption>[],
    this.textConstraints,
    this.selectionConstraints,
    this.resultBinding,
  }) : options = List<SceneInteractionOption>.unmodifiable(options) {
    _validate();
  }

  factory ScenePreSessionInteractionSpec.message({
    required SceneInteractionPrompt prompt,
  }) {
    return ScenePreSessionInteractionSpec._(
      kind: SceneInteractionRequestKind.message,
      prompt: prompt,
    );
  }

  factory ScenePreSessionInteractionSpec.choice({
    required SceneInteractionPrompt prompt,
    required List<SceneInteractionOption> options,
    ScenePreSessionResultBinding? resultBinding,
  }) {
    return ScenePreSessionInteractionSpec._(
      kind: SceneInteractionRequestKind.choice,
      prompt: prompt,
      options: options,
      resultBinding: resultBinding,
    );
  }

  factory ScenePreSessionInteractionSpec.text({
    required SceneInteractionPrompt prompt,
    SceneTextInputConstraints? constraints,
    ScenePreSessionResultBinding? resultBinding,
  }) {
    return ScenePreSessionInteractionSpec._(
      kind: SceneInteractionRequestKind.text,
      prompt: prompt,
      textConstraints: constraints,
      resultBinding: resultBinding,
    );
  }

  factory ScenePreSessionInteractionSpec.confirmation({
    required SceneInteractionPrompt prompt,
    ScenePreSessionResultBinding? resultBinding,
  }) {
    return ScenePreSessionInteractionSpec._(
      kind: SceneInteractionRequestKind.confirmation,
      prompt: prompt,
      resultBinding: resultBinding,
    );
  }

  factory ScenePreSessionInteractionSpec.selection({
    required SceneInteractionPrompt prompt,
    required List<SceneInteractionOption> options,
    SceneSelectionConstraints? constraints,
    ScenePreSessionResultBinding? resultBinding,
  }) {
    return ScenePreSessionInteractionSpec._(
      kind: SceneInteractionRequestKind.selection,
      prompt: prompt,
      options: options,
      selectionConstraints: constraints,
      resultBinding: resultBinding,
    );
  }

  factory ScenePreSessionInteractionSpec.fromJson(Map<String, dynamic> json) {
    final kind = _readEnum(
      SceneInteractionRequestKind.values,
      json['kind'],
      'kind',
    );
    final prompt = SceneInteractionPrompt.fromJson(_readObject(json, 'prompt'));
    final options = _readObjectList(
      json,
      'options',
    ).map(SceneInteractionOption.fromJson).toList(growable: false);
    final textConstraints = _readOptionalObject(
      json,
      'textConstraints',
      SceneTextInputConstraints.fromJson,
    );
    final selectionConstraints = _readOptionalObject(
      json,
      'selectionConstraints',
      SceneSelectionConstraints.fromJson,
    );
    final resultBinding = _readOptionalObject(
      json,
      'resultBinding',
      ScenePreSessionResultBinding.fromJson,
    );
    return ScenePreSessionInteractionSpec._(
      kind: kind,
      prompt: prompt,
      options: options,
      textConstraints: textConstraints,
      selectionConstraints: selectionConstraints,
      resultBinding: resultBinding,
    );
  }

  final SceneInteractionRequestKind kind;
  final SceneInteractionPrompt prompt;
  final List<SceneInteractionOption> options;
  final SceneTextInputConstraints? textConstraints;
  final SceneSelectionConstraints? selectionConstraints;
  final ScenePreSessionResultBinding? resultBinding;

  SceneInteractionRequest buildRequest({
    required String requestId,
    required int revision,
  }) => switch (kind) {
    SceneInteractionRequestKind.message => SceneInteractionRequest.message(
      requestId: requestId,
      revision: revision,
      prompt: prompt,
    ),
    SceneInteractionRequestKind.choice => SceneInteractionRequest.choice(
      requestId: requestId,
      revision: revision,
      prompt: prompt,
      options: options,
    ),
    SceneInteractionRequestKind.text => SceneInteractionRequest.text(
      requestId: requestId,
      revision: revision,
      prompt: prompt,
      constraints: textConstraints,
    ),
    SceneInteractionRequestKind.confirmation =>
      SceneInteractionRequest.confirmation(
        requestId: requestId,
        revision: revision,
        prompt: prompt,
      ),
    SceneInteractionRequestKind.selection => SceneInteractionRequest.selection(
      requestId: requestId,
      revision: revision,
      prompt: prompt,
      options: options,
      constraints: selectionConstraints,
    ),
  };

  List<String> get outputPortIds => switch (kind) {
    SceneInteractionRequestKind.choice => List<String>.unmodifiable(
      options.map((option) => option.id),
    ),
    SceneInteractionRequestKind.confirmation => const <String>[
      'confirmed',
      'declined',
    ],
    SceneInteractionRequestKind.message ||
    SceneInteractionRequestKind.text ||
    SceneInteractionRequestKind.selection => const <String>['completed'],
  };

  Map<String, dynamic> toJson() => <String, dynamic>{
    'kind': kind.name,
    'prompt': prompt.toJson(),
    if (options.isNotEmpty)
      'options': options.map((option) => option.toJson()).toList(),
    if (textConstraints != null) 'textConstraints': textConstraints!.toJson(),
    if (selectionConstraints != null)
      'selectionConstraints': selectionConstraints!.toJson(),
    if (resultBinding != null) 'resultBinding': resultBinding!.toJson(),
  };

  void _validate() {
    final expectsOptions =
        kind == SceneInteractionRequestKind.choice ||
        kind == SceneInteractionRequestKind.selection;
    if (expectsOptions && options.isEmpty) {
      throw ArgumentError.value(options, 'options', 'must not be empty');
    }
    if (!expectsOptions && options.isNotEmpty) {
      throw ArgumentError.value(options, 'options', 'are not supported');
    }
    final optionIds = <String>{};
    for (final option in options) {
      if (!optionIds.add(option.id)) {
        throw ArgumentError.value(option.id, 'options', 'must be unique');
      }
    }
    if (kind != SceneInteractionRequestKind.text && textConstraints != null) {
      throw ArgumentError.value(
        textConstraints,
        'textConstraints',
        'are supported only for text requests',
      );
    }
    if (kind != SceneInteractionRequestKind.selection &&
        selectionConstraints != null) {
      throw ArgumentError.value(
        selectionConstraints,
        'selectionConstraints',
        'are supported only for selection requests',
      );
    }
    final binding = resultBinding;
    if (binding == null) return;
    switch (binding.field) {
      case ScenePreSessionDraftField.playerName:
        if (kind != SceneInteractionRequestKind.text) {
          throw ArgumentError.value(
            binding.field,
            'resultBinding',
            'playerName requires a text request',
          );
        }
      case ScenePreSessionDraftField.avatarCharacterId:
      case ScenePreSessionDraftField.starterOptionId:
        if (kind != SceneInteractionRequestKind.choice &&
            kind != SceneInteractionRequestKind.selection) {
          throw ArgumentError.value(
            binding.field,
            'resultBinding',
            'identity selection requires a choice or selection request',
          );
        }
        if (kind == SceneInteractionRequestKind.selection &&
            (selectionConstraints?.maxSelections ?? 1) != 1) {
          throw ArgumentError.value(
            selectionConstraints?.maxSelections,
            'selectionConstraints.maxSelections',
            'must be 1 for a scalar draft binding',
          );
        }
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScenePreSessionInteractionSpec &&
          other.kind == kind &&
          other.prompt == prompt &&
          _listEquals(other.options, options) &&
          other.textConstraints == textConstraints &&
          other.selectionConstraints == selectionConstraints &&
          other.resultBinding == resultBinding;

  @override
  int get hashCode => Object.hash(
    kind,
    prompt,
    Object.hashAll(options),
    textConstraints,
    selectionConstraints,
    resultBinding,
  );
}

T _readEnum<T extends Enum>(List<T> values, Object? value, String path) {
  if (value is! String) {
    throw FormatException('$path must be a string.');
  }
  for (final candidate in values) {
    if (candidate.name == value) return candidate;
  }
  throw FormatException('$path contains an unknown value: $value.');
}

Map<String, dynamic> _readObject(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! Map) throw FormatException('$key must be an object.');
  return Map<String, dynamic>.from(value);
}

List<Map<String, dynamic>> _readObjectList(
  Map<String, dynamic> json,
  String key,
) {
  final value = json[key];
  if (value == null) return const <Map<String, dynamic>>[];
  if (value is! List) throw FormatException('$key must be a list.');
  return <Map<String, dynamic>>[
    for (final item in value)
      if (item is Map)
        Map<String, dynamic>.from(item)
      else
        throw FormatException('$key entries must be objects.'),
  ];
}

T? _readOptionalObject<T>(
  Map<String, dynamic> json,
  String key,
  T Function(Map<String, dynamic>) decode,
) {
  final value = json[key];
  if (value == null) return null;
  if (value is! Map) throw FormatException('$key must be an object.');
  return decode(Map<String, dynamic>.from(value));
}

bool _listEquals<T>(List<T> left, List<T> right) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
