import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/project_settings/application/project_settings_session_controller.dart';
import 'package:avelune_studio/features/project_visuals/application/project_visuals_controller.dart';
import 'package:avelune_studio/features/project_visuals/domain/project_visuals_port.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_atmosphere_settings_panel.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_camera_panel.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_day_night_panel.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_settings_inspector.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/features/project_settings/project_settings_page.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

const _distance = SpatialVisualParameter.cameraDistance;

void main() {
  test(
    'reset removes the local camera override and follows future defaults',
    () {
      final project24 = SpatialVisualPatch().set(_distance, 24.0);
      final local10 = SpatialVisualPatch().set(_distance, 10.0);
      expect(project24.overriddenBy(local10).number(_distance), 10.0);
      final project30 = project24.set(_distance, 30.0);
      expect(project30.overriddenBy(local10).number(_distance), 10.0);
      final inherited = local10.set(_distance, null);
      expect(inherited.toJson().containsKey('cameraDistance'), isFalse);
      expect(project30.overriddenBy(inherited).number(_distance), 30.0);
      final project32 = project30.set(_distance, 32.0);
      expect(project32.overriddenBy(inherited).number(_distance), 32.0);
      final local = SpatialVisualPatch()
          .set(_distance, 10.0)
          .set(SpatialVisualParameter.windowsLit, false);
      final reset = local.set(_distance, null);
      expect(reset.number(_distance), isNull);
      expect(reset.enabled(SpatialVisualParameter.windowsLit), isFalse);
    },
  );

  test('project 24 map 10, project 30 map 10, reset 30, project 32 map 32, after reopening', () async {
    final storage = _Storage()
      ..project = SpatialVisualPatch().set(_distance, 24.0);
    final mapA = workspaceEntries.first, mapB = workspaceEntries.last;
    final project = ProjectVisualsController(
      session: workspaceSession,
      port: storage,
    );
    final local = ProjectVisualsController(
      session: workspaceSession,
      port: storage,
    );
    addTearDown(project.dispose);
    addTearDown(local.dispose);
    await project.open();
    await local.open(map: mapA);
    final settings = ProjectSettingsSessionController(
      projectVisuals: project,
      mapVisuals: (id) => id == mapA.id ? local : null,
      initialSection: ProjectSettingsSection.image,
    );
    addTearDown(settings.dispose);
    double effective() => project.saved!.profile
        .overriddenBy(local.saved!.profile)
        .number(_distance)!;

    settings.scopeTo(mapA.id);
    local.edit(local.preview.value.set(_distance, 10.0));
    expect(await settings.save(ProjectSettingsSection.image), isTrue);
    expect(effective(), 10);

    settings.scopeTo(null);
    project.edit(project.preview.value.set(_distance, 30.0));
    expect(await settings.save(ProjectSettingsSection.image), isTrue);
    expect(effective(), 10);

    settings.scopeTo(mapA.id);
    local.edit(local.preview.value.set(_distance, null));
    expect(local.preview.value.number(_distance), isNull);
    settings.undo(ProjectSettingsSection.image);
    expect(local.preview.value.number(_distance), 10);
    settings.redo(ProjectSettingsSection.image);
    expect(await settings.save(ProjectSettingsSection.image), isTrue);
    expect(
      storage.maps[mapA.id]!.toJson().containsKey('cameraDistance'),
      isFalse,
    );
    expect(effective(), 30);

    settings.scopeTo(null);
    project.edit(project.preview.value.set(_distance, 32.0));
    expect(await settings.save(ProjectSettingsSection.image), isTrue);
    expect(effective(), 32);
    expect(storage.maps.containsKey(mapB.id), isFalse);
    expect(storage.mapWrites[mapA.id], 2);

    final reopenedProject = ProjectVisualsController(
      session: workspaceSession,
      port: storage,
    );
    final reopenedLocal = ProjectVisualsController(
      session: workspaceSession,
      port: storage,
    );
    addTearDown(reopenedProject.dispose);
    addTearDown(reopenedLocal.dispose);
    await reopenedProject.open();
    await reopenedLocal.open(map: mapA);
    expect(
      reopenedProject.saved!.profile
          .overriddenBy(reopenedLocal.saved!.profile)
          .number(_distance),
      32,
    );
    expect(reopenedLocal.saved!.profile.value(_distance), isNull);
  });

  test(
    'map effects say which ones image settings replace in game, and from where',
    () {
      expect(mapAtmosphereOverrides(SpatialVisualPatch(), null), isNull);
      final effective = SpatialVisualPatch()
          .set(SpatialVisualParameter.fogOpacity, .2)
          .set(SpatialVisualParameter.windowsLit, false);
      final local = SpatialVisualPatch().set(
        SpatialVisualParameter.windowsLit,
        false,
      );
      final notice = mapAtmosphereOverrides(effective, local)!;
      expect(notice, contains('brume (réglages du projet'));
      expect(notice, contains('fenêtres (dérogation propre à cette carte)'));
      expect(notice, isNot(contains('lucioles (')));
    },
  );

  test('undoing a saved reset restores the override, not a copy of the project value', () async {
    final storage = _Storage()
      ..project = SpatialVisualPatch().set(_distance, 30.0)
      ..maps[workspaceEntries.first.id] = SpatialVisualPatch().set(
        _distance,
        10.0,
      );
    final local = ProjectVisualsController(
      session: workspaceSession,
      port: storage,
    );
    addTearDown(local.dispose);
    await local.open(map: workspaceEntries.first);
    local.edit(local.preview.value.set(_distance, null));
    local.undo();
    expect(local.preview.value.number(_distance), 10);
    expect(local.dirty, isFalse);
  });

  testWidgets(
    'the map scope labels each value as local or inherited and resets one field',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final storage = _Storage()
        ..project = SpatialVisualPatch().set(_distance, 24.0)
        ..maps[workspaceEntries.first.id] = SpatialVisualPatch()
            .set(_distance, 10.0)
            .set(SpatialVisualParameter.windowsLit, false);
      final workspace = MapWorkspaceController(workspaceSession, storage);
      await workspace.initialize();
      final owner = ProjectVisualsController(
        session: workspaceSession,
        port: storage,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: ProjectSettingsPage(workspace: workspace, owner: owner),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('settings-section-image')));
      await tester.pumpAndSettle();
      tester
          .widget<StudioSelect>(find.byKey(const ValueKey('settings-scope')))
          .onChanged!('map');
      await tester.pumpAndSettle();
      final provenance = find.byKey(
        const ValueKey('visual-provenance-cameraDistance'),
      );
      expect(tester.widget<Text>(provenance).data, 'Propre à cette carte');
      final reset = find.byKey(const ValueKey('inherit-cameraDistance'));
      await tester.ensureVisible(reset);
      await tester.tap(reset);
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(provenance).data, 'Suit le projet');
      final local =
          workspace.documents[workspaceEntries.first.id]!.weatherVisuals!;
      expect(local.preview.value.value(_distance), isNull);
      expect(
        local.preview.value.enabled(SpatialVisualParameter.windowsLit),
        isFalse,
      );
      await tester.tap(find.byKey(const ValueKey('settings-section-save')));
      await tester.pumpAndSettle();
      expect(storage.maps[workspaceEntries.first.id]!.value(_distance), isNull);
      expect(
        storage.maps[workspaceEntries.first.id]!.enabled(
          SpatialVisualParameter.windowsLit,
        ),
        isFalse,
      );
      expect(storage.projectWrites, 0);
      expect(storage.writes, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      owner.dispose();
      workspace.dispose();
    },
  );
  EditableMapDocument mapDocument({bool spatial = true}) {
    final map = MapData(
      id: 'room',
      name: 'Salle des cartes',
      version: ProjectVersion.v9,
      size: const GridSize(width: 8, height: 8),
      spatialScene: spatial ? MapSpatialScene(width: 8, depth: 8) : null,
    );
    return EditableMapDocument(
      MapWorkspaceDocument(map: map, revision: 'initial', mapId: map.id),
    );
  }

  final settingsProject = ProjectManifest(
    name: 'World',
    maps: const [],
    tilesets: const [],
    settings: ProjectSettings(dimension: ProjectDimension.threeD),
  );

  testWidgets('the map scope splits Image, Temps and Jeu for a 3D map', (
    tester,
  ) async {
    final view = MapWorkspaceViewState();
    addTearDown(view.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: MapSettingsInspector(
              project: settingsProject,
              document: mapDocument(),
              view: view,
              onChanged: () {},
              onRenameMap: () {},
            ),
          ),
        ),
      ),
    );
    expect(find.text('RÉGLAGES DE CETTE CARTE'), findsOneWidget);
    expect(find.text('Salle des cartes'), findsOneWidget);
    for (final label in ['Image', 'Temps', 'Jeu']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.byType(MapCameraPanel), findsOneWidget);
    expect(find.byType(MapDayNightPanel), findsNothing);
    await tester.tap(find.text('Temps'));
    await tester.pumpAndSettle();
    expect(find.byType(MapCameraPanel), findsNothing);
    expect(find.text('Jour et nuit'), findsOneWidget);
    expect(find.byType(MapAtmosphereSettingsPanel), findsNothing);
    await tester.tap(find.text('Jeu'));
    await tester.pumpAndSettle();
    expect(find.text('Renommer la carte…'), findsOneWidget);
    expect(find.text('8 × 8 cases'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a 2D map only exposes its game settings', (tester) async {
    final view = MapWorkspaceViewState();
    addTearDown(view.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: MapSettingsInspector(
              project: settingsProject,
              document: mapDocument(spatial: false),
              view: view,
              onChanged: () {},
              onRenameMap: () {},
            ),
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('map-settings-tabs')), findsNothing);
    expect(find.textContaining('carte 2D'), findsOneWidget);
    expect(find.text('Renommer la carte…'), findsOneWidget);
    expect(find.byType(MapCameraPanel), findsNothing);
  });

  testWidgets(
    'Sélection / Carte shows the map settings and returns to a new selection',
    (tester) async {
      final view = MapWorkspaceViewState();
      addTearDown(view.dispose);
      final document = mapDocument();
      late StateSetter rebuild;
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: SizedBox(
              height: 700,
              child: StatefulBuilder(
                builder: (context, setState) {
                  rebuild = setState;
                  return MapInspectorScope(
                    document: document,
                    view: view,
                    width: 320,
                    selection: const Text('inspecteur de sélection'),
                    mapSettings: () => MapSettingsInspector(
                      project: settingsProject,
                      document: document,
                      view: view,
                      onChanged: () {},
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
      expect(find.byKey(const ValueKey('map-inspector-scope')), findsNothing);
      expect(find.text('inspecteur de sélection'), findsOneWidget);
      view.select(document, MapSelectionFamily.zone, 'zone-a');
      rebuild(() {});
      await tester.pumpAndSettle();
      expect(find.text('Sélection'), findsOneWidget);
      expect(find.text('inspecteur de sélection'), findsOneWidget);
      await tester.tap(find.text('Carte'));
      await tester.pumpAndSettle();
      expect(find.text('inspecteur de sélection'), findsNothing);
      expect(find.byType(MapSettingsInspector), findsOneWidget);
      expect(find.byType(MapCameraPanel), findsOneWidget);
      view.select(document, MapSelectionFamily.zone, 'zone-b');
      rebuild(() {});
      await tester.pumpAndSettle();
      expect(find.text('inspecteur de sélection'), findsOneWidget);
      expect(find.byType(MapSettingsInspector), findsNothing);
    },
  );
}

final class _Storage extends WorkspaceMemoryPort implements ProjectVisualsPort {
  SpatialVisualPatch project = SpatialVisualPatch();
  final maps = <String, SpatialVisualPatch>{};
  final mapWrites = <String, int>{};
  int projectWrites = 0;

  @override
  Future<MapWorkspaceDocument> loadMap(
    ProjectSession session,
    ProjectMapEntry entry,
  ) async {
    final value = await super.loadMap(session, entry);
    return MapWorkspaceDocument(
      map: value.map.copyWith(
        spatialScene: MapSpatialScene(width: 20, depth: 16),
      ),
      revision: value.revision,
      mapId: entry.id,
    );
  }

  String _revision(String? mapId) =>
      mapId == null ? 'p$projectWrites' : 'm$mapId${mapWrites[mapId] ?? 0}';

  @override
  Future<ProjectVisualsState> loadVisuals(
    ProjectSession session, {
    ProjectMapEntry? map,
  }) async => ProjectVisualsState(
    profile: map == null ? project : maps[map.id] ?? SpatialVisualPatch(),
    revision: _revision(map?.id),
  );

  @override
  Future<ProjectVisualsState> saveVisuals(
    ProjectSession session,
    SpatialVisualPatch profile,
    String expectedRevision, {
    ProjectMapEntry? map,
  }) async {
    if (expectedRevision != _revision(map?.id)) throw StateError('stale');
    if (map == null) {
      projectWrites++;
      project = profile;
    } else {
      mapWrites[map.id] = (mapWrites[map.id] ?? 0) + 1;
      maps[map.id] = profile;
    }
    return ProjectVisualsState(profile: profile, revision: _revision(map?.id));
  }

  @override
  Future<ProjectVisualsState> undoVisuals(
    ProjectSession session,
    String receiptId,
    String expectedRevision, {
    ProjectMapEntry? map,
  }) => throw UnimplementedError();

}
