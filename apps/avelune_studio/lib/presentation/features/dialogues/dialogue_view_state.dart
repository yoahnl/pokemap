import 'package:flutter/material.dart';
import 'package:map_authoring/map_authoring_dialogue.dart';
import '../scenes/scene_canvas_types.dart';

class DialogueViewStore {
  final search = TextEditingController();
  final sessions = <String, DialogueViewState>{};
  bool libraryOpen = false;
  bool inspectorOpen = false;
  String folderId = '';
  DialogueViewState forDialogue(String id) =>
      sessions.putIfAbsent(id, DialogueViewState.new);
  void dispose() {
    search.dispose();
    for (final state in sessions.values) {
      state.viewport.dispose();
    }
  }
}

class DialogueViewState {
  final viewport = SceneGraphViewport();
  final positions = <String, Offset>{};
  String? nodeId, stepId, branchId, wireId;
  bool previewOpen = true;
  String tab = 'properties';
  void select(String node, {String? step, String? branch}) {
    nodeId = node;
    stepId = step;
    branchId = branch;
    wireId = null;
  }

  void reconcile(DialogueEditorDocument document) {
    if (document.nodeById(nodeId ?? '') == null) {
      nodeId = document.nodes.firstOrNull?.id;
      stepId = null;
      branchId = null;
      wireId = null;
    }
    for (var i = 0; i < document.nodes.length; i++) {
      positions.putIfAbsent(
        document.nodes[i].id,
        () => i == 0
            ? const Offset(50, 130)
            : Offset(390 + ((i - 1) ~/ 2) * 340, 35 + ((i - 1) % 2) * 330),
      );
    }
  }
}

Iterable<DialogueEditorStep> dialogueSteps(
  List<DialogueEditorStep> steps,
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

Iterable<DeChoiceBranch> dialogueBranches(DialogueEditorNode node) sync* {
  for (final step in dialogueSteps(node.steps).whereType<DeChoiceStep>()) {
    yield* step.branches;
  }
}
