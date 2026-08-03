enum EditorExitBlockerKind {
  map,
  projectManifest,
  narrative,
  personalization,
  borderPreview,
  borderStudio,
  stepStudio,
  environmentStudio,
  dialogueStudio,
  globalStoryStudio,
  eventBuilderV2,
  pendingTemplate,
  saveInProgress,
  unknown,
}

final class EditorExitBlocker {
  const EditorExitBlocker({
    required this.id,
    required this.kind,
  });

  final String id;
  final EditorExitBlockerKind kind;
}

final class EditorExitReadiness {
  EditorExitReadiness.fromBlockers(Iterable<EditorExitBlocker> blockers)
      : blockers = _normalized(blockers);

  const EditorExitReadiness._(this.blockers);

  static const EditorExitReadiness clean = EditorExitReadiness._([]);

  final List<EditorExitBlocker> blockers;

  bool get canExit => blockers.isEmpty;

  static List<EditorExitBlocker> _normalized(
    Iterable<EditorExitBlocker> blockers,
  ) {
    final unique = <String, EditorExitBlocker>{};
    for (final blocker in blockers) {
      unique['${blocker.kind.name}:${blocker.id}'] = blocker;
    }
    final result = unique.values.toList()
      ..sort((left, right) {
        final kindOrder = left.kind.index.compareTo(right.kind.index);
        return kindOrder != 0 ? kindOrder : left.id.compareTo(right.id);
      });
    return List.unmodifiable(result);
  }
}
