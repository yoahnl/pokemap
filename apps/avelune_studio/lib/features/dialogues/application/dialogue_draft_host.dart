import '../../story_draft/application/story_draft.dart';
import '../../story_draft/domain/story_dialogue_source.dart';

abstract interface class DialogueDraftHost {
  bool get editable;
  StoryDraft get draft;
  void rememberDialogue(StoryDialogueSource saved);
  StoryDialogueSource? savedDialogue(String id);
  void stage(void Function(StoryDraft draft) edit);
}
