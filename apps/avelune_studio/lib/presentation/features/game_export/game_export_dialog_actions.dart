part of 'game_export_dialog.dart';

extension _GameExportDialogActions on _GameExportDialogState {
  Future<void> _export() async {
    if (_working || !widget.isCurrentProject()) return;
    final metadata = _metadata!;
    final problem = widget.port.checkIdentity(metadata);
    _change(() {
      _problem = problem;
      _error = null;
    });
    if (problem != null) return;
    FocusManager.instance.primaryFocus?.unfocus();
    _change(() => _running = true);
    var selecting = true;
    try {
      final suggested = metadata.title.trim().replaceAll(
        RegExp(r'[\\/:*?"<>|]'),
        '_',
      );
      final target = await widget.pickFile(suggested);
      selecting = false;
      if (!mounted || !widget.isCurrentProject() || target == null) return;
      if (target.exists && !await _confirmReplacement(target.path)) return;
      if (!mounted || !widget.isCurrentProject()) return;
      _change(() => _attempted = true);
      await widget.port.export(
        metadata: metadata,
        outputPath: target.path,
        overwriteConfirmed: target.exists,
        publication: _publication,
        prepare: widget.prepare,
        preparationFailure: widget.preparationFailure,
        hasPendingChanges: widget.hasPendingChanges,
        isCurrentProject: () => mounted && widget.isCurrentProject(),
      );
    } on Object {
      if (mounted) {
        _change(
          () => _error = selecting
              ? context.l10n.exportPickerFailed
              : context.l10n.exportFailed,
        );
      }
    } finally {
      if (mounted) _change(() => _running = false);
    }
  }

  Future<bool> _confirmReplacement(String path) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialog) => StudioReviewDialog(
          title: context.l10n.exportOverwriteTitle,
          content: Text(context.l10n.exportOverwriteHint(path)),
          confirmLabel: context.l10n.exportOverwriteAction,
          onConfirmed: () => Navigator.pop(dialog, true),
          cancelLabel: context.l10n.cancel,
          onCancelled: () => Navigator.pop(dialog, false),
        ),
      ) ??
      false;
}
