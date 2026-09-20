import 'dart:convert';
import 'dialogue_editor_model.dart';

DialogueEditorDocument reconcileDialogueDocumentIds(DialogueEditorDocument doc,
    {DialogueEditorDocument? previous}) {
  final nodes = <DialogueEditorNode>[];
  String? entry;
  for (final node in doc.nodes) {
    final old = previous?.nodes.where((n) => n.title == node.title).firstOrNull;
    final id = old?.id ?? 'de_${base64Url.encode(utf8.encode(node.title))}';
    if (node.id == doc.entryNodeId) entry = id;
    nodes.add(DialogueEditorNode(
        id: id,
        title: node.title,
        headers: List.of(node.headers),
        steps: _reconcileSteps(node.steps, old?.steps, id)));
  }
  return DialogueEditorDocument(
      nodes: nodes,
      entryNodeId: entry,
      sourcePreservation: doc.sourcePreservation);
}

List<DialogueEditorStep> _reconcileSteps(List<DialogueEditorStep> list,
        List<DialogueEditorStep>? previous, String prefix) =>
    [
      for (var i = 0; i < list.length; i++)
        _step(
            list[i],
            previous != null && i < previous.length ? previous[i] : null,
            '${prefix}_$i'),
    ];
DialogueEditorStep _step(
    DialogueEditorStep s, DialogueEditorStep? old, String fallback) {
  final id = old?.runtimeType == s.runtimeType ? old!.id : fallback;
  return switch (s) {
    DeStartStep() => DeStartStep(id: id),
    DeEndStep() => DeEndStep(id: id),
    DeLineStep() => DeLineStep(
        id: id,
        body: s.body,
        speaker: s.speaker,
        characterId: s.characterId,
        portraitStateId: s.portraitStateId),
    DeNarrationStep() => DeNarrationStep(id: id, text: s.text),
    DeJumpStep() => DeJumpStep(id: id, targetTitle: s.targetTitle),
    DeCommandStep() => DeCommandStep(id: id, raw: s.raw),
    DeConditionStep() => DeConditionStep(id: id, raw: s.raw),
    DeChoiceStep() => DeChoiceStep(id: id, branches: [
        for (var i = 0; i < s.branches.length; i++)
          _branch(
              s.branches[i],
              old is DeChoiceStep && i < old.branches.length
                  ? old.branches[i]
                  : null,
              '${id}_b$i')
      ]),
  };
}

DeChoiceBranch _branch(
        DeChoiceBranch b, DeChoiceBranch? old, String fallback) =>
    DeChoiceBranch(
        id: old?.id ?? fallback,
        label: b.label,
        outcomeId: b.outcomeId,
        steps: _reconcileSteps(b.steps, old?.steps, old?.id ?? fallback));
