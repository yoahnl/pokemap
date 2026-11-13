import 'dart:convert';

import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:avelune_studio/features/map_workspace/application/map_story_behaviours.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  test(
    'behaviour edits reuse the prepared catalog until its inputs change',
    () {
      final behaviours = MapStoryBehaviours()..prepare(_project, _map);
      Object sources([ProjectManifest? project, MapData? map]) => behaviours
          .context(project ?? _project, map ?? _map)
          .catalog
          .outcomeSources;
      final prepared = sources();

      expect(_rename(behaviours, _project, 'Rencontre'), isNull);
      expect(sources(), same(prepared));
      expect(
        behaviours
            .context(_project, _map)
            .catalog
            .events
            .single
            .record
            .definitionOrNull
            ?.name,
        'Rencontre',
      );

      final moved = _map.copyWith();
      final afterMove = sources(_project, moved);
      expect(afterMove, isNot(same(prepared)));
      expect(sources(_project, moved), same(afterMove));

      behaviours.media = ProjectMediaCatalog();
      final afterMedia = sources(_project, moved);
      expect(afterMedia, isNot(same(afterMove)));

      final reloaded = _project.copyWith();
      expect(sources(reloaded, moved), isNot(same(afterMedia)));
    },
  );

  test('a behaviour edit never fingerprints the whole manifest', () {
    final project = _project.copyWith(
      globalProperties: {'unserializable': double.nan},
    );
    expect(
      () => buildNarrativeEventProjectCatalog(project: project, maps: [_map]),
      throwsA(isA<JsonUnsupportedObjectError>()),
    );
    final behaviours = MapStoryBehaviours()..prepare(project, _map);

    expect(_rename(behaviours, project, 'Rencontre'), isNull);
    expect(
      behaviours.registry(project)!.records.single.definitionOrNull?.name,
      'Rencontre',
    );
  });

  test('an outside change to another behaviour never joins the draft', () {
    final project = _withRecords([_meeting, _other]);
    final behaviours = MapStoryBehaviours()..prepare(project, _map);
    expect(_rename(behaviours, project, 'Rencontre'), isNull);

    final outside = _withRecords([_meeting, _named(_other, 'Changé ailleurs')]);

    expect(
      [for (final change in behaviours.changes(outside)) change.id],
      [_meeting.id],
    );
    expect(behaviours.conflicts(outside), isEmpty);
    expect(
      _nameOf(behaviours.registry(outside)!, _other.id),
      'Changé ailleurs',
    );
    expect(_nameOf(behaviours.registry(outside)!, _meeting.id), 'Rencontre');
  });

  test('the same behaviour changed on both sides is a kept conflict', () {
    final project = _withRecords([_meeting, _other]);
    final behaviours = MapStoryBehaviours()..prepare(project, _map);
    expect(_rename(behaviours, project, 'Rencontre'), isNull);

    final outside = _withRecords([_named(_meeting, 'Réunion'), _other]);
    behaviours.settle(outside);

    expect(behaviours.changes(outside), isEmpty);
    expect(behaviours.conflicts(outside), [_meeting.id]);
    expect(behaviours.dirty(outside), isTrue);
    expect(_nameOf(behaviours.registry(outside)!, _meeting.id), 'Rencontre');
  });

  test('a saved behaviour edit can still be undone as a change', () {
    final behaviours = MapStoryBehaviours()..prepare(_project, _map);
    expect(_rename(behaviours, _project, 'Rencontre'), isNull);
    final saved = _withRecords([_named(_meeting, 'Rencontre')]);

    behaviours.settle(saved);
    expect(behaviours.dirty(saved), isFalse);
    expect(behaviours.canUndo, isTrue);

    behaviours.undo();
    final change = behaviours.changes(saved).single;
    expect(change.base?.name, 'Rencontre');
    expect(change.current?.name, 'Meeting');

    behaviours.redo();
    expect(behaviours.dirty(saved), isFalse);
  });

  test('an untouched behaviour keeps following the saved project', () {
    final behaviours = MapStoryBehaviours()..prepare(_project, _map);
    expect(_rename(behaviours, _project, 'Rencontre'), isNull);
    behaviours.undo();

    final outside = _withRecords([_named(_meeting, 'Réunion')]);

    expect(behaviours.dirty(outside), isFalse);
    expect(_nameOf(behaviours.registry(outside)!, _meeting.id), 'Réunion');
  });
}

String? _nameOf(NarrativeEventRegistry registry, String id) =>
    registry.records.singleWhere((record) => record.id == id).name;

NarrativeEventRecord _named(NarrativeEventRecord record, String name) {
  final definition = record.definitionOrNull!;
  return NarrativeEventRecord.configuredStructurallyUnchecked(
    NarrativeEventDefinition(
      id: definition.id,
      name: name,
      source: definition.source,
      conditions: definition.conditions,
      sceneId: definition.sceneId,
      reusePolicy: definition.reusePolicy,
      priority: definition.priority,
      order: definition.order,
      resetPolicy: definition.resetPolicy,
    ),
    enabled: record.enabledOrNull!,
  );
}

ProjectManifest _withRecords(List<NarrativeEventRecord> records) =>
    _project.copyWith(
      eventRegistry: NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.v2Only,
        records: records,
        legacyClaims: const [],
      ),
    );

final _other = NarrativeEventRecord.configuredStructurallyUnchecked(
  NarrativeEventDefinition(
    id: 'evt_00000000-0000-7000-8000-000000000002',
    name: 'Other',
    source: NarrativeEventSourceRef.mapEnter('map'),
    conditions: const [],
    sceneId: 'scene',
    reusePolicy: NarrativeEventReusePolicy.oneShot,
    priority: 0,
    order: 1,
  ),
  enabled: false,
);

String? _rename(
  MapStoryBehaviours behaviours,
  ProjectManifest project,
  String name,
) => behaviours.apply(project, _map, [
  (c) => renameNarrativeEvent(
    context: c,
    expectedRevision: c.revision,
    eventId: _meeting.id,
    name: name,
  ),
]).problem;

final _meeting = NarrativeEventRecord.configuredStructurallyUnchecked(
  NarrativeEventDefinition(
    id: 'evt_00000000-0000-7000-8000-000000000001',
    name: 'Meeting',
    source: NarrativeEventSourceRef.mapEnter('map'),
    conditions: const [],
    sceneId: 'scene',
    reusePolicy: NarrativeEventReusePolicy.oneShot,
    priority: 0,
    order: 0,
  ),
  enabled: false,
);

const _map = MapData(
  id: 'map',
  name: 'Map',
  size: GridSize(width: 8, height: 8),
);

final _project = ProjectManifest(
  name: 'Behaviours',
  maps: const [
    ProjectMapEntry(id: 'map', name: 'Map', relativePath: 'maps/map.json'),
  ],
  tilesets: const [],
  scenes: [
    SceneAsset(
      id: 'scene',
      name: 'Scene',
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'end',
            kind: SceneNodeKind.end,
            payload: SceneEndPayload(),
          ),
        ],
        edges: [
          SceneEdge(
            id: 'end',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'end',
            kind: SceneEdgeKind.defaultFlow,
          ),
        ],
      ),
    ),
  ],
  eventRegistry: NarrativeEventRegistry(
    schemaVersion: 1,
    mode: EventSystemMode.v2Only,
    records: [_meeting],
    legacyClaims: const [],
  ),
);
