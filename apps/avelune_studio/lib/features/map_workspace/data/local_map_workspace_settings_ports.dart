part of 'local_map_workspace_adapter.dart';

mixin _MapWorkspaceSettingsPorts
    implements
        ProjectAudioPort,
        ProjectCsPort,
        ProjectSurfPort,
        ProjectVisualsPort {
  LocalMapWorkspaceAdapter get _adapter;

  @override
  Future<ProjectAudioState> loadAudio(ProjectSession session) =>
      _adapter._loadAudio(session);
  @override
  Future<ProjectAudioState> saveAudioCue(
    ProjectSession session,
    ProjectSoundCue cue,
    ProjectSoundBinding? binding,
    String expectedRevision,
  ) => _adapter.withResourceMutation(
    () => _adapter._saveAudioCue(session, cue, binding, expectedRevision),
  );
  @override
  Future<ProjectAudioPage> queryAudio(
    ProjectSession session, {
    String query = '',
    String? cursor,
  }) => _adapter._queryAudio(session, query: query, cursor: cursor);
  @override
  Future<ProjectAudioImport> importAudio(
    ProjectSession session,
    String sourcePath,
    String label,
    String expectedRevision,
  ) => _adapter.withResourceMutation(
    () => _adapter._importAudio(session, sourcePath, label, expectedRevision),
  );
  @override
  Future<ProjectAudioFile> resolveAudio(
    ProjectSession session,
    String mediaId,
  ) => _adapter._resolveAudio(session, mediaId);
  @override
  Future<ProjectAudioPage> queryLegacyAudio(
    ProjectSession session, {
    String query = '',
    String? cursor,
  }) => _adapter._queryLegacyAudio(session, query: query, cursor: cursor);
  @override
  Future<ProjectAudioImport> adoptAudioAsset(
    ProjectSession session,
    String assetId,
    String mediaId,
    String label,
    String expectedRevision,
  ) => _adapter.withResourceMutation(
    () => _adapter._adoptAudioAsset(
      session,
      assetId,
      mediaId,
      label,
      expectedRevision,
    ),
  );

  @override
  Future<ProjectCsState> loadFieldAbilities(ProjectSession session) =>
      _adapter._loadFieldAbilities(session);
  @override
  Future<ProjectCsState> saveFieldAbility(
    ProjectSession session,
    FieldAbility ability,
    bool enabled,
    String expectedRevision,
  ) => saveFieldAbilityId(session, ability.moveId, enabled, expectedRevision);
  @override
  Future<ProjectCsState> saveFieldAbilityId(
    ProjectSession session,
    String abilityId,
    bool enabled,
    String expectedRevision,
  ) => _adapter.withResourceMutation(
    () => _adapter._saveFieldAbilityId(
      session,
      abilityId,
      enabled,
      expectedRevision,
    ),
  );

  @override
  Future<ProjectSurfState> loadSurf(ProjectSession session) =>
      _adapter._loadSurf(session);
  @override
  Future<ProjectSurfState> saveSurf(
    ProjectSession session,
    ProjectSurfSettings? configuration,
    String expectedRevision,
  ) => _adapter.withResourceMutation(
    () => _adapter._saveSurf(session, configuration, expectedRevision),
  );
  @override
  Future<ProjectSurfReferences> loadSurfReferences(ProjectSession session) =>
      _adapter._loadSurfReferences(session);
  @override
  Future<NarrativeFactDefinition> loadSurfFact(
    ProjectSession session,
    String id,
  ) => _adapter._loadSurfFact(session, id);

  @override
  Future<ProjectVisualsState> loadVisuals(
    ProjectSession session, {
    ProjectMapEntry? map,
  }) => _adapter._loadVisuals(session, map);
  @override
  Future<ProjectVisualsState> saveVisuals(
    ProjectSession session,
    SpatialVisualPatch profile,
    String expectedRevision, {
    ProjectMapEntry? map,
  }) => _adapter._saveVisuals(session, profile, expectedRevision, map);
  @override
  Future<ProjectVisualsState> undoVisuals(
    ProjectSession session,
    String receiptId,
    String expectedRevision, {
    ProjectMapEntry? map,
  }) => _adapter._undoVisuals(session, receiptId, expectedRevision, map);
}
