part of 'story_page.dart';

extension _StoryPageDialogues on _StoryPageState {
  Future<void> _consumeDialogueRequest() async {
    final request = widget.dialogueRequest;
    if (request == null) return;
    await widget.beforeNavigation?.call();
    if (!mounted || widget.dialogueRequest != request) return;
    _openSection(StorySection.dialogues);
    unawaited(_dialogues?.open());
    _workspace = _workspace.select(StorySection.dialogues);
    _dialogues?.select(request.id);
    _selectItem(StorySection.dialogues, (
      kind: StoryDraftKind.dialogue,
      id: request.id,
    ));
    _changed();
  }
}
