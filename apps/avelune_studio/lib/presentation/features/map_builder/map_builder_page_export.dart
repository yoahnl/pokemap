part of 'map_builder_page.dart';

extension _MapBuilderPageExport on _MapBuilderPageState {
  Future<void> _exportGame() async {
    if (!_editable || _openingExport || _testing || _maps.project == null) {
      return;
    }
    _openingExport = true;
    _changed();
    final subscription = ref.listenManual(
      gameExportPortProvider(widget.session),
      (_, _) {},
    );
    final sessions = ref.read(projectSessionControllerProvider);
    bool current() =>
        mounted &&
        !_disposed &&
        identical(sessions.state.project, widget.session);
    try {
      await _commitTyping();
      if (!mounted || !current()) return;
      FocusManager.instance.primaryFocus?.unfocus();
      _openingExport = false;
      _exporting = true;
      _changed();
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => GameExportDialog(
          port: subscription.read(),
          pickFile: ref.read(gameExportPickerProvider),
          prepare: _save,
          hasPendingChanges: () =>
              _draft.unsaved || _textTransactions.pending || _typing,
          isCurrentProject: current,
          preparationFailure: () => _maps.error ?? _maps.active?.error,
        ),
      );
    } finally {
      subscription.close();
      _openingExport = false;
      _exporting = false;
      _changed();
    }
  }
}
