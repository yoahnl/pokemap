import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/project_settings/application/project_settings_session_controller.dart';
import 'package:avelune_studio/features/project_visuals/application/project_visuals_controller.dart';
import 'package:avelune_studio/features/project_visuals/application/spatial_visual_editing.dart';
import 'package:avelune_studio/features/project_visuals/domain/project_visuals_port.dart';
import 'package:avelune_studio/features/map_workspace/application/map_atmosphere_editing.dart';
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

  test(
    'resetting a scoped field preserves the other local overrides',
    () async {
      final entry = workspaceEntries.first;
      final storage = _Storage()
        ..project = SpatialVisualPatch().set(_distance, 24.0)
        ..maps[entry.id] = SpatialVisualPatch()
            .set(_distance, 10.0)
            .set(SpatialVisualParameter.windowsLit, false);
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
      await local.open(map: entry);
      final settings = ProjectSettingsSessionController(
        projectVisuals: project,
        mapVisuals: (id) => id == entry.id ? local : null,
        initialSection: ProjectSettingsSection.image,
      );
      addTearDown(settings.dispose);
      settings.scopeTo(entry.id);
      SpatialVisualEditing editing() => SpatialVisualEditing(
        patch: local.preview.value,
        inherited: project.preview.value,
        onChanged: local.edit,
      );
      expect(editing().patch.number(_distance), 10);
      editing().inherit(_distance);
      expect(editing().patch.value(_distance), isNull);
      expect(editing().effective.number(_distance), 24);
      expect(
        editing().patch.enabled(SpatialVisualParameter.windowsLit),
        isFalse,
      );
      expect(await settings.save(ProjectSettingsSection.image), isTrue);
      expect(storage.maps[entry.id]!.value(_distance), isNull);
      expect(
        storage.maps[entry.id]!.enabled(SpatialVisualParameter.windowsLit),
        isFalse,
      );
      expect(storage.mapWrites, {entry.id: 1});
      expect(storage.projectWrites, 0);
      expect(storage.writes, 0);
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
