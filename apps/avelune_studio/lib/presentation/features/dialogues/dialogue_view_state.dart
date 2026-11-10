export '../../../features/dialogues/application/dialogue_workspace_controller.dart'
    show dialogueSteps, dialogueBranches;

import 'package:flutter/material.dart';
import 'package:map_authoring/map_authoring_dialogue.dart';

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
  }
}

class DialogueViewState {
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
  }
}
