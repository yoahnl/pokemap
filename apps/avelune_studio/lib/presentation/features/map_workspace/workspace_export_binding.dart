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
      publicationAvailable:
          _controller.project != null &&
          _controller.project!.settings.dimension != ProjectDimension.threeD,
      prepare: _prepareGameExport,
      preparationFailure: () => _actions.exportPreparationFailure,
      hasPendingChanges: () => _actions.hasPendingChanges,
      isCurrentProject: () =>
          mounted &&
          !_controller.isDisposed &&
          _controller.session.directoryPath == projectPath,
      pickFile: widget.gameExportPicker!,
      onBack: _goHome,
      identity: _identityOwner,
      onEditIdentity: () => _openSettingsSection(ProjectSettingsSection.general),
      onOpenOwner: _openFailureOwner,
    );
  }

  void _openSettingsSection(ProjectSettingsSection section) {
    _settingsSection = section;
    _show(WorkspaceSpace.projectSettings);
  }

  void _showPokemonOwner() {
    _show(WorkspaceSpace.pokemon);
    unawaited(_pokemon?.load());
  }

  void _openFailureOwner(StudioFailureOwner owner) => switch (owner) {
    StudioFailureOwner.general =>
      _openSettingsSection(ProjectSettingsSection.general),
    StudioFailureOwner.image =>
      _openSettingsSection(ProjectSettingsSection.image),
    StudioFailureOwner.timeWeather =>
      _openSettingsSection(ProjectSettingsSection.timeWeather),
    StudioFailureOwner.resources => _show(WorkspaceSpace.resources),
    StudioFailureOwner.pokemon => _showPokemonOwner(),
    StudioFailureOwner.regionalMap => _show(WorkspaceSpace.regionalMap),
    StudioFailureOwner.story => _show(WorkspaceSpace.story),
    StudioFailureOwner.presentations =>
      _presentations == null ? _show(WorkspaceSpace.story) : _openPresentations(),
    StudioFailureOwner.map => _show(WorkspaceSpace.map),
    StudioFailureOwner.verification => _show(WorkspaceSpace.verification),
    StudioFailureOwner.exportDestination ||
    StudioFailureOwner.exportMode => null,
  };

  Future<bool> _allowCloseWithExport() async {
    if (_connectionBusy || _controller.catalogBusy) return false;
    if (_gameExport?.operationActive == true) return false;
    if (!await _allowLeavePokemon()) return false;
    if (_libraryExitGuard != null && !await _libraryExitGuard!()) return false;
    return _actions.allowClose();
  }

  Future<bool> _prepareGameExport() async {
    if (_resources?.busy == true || _resources?.packTransfer?.blocksClose == true) return false;
    if (_controller.catalogBusy || _controller.pendingCatalogReceipt != null) {
      return false;
    }
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
