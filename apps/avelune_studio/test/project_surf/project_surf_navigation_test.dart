import 'package:avelune_studio/features/project_audio/domain/project_audio_port.dart';
import 'package:avelune_studio/features/project_cs/domain/project_cs_port.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/project_surf/application/project_surf_controller.dart';
import 'package:avelune_studio/features/project_surf/domain/project_surf_port.dart';
import 'package:avelune_studio/features/project_visuals/application/project_visuals_controller.dart';
import 'package:avelune_studio/features/project_visuals/domain/project_visuals_port.dart';
import 'package:avelune_studio/presentation/features/map_workspace/workspace_actions.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_screen.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_layout.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_visuals.dart';
import 'package:avelune_studio/presentation/features/project_settings/project_settings_page.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  testWidgets(
    'Surf tab saves without reloading maps or replacing pending ambience',
    (tester) async {
      tester.view.physicalSize = const Size(1536, 1024);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final port = _Port();
      final workspace = MapWorkspaceController(workspaceSession, port);
      addTearDown(workspace.dispose);
      await workspace.initialize();
      final active = workspace.active!;
      final visuals = ProjectVisualsController(
        session: workspaceSession,
        port: port,
      );
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
      late BuildContext context;
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: Builder(
              builder: (value) {
                context = value;
                return ProjectSettingsPage(
                  workspace: workspace,
                  owner: visuals,
                  surfOwner: surf,
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final reads = port.reads,
          catalogs = port.catalogs,
          visualReads = port.visualReads;
      await tester.tap(find.text('CS'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('surf-enabled')));
      await tester.pump();
      final actions = WorkspaceActions(
        controller: workspace,
        context: () => context,
        mounted: () => true,
        changed: () {},
        resources: () => null,
        narrative: () => null,
        projectSurf: () => surf,
        runtimeBuilder: (_, _, _) => const SizedBox(),
      );
      expect(actions.hasCatalogDependencyDraft, isTrue);
      await tester.ensureVisible(
        find.byKey(const ValueKey('save-project-surf')),
      );
      await tester.tap(find.byKey(const ValueKey('save-project-surf')));
      await tester.pumpAndSettle();
      expect(surf.dirty, isFalse);
      expect(actions.hasCatalogDependencyDraft, isFalse);
      expect(port.surfWrites, 1);
      expect(port.reads, reads);
      expect(port.catalogs, catalogs);
      expect(port.visualReads, visualReads);
      expect(port.visualWrites, 0);
      expect(identical(workspace.active, active), isTrue);
      expect(visuals.preview.value, visualDraft);
      expect(visuals.dirty, isTrue);
      expect(workspace.project!.settings.surf!.enabled, isTrue);
      final projected = workspace.visualProject;
      expect(identical(workspace.visualProject, projected), isTrue);
      await tester.tap(find.text('Réglages'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('CS'));
      await tester.pumpAndSettle();
      expect(port.surfReads, 1);
      expect(surf.dirty, isFalse);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'the real settings route publishes Surf metadata without rebuilding visual resources',
    (tester) async {
      tester.view.physicalSize = const Size(1536, 1024);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final port = _Port();
      final workspace = MapWorkspaceController(workspaceSession, port);
      addTearDown(workspace.dispose);
      final visuals = _Visuals();
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: MapWorkspaceScreen(
            controller: workspace,
            loadVisuals: (_, _) async => visuals,
            runtimeBuilder: (_, _, _) => const SizedBox(),
            onClose: () async {},
            registerExitGuard: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      tester
          .widget<MapWorkspaceLayout>(find.byType(MapWorkspaceLayout))
          .onProjectSettings!();
      await tester.pumpAndSettle();
      await tester.tap(find.text('CS'));
      await tester.pumpAndSettle();
      final updates = visuals.updates, maps = visuals.mapUpdates;
      await tester.tap(find.byKey(const ValueKey('surf-enabled')));
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('save-project-surf')),
      );
      await tester.tap(find.byKey(const ValueKey('save-project-surf')));
      await tester.pumpAndSettle();
      expect(port.surfWrites, 1);
      expect(visuals.updates, updates);
      expect(visuals.mapUpdates, maps);
      expect(workspace.project!.settings.surf!.enabled, isFalse);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'CS and Son revisions compose through the real settings route without visual rebuild',
    (tester) async {
      tester.view.physicalSize = const Size(1536, 1024);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final port = _CsAudioPort();
      final workspace = MapWorkspaceController(workspaceSession, port);
      addTearDown(workspace.dispose);
      final visuals = _Visuals();
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: MapWorkspaceScreen(
            controller: workspace,
            loadVisuals: (_, _) async => visuals,
            runtimeBuilder: (_, _, _) => const SizedBox(),
            onClose: () async {},
            registerExitGuard: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      tester
          .widget<MapWorkspaceLayout>(find.byType(MapWorkspaceLayout))
          .onProjectSettings!();
      await tester.pumpAndSettle();
      final maps = port.reads,
          catalogs = port.catalogs,
          updates = visuals.updates,
          mapUpdates = visuals.mapUpdates;
      await tester.tap(find.text('CS'));
      await tester.pumpAndSettle();
      for (final id in ['rock_climb', 'defog']) {
        await tester.ensureVisible(find.byKey(ValueKey('cs-$id')));
        await tester.tap(find.byKey(ValueKey('cs-$id')));
        await tester.pump();
      }
      await tester.tap(find.text('Son'));
      await tester.pumpAndSettle();
      tester
          .widget<StudioSelect>(
            find.byKey(const ValueKey('project-audio-source-ui.confirm')),
          )
          .onChanged!('builtin');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('save-project-audio')),
      );
      await tester.tap(find.byKey(const ValueKey('save-project-audio')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('CS'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('save-project-cs')));
      await tester.tap(find.byKey(const ValueKey('save-project-cs')));
      await tester.pumpAndSettle();
      expect(port.revision, 3);
      expect(workspace.project!.settings.fieldAbilities!.disabledAbilityIds, {
        'rock_climb',
        'defog',
      });
      expect(
        workspace
            .project!
            .settings
            .audio!
            .cues[ProjectSoundCue.uiConfirm]!
            .source,
        ProjectSoundSource.builtin,
      );
      expect(port.reads, maps);
      expect(port.catalogs, catalogs);
      expect(visuals.updates, updates);
      expect(visuals.mapUpdates, mapUpdates);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
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

class _Visuals extends WorkspaceTestVisuals
    implements ResourceWorkspaceVisuals {
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
