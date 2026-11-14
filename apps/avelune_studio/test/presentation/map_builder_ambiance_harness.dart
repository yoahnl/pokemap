import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_draft.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_atmosphere_port.dart';
import 'package:avelune_studio/features/project_audio/domain/project_audio_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/project_visuals/domain/project_visuals_port.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_ambiance_binding.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_ambiance_inspector.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_header.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_space_outline.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_space.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_space_panel.dart';
import 'package:avelune_studio/presentation/shell/studio_top_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

late AmbianceVisualsPort port;
late MapWorkspaceController maps;
late MapBuilderAmbianceBinding ambiance;
late MapEditingViewportSession view;

Future<void> open(WidgetTester tester, {required bool spatial}) async {
  tester.view.physicalSize = const Size(1920, 1080);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  port = AmbianceVisualsPort();
  port.saved['a'] = spatial ? spatialMap('a') : workspaceMap('a');
  maps = MapWorkspaceController(workspaceSession, port);
  addTearDown(maps.dispose);
  final tick = ValueNotifier(0);
  addTearDown(tick.dispose);
  view = MapEditingViewportSession();
  ambiance = MapBuilderAmbianceBinding(
    maps: maps,
    changed: () => tick.value++,
    view: () => view,
  );
  addTearDown(ambiance.dispose);
  await maps.initialize();
  ambiance
    ..shown = true
    ..reconcile();
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: studioTheme(),
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ListenableBuilder(
            listenable: tick,
            builder: (context, _) => Column(
              children: [
                MapBuilderHeader(
                  maps: maps,
                  draft: MapWorkspaceDraft(maps),
                  projectName: 'Ambiance',
                  editable: true,
                  saveFailed: false,
                  onSave: () {},
                  onTestMap: () {},
                  testing: false,
                  ambiance: ambiance,
                ),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      MapBuilderSpacePanel(
                        outline: mapBuilderSpaceOutline(
                          MapBuilderSpace.ambiance,
                          AppLocalizations.of(context),
                        )!,
                        liveRubrics: mapBuilderAmbianceRubrics,
                        selectedRubric: ambiance.rubric,
                        onRubric: ambiance.openRubric,
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          child: MapBuilderAmbianceInspector(
                            binding: ambiance,
                            enabled: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  for (var frame = 0; frame < 4; frame++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

SpatialVisualPatch patch() => ambiance.visuals!.preview.value;

StudioTopBar bar(WidgetTester tester) =>
    tester.widget(find.byType(StudioTopBar));

class AmbianceVisualsPort extends WorkspaceMemoryPort
    implements ProjectVisualsPort, MapAtmospherePort, ProjectAudioPort {
  AmbianceVisualsPort() : super(manifest: _project);

  var project = SpatialVisualPatch.fromJson({
    'timeMode': 'real',
    'dayNightEnabled': true,
    'minuteOfDay': 720,
    'weatherMode': 'real',
    'weatherEnabled': true,
    'weatherLightning': true,
    'halosEnabled': true,
    'haloStrength': 1.06,
    'fireflies': true,
  });
  final mapPatches = <String, SpatialVisualPatch>{};
  final atmospheres = <String, SpatialAtmosphereSettings>{};
  final sounds = const [
    ProjectAudioEntry(
      id: 'town',
      label: 'theme.wav',
      path: 'assets/audio/johto/bourg/theme.wav',
    ),
    ProjectAudioEntry(
      id: 'battle',
      label: 'combat.wav',
      path: 'assets/audio/johto/arene/combat.wav',
    ),
    ProjectAudioEntry(
      id: 'title',
      label: 'titre.m4a',
      path: 'presentation/demarrage/titre.m4a',
    ),
  ];

  @override
  Future<ProjectAudioPage> queryLegacyAudio(
    ProjectSession session, {
    String query = '',
    String? cursor,
  }) async => ProjectAudioPage(
    entries: [
      for (final entry in sounds)
        if (entry.path!.contains(query.trim())) entry,
    ],
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
  var revision = 0;

  @override
  Future<MapAtmosphereState> loadAtmosphere(
    ProjectSession session,
    String mapId,
  ) async => MapAtmosphereState(
    settings: atmospheres[mapId] ?? SpatialAtmosphereSettings(),
    revision: 'a$revision',
  );

  @override
  Future<MapAtmosphereState> saveAtmosphere(
    ProjectSession session,
    String mapId,
    SpatialAtmosphereSettings settings,
    String expectedRevision,
  ) async {
    atmospheres[mapId] = settings;
    return MapAtmosphereState(settings: settings, revision: 'a${++revision}');
  }

  @override
  Future<ProjectVisualsState> loadVisuals(
    ProjectSession session, {
    ProjectMapEntry? map,
  }) async => ProjectVisualsState(
    profile: map == null ? project : mapPatches[map.id] ?? SpatialVisualPatch(),
    revision: 'v$revision',
  );

  @override
  Future<ProjectVisualsState> saveVisuals(
    ProjectSession session,
    SpatialVisualPatch profile,
    String expectedRevision, {
    ProjectMapEntry? map,
  }) async {
    if (map == null) {
      project = profile;
    } else {
      mapPatches[map.id] = profile;
    }
    return ProjectVisualsState(profile: profile, revision: 'v${++revision}');
  }

  @override
  Future<ProjectVisualsState> undoVisuals(
    ProjectSession session,
    String receiptId,
    String expectedRevision, {
    ProjectMapEntry? map,
  }) => throw UnimplementedError();
}

final _project = ProjectManifest(
  name: 'Ambiance',
  version: ProjectVersion.v9,
  settings: const ProjectSettings(dimension: ProjectDimension.threeD),
  maps: workspaceEntries,
  tilesets: const [],
  models3d: [
    ProjectModel3dEntry(
      id: 'lantern',
      name: 'Lanterne',
      sourceAssetId: 'lantern-source',
      relativePath: 'assets/models3d/lantern.glb',
      inspection: Model3dInspection(
        bounds: Model3dBounds(
          min: Model3dVector3(x: -.2, y: 0, z: -.2),
          max: Model3dVector3(x: .2, y: 1.6, z: .2),
        ),
        meshCount: 1,
        triangleCount: 4,
        materials: [
          Model3dMaterial(index: 0, name: 'verre'),
          Model3dMaterial(index: 1, name: 'fer'),
        ],
      ),
    ),
  ],
);

MapData spatialMap(String id) => MapData(
  id: id,
  name: id,
  version: ProjectVersion.v9,
  size: const GridSize(width: 8, height: 6),
  spatialScene: MapSpatialScene(
    width: 8,
    depth: 6,
    instances: [
      SpatialModelInstance(
        id: 'lamp-1',
        modelId: 'lantern',
        position: Model3dVector3(x: 2.5, y: 0, z: 2.5),
      ),
    ],
  ),
);
