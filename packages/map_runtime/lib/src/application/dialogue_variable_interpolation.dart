import 'package:map_core/map_core.dart';

import 'dialogue_runtime_models.dart';

final _dialogueVariablePattern = RegExp(
  r'\{\{\s*(fact\.[A-Za-z_][A-Za-z0-9_.:-]*|[A-Za-z_][A-Za-z0-9_.-]*)\s*\}\}',
);

/// Resolves `{{ variable_name }}` placeholders from persisted script values.
///
/// Unknown placeholders remain visible so authoring mistakes are diagnosable
/// instead of silently producing empty dialogue.
DialogueSession interpolateDialogueVariables(
  DialogueSession session,
  ScriptVariables variables, {
  int Function(PokedexSpeciesRange range)? pokedexCaughtCount,
  NarrativeFactRuntimeResolver? factResolver,
  NarrativeFactRuntimeState? factState,
  StoryFlags? storyFlags,
}) {
  session.mapText((text) {
    dialogueTextFactIds(text);
    return text;
  });
  for (final feedback in session.lineFeedback) {
    validateDialogueFactFeedback(feedback);
  }
  return session.mapText(
    (text) => text.replaceAllMapped(_dialogueVariablePattern, (match) {
      final name = match.group(1)!;
      if (name.startsWith('fact.')) {
        if (factResolver == null || factState == null || storyFlags == null) {
          throw StateError(
            'Dialogue Fact interpolation requires canonical runtime state.',
          );
        }
        final value = factResolver.resolve(
          factId: name.substring(5),
          runtimeState: factState,
          storyFlags: storyFlags,
        );
        if (value is! NarrativeFactRuntimeResolved) {
          throw StateError(
            'The dialogue Fact reference cannot be resolved: ${name.substring(5)}.',
          );
        }
        return value.narrativeValue.toJson().toString();
      }
      if (name.startsWith(PokedexSpeciesRange.dialogueVariablePrefix)) {
        final range = PokedexSpeciesRange.tryFromDialogueVariableName(name);
        if (range == null || pokedexCaughtCount == null) return match.group(0)!;
        return pokedexCaughtCount(range).toString();
      }

      final value = variables.values[name];
      if (value == null) return match.group(0)!;
      return value.map(
        bool: (entry) => entry.value.toString(),
        int: (entry) => entry.value.toString(),
        string: (entry) => entry.value,
      );
    }),
  );
}

bool dialogueUsesPokedexCaughtCount(DialogueSession session) {
  var found = false;
  session.mapText((text) {
    found =
        found ||
        _dialogueVariablePattern
            .allMatches(text)
            .any(
              (match) =>
                  PokedexSpeciesRange.tryFromDialogueVariableName(
                    match.group(1)!,
                  ) !=
                  null,
            );
    return text;
  });
  return found;
}
