import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/project_visuals/application/project_visuals_controller.dart';
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
