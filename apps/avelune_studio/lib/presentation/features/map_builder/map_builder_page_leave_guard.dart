part of 'map_builder_page.dart';

extension _MapBuilderPageLeaveGuard on _MapBuilderPageState {
  void _protect() {
    if (_guarded ||
        _disposed ||
        !(_openingExport ||
            _exporting ||
            _packDialogOpen ||
            _pokemonImporting ||
            _draft.unsaved ||
            _typing)) {
      return;
    }
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

  Future<void> _commitTyping() {
    if (!_typing) return _textTransactions.finish();
    final pending = MapBuilderNameField.commitFocused();
    _pageFocus.requestFocus();
    FocusManager.instance.applyFocusChangesIfNeeded();
    return Future.wait([pending, _textTransactions.finish()]).then((_) {});
  }

  Future<bool> _askToLeave() async {
    if (_openingExport || _exporting || _packDialogOpen || _pokemonImporting) {
      return false;
    }
    await _commitTyping();
    if (!mounted || _disposed || !_draft.unsaved) return true;
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
