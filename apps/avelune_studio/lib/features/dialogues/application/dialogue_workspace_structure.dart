part of 'dialogue_workspace_controller.dart';

Iterable<DialogueEditorStep> dialogueSteps(
  Iterable<DialogueEditorStep> steps,
) sync* {
  for (final step in steps) {
    yield step;
    if (step is DeChoiceStep) {
      for (final branch in step.branches) {
        yield* dialogueSteps(branch.steps);
      }
    }
  }
}

DialogueEditorStep _step(DialogueEditorDocument doc, String id) => doc.nodes
    .expand((n) => dialogueSteps(n.steps))
    .firstWhere((s) => s.id == id);
DeChoiceBranch _branch(DialogueEditorDocument doc, String id) => doc.nodes
    .expand((n) => dialogueSteps(n.steps))
    .whereType<DeChoiceStep>()
    .expand((s) => s.branches)
    .firstWhere((b) => b.id == id);
List<DialogueEditorStep> _stepList(DialogueEditorDocument doc, String id) {
  List<DialogueEditorStep>? locate(List<DialogueEditorStep> values) {
    if (values.any((s) => s.id == id)) return values;
    for (final choice in values.whereType<DeChoiceStep>()) {
      for (final b in choice.branches) {
        final found = locate(b.steps);
        if (found != null) return found;
      }
    }
    return null;
  }

  for (final n in doc.nodes) {
    final found = locate(n.steps);
    if (found != null) return found;
  }
  throw StateError('Bloc absent.');
}

extension DialogueWorkspaceReconciliation on DialogueWorkspaceController {
  void _reconcileCatalog() {
    if (_closed) return;
    final invalid = _sessions.entries
        .where((e) {
          final saved = e.value.base;
          return saved != null &&
              !e.value.dirty &&
              !_publishing.contains(e.key) &&
              project.dialogues.where((d) => d.id == e.key).firstOrNull !=
                  saved.entry;
        })
        .map((e) => e.key)
        .toSet();
    if (invalid.isEmpty) return;
    _invalidateSources(invalid);
    if (invalid.contains(activeId)) {
      error = 'Ce dialogue a changé ou a disparu. Rouvrez sa version actuelle.';
    }
    changed();
  }
}
