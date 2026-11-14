part of 'map_builder_page.dart';

extension _MapBuilderPageLeaveGuard on _MapBuilderPageState {
  void _protect() {
    if (_guarded || _disposed || !(_draft.unsaved || _typing)) return;
    _guarded = true;
    _exitGuard.register(widget.session.sessionId, _confirmLeave);
  }

  bool get _typing {
    final focused = FocusManager.instance.primaryFocus?.context;
    if (_disposed || focused == null || !focused.mounted) return false;
    return (focused.widget is EditableText ||
            focused.findAncestorWidgetOfExactType<EditableText>() != null) &&
        identical(
          focused.findAncestorStateOfType<_MapBuilderPageState>(),
          this,
        );
  }

  void _commitTyping() {
    if (!_typing) return;
    _pageFocus.requestFocus();
    FocusManager.instance.applyFocusChangesIfNeeded();
  }

  Future<bool> _askToLeave() async {
    _commitTyping();
    if (_disposed || !_draft.unsaved) return true;
    final l10n = context.l10n;
    final choice = await showStudioSaveChoiceDialog(
      context,
      title: l10n.leaveGuardTitle,
      message: l10n.leaveGuardMessage(
        _maps.project?.name ?? widget.session.name,
      ),
      saveLabel: l10n.leaveGuardSave,
      discardLabel: l10n.leaveGuardDiscard,
      cancelLabel: l10n.leaveGuardCancel,
    );
    if (_disposed) return choice == StudioSaveChoice.discard;
    return switch (choice) {
      StudioSaveChoice.save => _save(),
      StudioSaveChoice.discard => true,
      StudioSaveChoice.cancel => false,
    };
  }
}
