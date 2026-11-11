part of 'map_workspace_screen.dart';

extension _WorkspaceSettingsRecovery on _MapWorkspaceScreenState {
  Widget _settingsRecovery() => ProjectSettingsRecoveryPane(
    key: const ValueKey('project-settings-unavailable'),
    changes: Listenable.merge([
      ?_projectIdentity,
      ?_projectSurf,
      ?_projectCs,
      ?_projectAudio,
      ?_projectVisuals,
      for (final document in _controller.documents.values)
        ?document.weatherVisuals,
    ]),
    targets: _settingsRecoveryTargets,
    onBack: () => _show(_settingsOrigin),
    backLabel: workspaceSettingsReturnLabel(_settingsOrigin),
  );

  List<ProjectSettingsRecoveryTarget> _settingsRecoveryTargets() =>
      projectSettingsRecoveryTargets(
        identity: _projectIdentity,
        surf: _projectSurf,
        cs: _projectCs,
        audio: _projectAudio,
        projectVisuals: _projectVisuals,
        maps: [
          for (final document in _controller.documents.values)
            if (document.weatherVisuals case final owner?)
              (
                mapId: document.base.mapId,
                name: document.current.name,
                owner: owner,
              ),
        ],
      );
}
