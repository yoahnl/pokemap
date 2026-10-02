part of 'dialogue_workspace_controller.dart';

extension DialogueCharacterReconciliation on DialogueWorkspaceController {
  List<String> characterDraftOwners(String characterId) => [
    for (final entry in _sessions.entries)
      if (accessProblem(entry.key) != null &&
          [entry.value.current.source, entry.value.saved.source].any(
            (source) => RegExp(
              r'^\s*<<(?:portrait|speaker)\s+' +
                  RegExp.escape(characterId) +
                  r'(?:\s|>>)',
              multiLine: true,
            ).hasMatch(source),
          ))
        'Dialogue · ${entry.value.current.entry.name}',
  ];

  String? characterSourceProblem(Set<String> ids) {
    for (final id in ids) {
      final problem =
          accessProblem(id) ?? narrative.dialogueInteractionAccessProblem(id);
      if (problem != null) return problem;
    }
    return null;
  }

  void invalidateCharacterSources(Set<String> ids) {
    final problem = characterSourceProblem(ids);
    if (problem != null) throw StateError(problem);
    if (ids.contains(activeId)) {
      _generation++;
      _loading = false;
    }
    for (final id in ids) {
      _identities.remove(id);
      _sessions.remove(id);
      narrative.invalidateCleanDialogueSessions(id);
    }
    if (ids.contains(activeId)) preview = null;
    changed();
  }
}
