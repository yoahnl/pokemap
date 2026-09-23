part of 'narrative_story_pane.dart';

extension _NarrativeStoryPaneCreation on _NarrativeStoryPaneState {
  Future<void> _createStory() async {
    final owner = widget.storyOwner;
    if (owner == null) return;
    final request = await askStoryCreation(context);
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

  Future<void> _createScene() async {
    final owner = widget.sceneOwner;
    final open = widget.onOpenScene;
    if (owner == null || open == null) return;
    final name = await askNarrativeName(context, 'Nom de la scène');
    if (!mounted || name == null) return;
    final created = owner.create(name);
    if (created == null) {
      state.notice = owner.error;
      refresh();
      return;
    }
    await _navigateDocument(open, created.current.id);
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
