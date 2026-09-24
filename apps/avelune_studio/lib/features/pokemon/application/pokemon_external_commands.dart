part of 'pokemon_workspace_controller.dart';

extension PokemonExternalCommands on PokemonWorkspaceController {
  Future<bool> searchExternal(String query) async {
    if (operationActive) return false;
    externalBusy = true;
    externalSearch = null;
    externalPreview = null;
    error = null;
    _notify();
    try {
      final result = await port.searchExternal(query);
      if (_disposed) return false;
      externalSearch = result;
      return true;
    } on Object catch (failure) {
      if (!_disposed) error = 'Recherche externe indisponible : $failure';
      return false;
    } finally {
      externalBusy = false;
      _notify();
    }
  }

  Future<bool> previewExternal(String speciesId) async {
    if (operationActive || hasPendingChanges) return false;
    externalBusy = true;
    externalPreview = null;
    externalResult = null;
    error = null;
    _notify();
    try {
      final preview = await port.previewExternal(speciesId);
      if (_disposed) return false;
      externalPreview = preview;
      return true;
    } on Object catch (failure) {
      if (!_disposed) error = 'Import externe indisponible : $failure';
      return false;
    } finally {
      externalBusy = false;
      _notify();
    }
  }

  Future<bool> applyExternal(PokemonExternalConflictPolicy policy) async {
    final preview = externalPreview;
    if (preview == null || operationActive || hasPendingChanges) return false;
    externalBusy = true;
    committing = true;
    error = null;
    _notify();
    try {
      final result = await port.applyExternal(preview, policy);
      if (_disposed) return false;
      externalPreview = null;
      externalResult = result;
      await load(refresh: true);
      if (_disposed) return false;
      selectedId = null;
      _drafts.remove(result.speciesId);
      await selectSpecies(result.speciesId);
      return !_disposed;
    } on Object catch (failure) {
      if (!_disposed) error = 'Import externe refusé : $failure';
      return false;
    } finally {
      externalBusy = false;
      committing = false;
      _notify();
    }
  }

  void clearExternal() {
    if (externalBusy) return;
    externalPreview = null;
    externalSearch = null;
    _notify();
  }

  void clearExternalPreview() {
    if (externalBusy) return;
    externalPreview = null;
    _notify();
  }
}
