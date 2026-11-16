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
  const StoryWorkspaceState({this.section = StorySection.trame});

  final StorySection section;

  StoryWorkspaceState select(StorySection section) =>
      section == this.section ? this : StoryWorkspaceState(section: section);
}
