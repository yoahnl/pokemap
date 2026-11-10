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
      publicationAvailable: studioPublicationAvailable(
        _controller.project?.settings.dimension,
      ),
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
      onEditIdentity: () =>
          _openSettingsSection(ProjectSettingsSection.general),
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
    StudioFailureOwner.general => _openSettingsSection(
      ProjectSettingsSection.general,
    ),
    StudioFailureOwner.image => _openSettingsSection(
      ProjectSettingsSection.image,
    ),
    StudioFailureOwner.timeWeather => _openSettingsSection(
      ProjectSettingsSection.timeWeather,
    ),
    StudioFailureOwner.resources => _show(WorkspaceSpace.resources),
    StudioFailureOwner.pokemon => _showPokemonOwner(),
    StudioFailureOwner.regionalMap => _show(WorkspaceSpace.regionalMap),
    StudioFailureOwner.story => _show(WorkspaceSpace.story),
    StudioFailureOwner.presentations =>
      _presentations == null
          ? _show(WorkspaceSpace.story)
          : _openPresentations(),
    StudioFailureOwner.map => _show(WorkspaceSpace.map),
    StudioFailureOwner.verification => _show(WorkspaceSpace.verification),
    StudioFailureOwner.exportDestination ||
    StudioFailureOwner.exportMode => null,
  };

  Future<bool> _allowCloseWithExport() => _publication.allowClose(
    leavePokemon: _allowLeavePokemon,
    leaveLibrary: () async => await _libraryExitGuard?.call() ?? true,
  );

  Future<bool> _prepareGameExport() => _publication.prepareExport(
    confirmPokemonSave: () async =>
        await showDialog<bool>(
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
        ) ==
        true,
    confirmSave: () async =>
        await showDialog<bool>(
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
        ) ==
        true,
  );
}
