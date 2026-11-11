import 'package:avelune_studio/features/events/application/event_map_loader.dart';
import 'package:avelune_studio/features/events/application/event_source_description.dart';
import 'package:avelune_studio/features/events/application/event_source_selection_session.dart';
import 'package:avelune_studio/features/events/application/event_workspace_controller.dart';
import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/event_backend_fixture.dart';
import '../support/map_workspace_fixture.dart';
import '../support/ui06_scene_fixture.dart';

void main() {
  for (final blocking in [true, false]) {
    test('automatic identity accepts logical owners with blocking=$blocking', () {
      final description = describeEventSource(
        source: NarrativeEventSourceRef.entityAutorun('a', 'chief'),
        map: workspaceMap(
          'a',
        ).copyWith(entities: [_logicalOwner.copyWith(blocksMovement: blocking)]),
        project: workspaceProject,
      );
      expect(description.title, 'Source invisible originale');
      expect(description.position, 'Position : (3, 3)');
    });
  }

  test('automatic identity refuses a missing project or an unavailable owner', () {
    final source = NarrativeEventSourceRef.entityAutorun('a', 'chief');
    final map = workspaceMap('a').copyWith(entities: [_logicalOwner]);
    expect(
      describeEventSource(source: source, map: map, project: null).title,
      'Source indisponible · élément source à réparer',
    );
    expect(
      describeEventSource(
        source: source,
        map: map,
        project: workspaceProject.copyWith(
          settings: const ProjectSettings(dimension: ProjectDimension.threeD),
        ),
      ).title,
      'Source indisponible · élément source à réparer',
    );
  });

  test('automatic identity rejects a loaded map with another identity', () {
    final description = describeEventSource(
      source: NarrativeEventSourceRef.entityAutorun('a', 'chief'),
      map: workspaceMap('b').copyWith(entities: [_logicalOwner]),
      project: workspaceProject,
    );
    expect(description.title, 'Source indisponible · carte à réparer');
    expect(description.title, isNot('Source invisible originale'));
    expect(description.position, isNull);
  });

  test('source selection never installs a loaded map with another identity', () async {
    final backend = await EventBackendFixture.create();
    final port = WorkspaceMemoryPort();
    final workspace = MapWorkspaceController(workspaceSession, port);
    await workspace.initialize();
    final record = NarrativeEventRecord.draft(
      NarrativeEventDraft(
        id: Ui06SceneFixture.eventId,
        name: 'Automatique',
        source: NarrativeEventSourceRef.entityAutorun('a', 'chief'),
        conditions: const [],
        priority: 0,
        order: 0,
      ),
    );
    workspace.project = workspaceProject.copyWith(
      eventRegistry: NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.legacyOnly,
        records: [record],
        legacyClaims: const [],
      ),
    );
    final narrative = NarrativeWorkspaceController(
      workspace,
      backend.narrative.port,
      () {},
      (_, _) async {},
    );
    final events = EventWorkspaceController(
      narrative,
      backend.port,
      changed: () {},
    );
    final loader = _FixedLoader(workspace, {
      'a': workspaceMap('b').copyWith(entities: [_logicalOwner]),
      'b': workspaceMap('b').copyWith(entities: [_logicalOwner]),
    });
    final selection = EventSourceSelectionSession(
      controller: events,
      loader: loader,
      record: record,
      changed: () {},
    );
    addTearDown(() async {
      selection.dispose();
      events.dispose();
      narrative.dispose();
      workspace.dispose();
      await backend.dispose();
    });

    await selection.pendingMap;
    expect(selection.mapId, 'a');
    expect(selection.map, isNull);
    expect(
      await selection.choose(NarrativeEventSourceKind.entityAutorun),
      isTrue,
    );
    expect(
      selection.accept(NarrativeEventSourceRef.entityAutorun('a', 'chief')),
      isFalse,
    );
    expect(events.record(record.id)!.source, record.source);

    selection.selectMap('b');
    await selection.pendingMap;
    expect(selection.map!.id, 'b');
  }, timeout: _slow);

  for (final available in [true, false]) {
    test('contact source identity preserves the NPC and availability=$available', () {
      final description = describeEventSource(
        source: NarrativeEventSourceRef.entityBump('a', 'chief'),
        map: workspaceMap(
          'a',
        ).copyWith(entities: [_npc.copyWith(blocksMovement: available)]),
        project: _contactProject,
      );
      expect(
        description.title,
        available ? 'Chef original' : 'Source indisponible · personnage à réparer',
      );
      expect(description.position, available ? 'Position : (3, 3)' : isNull);
    });
  }

  test('identity reports absent, ambiguous, whole-map and zone sources', () {
    final map = workspaceMap('a').copyWith(
      entities: [_npc, _npc.copyWith(id: 'twin'), _npc.copyWith(id: 'twin')],
      triggers: [_zone, _zone.copyWith(type: TriggerType.custom, id: 'door')],
    );
    String title(NarrativeEventSourceRef source) => describeEventSource(
      source: source,
      map: map,
      project: _contactProject,
    ).title;

    expect(
      title(NarrativeEventSourceRef.entityInteract('a', 'ghost')),
      'Source absente · ghost',
    );
    expect(
      title(NarrativeEventSourceRef.entityInteract('a', 'twin')),
      'Source ambiguë · twin',
    );
    expect(
      title(NarrativeEventSourceRef.mapEnter('a')),
      'Toute la carte · à son entrée',
    );
    expect(
      title(NarrativeEventSourceRef.triggerEnter('a', 'chief')),
      'Sortie originale',
    );
    expect(
      title(NarrativeEventSourceRef.triggerBump('a', 'door')),
      'Source indisponible · zone à réparer',
    );
    expect(
      describeEventSource(
        source: NarrativeEventSourceRef.entityInteract('a', 'chief'),
        map: workspaceMap('a').copyWith(entities: [_npc.copyWith(name: '')]),
        project: _contactProject,
      ).title,
      'Interaction du joueur',
    );
  });
}

class _FixedLoader extends EventMapLoader {
  _FixedLoader(super.workspace, this.maps);
  final Map<String, MapData> maps;
  @override
  Future<MapData> load(String id) async => maps[id]!;
}

const _logicalOwner = MapEntity(
  id: 'chief',
  name: 'Source invisible originale',
  kind: MapEntityKind.custom,
  pos: GridPos(x: 3, y: 3),
  blocksMovement: false,
);

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

const _zone = MapTrigger(
  id: 'chief',
  name: 'Sortie originale',
  type: TriggerType.event,
  area: MapRect(pos: GridPos(x: 3, y: 3), size: GridSize(width: 1, height: 1)),
);

final _contactProject = workspaceProject.copyWith(characters: [_character]);

const _slow = Timeout(Duration(minutes: 3));
