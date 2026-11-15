part of 'spatial_map_editing_viewport.dart';

extension _SpatialPreviewProblems on _SpatialMapEditingViewportState {
  void reportPreviewProblem(Object failure) {
    clearPreviewProblem();
    final message = AppLocalizations.of(context)
        .mapCharacterPreviewUnavailable('$failure');
    previewProblem = (editingDocument, message);
    editingDocument.error = message;
    widget.onChanged();
  }

  void clearPreviewProblem() {
    final problem = previewProblem;
    previewProblem = null;
    if (problem == null || problem.$1.error != problem.$2) return;
    problem.$1.error = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onChanged();
    });
  }
}
