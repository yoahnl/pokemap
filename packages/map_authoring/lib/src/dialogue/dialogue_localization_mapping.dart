part of 'dialogue_localization_document.dart';

typedef _MapText = (String, String) Function(
    String id, String binding, DialogueTextKind kind, String text);

DialogueEditorDocument _mapDialogueTexts(
    DialogueEditorDocument document, _MapText map,
    {bool independent = false}) {
  final nodes = <DialogueEditorNode>[];
  String? entry;
  for (final node in document.nodes) {
    final id = independent ? newDialogueEditorId() : node.id;
    if (node.id == document.effectiveEntryNodeId) entry = id;
    nodes.add(DialogueEditorNode(
        id: id,
        title: node.title,
        headers: List.of(node.headers),
        steps: _mapSteps(node.steps, '/${Uri.encodeComponent(node.title)}', map,
            independent)));
  }
  return DialogueEditorDocument(
      nodes: nodes,
      entryNodeId: entry,
      sourcePreservation: document.sourcePreservation);
}

List<DialogueEditorStep> _mapSteps(List<DialogueEditorStep> steps,
    String prefix, _MapText map, bool independent) {
  final result = <DialogueEditorStep>[];
  var index = 0;
  for (final step in steps) {
    final binding = '$prefix/$index';
    if (step is! DeStartStep && step is! DeEndStep) index++;
    final id = independent ? newDialogueEditorId() : step.id;
    result.add(switch (step) {
      DeLineStep() => _mapLine(step, binding, map),
      DeNarrationStep() => _mapNarration(step, binding, map),
      DeChoiceStep() => DeChoiceStep(id: id, branches: [
          for (final (i, branch) in step.branches.indexed)
            _mapBranch(branch, '$binding/choice/$i', map, independent),
        ]),
      DeJumpStep() => DeJumpStep(id: id, targetTitle: step.targetTitle),
      DeCommandStep() => DeCommandStep(id: id, raw: step.raw),
      DeConditionStep() => DeConditionStep(id: id, raw: step.raw),
      DeStartStep() => DeStartStep(id: id),
      DeEndStep() => DeEndStep(id: id),
    });
  }
  return result;
}

DeLineStep _mapLine(DeLineStep step, String binding, _MapText map) {
  final (id, text) = map(step.id, binding, DialogueTextKind.line, step.body);
  return DeLineStep(
      id: id,
      body: text,
      speaker: step.speaker,
      characterId: step.characterId,
      portraitStateId: step.portraitStateId);
}

DeNarrationStep _mapNarration(
    DeNarrationStep step, String binding, _MapText map) {
  final (id, text) =
      map(step.id, binding, DialogueTextKind.narration, step.text);
  return DeNarrationStep(id: id, text: text);
}

DeChoiceBranch _mapBranch(
    DeChoiceBranch branch, String binding, _MapText map, bool independent) {
  final (id, text) =
      map(branch.id, binding, DialogueTextKind.choice, branch.label);
  return DeChoiceBranch(
      id: id,
      label: text,
      outcomeId: branch.outcomeId,
      steps: _mapSteps(branch.steps, binding, map, independent));
}
