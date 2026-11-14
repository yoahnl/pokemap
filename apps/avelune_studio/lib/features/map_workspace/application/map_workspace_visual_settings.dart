part of 'map_workspace_controller.dart';

extension MapWorkspaceVisualSettings on MapWorkspaceController {
  void _cacheVisualComposition(ProjectManifest map, ProjectManifest family) {
    _visualMapSource = map;
    _visualFamilySource = family;
    _combinedVisuals = _prepareModelProjection(
      combineResourceVisuals(map, family),
    );
    visualProjectionBuilds++;
  }

  ProjectManifest _withSurfConfiguration(ProjectManifest value) {
    final settings = value.settings;
    final updated = settings.copyWith(
      surf: _surfConfigurationAccepted
          ? _acceptedSurfConfiguration
          : settings.surf,
      fieldAbilities: _fieldAbilitiesAccepted
          ? _acceptedFieldAbilities
          : settings.fieldAbilities,
      audio: _audioAccepted ? _acceptedAudio : settings.audio,
    );
    if (settings == updated) return value;
    return _surfProjections[value] ??= value.copyWith(settings: updated);
  }

  void _acceptSettingsProjection(bool notifyChange) {
    if (_disposed) return;
    _surfProjections = Expando<ProjectManifest>();
    if (project case final current?) project = _withSurfConfiguration(current);
    if (notifyChange) notify();
  }

  void acceptSurfConfiguration(
    ProjectSurfSettings? configuration, {
    bool notifyChange = true,
  }) {
    if (_disposed) return;
    _surfConfigurationAccepted = true;
    _acceptedSurfConfiguration = configuration;
    _acceptSettingsProjection(notifyChange);
  }

  void acceptFieldAbilities(
    ProjectFieldAbilitiesSettings? configuration, {
    bool notifyChange = true,
  }) {
    if (_disposed) return;
    _fieldAbilitiesAccepted = true;
    _acceptedFieldAbilities = configuration;
    _acceptSettingsProjection(notifyChange);
  }

  void acceptAudio(
    ProjectAudioSettings? configuration, {
    bool notifyChange = true,
  }) {
    if (_disposed) return;
    _audioAccepted = true;
    _acceptedAudio = configuration;
    _acceptSettingsProjection(notifyChange);
  }

  ProjectVisualsController? weatherDraftFor(EditableMapDocument document) {
    if (document.weatherVisuals case final existing?) return existing;
    final source = port;
    if (source is! ProjectVisualsPort) return null;
    final entry = project?.maps
        .where((map) => map.id == document.base.mapId)
        .firstOrNull;
    if (entry == null) return null;
    final owner = ProjectVisualsController(
      session: session,
      port: source as ProjectVisualsPort,
    );
    document.weatherVisuals = owner;
    var attached = false;
    owner.addListener(() {
      if (_disposed || owner.saved == null) return;
      if (!owner.dirty) _mapVisualProfiles[entry.id] = owner.preview.value;
      document.visualProfile = inheritedVisualProfile.overriddenBy(
        owner.preview.value,
      );
      if (!attached) {
        attached = true;
        notify();
      }
    });
    unawaited(
      Future<void>(() async {
        if (!_disposed) await owner.open(map: entry);
      }),
    );
    return owner;
  }
}
