import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_atmosphere_port.dart';
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

class _VisualsPort extends WorkspaceMemoryPort
    implements ProjectVisualsPort, MapAtmospherePort {
  _VisualsPort() : super(manifest: _project);

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

MapData _spatial(String id) => MapData(
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

void main() {
  late _VisualsPort port;
  late MapWorkspaceController maps;
  late MapBuilderAmbianceBinding ambiance;
  late MapEditingViewportSession view;

  Future<void> open(WidgetTester tester, {required bool spatial}) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    port = _VisualsPort();
    port.saved['a'] = spatial ? _spatial('a') : workspaceMap('a');
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
              listenable: Listenable.merge([tick, ?ambiance.visuals]),
              builder: (context, _) => Column(
                children: [
                  MapBuilderHeader(
                    maps: maps,
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

  testWidgets('a map keeps the project clock or fixes its own hour', (
    tester,
  ) async {
    await open(tester, spatial: true);

    expect(
      find.byKey(const ValueKey('map-space-rubric-dayNight')),
      findsOneWidget,
    );
    expect(
      find.text('Le projet suit l’heure réelle de l’appareil.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<StudioChoice>(
            find.byKey(const ValueKey('map-ambiance-time-inherit')),
          )
          .selected,
      isTrue,
    );
    expect(find.byKey(const ValueKey('map-ambiance-time-hour')), findsNothing);
    expect(maps.dirty, isFalse);

    await tester.tap(find.byKey(const ValueKey('map-ambiance-time-fixed')));
    await tester.pump();
    expect(patch().choice(SpatialVisualParameter.timeMode), 'fixed');
    expect(find.text('Heure · 12:00'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('map-ambiance-time-preset-1380')),
    );
    await tester.pump();
    expect(patch().number(SpatialVisualParameter.minuteOfDay), 1380);
    expect(find.text('Heure · 23:00'), findsOneWidget);
    expect(
      maps.active!.visualProfile.number(SpatialVisualParameter.minuteOfDay),
      1380,
    );
    expect(maps.dirty, isTrue);

    bar(tester).onUndo!();
    await tester.pump();
    expect(patch().number(SpatialVisualParameter.minuteOfDay), 720);
    expect(patch().choice(SpatialVisualParameter.timeMode), 'fixed');
    bar(tester).onRedo!();
    await tester.pump();
    expect(patch().number(SpatialVisualParameter.minuteOfDay), 1380);

    expect(await maps.saveAll(), isTrue);
    expect(port.mapPatches['a']!.toJson(), {
      'timeMode': 'fixed',
      'minuteOfDay': 1380.0,
    });
    expect(port.saved['a'], _spatial('a'));
    expect(maps.dirty, isFalse);

    await tester.tap(find.byKey(const ValueKey('map-ambiance-time-inherit')));
    await tester.pump();
    expect(patch().toJson(), isEmpty);
    expect(find.byKey(const ValueKey('map-ambiance-time-hour')), findsNothing);
  });

  testWidgets('a map keeps the project weather or fixes its own sky', (
    tester,
  ) async {
    await open(tester, spatial: true);
    await tester.tap(find.byKey(const ValueKey('map-space-rubric-weather')));
    await tester.pump();

    expect(find.text('Le projet suit la météo réelle.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('map-ambiance-weather-kind-rain')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('map-ambiance-weather-fixed')));
    await tester.pump();
    expect(patch().choice(SpatialVisualParameter.weatherMode), 'fixed');
    expect(patch().choice(SpatialVisualParameter.weatherKind), 'rain');
    expect(
      find.byKey(const ValueKey('map-ambiance-weather-kind-rain')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('map-ambiance-weather-fixed')));
    await tester.pump();
    expect(patch().choice(SpatialVisualParameter.weatherKind), 'rain');

    await tester.tap(
      find.byKey(const ValueKey('map-ambiance-weather-kind-storm')),
    );
    await tester.pump();
    expect(patch().choice(SpatialVisualParameter.weatherKind), 'storm');
    expect(
      find.byKey(const ValueKey('map-ambiance-weather-lightning')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('map-ambiance-weather-sound')));
    await tester.pump();
    expect(patch().enabled(SpatialVisualParameter.weatherSoundEnabled), isTrue);

    await tester.tap(
      find.byKey(const ValueKey('map-ambiance-weather-kind-clear')),
    );
    await tester.pump();
    expect(patch().choice(SpatialVisualParameter.weatherKind), 'clear');
    expect(patch().enabled(SpatialVisualParameter.weatherEnabled), isFalse);
    expect(
      find.byKey(const ValueKey('map-ambiance-weather-intensity')),
      findsNothing,
    );

    bar(tester).onUndo!();
    await tester.pump();
    expect(patch().choice(SpatialVisualParameter.weatherKind), 'storm');
    expect(patch().enabled(SpatialVisualParameter.weatherSoundEnabled), isTrue);

    expect(await maps.saveAll(), isTrue);
    expect(
      port.mapPatches['a']!.choice(SpatialVisualParameter.weatherKind),
      'storm',
    );

    await tester.tap(
      find.byKey(const ValueKey('map-ambiance-weather-inherit')),
    );
    await tester.pump();
    expect(patch().toJson(), isEmpty);
  });

  testWidgets('each effect follows the project or takes its own setting', (
    tester,
  ) async {
    await open(tester, spatial: true);
    await tester.tap(find.byKey(const ValueKey('map-space-rubric-effects')));
    await tester.pump();

    expect(find.text('Activé · comme le projet'), findsNWidgets(2));
    expect(
      find.byKey(const ValueKey('map-ambiance-effect-detail-halos')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('map-ambiance-effect-toggle')),
      findsNothing,
    );

    await tester.tap(find.text('Cette carte'));
    await tester.pump();
    expect(patch().enabled(SpatialVisualParameter.halosEnabled), isTrue);
    expect(patch().number(SpatialVisualParameter.haloStrength), 1.06);
    expect(
      find.byKey(const ValueKey('map-ambiance-effect-level-haloStrength')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('map-ambiance-effect-toggle')));
    await tester.pump();
    expect(patch().enabled(SpatialVisualParameter.halosEnabled), isFalse);
    expect(find.text('Désactivé · propre à la carte'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('map-ambiance-effect-level-haloStrength')),
      findsNothing,
    );

    await tester.tap(
      find.byKey(const ValueKey('map-ambiance-effect-fireflies')),
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey('map-ambiance-effect-detail-halos')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('map-ambiance-effect-detail-fireflies')),
      findsOneWidget,
    );

    bar(tester).onUndo!();
    await tester.pump();
    expect(patch().enabled(SpatialVisualParameter.halosEnabled), isTrue);
    bar(tester).onRedo!();
    await tester.pump();

    expect(await maps.saveAll(), isTrue);
    final saved = port.mapPatches['a']!;
    expect(saved.enabled(SpatialVisualParameter.halosEnabled), isFalse);
    expect(saved.number(SpatialVisualParameter.haloStrength), 1.06);
    expect(saved.number(SpatialVisualParameter.haloSpread), isNotNull);
    expect(saved.values.keys, hasLength(3));

    await tester.tap(find.byKey(const ValueKey('map-ambiance-effect-halos')));
    await tester.pump();
    await tester.tap(find.text('Projet'));
    await tester.pump();
    expect(patch().toJson(), isEmpty);
  });

  testWidgets('effect sources come from the canvas and share the tab history', (
    tester,
  ) async {
    await open(tester, spatial: true);
    await tester.tap(find.byKey(const ValueKey('map-space-rubric-effects')));
    await tester.pump();
    SpatialAtmosphereSettings sources() => maps.active!.atmosphere!.current;
    Finder key(String value) => find.byKey(ValueKey(value));

    expect(find.text('Aucun halo placé sur cette carte.'), findsOneWidget);
    expect(key('map-ambiance-source-hint'), findsOneWidget);
    expect(key('map-ambiance-source-add-halo'), findsNothing);

    view.select(maps.active!, MapSelectionFamily.decor, 'lamp-1');
    ambiance.changed();
    await tester.pump();
    expect(find.text('Lanterne'), findsOneWidget);

    await tester.tap(find.text('Cette carte'));
    await tester.pump();
    await tester.tap(key('map-ambiance-source-add-halo'));
    await tester.pump();
    expect(sources().halos.single.instanceId, 'lamp-1');
    expect(find.text('1 halo placé sur cette carte.'), findsOneWidget);
    expect(key('map-ambiance-source-0'), findsOneWidget);

    bar(tester).onUndo!();
    await tester.pump();
    expect(sources().halos, isEmpty);
    expect(patch().toJson(), isNotEmpty);
    bar(tester).onUndo!();
    await tester.pump();
    expect(patch().toJson(), isEmpty);
    expect(bar(tester).onUndo, isNull);
    bar(tester).onRedo!();
    await tester.pump();
    expect(patch().toJson(), isNotEmpty);
    expect(sources().halos, isEmpty);
    bar(tester).onRedo!();
    await tester.pump();
    expect(sources().halos, hasLength(1));

    bar(tester).onUndo!();
    await tester.pump();
    expect(bar(tester).onRedo, isNotNull);
    await tester.tap(key('map-ambiance-effect-toggle'));
    await tester.pump();
    expect(bar(tester).onRedo, isNull);
    expect(sources().halos, isEmpty);

    await tester.tap(key('map-ambiance-source-add-halo'));
    await tester.pump();
    await tester.tap(key('map-ambiance-source-remove-0'));
    await tester.pump();
    expect(sources().halos, isEmpty);
    await tester.tap(key('map-ambiance-source-add-halo'));
    await tester.pump();

    await tester.tap(key('map-ambiance-effect-water'));
    await tester.pump();
    await tester.tap(key('map-ambiance-material-lamp-1-verre'));
    await tester.pump();
    expect(sources().waterTargets.single.materialName, 'verre');
    expect(find.text('verre · Lanterne'), findsOneWidget);
    await tester.tap(key('map-ambiance-material-lamp-1-verre'));
    await tester.pump();
    expect(sources().waterTargets, isEmpty);

    await tester.tap(key('map-ambiance-effect-windows'));
    await tester.pump();
    await tester.tap(key('map-ambiance-material-lamp-1-fer'));
    await tester.pump();
    expect(sources().windows.single.target.materialName, 'fer');

    await tester.tap(key('map-ambiance-effect-fireflies'));
    await tester.pump();
    expect(key('map-ambiance-source-hint'), findsNothing);
    await tester.tap(key('map-ambiance-source-cover-map'));
    await tester.pump();
    expect(sources().fireflyZones, hasLength(1));
    expect(find.text('Toute la carte'), findsOneWidget);
    expect(key('map-ambiance-source-cover-map'), findsNothing);

    expect(await maps.saveAll(), isTrue);
    final saved = port.atmospheres['a']!;
    expect(saved.halos.single.instanceId, 'lamp-1');
    expect(saved.windows, hasLength(1));
    expect(saved.waterTargets, isEmpty);
    expect(saved.fireflyZones, hasLength(1));
    expect(port.saved['a'], _spatial('a'));

    view.clearSelection(maps.active!);
    ambiance.changed();
    await tester.pump();
    await tester.tap(key('map-ambiance-source-remove-0'));
    await tester.pump();
    expect(sources().fireflyZones, isEmpty);
    expect(key('map-ambiance-source-cover-map'), findsOneWidget);
  });

  testWidgets('a custom clock override is announced and can be replaced', (
    tester,
  ) async {
    await open(tester, spatial: true);
    port.mapPatches['a'] = SpatialVisualPatch.fromJson({
      'timeMode': 'cycle',
      'dayDurationSeconds': 300,
    });
    await ambiance.visuals!.open(map: workspaceEntries.first);
    await tester.pump();

    expect(
      find.text(
        'Cette carte a un réglage d’horloge personnalisé. Choisissez une option pour le remplacer.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('map-ambiance-time-fixed')));
    await tester.pump();
    expect(patch().toJson(), {'timeMode': 'fixed', 'minuteOfDay': 720.0});
  });

  testWidgets('a 2D map says ambience needs a 3D map', (tester) async {
    await open(tester, spatial: false);

    expect(find.text('L’ambiance se règle sur les cartes 3D.'), findsOneWidget);
    expect(ambiance.visuals, isNull);
    expect(bar(tester).onUndo, isNull);
  });
}
