import '../../map_workspace/application/editable_map_document.dart';
import '../domain/dialogue_draft.dart';
import 'narrative_interaction.dart';

class InteractionEditState {
  const InteractionEditState(this.dialogue, this.interaction);
  final DialogueDraft dialogue;
  final NarrativeInteractionDraft interaction;
}

class InteractionEditSession {
  InteractionEditSession({
    required this.document,
    required DialogueDraft dialogue,
    required NarrativeInteractionDraft interaction,
    this.readOnlySource,
  }) : current = InteractionEditState(dialogue, interaction) {
    saved = current;
  }
  final EditableMapDocument document;
  final String? readOnlySource;
  InteractionEditState current;
  late InteractionEditState saved;
  final List<InteractionEditState> _undo = [];
  final List<InteractionEditState> _redo = [];
  bool get dirty => !identical(current, saved);
  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;
  bool get editable => readOnlySource == null;
  int branchIndex = 0;

  void change({
    DialogueDraft? dialogue,
    NarrativeInteractionDraft? interaction,
  }) {
    if (!editable) return;
    _undo.add(current);
    _redo.clear();
    current = InteractionEditState(
      dialogue ?? current.dialogue,
      interaction ?? current.interaction,
    );
  }

  void restore({required bool redo}) {
    final source = redo ? _redo : _undo;
    if (source.isEmpty) return;
    (redo ? _undo : _redo).add(current);
    current = source.removeLast();
    if (branchIndex >= current.dialogue.branches.length) branchIndex = 0;
  }

  void acceptSave(InteractionEditState snapshot) => saved = snapshot;
}
