part of 'narrative_story_pane.dart';

extension _NarrativeStoryPaneCreation on _NarrativeStoryPaneState {
  Future<void> _createStory([StorylineType type = StorylineType.main]) async {
    final owner = widget.storyOwner;
    if (owner == null) return;
    final request = await askStoryCreation(context, initialType: type);
    if (!mounted || request == null) return;
    final created = owner.create(request.$1, type: request.$2);
    if (created == null) {
      state.notice = owner.error;
      refresh();
      return;
    }
    state.storyId = created.id;
    widget.onProgression?.call();
  }

  Future<void> _createEvent() async {
    final owner = widget.eventOwner;
    final open = widget.onOpenEvent;
    if (owner == null || open == null) return;
    final name = await askNarrativeName(context, 'Nom du nouvel événement');
    if (!mounted || name == null) return;
    if (!await owner.prepare() || !mounted) {
      if (mounted) {
        state.notice = owner.error;
        refresh();
      }
      return;
    }
    final created = owner.create(name);
    if (created == null) {
      state.notice = owner.error;
      refresh();
      return;
    }
    open(created.id);
  }
}
