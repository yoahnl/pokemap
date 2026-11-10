import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/features/events/data/local_event_adapter.dart';
import 'package:map_core/map_core.dart';
import 'package:avelune_studio/features/events/domain/event_record_view.dart';

import 'package:avelune_studio/features/events/application/event_workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/ui06_scene_fixture.dart';

void main() {
  test('modern creation and editing publish contact identity through canonical API and cold reopen', () async {
    final f = await _backend();
    addTearDown(f.dispose);
    final c = f.attach();
    expect(await c.prepare(), isTrue, reason: c.error);
    final map = f.workspace.active!;
    final mapBefore = map.current;
    final projectBefore = await f.readFresh();
    final source = NarrativeEventSourceRef.entityBump(map.current.id, 'chief');
    final recordedAdapter = LocalMapWorkspaceAdapter();
    final recordedProject = await recordedAdapter.loadProject(f.source.session);
    final recordedMap = await recordedAdapter.loadMap(
      f.source.session,
      recordedProject.maps.singleWhere((entry) => entry.id == map.current.id),
    );
    expect(recordedMap.map.entities.single.id, 'chief');
    expect(
      recordedMap.map.entities.single.npc!.characterId,
      'contact-character',
    );
    expect(recordedProject.characters.single.id, 'contact-character');
    expect(
      isNarrativeEntityBumpSourceAvailable(
        project: recordedProject,
        map: recordedMap.map,
        entityId: 'chief',
      ),
      isTrue,
      reason: 'The stored fixture must admit its native contact source before publication',
    );
    final created = c.create('Contact original', source: source);
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
      {'kind': 'entityBump', 'mapId': map.current.id, 'entityId': 'chief'},
    );
  });

  test('modern contact replacement refuses unavailable owners without changing the stored source', () async {
    final f = await _backend();
    addTearDown(f.dispose);
    final c = f.attach();
    await c.prepare();
    final original = c.record(Ui06SceneFixture.eventId)!.source;
    final map = f.workspace.active!;
    for (final entities in <List<MapEntity>>[
      [],
      [_npc.copyWith(blocksMovement: false)],
      [_npc, _npc],
      [
        const MapEntity(
          id: 'chief',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 3, y: 3),
        ),
      ],
    ]) {
      map.commit(map.current.copyWith(entities: entities));
      expect(
        c.setSource(
          Ui06SceneFixture.eventId,
          NarrativeEventSourceRef.entityBump(map.current.id, 'chief'),
        ),
        isFalse,
      );
      expect(c.record(Ui06SceneFixture.eventId)!.source, original);
    }
    expect(
      c.setSource(
        Ui06SceneFixture.eventId,
        NarrativeEventSourceRef.entityBump('missing', 'chief'),
      ),
      isFalse,
    );
    expect(c.record(Ui06SceneFixture.eventId)!.source, original);
  });
}

const _character = ProjectCharacterEntry(
  id: 'contact-character',
  name: 'Original contact actor',
  tilesetId: 'atlas',
);
const _npc = MapEntity(
  id: 'chief',
  name: 'Chef original',
  kind: MapEntityKind.npc,
  pos: GridPos(x: 3, y: 3),
  npc: MapEntityNpcData(characterId: 'contact-character'),
);

Future<_ContactBackend> _backend() async {
  final source = await Ui06SceneFixture.create(
    seedProject: (project) => project.copyWith(
      characters: [_character.copyWith(tilesetId: project.tilesets.first.id)],
    ),
  );
  final maps = LocalMapWorkspaceAdapter();
  final project = await maps.loadProject(source.session);
  final base = await maps.loadMap(source.session, project.maps.first);
  await maps.saveMap(source.session, base, base.map.copyWith(entities: [_npc]));
  final workspace = MapWorkspaceController(source.session, maps);
  await workspace.initialize();
  return _ContactBackend(source, workspace, maps);
}

class _ContactBackend {
  _ContactBackend(this.source, this.workspace, LocalMapWorkspaceAdapter maps) {
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
