import 'dart:convert';
import 'dart:typed_data';

import '../operations/narrative_event_canonical_json.dart';

/// Data-only dialogue document consumed by packaged games.
final class RuntimeDialogueDocument {
  RuntimeDialogueDocument({
    this.version = 1,
    required List<RuntimeDialogueNode> nodes,
  }) : nodes = List.unmodifiable(nodes) {
    if (version != 1) {
      throw const FormatException('Unsupported runtime dialogue format.');
    }
    if (this.nodes.isEmpty) {
      throw const FormatException(
        'Runtime dialogue requires at least one node.',
      );
    }
    final titles = <String>{};
    for (final node in this.nodes) {
      if (!titles.add(node.title)) {
        throw FormatException(
          'Duplicate runtime dialogue node "${node.title}".',
        );
      }
    }
    for (final node in this.nodes) {
      _validateSteps(node.steps, titles);
    }
  }

  final int version;
  final List<RuntimeDialogueNode> nodes;

  Map<String, Object?> toJson() => <String, Object?>{
    'format': version,
    'nodes': nodes.map((node) => node.toJson()).toList(growable: false),
  };

  static void _validateSteps(
    List<RuntimeDialogueStep> steps,
    Set<String> nodeTitles,
  ) {
    for (final step in steps) {
      switch (step) {
        case RuntimeDialogueLine():
          break;
        case RuntimeDialogueJump():
          if (!nodeTitles.contains(step.targetNode)) {
            throw FormatException(
              'Unknown runtime dialogue jump target "${step.targetNode}".',
            );
          }
        case RuntimeDialogueChoiceBlock():
          for (final choice in step.choices) {
            _validateSteps(choice.steps, nodeTitles);
          }
      }
    }
  }

  @override
  bool operator ==(Object other) =>
      other is RuntimeDialogueDocument &&
      version == other.version &&
      _listEquals(nodes, other.nodes);

  @override
  int get hashCode => Object.hash(version, Object.hashAll(nodes));
}

final class RuntimeDialogueNode {
  RuntimeDialogueNode({
    required String title,
    required List<RuntimeDialogueStep> steps,
  }) : title = title.trim(),
       steps = List.unmodifiable(steps) {
    if (this.title.isEmpty) {
      throw const FormatException('Runtime dialogue node title is required.');
    }
    if (this.steps.isEmpty) {
      throw FormatException(
        'Runtime dialogue node "${this.title}" has no content.',
      );
    }
  }

  final String title;
  final List<RuntimeDialogueStep> steps;

  Map<String, Object?> toJson() => <String, Object?>{
    'title': title,
    'steps': steps.map((step) => step.toJson()).toList(growable: false),
  };

  @override
  bool operator ==(Object other) =>
      other is RuntimeDialogueNode &&
      title == other.title &&
      _listEquals(steps, other.steps);

  @override
  int get hashCode => Object.hash(title, Object.hashAll(steps));
}

sealed class RuntimeDialogueStep {
  const RuntimeDialogueStep();

  Map<String, Object?> toJson();
}

final class RuntimeDialogueLine extends RuntimeDialogueStep {
  RuntimeDialogueLine(
    String text, {
    String? characterId,
    String? portraitStateId,
  }) : text = text.trim(),
       characterId = characterId?.trim(),
       portraitStateId = portraitStateId?.trim() {
    if (this.text.isEmpty) {
      throw const FormatException('Runtime dialogue line cannot be empty.');
    }
    if (this.characterId?.isEmpty ?? false) {
      throw const FormatException(
        'Runtime dialogue character ID cannot be empty.',
      );
    }
    if (this.portraitStateId?.isEmpty ?? false) {
      throw const FormatException(
        'Runtime dialogue portrait state ID cannot be empty.',
      );
    }
    if (this.characterId == null && this.portraitStateId != null) {
      throw const FormatException(
        'Runtime dialogue portrait state requires a character ID.',
      );
    }
  }

  final String text;
  final String? characterId;
  final String? portraitStateId;

  @override
  Map<String, Object?> toJson() => <String, Object?>{
    'kind': 'line',
    'text': text,
    if (characterId != null) 'characterId': characterId,
    if (portraitStateId != null) 'portraitStateId': portraitStateId,
  };

  @override
  bool operator ==(Object other) =>
      other is RuntimeDialogueLine &&
      text == other.text &&
      characterId == other.characterId &&
      portraitStateId == other.portraitStateId;

  @override
  int get hashCode =>
      Object.hash(runtimeType, text, characterId, portraitStateId);
}

final class RuntimeDialogueJump extends RuntimeDialogueStep {
  RuntimeDialogueJump(String targetNode) : targetNode = targetNode.trim() {
    if (this.targetNode.isEmpty) {
      throw const FormatException('Runtime dialogue jump target is required.');
    }
  }

  final String targetNode;

  @override
  Map<String, Object?> toJson() => <String, Object?>{
    'kind': 'jump',
    'targetNode': targetNode,
  };

  @override
  bool operator ==(Object other) =>
      other is RuntimeDialogueJump && targetNode == other.targetNode;

  @override
  int get hashCode => Object.hash(runtimeType, targetNode);
}

final class RuntimeDialogueChoiceBlock extends RuntimeDialogueStep {
  RuntimeDialogueChoiceBlock(List<RuntimeDialogueChoice> choices)
    : choices = List.unmodifiable(choices) {
    if (this.choices.isEmpty) {
      throw const FormatException(
        'Runtime dialogue choice block cannot be empty.',
      );
    }
  }

  final List<RuntimeDialogueChoice> choices;

  @override
  Map<String, Object?> toJson() => <String, Object?>{
    'kind': 'choices',
    'choices': choices.map((choice) => choice.toJson()).toList(growable: false),
  };

  @override
  bool operator ==(Object other) =>
      other is RuntimeDialogueChoiceBlock &&
      _listEquals(choices, other.choices);

  @override
  int get hashCode => Object.hash(runtimeType, Object.hashAll(choices));
}

final class RuntimeDialogueChoice {
  RuntimeDialogueChoice({
    required String text,
    required List<RuntimeDialogueStep> steps,
    String? outcomeId,
  }) : text = text.trim(),
       steps = List.unmodifiable(steps),
       outcomeId = outcomeId?.trim() {
    if (this.text.isEmpty) {
      throw const FormatException('Runtime dialogue choice text is required.');
    }
    if (this.outcomeId?.isEmpty ?? false) {
      throw const FormatException(
        'Runtime dialogue outcome ID cannot be empty.',
      );
    }
  }

  final String text;
  final List<RuntimeDialogueStep> steps;
  final String? outcomeId;

  Map<String, Object?> toJson() => <String, Object?>{
    'text': text,
    if (outcomeId != null) 'outcomeId': outcomeId,
    'steps': steps.map((step) => step.toJson()).toList(growable: false),
  };

  @override
  bool operator ==(Object other) =>
      other is RuntimeDialogueChoice &&
      text == other.text &&
      outcomeId == other.outcomeId &&
      _listEquals(steps, other.steps);

  @override
  int get hashCode => Object.hash(text, outcomeId, Object.hashAll(steps));
}

final class RuntimeDialogueDocumentCodec {
  const RuntimeDialogueDocumentCodec();

  Uint8List encodeUtf8(RuntimeDialogueDocument document) =>
      Uint8List.fromList(canonicalizeNarrativeEventJsonUtf8(document.toJson()));

  RuntimeDialogueDocument decodeUtf8(List<int> bytes) {
    final Object? decoded;
    try {
      decoded = decodeNarrativeEventJsonStrict(
        utf8.decode(bytes, allowMalformed: false),
      );
    } on Object {
      throw const FormatException('Invalid runtime dialogue JSON.');
    }
    return decodeJson(decoded);
  }

  RuntimeDialogueDocument decodeJson(Object? value) {
    final json = _object(value, required: const <String>{'format', 'nodes'});
    final format = json['format'];
    if (format != 1) {
      throw const FormatException('Unsupported runtime dialogue format.');
    }
    final nodes = _list(json['nodes']).map(_decodeNode).toList(growable: false);
    return RuntimeDialogueDocument(version: format as int, nodes: nodes);
  }

  RuntimeDialogueNode _decodeNode(Object? value) {
    final json = _object(value, required: const <String>{'title', 'steps'});
    return RuntimeDialogueNode(
      title: _string(json['title']),
      steps: _list(json['steps']).map(_decodeStep).toList(growable: false),
    );
  }

  RuntimeDialogueStep _decodeStep(Object? value) {
    final source = _object(
      value,
      required: const <String>{'kind'},
      optional: const <String>{
        'text',
        'targetNode',
        'choices',
        'characterId',
        'portraitStateId',
      },
    );
    return switch (_string(source['kind'])) {
      'line' => RuntimeDialogueLine(
        _string(
          _exact(
            source,
            required: const <String>{'kind', 'text'},
            optional: const <String>{'characterId', 'portraitStateId'},
          )['text'],
        ),
        characterId: source.containsKey('characterId')
            ? _string(source['characterId'])
            : null,
        portraitStateId: source.containsKey('portraitStateId')
            ? _string(source['portraitStateId'])
            : null,
      ),
      'jump' => RuntimeDialogueJump(
        _string(
          _exact(
            source,
            required: const <String>{'kind', 'targetNode'},
          )['targetNode'],
        ),
      ),
      'choices' => RuntimeDialogueChoiceBlock(
        _list(
          _exact(
            source,
            required: const <String>{'kind', 'choices'},
          )['choices'],
        ).map(_decodeChoice).toList(growable: false),
      ),
      _ => throw const FormatException('Unknown runtime dialogue step kind.'),
    };
  }

  RuntimeDialogueChoice _decodeChoice(Object? value) {
    final json = _object(
      value,
      required: const <String>{'text', 'steps'},
      optional: const <String>{'outcomeId'},
    );
    return RuntimeDialogueChoice(
      text: _string(json['text']),
      outcomeId: json.containsKey('outcomeId')
          ? _string(json['outcomeId'])
          : null,
      steps: _list(json['steps']).map(_decodeStep).toList(growable: false),
    );
  }

  Map<String, Object?> _object(
    Object? value, {
    required Set<String> required,
    Set<String> optional = const <String>{},
  }) {
    if (value is! Map) {
      throw const FormatException('Expected a runtime dialogue object.');
    }
    final result = <String, Object?>{};
    for (final entry in value.entries) {
      if (entry.key is! String) {
        throw const FormatException('Runtime dialogue keys must be strings.');
      }
      result[entry.key as String] = entry.value;
    }
    return _exact(result, required: required, optional: optional);
  }

  Map<String, Object?> _exact(
    Map<String, Object?> value, {
    required Set<String> required,
    Set<String> optional = const <String>{},
  }) {
    if (!value.keys.toSet().containsAll(required) ||
        value.keys.any(
          (key) => !required.contains(key) && !optional.contains(key),
        )) {
      throw const FormatException('Invalid runtime dialogue object fields.');
    }
    return value;
  }

  List<Object?> _list(Object? value) {
    if (value is! List) {
      throw const FormatException('Expected a runtime dialogue list.');
    }
    return value.cast<Object?>();
  }

  String _string(Object? value) {
    if (value is! String || value.trim().isEmpty) {
      throw const FormatException('Expected a non-empty dialogue string.');
    }
    return value;
  }
}

bool _listEquals<T>(List<T> left, List<T> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
