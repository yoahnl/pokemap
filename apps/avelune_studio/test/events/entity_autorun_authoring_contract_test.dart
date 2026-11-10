import 'package:avelune_studio/features/narrative/application/narrative_overview_context.dart';


import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/features/events/data/local_event_adapter.dart';
import 'package:map_core/map_core.dart';
import 'package:avelune_studio/features/events/domain/event_record_view.dart';

import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/events/application/event_workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_workspace_fixture.dart';
import '../support/ui06_scene_fixture.dart';

void main() {
  test('modern creation and editing publish automatic identity through canonical API and cold reopen', () async {
    final f = await _backend();
    addTearDown(f.dispose);
    final c = f.attach();
    expect(await c.prepare(), isTrue, reason: c.error);
    final map = f.workspace.active!;
    final mapBefore = map.current;
    final projectBefore = await f.readFresh();
    final source = NarrativeEventSourceRef.entityAutorun(
      map.current.id,
      'chief',
    );
    final created = c.create('Automatic original', source: source);
    expect(created, isNotNull, reason: c.error);
    expect(
      c.setScene(created!.id, Ui06SceneFixture.sceneId),
      isTrue,
      reason: c.error,
    );
    expect(c.setReuse(created.id, NarrativeEventReusePolicy.reusable), isTrue);
    expect(c.configure(created.id), isTrue, reason: c.error);
    expect(c.setEnabled(created.id, true), isTrue, reason: c.error);
    expect(
      c.setSource(Ui06SceneFixture.eventId, source),
      isTrue,
      reason: c.error,
    );
    expect(await c.save(), isTrue, reason: c.error);
    final fresh = await f.readFresh();
    expect(
      fresh.eventRegistry!.records
          .singleWhere((r) => r.id == created.id)
          .source,
      source,
    );
    expect(
      fresh.eventRegistry!.records
          .singleWhere((r) => r.id == Ui06SceneFixture.eventId)
          .source,
      source,
    );
    expect(fresh.scenes, projectBefore.scenes);
    expect(map.current, mapBefore);
    c.dispose();
    final maps = LocalMapWorkspaceAdapter();
    final workspace = MapWorkspaceController(f.source.session, maps);
    await workspace.initialize();
    final narrative = NarrativeWorkspaceController(
      workspace,
      LocalNarrativeAdapter(session: f.source.session, mapAdapter: maps),
      () {},
      (_, _) async {},
    );
    final reopened = EventWorkspaceController(
      narrative,
      LocalEventAdapter(session: f.source.session, mapAdapter: maps),
      changed: () {},
    );
    addTearDown(() {
      reopened.dispose();
      narrative.dispose();
      workspace.dispose();
    });
    expect(await reopened.prepare(), isTrue, reason: reopened.error);
    final loaded = reopened.project;
    expect(
      loaded.eventRegistry!.records
          .singleWhere((r) => r.id == created.id)
          .source!
          .toJson(),
      {'kind': 'entityAutorun', 'mapId': map.current.id, 'entityId': 'chief'},
    );
  });

  test('modern automatic replacement refuses unavailable owners without changing the stored source', () async {
    final f = await _backend();
    addTearDown(f.dispose);
    final c = f.attach();
    await c.prepare();
    final original = c.record(Ui06SceneFixture.eventId)!.source;
    final map = f.workspace.active!;
    for (final entities in <List<MapEntity>>[
      [],
      [_owner, _owner],
    ]) {
      map.commit(map.current.copyWith(entities: entities));
      expect(
        c.setSource(
          Ui06SceneFixture.eventId,
          NarrativeEventSourceRef.entityAutorun(map.current.id, 'chief'),
        ),
        isFalse,
      );
      expect(c.record(Ui06SceneFixture.eventId)!.source, original);
    }
    expect(
      c.setSource(
        Ui06SceneFixture.eventId,
        NarrativeEventSourceRef.entityAutorun('missing', 'chief'),
      ),
      isFalse,
    );
    expect(c.record(Ui06SceneFixture.eventId)!.source, original);
  });

  test(
    'automatic overview describes logical owners independently of map entry',
    () {
      final map = workspaceMap('a').copyWith(entities: [_owner]);
      final context = NarrativeOverviewContext(_project, const [], const [], [
        map,
      ]);
      final automatic = context.source(
        NarrativeEventSourceRef.entityAutorun('a', 'chief'),
      );
      final entry = context.source(NarrativeEventSourceRef.mapEnter('a'));
      final interaction = context.source(
        NarrativeEventSourceRef.entityInteract('a', 'chief'),
      );
      expect(automatic.mapId, 'a');
      expect(automatic.label, contains('Source invisible originale'));
      expect(automatic.when, contains('automatiquement'));
      expect(automatic.when, isNot(entry.when));
      expect(automatic.when, isNot(interaction.when));
      expect(automatic.missing, isNull);
    },
  );
}

const _owner = MapEntity(
  id: 'chief',
  name: 'Source invisible originale',
  kind: MapEntityKind.custom,
  pos: GridPos(x: 3, y: 3),
  blocksMovement: false,
);
final _project = workspaceProject;

Future<_AutorunBackend> _backend() async {
  final source = await Ui06SceneFixture.create();
  final projectFile = File('${source.directory.path}/project.json');
  final original = ProjectManifest.fromJson(
    jsonDecode(await projectFile.readAsString()) as Map<String, dynamic>,
  );
  final project = original;
  final maps = LocalMapWorkspaceAdapter();
  await maps.loadProject(source.session);
  final base = await maps.loadMap(source.session, project.maps.first);
  await maps.saveMap(
    source.session,
    base,
    base.map.copyWith(entities: [_owner]),
  );
  final workspace = MapWorkspaceController(source.session, maps);
  await workspace.initialize();
  return _AutorunBackend(source, workspace, maps);
}

class _AutorunBackend {
  _AutorunBackend(this.source, this.workspace, LocalMapWorkspaceAdapter maps) {
    narrative = NarrativeWorkspaceController(
      workspace,
      LocalNarrativeAdapter(session: source.session, mapAdapter: maps),
      () {},
      (_, _) async {},
    );
    port = LocalEventAdapter(session: source.session, mapAdapter: maps);
  }
  final Ui06SceneFixture source;
  final MapWorkspaceController workspace;
  late final NarrativeWorkspaceController narrative;
  late final LocalEventAdapter port;
  EventWorkspaceController? controller;
  EventWorkspaceController attach() =>
      controller = EventWorkspaceController(narrative, port, changed: () {});
  Future<ProjectManifest> readFresh() =>
      LocalMapWorkspaceAdapter().loadProject(source.session);
  Future<void> dispose() async {
    controller?.dispose();
    narrative.dispose();
    workspace.dispose();
    await source.dispose();
  }
}
