export '../../../features/dialogues/application/dialogue_workspace_controller.dart'
    show dialogueSteps, dialogueBranches;

import 'package:flutter/material.dart';
export '../../../features/dialogues/application/dialogue_view_selection.dart';
import '../../../features/dialogues/application/dialogue_view_selection.dart';

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
