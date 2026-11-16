import 'package:map_authoring/map_authoring_dialogue.dart';
import 'package:map_core/map_core_domain.dart';

import '../domain/story_dialogue_source.dart';

List<DialogueLineTextEdit>? storyDialogueTextEdits(
  StoryDialogueSource? before,
  StoryDialogueSource? after,
) {
  if (before == null || after == null || before.source == after.source) {
    return null;
  }
  const compiler = DialogueAuthoringCompiler();
  final old = compiler
      .compile(entry: before.entry, source: before.source)
      .document;
  final next = compiler
      .compile(entry: after.entry, source: after.source)
      .document;
  if (old == null || next == null) return null;
  final oldScopes = {
    for (final scope in sceneDialogueLineScopes(old))
      (scope.nodeName, scope.lineIndex): scope.text,
  };
  final scopes = sceneDialogueLineScopes(next);
  if (scopes.length != oldScopes.length ||
      scopes.any(
        (scope) => !oldScopes.containsKey((scope.nodeName, scope.lineIndex)),
      )) {
    return null;
  }
  final edits = [
    for (final scope in scopes)
      if (oldScopes[(scope.nodeName, scope.lineIndex)] != scope.text)
        DialogueLineTextEdit(
          nodeName: scope.nodeName,
          lineIndex: scope.lineIndex,
          beforeText: oldScopes[(scope.nodeName, scope.lineIndex)]!,
          afterText: scope.text,
        ),
  ];
  return edits.isEmpty ? null : edits;
}
