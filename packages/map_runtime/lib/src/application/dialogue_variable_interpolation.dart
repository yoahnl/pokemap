import 'package:map_core/map_core.dart';

import 'dialogue_runtime_models.dart';

final _dialogueVariablePattern = RegExp(
  r'\{\{\s*([A-Za-z_][A-Za-z0-9_.-]*)\s*\}\}',
);

/// Resolves `{{ variable_name }}` placeholders from persisted script values.
///
/// Unknown placeholders remain visible so authoring mistakes are diagnosable
/// instead of silently producing empty dialogue.
DialogueSession interpolateDialogueVariables(
  DialogueSession session,
  ScriptVariables variables,
) {
  return session.mapText(
    (text) => text.replaceAllMapped(_dialogueVariablePattern, (match) {
      final name = match.group(1)!;
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
