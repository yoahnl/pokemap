import '../../story_draft/domain/story_draft_entry.dart';

enum StorySection {
  trame,
  behaviours,
  scenes,
  dialogues,
  facts,
  rules,
  verification,
}

final class StoryWorkspaceState {
  const StoryWorkspaceState({
    this.section = StorySection.trame,
    this.selections = const {},
  });

  final StorySection section;
  final Map<StorySection, StoryDraftRef> selections;

  StoryDraftRef? get selection => selections[section];

  StoryWorkspaceState select(StorySection section) => section == this.section
      ? this
      : StoryWorkspaceState(section: section, selections: selections);

  StoryWorkspaceState selectItem(StorySection section, StoryDraftRef? ref) =>
      selections[section] == ref
      ? this
      : StoryWorkspaceState(
          section: this.section,
          selections: Map.unmodifiable(
            {...selections, section: ?ref}
              ..removeWhere((key, _) => key == section && ref == null),
          ),
        );
}
