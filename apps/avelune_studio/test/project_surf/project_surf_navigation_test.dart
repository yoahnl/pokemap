import 'package:avelune_studio/features/project_audio/domain/project_audio_port.dart';
import 'package:avelune_studio/features/project_cs/domain/project_cs_port.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_session_controllers.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_visual_projection_queue.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_workflow.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/project_settings/application/project_settings_session_controller.dart';
import 'package:avelune_studio/features/project_surf/application/project_surf_controller.dart';
import 'package:avelune_studio/features/project_surf/domain/project_surf_port.dart';
import 'package:avelune_studio/features/project_visuals/application/project_visuals_controller.dart';
import 'package:avelune_studio/features/project_visuals/domain/project_visuals_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:avelune_studio/platform/rendering/contracts/map_workspace_visuals.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  test('Surf settings save without reloading maps or replacing pending ambience', () async {
    final port = _Port();
    final workspace = MapWorkspaceController(workspaceSession, port);
    addTearDown(workspace.dispose);
    await workspace.initialize();
    final active = workspace.active!;
    final visuals = ProjectVisualsController(session: workspaceSession, port: port);
    addTearDown(visuals.dispose);
    await visuals.open();
    final visualDraft = SpatialVisualPatch.fromJson({
      'weatherMode': 'fixed',
      'weatherKind': 'storm',
    });
    visuals.edit(visualDraft);
    final surf = ProjectSurfController(
      session: workspaceSession,
      port: port,
      dimension: ProjectDimension.threeD,
      onSaved: workspace.acceptSurfConfiguration,
    );
    addTearDown(surf.dispose);
    await surf.open();
    final session = ProjectSettingsSessionController(projectVisuals: visuals, surf: surf);
    addTearDown(session.dispose);
    final reads = port.reads, catalogs = port.catalogs, visualReads = port.visualReads;
    session.select(ProjectSettingsSection.fieldAbilities);
    surf.change(enabled: true);
    final actions = WorkspaceWorkflow(
      controller: workspace,
      isActive: () => true,
      changed: () {},
      resources: () => null,
      narrative: () => null,
      projectSurf: () => surf,
      confirmClose: () async => WorkspaceCloseChoice.cancel,
      flushFocus: () {},
      launchMap: (_, _) async {},
    );
    expect(actions.hasCatalogDependencyDraft, isTrue);
    expect(await session.save(ProjectSettingsSection.fieldAbilities), isTrue);
    expect(surf.dirty, isFalse);
    expect(actions.hasCatalogDependencyDraft, isFalse);
    expect(port.surfWrites, 1);
    expect(port.reads, reads);
    expect(port.catalogs, catalogs);
    expect(port.visualReads, visualReads);
    expect(port.visualWrites, 0);
    expect(workspace.active, same(active));
    expect(visuals.preview.value, same(visualDraft));
    expect(visuals.dirty, isTrue);
    expect(workspace.project!.settings.surf!.enabled, isTrue);
    final projected = workspace.visualProject;
    expect(workspace.visualProject, same(projected));
    session.select(ProjectSettingsSection.image);
    session.select(ProjectSettingsSection.fieldAbilities);
    await surf.open();
    expect(port.surfReads, 1);
    expect(surf.dirty, isFalse);
  });

  test('shared settings owners publish Surf without rebuilding visual resources', () async {
    final port = _Port();
    final workspace = MapWorkspaceController(workspaceSession, port);
    addTearDown(workspace.dispose);
    await workspace.initialize();
    final projected = workspace.visualProject;
    final active = workspace.active;
    final projectedChanges = <ProjectManifest?>[];
    final rendering = _observeProjection(workspace);
    final owners = WorkspaceSessionControllers(
      controller: workspace,
      changed: () {},
      visualCatalogChanged: (value) {
        projectedChanges.add(value);
        rendering.queue.acknowledgeDefinitions(value);
      },
      flushEditors: () async => true,
    );
    addTearDown(owners.dispose);
    final surf = owners.surfOwner!;
    final visuals = owners.visualOwner;
    await surf.open();
    await visuals.open();
    final session = ProjectSettingsSessionController(projectVisuals: visuals, surf: surf);
    addTearDown(session.dispose);
    final reads = port.reads, catalogs = port.catalogs;
    surf.change(enabled: false);
    expect(await session.save(ProjectSettingsSection.fieldAbilities), isTrue);
    expect(port.surfWrites, 1);
    expect(workspace.project!.settings.surf!.enabled, isFalse);
    expect(workspace.active, same(active));
    expect(projectedChanges, [same(workspace.visualProject)]);
    expect(workspace.visualProject!.elements, projected!.elements);
    expect(rendering.visuals.updates, 0);
    expect(rendering.visuals.mapUpdates, 0);
    expect(port.reads, reads);
    expect(port.catalogs, catalogs);
    expect(port.visualWrites, 0);
  });

  test('CS and sound revisions compose through shared settings owners without reloading maps', () async {
    final port = _CsAudioPort();
    final workspace = MapWorkspaceController(workspaceSession, port);
    addTearDown(workspace.dispose);
    await workspace.initialize();
    final projected = workspace.visualProject;
    final active = workspace.active;
    final projectedChanges = <ProjectManifest?>[];
    final rendering = _observeProjection(workspace);
    final owners = WorkspaceSessionControllers(
      controller: workspace,
      changed: () {},
      visualCatalogChanged: (value) {
        projectedChanges.add(value);
        rendering.queue.acknowledgeDefinitions(value);
      },
      flushEditors: () async => true,
    );
    addTearDown(owners.dispose);
    final cs = owners.csOwner!, surf = owners.surfOwner!, audio = owners.audioOwner!;
    final visuals = owners.visualOwner;
    await cs.open();
    await surf.open();
    await audio.open();
    await visuals.open();
    final session = ProjectSettingsSessionController(
      projectVisuals: visuals,
      fieldAbilities: cs,
      surf: surf,
      audio: audio,
    );
    addTearDown(session.dispose);
    final reads = port.reads, catalogs = port.catalogs;
    for (final id in ['rock_climb', 'defog']) {
      cs.setEnabledId(id, false);
    }
    audio.source(ProjectSoundCue.uiConfirm, 'builtin');
    expect(await session.save(ProjectSettingsSection.sounds), isTrue);
    expect(await session.save(ProjectSettingsSection.fieldAbilities), isTrue);
    expect(port.revision, 3);
    expect(workspace.project!.settings.fieldAbilities!.disabledAbilityIds, {'rock_climb', 'defog'});
    expect(workspace.project!.settings.audio!.cues[ProjectSoundCue.uiConfirm]!.source, ProjectSoundSource.builtin);
    expect(port.reads, reads);
    expect(port.catalogs, catalogs);
    expect(workspace.active, same(active));
    expect(workspace.visualProject!.elements, projected!.elements);
    expect(projectedChanges, hasLength(3));
    expect(projectedChanges.last, same(workspace.visualProject));
    expect(rendering.visuals.updates, 0);
    expect(rendering.visuals.mapUpdates, 0);
  });
}

({_Visuals visuals, WorkspaceVisualProjectionQueue queue}) _observeProjection(
  MapWorkspaceController workspace,
) {
  final visuals = _Visuals();
  final queue = WorkspaceVisualProjectionQueue(
    currentVisuals: () => visuals,
    activeMap: () => workspace.active?.current,
    isActive: () => !workspace.isDisposed,
    prepared: (_) {},
    failed: (error) => throw error,
    changed: () {},
  );
  queue.acknowledgeDefinitions(workspace.visualProject);
  queue.preparedMap = workspace.active?.current;
  void changed() => queue.synchronize(workspace.visualProject);
  workspace.addListener(changed);
  addTearDown(() => workspace.removeListener(changed));
  return (visuals: visuals, queue: queue);
}

class _Visuals extends WorkspaceTestVisuals implements ResourceWorkspaceVisuals {
  int updates = 0, mapUpdates = 0;

  @override
  void setActiveMap(MapData map) {
    mapUpdates++;
  }

  @override
  void setTerrainBrush(ProjectSmartTilePreset? preset) {}

  @override
  Widget atlasPreview(String id) => const SizedBox();

  @override
  Future<void> updateCatalog(
    ProjectManifest manifest, {
    Set<String> changedRelativePaths = const {},
  }) async {
    updates++;
  }
}

class _Port extends WorkspaceMemoryPort
    implements ProjectSurfPort, ProjectVisualsPort {
  int surfReads = 0, surfWrites = 0, visualReads = 0, visualWrites = 0;
  @override
  Future<MapWorkspaceDocument> loadMap(
    ProjectSession session,
    ProjectMapEntry entry,
  ) async {
    final result = await super.loadMap(session, entry);
    return MapWorkspaceDocument(
      map: result.map.copyWith(
        spatialScene: MapSpatialScene(width: 20, depth: 16),
      ),
      revision: result.revision,
      mapId: entry.id,
    );
  }

  @override
  Future<ProjectSurfState> loadSurf(session) async {
    surfReads++;
    return const ProjectSurfState(configuration: null, revision: '0');
  }

  @override
  Future<ProjectSurfState> saveSurf(
    session,
    ProjectSurfSettings? configuration,
    String revision,
  ) async {
    surfWrites++;
    return ProjectSurfState(
      configuration: configuration,
      revision: '$surfWrites',
    );
  }

  @override
  Future<ProjectSurfReferences> loadSurfReferences(session) async =>
      const ProjectSurfReferences();
  @override
  Future<NarrativeFactDefinition> loadSurfFact(session, String id) =>
      throw UnimplementedError();
  @override
  Future<ProjectVisualsState> loadVisuals(
    session, {
    ProjectMapEntry? map,
  }) async {
    visualReads++;
    return ProjectVisualsState(
      profile: SpatialVisualPatch(),
      revision: 'visual',
    );
  }

  @override
  Future<ProjectVisualsState> saveVisuals(
    session,
    SpatialVisualPatch profile,
    String revision, {
    ProjectMapEntry? map,
  }) async {
    visualWrites++;
    return ProjectVisualsState(profile: profile, revision: 'visual-saved');
  }

  @override
  Future<ProjectVisualsState> undoVisuals(
    session,
    String id,
    String revision, {
    ProjectMapEntry? map,
  }) => throw UnimplementedError();
}

class _CsAudioPort extends _Port implements ProjectCsPort, ProjectAudioPort {
  @override
  Future<ProjectAudioPage> queryLegacyAudio(
    session, {
    String query = '',
    String? cursor,
  }) async => const ProjectAudioPage(entries: []);
  @override
  Future<ProjectAudioImport> adoptAudioAsset(
    session,
    String assetId,
    String mediaId,
    String label,
    String expectedRevision,
  ) => throw UnimplementedError();
  int revision = 0;
  ProjectAudioSettings? audio;
  ProjectFieldAbilitiesSettings? cs;
  @override
  Future<ProjectSurfState> loadSurf(session) async =>
      ProjectSurfState(configuration: null, revision: '$revision');
  @override
  Future<ProjectCsState> loadFieldAbilities(session) async =>
      ProjectCsState(configuration: cs, revision: '$revision');
  @override
  Future<ProjectAudioState> loadAudio(session) async =>
      ProjectAudioState(configuration: audio, revision: '$revision');
  @override
  Future<ProjectCsState> saveFieldAbility(
    session,
    FieldAbility ability,
    bool enabled,
    String expectedRevision,
  ) => saveFieldAbilityId(session, ability.moveId, enabled, expectedRevision);

  @override
  Future<ProjectCsState> saveFieldAbilityId(
    session,
    String abilityId,
    bool enabled,
    String expectedRevision,
  ) async {
    expect(expectedRevision, '$revision');
    final disabled = {...?cs?.disabledAbilityIds};
    enabled ? disabled.remove(abilityId) : disabled.add(abilityId);
    cs = ProjectFieldAbilitiesSettings.fromIds(disabled);
    revision++;
    return ProjectCsState(configuration: cs, revision: '$revision');
  }

  @override
  Future<ProjectAudioState> saveAudioCue(
    session,
    ProjectSoundCue cue,
    ProjectSoundBinding? binding,
    String expectedRevision,
  ) async {
    expect(expectedRevision, '$revision');
    audio = (audio ?? ProjectAudioSettings()).withCue(cue, binding);
    revision++;
    return ProjectAudioState(configuration: audio, revision: '$revision');
  }

  @override
  Future<ProjectAudioPage> queryAudio(
    session, {
    String query = '',
    String? cursor,
  }) async => const ProjectAudioPage(entries: []);
  @override
  Future<ProjectAudioFile> resolveAudio(session, String id) =>
      throw UnimplementedError();
  @override
  Future<ProjectAudioImport> importAudio(
    session,
    String sourcePath,
    String label,
    String expectedRevision,
  ) => throw UnimplementedError();
}
