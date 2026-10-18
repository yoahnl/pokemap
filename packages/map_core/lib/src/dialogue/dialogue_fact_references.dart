import '../models/dialogue_line_feedback.dart';
import '../models/project_manifest.dart';
import 'runtime_dialogue_document.dart';

final _factReference = RegExp(
  r'\{\{\s*fact\.([A-Za-z_][A-Za-z0-9_.:-]{0,191})\s*\}\}',
);
final _factReferenceStart = RegExp(r'\{\{\s*fact(?:\.|\s|\})');
final _factId = RegExp(r'^[A-Za-z_][A-Za-z0-9_.:-]{0,191}$');

String dialogueFactPlaceholder(String factId) {
  if (!_factId.hasMatch(factId))
    throw const FormatException('Invalid dialogue Fact identity.');
  return '{{ fact.$factId }}';
}

Set<String> dialogueTextFactIds(String text) {
  final matches = _factReference.allMatches(text).toList();
  final residue = text.replaceAll(_factReference, '');
  if (_factReferenceStart.hasMatch(residue)) {
    throw const FormatException('Malformed dialogue Fact reference.');
  }
  return {for (final match in matches) match.group(1)!};
}

Iterable<String> dialogueDocumentTexts(RuntimeDialogueDocument document) sync* {
  Iterable<String> visit(List<RuntimeDialogueStep> steps) sync* {
    for (final step in steps) {
      switch (step) {
        case RuntimeDialogueLine():
          if (step.feedback case final feedback?)
            validateDialogueFactFeedback(feedback);
          yield step.text;
        case RuntimeDialogueChoiceBlock():
          for (final choice in step.choices) {
            yield choice.text;
            yield* visit(choice.steps);
          }
        case RuntimeDialogueJump():
          break;
      }
    }
  }

  for (final node in document.nodes) {
    yield* visit(node.steps);
  }
}

Set<String> dialogueDocumentFactIds(RuntimeDialogueDocument document) => {
  for (final text in dialogueDocumentTexts(document))
    ...dialogueTextFactIds(text),
};

void validateDialogueFactReferences({
  required ProjectManifest project,
  required RuntimeDialogueDocument document,
}) {
  for (final id in dialogueDocumentFactIds(document)) {
    if (project.facts.where((fact) => fact.id == id).length != 1) {
      throw FormatException(
        'Dialogue Fact reference is missing or ambiguous: $id.',
      );
    }
  }
}

void validateDialogueFactFeedback(DialogueLineFeedback feedback) {
  final text = feedback.plainText;
  dialogueTextFactIds(text);
  final boundaries = <int>{};
  var length = 0;
  for (final segment in feedback.segments) {
    length += segment.plainText.length;
    boundaries.add(length);
  }
  for (final match in _factReference.allMatches(text)) {
    if (boundaries.any(
      (boundary) => boundary > match.start && boundary < match.end,
    )) {
      throw const FormatException(
        'A dialogue Fact reference cannot span multiple segments.',
      );
    }
  }
}
