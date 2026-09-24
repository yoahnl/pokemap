part of 'pokemon_workspace_controller.dart';

extension PokemonImportCommands on PokemonWorkspaceController {
  Future<bool> prepareJsonImport(String path) async {
    if (operationActive || hasPendingChanges) return false;
    importing = true;
    importPreview = null;
    error = null;
    _notify();
    try {
      final preview = await port.previewJsonImport(path);
      if (_disposed) return false;
      importPreview = preview;
      return true;
    } on Object catch (failure) {
      if (!_disposed) error = 'Import JSON refusé : $failure';
      return false;
    } finally {
      importing = false;
      _notify();
    }
  }

  Future<bool> applyJsonImport({required bool confirmOverwrite}) async {
    final preview = importPreview;
    if (preview == null || operationActive || hasPendingChanges) return false;
    importing = true;
    committing = true;
    error = null;
    _notify();
    try {
      final id = await port.applyJsonImport(
        preview,
        confirmOverwrite: confirmOverwrite,
      );
      if (_disposed) return false;
      importPreview = null;
      await load(refresh: true);
      if (_disposed) return false;
      selectedId = null;
      _drafts.remove(id);
      return await selectSpecies(id);
    } on Object catch (failure) {
      if (!_disposed) error = 'Application de l’import refusée : $failure';
      return false;
    } finally {
      importing = false;
      committing = false;
      _notify();
    }
  }

  void clearImport() {
    if (importing) return;
    importPreview = null;
    _notify();
  }

  Future<bool> importMenuPng({
    required String sourcePath,
    required String formId,
    required String role,
  }) async {
    final draft = selectedDraft;
    if (draft == null || operationActive || hasPendingChanges) return false;
    importing = true;
    committing = true;
    error = null;
    notice = null;
    _notify();
    try {
      final result = await port.importMenuPng(
        sourcePath: sourcePath,
        speciesId: draft.id,
        formId: formId,
        role: role,
      );
      if (_disposed) return false;
      notice = result;
      await load(refresh: true);
      if (_disposed) return false;
      final entry = index?.entries
          .where((item) => item.id == draft.id)
          .firstOrNull;
      if (entry != null) {
        _drafts[draft.id] = PokemonSpeciesDraft(await port.loadSpecies(entry));
        if (_disposed) return false;
      }
      _notify();
      return true;
    } on Object catch (failure) {
      if (!_disposed) error = 'Import PNG refusé : $failure';
      return false;
    } finally {
      importing = false;
      committing = false;
      _notify();
    }
  }
}
