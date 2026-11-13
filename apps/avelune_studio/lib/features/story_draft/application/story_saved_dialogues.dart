import '../domain/story_dialogue_source.dart';
import '../domain/story_draft_entry.dart';
import '../domain/story_draft_saved.dart';

typedef StoryDialogueLoader = Future<StoryDialogueSource> Function(String id);

final class StorySavedDialogues implements StoryDraftSaved {
  final _known = <String, StoryDialogueSource>{};

  bool knows(String id) => _known.containsKey(id);

  StoryDialogueSource? operator [](String id) => _known[id];

  void remember(StoryDialogueSource dialogue) => _known[dialogue.id] = dialogue;

  void forget(String id) => _known.remove(id);

  @override
  Object? read(StoryDraftKind<Object> kind, String id) =>
      kind == StoryDraftKind.dialogue ? _known[id] : null;
}
