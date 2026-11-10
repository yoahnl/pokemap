import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/project_visuals/application/project_visuals_controller.dart';
import 'package:avelune_studio/features/project_visuals/domain/project_visuals_port.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  test(
    'switching active map retains distinct weather draft ownership',
    () async {
      final workspace = MapWorkspaceController(workspaceSession, _Maps());
      addTearDown(workspace.dispose);
      await workspace.initialize();
      final original = workspace.active!;
      final owner = workspace.weatherDraftFor(original)!;
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      await workspace.activate(workspaceEntries.last);
      expect(workspace.active, isNot(same(original)));
      expect(workspace.weatherDraftFor(workspace.active!), isNot(same(owner)));
      expect(original.weatherVisuals, same(owner));
      expect(owner.dirty, isFalse);
    },
  );

  test(
    'unsaved map weather makes the workspace dirty without writing files',
    () async {
      final maps = _Maps();
      final workspace = MapWorkspaceController(workspaceSession, maps);
      addTearDown(workspace.dispose);
      await workspace.initialize();
      final owner = workspace.weatherDraftFor(workspace.active!)!;
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(owner.saved, isNotNull);
      owner.edit(
        SpatialVisualPatch.fromJson({
          'weatherMode': 'fixed',
          'weatherKind': 'storm',
        }),
      );
      expect(owner.dirty, isTrue);
      expect(workspace.dirty, isTrue);
      expect(maps.visualWrites, 0);
      expect(maps.writes, 0);
    },
  );

  test(
    'saving active map weather writes only the active visual document',
    () async {
      final maps = _Maps();
      final workspace = MapWorkspaceController(workspaceSession, maps);
      addTearDown(workspace.dispose);
      await workspace.initialize();
      await workspace.activate(workspaceEntries.last);
      final owner = workspace.weatherDraftFor(workspace.active!)!;
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      owner.edit(
        SpatialVisualPatch.fromJson({
          'weatherMode': 'fixed',
          'weatherKind': 'clear',
        }),
      );
      expect(
        workspace.active!.visualProfile.choice(
          SpatialVisualParameter.weatherKind,
        ),
        'clear',
      );
      final reads = maps.visualReads;
      final catalogs = maps.catalogs;
      expect(await workspace.save(workspace.active!), isTrue);
      expect(maps.lastVisualMap, workspaceEntries.last.id);
      expect(maps.visualWrites, 1);
      expect(maps.visualReads, reads);
      expect(maps.catalogs, catalogs);
      expect(maps.writes, 0);
    },
  );
  test('map ambiance draft survives panel changes and saves only its visual document', () async {
    final maps = _Maps();
    final workspace = MapWorkspaceController(workspaceSession, maps);
    addTearDown(workspace.dispose);
    await workspace.initialize();
    final document = workspace.active!;
    final owner = workspace.weatherDraftFor(document)!;
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    final catalogs = maps.catalogs;
    final writes = maps.writes;
    var workspaceNotifications = 0;
    workspace.addListener(() => workspaceNotifications++);
    owner.edit(
      owner.preview.value
          .set(SpatialVisualParameter.weatherMode, 'fixed')
          .set(SpatialVisualParameter.weatherKind, 'storm'),
    );
    expect(workspace.dirty, isTrue);
    expect(workspaceNotifications, 0);
    expect(identical(workspace.weatherDraftFor(document), owner), isTrue);
    expect(
      document.visualProfile.choice(SpatialVisualParameter.weatherKind),
      'storm',
    );
    await workspace.activate(workspaceEntries.last);
    await workspace.activate(workspaceEntries.first);
    expect(
      document.visualProfile.choice(SpatialVisualParameter.weatherKind),
      'storm',
    );
    final reads = maps.visualReads;
    expect(await workspace.save(document), isTrue);
    expect(maps.visualWrites, 1);
    expect(maps.lastVisualMap, document.base.mapId);
    expect(maps.visualReads, reads);
    expect(maps.catalogs, catalogs);
    expect(maps.writes, writes);
    expect(workspace.dirty, isFalse);
  });
  test('project visual settings load independently without reloading the map catalogue', () async {
    final maps = _Maps();
    final workspace = MapWorkspaceController(workspaceSession, maps);
    final settings = ProjectVisualsController(
      session: workspaceSession,
      port: maps,
    );
    addTearDown(workspace.dispose);
    addTearDown(settings.dispose);
    await workspace.initialize();
    final document = workspace.active!;
    final catalogs = maps.catalogs;
    await settings.open();
    expect(settings.saved, isNotNull);
    expect(settings.error, isNull);
    expect(workspace.active, same(document));
    expect(maps.catalogs, catalogs);
  });
}

class _Maps extends WorkspaceMemoryPort implements ProjectVisualsPort {
  int visualReads = 0, visualWrites = 0;
  String? lastVisualMap;
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

  @override
  Future<ProjectVisualsState> loadVisuals(
    ProjectSession session, {
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
    ProjectSession session,
    SpatialVisualPatch profile,
    String expectedRevision, {
    ProjectMapEntry? map,
  }) async {
    visualWrites++;
    lastVisualMap = map?.id;
    return ProjectVisualsState(profile: profile, revision: 'saved');
  }

  @override
  Future<ProjectVisualsState> undoVisuals(
    ProjectSession session,
    String receiptId,
    String expectedRevision, {
    ProjectMapEntry? map,
  }) => throw UnimplementedError();
}
