part of 'pokemon_workspace_controller.dart';

extension PokemonMovesSyncCommands on PokemonWorkspaceController {
  Future<bool> previewMovesSync() async {
    if (operationActive || hasPendingChanges) return false;
    syncing = true;
    movesPreview = null;
    error = null;
    notice = null;
    _notify();
    try {
      final preview = await port.previewMovesSync();
      if (_disposed) return false;
      movesPreview = preview;
      return true;
    } on Object catch (failure) {
      if (!_disposed) error = 'Aperçu de synchronisation refusé : $failure';
      return false;
    } finally {
      syncing = false;
      _notify();
    }
  }

  Future<bool> applyMovesSync() async {
    final preview = movesPreview;
    if (preview == null || operationActive || hasPendingChanges) return false;
    syncing = true;
    committing = true;
    error = null;
    notice = null;
    _notify();
    try {
      await port.applyMovesSync(preview);
      if (_disposed) return false;
      movesPreview = null;
      await load(refresh: true);
      if (_disposed) return false;
      notice = 'Catalogue des attaques synchronisé.';
      return true;
    } on Object catch (failure) {
      if (!_disposed) error = 'Synchronisation refusée : $failure';
      return false;
    } finally {
      syncing = false;
      committing = false;
      _notify();
    }
  }

  void clearMovesPreview() {
    if (syncing) return;
    movesPreview = null;
    _notify();
  }
}
