import 'dart:async';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/project_settings/application/project_settings_preview_controller.dart';
import 'package:avelune_studio/features/project_settings/application/project_settings_session_controller.dart';
import 'package:avelune_studio/features/project_visuals/application/project_visuals_controller.dart';
import 'package:avelune_studio/features/project_visuals/domain/project_visuals_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/map_workspace_fixture.dart';

Future<ProjectSettingsPreviewController> _open(_Maps maps) async {
  final workspace = MapWorkspaceController(workspaceSession, maps);
  addTearDown(workspace.dispose);
  await workspace.initialize();
  final owner = ProjectVisualsController(session: workspaceSession, port: maps);
  addTearDown(owner.dispose);
  await owner.open();
  final session = ProjectSettingsSessionController(
    projectVisuals: owner,
    mapVisuals: (id) => workspace.documents[id] == null
        ? null
        : workspace.weatherDraftFor(workspace.documents[id]!),
  );
  addTearDown(session.dispose);
  final preview = ProjectSettingsPreviewController(
    workspace: workspace,
    owner: owner,
    session: session,
  );
  addTearDown(preview.dispose);
  await preview.start();
  return preview;
}

void main() {
  test('preview composes project and local drafts without saving or reloading on comparison', () async {
    final maps = _Maps();
    final preview = await _open(maps);
    preview.chooseScope('map');
    await Future<void>.delayed(Duration.zero);
    final draft = preview.mapDraft!;
    expect(draft.saved, isNotNull);
    final reads = maps.visualReads, catalogs = maps.catalogs;
    final builds = preview.workspace.visualProjectionBuilds;
    draft.edit(
      draft.preview.value.set(SpatialVisualParameter.weatherKind, 'storm'),
    );
    expect(
      preview.rendered.value.choice(SpatialVisualParameter.weatherKind),
      'storm',
    );
    preview.compareSaved(true);
    expect(
      preview.rendered.value.choice(SpatialVisualParameter.weatherKind),
      'clear',
    );
    preview.compareSaved(false);
    expect(
      preview.rendered.value.choice(SpatialVisualParameter.weatherKind),
      'storm',
    );
    expect(maps.visualReads, reads);
    expect(maps.catalogs, catalogs);
    expect(maps.writes, 0);
    expect(maps.visualWrites, 0);
    expect(preview.workspace.visualProjectionBuilds, builds);
    expect(draft.dirty, isTrue);
  });

  test(
    'a dirty native map cannot start the visual test and retains its draft',
    () async {
      final maps = _Maps();
      final preview = await _open(maps);
      final document = preview.workspace.active!;
      expect(preview.preparePlaytest()?.entry.id, 'a');
      document.commit(document.current.copyWith(name: 'Travail conservé'));
      expect(preview.preparePlaytest(), isNull);
      expect(preview.testError, contains('Enregistrez d’abord'));
      expect(document.dirty, isTrue);
      expect(maps.writes, 0);
    },
  );

  test('a 2D preview returns local visual scope to project and preserves the project draft', () async {
    final maps = _Maps()..twoD.add('b');
    final preview = await _open(maps);
    preview.chooseScope('map');
    preview.owner.edit(
      preview.owner.preview.value.set(
        SpatialVisualParameter.weatherKind,
        'storm',
      ),
    );
    final draft = preview.owner.preview.value;
    await preview.choosePreview('b');
    expect(preview.previewSpatial, isFalse);
    expect(preview.session.scopeMapId, isNull);
    expect(preview.scopeNotice, contains('Tout le projet'));
    expect(preview.previewProblem, contains('n’a pas de rendu 3D'));
    expect(preview.owner.preview.value, draft);
    expect(preview.owner.dirty, isTrue);
    expect(preview.preparePlaytest(), isNull);
    expect(maps.visualWrites, 0);
    expect(maps.writes, 0);
  });

  test(
    'a late map read cannot replace the most recently selected preview',
    () async {
      final maps = _Maps();
      final preview = await _open(maps);
      preview.chooseScope('map');
      await Future<void>.delayed(Duration.zero);
      final retained = preview.mapDraft!;
      retained.edit(
        retained.preview.value.set(SpatialVisualParameter.weatherKind, 'rain'),
      );
      final gate = Completer<MapWorkspaceDocument>();
      maps.pending['b'] = gate;
      final opening = preview.choosePreview('b');
      expect(preview.previewSpatial, isFalse);
      expect(preview.mapDraft, isNull);
      expect(preview.session.scopeMapId, isNull);
      await Future<void>.delayed(Duration.zero);
      await preview.choosePreview('a');
      gate.complete(maps.document(workspaceEntries.last));
      await opening;
      expect(preview.preview!.id, 'a');
      expect(preview.workspace.active!.base.mapId, 'a');
      expect(preview.previewLoading, isFalse);
      expect(
        preview.rendered.value.choice(SpatialVisualParameter.weatherKind),
        'rain',
      );
      expect(preview.session.scopeMapId, 'a');
      expect(preview.mapDraft, same(retained));
      expect(retained.dirty, isTrue);
      expect(maps.writes, 0);
    },
  );

  test(
    'a failed visual load cannot launch another map with the previous profile',
    () async {
      final maps = _Maps();
      final preview = await _open(maps);
      preview.chooseScope('map');
      await Future<void>.delayed(Duration.zero);
      final retained = preview.mapDraft!;
      retained.edit(
        retained.preview.value.set(SpatialVisualParameter.weatherKind, 'rain'),
      );
      maps.failingPreviewVisuals.add('b');
      await preview.choosePreview('b');
      expect(preview.workspace.active!.base.mapId, 'b');
      expect(preview.previewProblem, contains('visual load failed'));
      expect(preview.preparePlaytest(), isNull);
      expect(preview.previewSpatial, isFalse);
      expect(preview.session.scopeMapId, isNull);
      expect(preview.mapDraft, isNull);
      expect(preview.local, SpatialVisualPatch());
      expect(retained.dirty, isTrue);
      expect(
        retained.preview.value.choice(SpatialVisualParameter.weatherKind),
        'rain',
      );
      maps.failingPreviewVisuals.remove('b');
      await preview.loadPreview(preview.preview!);
      expect(preview.previewProblem, isNull);
      expect(preview.preparePlaytest()?.entry.id, 'b');
      expect(
        preview.rendered.value.choice(SpatialVisualParameter.weatherKind),
        'storm',
      );
      expect(maps.writes, 0);
      expect(maps.visualWrites, 0);
    },
  );

  test('disposal prevents publication of a late preview response', () async {
    final maps = _Maps();
    final preview = await _open(maps);
    final gate = Completer<MapWorkspaceDocument>();
    maps.pending['b'] = gate;
    var notifications = 0;
    preview.addListener(() => notifications++);
    final opening = preview.choosePreview('b');
    await Future<void>.delayed(Duration.zero);
    preview.dispose();
    final before = notifications;
    gate.complete(maps.document(workspaceEntries.last));
    await opening;
    expect(notifications, before);
    expect(maps.writes, 0);
  });
}

class _Maps extends WorkspaceMemoryPort implements ProjectVisualsPort {
  final twoD = <String>{};
  final failingPreviewVisuals = <String>{};
  final mapVisualReads = <String, int>{};
  final pending = <String, Completer<MapWorkspaceDocument>>{};
  int visualReads = 0, visualWrites = 0;

  MapWorkspaceDocument document(ProjectMapEntry entry) => MapWorkspaceDocument(
    map: workspaceMap(entry.id).copyWith(
      spatialScene: twoD.contains(entry.id)
          ? null
          : MapSpatialScene(width: 20, depth: 16),
    ),
    revision: 'map-${entry.id}',
    mapId: entry.id,
  );

  @override
  Future<MapWorkspaceDocument> loadMap(
    ProjectSession session,
    ProjectMapEntry entry,
  ) async {
    reads++;
    return pending[entry.id]?.future ?? document(entry);
  }

  @override
  Future<ProjectVisualsState> loadVisuals(
    ProjectSession session, {
    ProjectMapEntry? map,
  }) async {
    visualReads++;
    if (map case final entry?) {
      final reads = mapVisualReads.update(
        entry.id,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
      if (failingPreviewVisuals.contains(entry.id) && reads > 1) {
        throw StateError('visual load failed');
      }
    }
    return ProjectVisualsState(
      profile: map == null
          ? SpatialVisualPatch()
          : SpatialVisualPatch.fromJson({
              'weatherKind': map.id == 'a' ? 'clear' : 'storm',
            }),
      revision: map?.id ?? 'project',
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
    return ProjectVisualsState(
      profile: profile,
      revision: 'saved-$visualWrites',
    );
  }

  @override
  Future<ProjectVisualsState> undoVisuals(
    ProjectSession session,
    String receiptId,
    String expectedRevision, {
    ProjectMapEntry? map,
  }) => throw UnimplementedError();
}
