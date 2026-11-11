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
    backLabel: switch (_settingsOrigin) {
      WorkspaceSpace.gameExport => 'Retour à l’export',
      WorkspaceSpace.verification => 'Retour aux vérifications',
      WorkspaceSpace.map => 'Retour à la carte',
      _ => 'Retour à l’espace précédent',
    },
  );

  List<ProjectSettingsRecoveryTarget> _settingsRecoveryTargets() {
    const loaded =
        'La dernière version chargée de cette rubrique sera reprise.';
    final targets = <ProjectSettingsRecoveryTarget>[];
    final identity = _projectIdentity;
    if (identity != null) {
      final external = identity.conflict;
      final metadata = external?.metadata;
      final draft = identity.draft;
      targets.add((
        id: 'project-general',
        label: 'Général · Tout le projet',
        draft: IdentitySettingsDraft(identity),
        busy: identity.loading || identity.saving,
        consequence: external == null
            ? loaded
            : 'La version enregistrée détectée sera reprise pour Général.\n'
                  'Titre : brouillon « ${draft.title} » ; enregistré « ${metadata?.title ?? identity.proposed.title} ».\n'
                  'Auteur : brouillon « ${draft.author} » ; enregistré « ${metadata?.author ?? identity.proposed.author} ».\n'
                  'Version : brouillon « ${draft.version} » ; enregistrée « ${metadata?.version ?? identity.proposed.version} ».\n'
                  'Langue : brouillon « ${draft.locale} » ; enregistrée « ${metadata?.locale ?? identity.proposed.locale} ».\n'
                  'Langues disponibles : brouillon « ${draft.locales} » ; enregistrées « ${metadata?.locales ?? identity.proposed.locales} ».',
        recover: external == null ? identity.discard : identity.reloadExternal,
      ));
    }
    final surf = _projectSurf, cs = _projectCs;
    if (surf != null || cs != null) {
      final draft = FieldAbilitySettingsDraft(cs, surf);
      targets.add((
        id: 'project-fieldAbilities',
        label: 'CS et Surf · Tout le projet',
        draft: draft,
        busy:
            surf?.loading == true ||
            surf?.saving == true ||
            cs?.loading == true ||
            cs?.saving == true,
        consequence: loaded,
        recover: draft.discard,
      ));
    }
    final audio = _projectAudio;
    if (audio != null) {
      targets.add((
        id: 'project-sounds',
        label: 'Sons · Tout le projet',
        draft: SoundSettingsDraft(audio),
        busy: audio.busy,
        consequence: loaded,
        recover: audio.discard,
      ));
    }
    void visuals(ProjectVisualsController owner, String id, String label) {
      for (final section in [
        ProjectSettingsSection.image,
        ProjectSettingsSection.timeWeather,
      ]) {
        final draft = VisualSettingsDraft(
          owner,
          section == ProjectSettingsSection.image
              ? isImageVisualParameter
              : isTimeWeatherVisualParameter,
        );
        targets.add((
          id: '$id-${section.name}',
          label:
              '${section == ProjectSettingsSection.image ? 'Image et caméra' : 'Temps et météo'} · $label',
          draft: draft,
          busy: owner.loading || owner.saving,
          consequence: loaded,
          recover: draft.discard,
        ));
      }
    }

    final projectVisuals = _projectVisuals;
    if (projectVisuals != null) {
      visuals(projectVisuals, 'project', 'Tout le projet');
    }
    for (final document in _controller.documents.values) {
      final owner = document.weatherVisuals;
      if (owner != null) {
        visuals(
          owner,
          'map-${document.base.mapId}',
          'Carte « ${document.current.name} »',
        );
      }
    }
    return targets;
  }
}
