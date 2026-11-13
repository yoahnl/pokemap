import 'story_draft_entry.dart';

abstract interface class StoryDraftSaved {
  Object? read(StoryDraftKind<Object> kind, String id);
}
