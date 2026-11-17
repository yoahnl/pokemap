import '../localization/project_locale_policy.dart';
import 'dialogue_feedback_text.dart';
import 'dialogue_localization.dart';
import 'runtime_dialogue_document.dart';

final class RuntimeDialogueTextScope {
  const RuntimeDialogueTextScope({
    required this.binding,
    required this.text,
    required this.kind,
  });

  final String binding;
  final String text;
  final DialogueTextKind kind;
}

List<RuntimeDialogueTextScope> runtimeDialogueTextScopes(
  RuntimeDialogueDocument document,
) {
  final scopes = <RuntimeDialogueTextScope>[];
  void visit(List<RuntimeDialogueStep> steps, String prefix) {
    for (final (index, step) in steps.indexed) {
      final binding = '$prefix/$index';
      switch (step) {
        case RuntimeDialogueLine():
          scopes.add(
            RuntimeDialogueTextScope(
              binding: binding,
              text: step.text,
              kind: DialogueTextKind.line,
            ),
          );
        case RuntimeDialogueChoiceBlock():
          for (final (choiceIndex, choice) in step.choices.indexed) {
            final choiceBinding = '$binding/choice/$choiceIndex';
            scopes.add(
              RuntimeDialogueTextScope(
                binding: choiceBinding,
                text: choice.text,
                kind: DialogueTextKind.choice,
              ),
            );
            visit(choice.steps, choiceBinding);
          }
        case RuntimeDialogueJump():
          break;
      }
    }
  }

  for (final node in document.nodes) {
    visit(node.steps, '/${Uri.encodeComponent(node.title)}');
  }
  return List.unmodifiable(scopes);
}

void validateRuntimeDialogueLocalization(
  RuntimeDialogueDocument document,
  DialogueLocalization localization,
) {
  final scopes = runtimeDialogueTextScopes(document);
  if (scopes.length != localization.units.length) {
    throw const FormatException(
      'Dialogue localization must cover every compiled text exactly.',
    );
  }
  final units = {for (final unit in localization.units) unit.binding: unit};
  for (final scope in scopes) {
    final unit = units[scope.binding];
    if (unit == null ||
        unit.source != scope.text ||
        (unit.kind == DialogueTextKind.choice) !=
            (scope.kind == DialogueTextKind.choice)) {
      throw FormatException(
        'Dialogue localization does not match compiled text at ${scope.binding}.',
      );
    }
  }
}

RuntimeDialogueDocument resolveRuntimeDialogueLocalization(
  RuntimeDialogueDocument document,
  DialogueLocalization localization, {
  required String preferredLocale,
  required ProjectLocalePolicy locales,
}) {
  validateRuntimeDialogueLocalization(document, localization);
  final units = {for (final unit in localization.units) unit.binding: unit};
  final resolved = localization.resolveAll(
    preferredLocale: preferredLocale,
    supportedLocales: locales.supportedLocales,
    fallbackLocale: locales.fallbackLocale,
  );
  String resolve(String binding) => resolved[units[binding]!.id]!.text;
  List<RuntimeDialogueStep> visit(
    List<RuntimeDialogueStep> steps,
    String prefix,
  ) => [
    for (final (index, step) in steps.indexed)
      switch (step) {
        RuntimeDialogueLine() => RuntimeDialogueLine(
          resolve('$prefix/$index'),
          characterId: step.characterId,
          portraitStateId: step.portraitStateId,
          preserveWhitespace: true,
          feedback: retargetDialogueLineFeedback(
            step.feedback,
            sourceText: step.text,
            text: resolve('$prefix/$index'),
          ),
        ),
        RuntimeDialogueJump() => step,
        RuntimeDialogueChoiceBlock() => RuntimeDialogueChoiceBlock([
          for (final (choiceIndex, choice) in step.choices.indexed)
            RuntimeDialogueChoice(
              text: resolve('$prefix/$index/choice/$choiceIndex'),
              preserveWhitespace: true,
              outcomeId: choice.outcomeId,
              steps: visit(choice.steps, '$prefix/$index/choice/$choiceIndex'),
            ),
        ]),
      },
  ];
  return RuntimeDialogueDocument(
    nodes: [
      for (final node in document.nodes)
        RuntimeDialogueNode(
          title: node.title,
          steps: visit(node.steps, '/${Uri.encodeComponent(node.title)}'),
        ),
    ],
  );
}

Object? runtimeDialogueTextShape(RuntimeDialogueDocument document) =>
    _withoutText(document.toJson());

Object? _withoutText(Object? value) {
  if (value is List) return value.map(_withoutText).toList(growable: false);
  if (value is Map<String, Object?>) {
    final isText =
        value['kind'] == 'line' ||
        (!value.containsKey('kind') &&
            value['steps'] is List &&
            value['text'] is String);
    return {
      for (final entry in value.entries)
        entry.key: isText && entry.key == 'text'
            ? null
            : _withoutText(entry.value),
    };
  }
  return value;
}
