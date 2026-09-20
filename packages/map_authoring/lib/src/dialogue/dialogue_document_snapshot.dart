import 'dialogue_editor_model.dart';

DialogueEditorDocument snapshotDialogueDocument(DialogueEditorDocument doc) =>
    DialogueEditorDocument(
      nodes: List.unmodifiable(doc.nodes.map(_SnapshotNode.new)),
      entryNodeId: doc.entryNodeId,
      sourcePreservation: doc.sourcePreservation,
    );
Never _immutable() => throw UnsupportedError('Dialogue snapshot is immutable.');
List<DialogueEditorStep> _steps(Iterable<DialogueEditorStep> list) =>
    List.unmodifiable(list.map((s) => switch (s) {
          DeLineStep() => _SnapshotLine(s),
          DeNarrationStep() => _SnapshotNarration(s),
          DeChoiceStep() => _SnapshotChoice(s),
          DeJumpStep() => _SnapshotJump(s),
          DeCommandStep() => _SnapshotCommand(s),
          DeConditionStep() => _SnapshotCondition(s),
          _ => cloneDialogueStep(s),
        }));

class _SnapshotNode extends DialogueEditorNode {
  _SnapshotNode(DialogueEditorNode n)
      : super(
            id: n.id,
            title: n.title,
            steps: _steps(n.steps),
            headers: List.unmodifiable(n.headers));
  @override
  set title(String value) => _immutable();
  @override
  set steps(List<DialogueEditorStep> value) => _immutable();
  @override
  set headers(List<DialogueEditorNodeHeader> value) => _immutable();
}

class _SnapshotLine extends DeLineStep {
  _SnapshotLine(DeLineStep s)
      : super(
            id: s.id,
            speaker: s.speaker,
            body: s.body,
            characterId: s.characterId,
            portraitStateId: s.portraitStateId);
  @override
  set body(String value) => _immutable();
  @override
  set speaker(String? value) => _immutable();
  @override
  set characterId(String? value) => _immutable();
  @override
  set portraitStateId(String? value) => _immutable();
}

class _SnapshotNarration extends DeNarrationStep {
  _SnapshotNarration(DeNarrationStep s) : super(id: s.id, text: s.text);
  @override
  set text(String value) => _immutable();
}

class _SnapshotChoice extends DeChoiceStep {
  _SnapshotChoice(DeChoiceStep s)
      : super(
            id: s.id,
            branches: List.unmodifiable(s.branches.map(_SnapshotBranch.new)));
  @override
  set branches(List<DeChoiceBranch> value) => _immutable();
}

class _SnapshotBranch extends DeChoiceBranch {
  _SnapshotBranch(DeChoiceBranch s)
      : super(
            id: s.id,
            label: s.label,
            outcomeId: s.outcomeId,
            steps: _steps(s.steps));
  @override
  set label(String value) => _immutable();
  @override
  set outcomeId(String? value) => _immutable();
  @override
  set steps(List<DialogueEditorStep> value) => _immutable();
}

class _SnapshotJump extends DeJumpStep {
  _SnapshotJump(DeJumpStep s) : super(id: s.id, targetTitle: s.targetTitle);
  @override
  set targetTitle(String value) => _immutable();
}

class _SnapshotCommand extends DeCommandStep {
  _SnapshotCommand(DeCommandStep s) : super(id: s.id, raw: s.raw);
  @override
  set raw(String value) => _immutable();
}

class _SnapshotCondition extends DeConditionStep {
  _SnapshotCondition(DeConditionStep s) : super(id: s.id, raw: s.raw);
  @override
  set raw(String value) => _immutable();
}
