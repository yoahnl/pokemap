part of 'map_workspace_screen.dart';

extension _WorkspaceExportBinding on _MapWorkspaceScreenState {
  void _openGameExport() {
    if (!mounted || _gameExport == null || widget.gameExportPicker == null) {
      return;
    }
    _show(WorkspaceSpace.gameExport);
  }

  Widget _gameExportPage() {
    final projectPath = _controller.session.directoryPath;
    return StudioGameExportPage(
      controller: _gameExport!,
      prepare: _prepareGameExport,
      preparationFailure: () => _actions.exportPreparationFailure,
      hasPendingChanges: () => _actions.hasPendingChanges,
      isCurrentProject: () =>
          mounted &&
          !_controller.isDisposed &&
          _controller.session.directoryPath == projectPath,
      pickFile: widget.gameExportPicker!,
      onBack: _goHome,
    );
  }

  Future<bool> _allowCloseWithExport() async {
    if (_gameExport?.operationActive == true) return false;
    if (!await _allowLeavePokemon()) return false;
    return _actions.allowClose();
  }

  Future<bool> _prepareGameExport() async {
    if (_pokemon?.operationActive == true) return false;
    if (_pokemon?.hasPendingChanges == true) {
      final choice = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Enregistrer la fiche Pokémon avant l’export ?'),
          content: const Text(
            'Le paquet utilise uniquement les documents enregistrés.',
          ),
          actions: [
            StudioButton(
              label: 'Annuler',
              secondary: true,
              onPressed: () => Navigator.pop(dialogContext, false),
            ),
            StudioButton(
              label: 'Enregistrer puis exporter',
              onPressed: () => Navigator.pop(dialogContext, true),
            ),
          ],
        ),
      );
      if (choice != true || !mounted || !await _pokemon!.saveActiveOwner()) {
        return false;
      }
    }
    if (!await _actions.flushEditors()) return false;
    if (!mounted) return false;
    if (!_actions.hasPendingChanges) return true;
    final choice = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Enregistrer avant l’export ?'),
        content: const Text(
          'Le paquet utilise uniquement la version enregistrée. '
          'Les documents en cours seront enregistrés par leurs éditeurs ; '
          'si l’un échoue, l’export sera arrêté et les brouillons conservés.',
        ),
        actions: [
          StudioButton(
            label: 'Annuler',
            secondary: true,
            onPressed: () => Navigator.pop(dialogContext, false),
          ),
          StudioButton(
            label: 'Enregistrer puis exporter',
            onPressed: () => Navigator.pop(dialogContext, true),
          ),
        ],
      ),
    );
    if (choice != true || !mounted) return false;
    return _actions.saveForExport();
  }
}
