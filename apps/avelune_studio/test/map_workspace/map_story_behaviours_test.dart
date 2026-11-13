import 'dart:convert';

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
}

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
