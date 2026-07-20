import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const _eventA = 'evt_10000000-0000-7000-8000-000000000001';
const _eventB = 'evt_10000000-0000-7000-8000-000000000002';
const _eventC = 'evt_10000000-0000-7000-8000-000000000003';

void main() {
  group('NSC-44 map Events read model', () {
    test('keeps an empty map and every unlinked physical source visible', () {
      final model = buildNarrativeMapEventsReadModel(
        project: _project(),
        maps: [_map()],
      );

      expect(model.maps, hasLength(1));
      expect(model.maps.single.mapId, 'map_port');
      expect(
        model.maps.single.sources.map((row) => row.option.ownerId),
        containsAll(<String?>[null, 'npc_lysa', 'zone_quay']),
      );
      expect(
        model.maps.single.sources
            .where((row) => row.option.selectable)
            .every((row) => row.linkState == NarrativeMapSourceLinkState.none),
        isTrue,
      );
      expect(model.maps.single.events, isEmpty);
    });

    test('synchronizes multiple Events with their exact source and order', () {
      final source =
          NarrativeEventSourceRef.entityInteract('map_port', 'npc_lysa');
      final model = buildNarrativeMapEventsReadModel(
        project: _project(
          records: [
            _configured(_eventA, 'Prioritaire', source, priority: 5, order: 0),
            _configured(_eventB, 'Secondaire', source, priority: 1, order: 2),
          ],
        ),
        maps: [_map()],
      );

      final row = model.maps.single.sources.singleWhere(
        (item) => item.option.ownerId == 'npc_lysa',
      );
      expect(row.linkState, NarrativeMapSourceLinkState.multiple);
      expect(row.eventIds, [_eventA, _eventB]);
      expect(row.hasPriorityConflict, isFalse);
      expect(
        model.maps.single.events.map((event) => event.eventId),
        [_eventA, _eventB],
      );
      expect(
        model.maps.single.events.every(
          (event) => event.sourceStableKey == row.stableKey,
        ),
        isTrue,
      );
    });

    test('flags same-source priority conflicts without hiding competitors', () {
      final source = NarrativeEventSourceRef.triggerEnter(
        'map_port',
        'zone_quay',
      );
      final model = buildNarrativeMapEventsReadModel(
        project: _project(
          records: [
            _configured(_eventA, 'Premier', source, priority: 3, order: 1),
            _configured(_eventB, 'Deuxième', source, priority: 3, order: 1),
          ],
        ),
        maps: [_map()],
      );

      final sourceRow = model.maps.single.sources.singleWhere(
        (row) => row.option.ownerId == 'zone_quay',
      );
      expect(sourceRow.hasPriorityConflict, isTrue);
      expect(
        model.maps.single.events.every((event) => event.hasPriorityConflict),
        isTrue,
      );
      expect(
        model.maps.single.diagnostics.map((item) => item.code),
        contains('priorityConflict'),
      );
    });

    test('separates source-less and cross-map Events honestly', () {
      final model = buildNarrativeMapEventsReadModel(
        project: _project(
          records: [
            NarrativeEventRecord.draft(
              NarrativeEventDraft(
                id: _eventA,
                name: 'À configurer',
                conditions: const [],
                priority: 0,
                order: 0,
              ),
            ),
            _configured(
              _eventC,
              'Map inconnue',
              NarrativeEventSourceRef.mapEnter('map_missing'),
            ),
          ],
        ),
        maps: [_map()],
      );

      expect(model.unassignedEvents.single.eventId, _eventA);
      expect(model.orphanEvents.single.eventId, _eventC);
      expect(
        model.orphanEvents.single.state,
        NarrativeMapEventLinkState.crossMap,
      );
    });

    test('projects canonical World Rules and exact Fact dependencies per map',
        () {
      final fact = NarrativeFactDefinition(
        id: 'fact_port_open',
        label: 'Port ouvert',
      );
      final rule = WorldRuleDefinition(
        id: 'rule_hide_lysa',
        label: 'Lysa disparaît',
        source: const WorldRuleSource(
          kind: WorldRuleSourceKind.fact,
          sourceId: 'fact_port_open',
          predicate: WorldRuleSourcePredicate.isTrue,
        ),
        target: const WorldRuleTarget(
          kind: WorldRuleTargetKind.mapEntity,
          mapId: 'map_port',
          entityId: 'npc_lysa',
        ),
        effect: const WorldRuleEffect(
          kind: WorldRuleEffectKind.entityHidden,
        ),
      );
      final model = buildNarrativeMapEventsReadModel(
        project: _project(facts: [fact], worldRules: [rule]),
        maps: [_map()],
      );

      expect(model.maps.single.worldRules.single.ruleId, 'rule_hide_lysa');
      expect(
        model.maps.single.worldRules.single.sourceFactId,
        'fact_port_open',
      );
      expect(model.maps.single.worldRules.single.targetAvailable, isTrue);
    });
  });
}

ProjectManifest _project({
  List<NarrativeEventRecord> records = const [],
  List<NarrativeFactDefinition> facts = const [],
  List<WorldRuleDefinition> worldRules = const [],
}) {
  return ProjectManifest(
    name: 'Selbrume',
    maps: const [
      ProjectMapEntry(
        id: 'map_port',
        name: 'Port des Brisants',
        relativePath: 'maps/port.json',
      ),
    ],
    tilesets: const [],
    scenes: [_scene()],
    facts: facts,
    worldRules: worldRules,
    eventRegistry: NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.v2Only,
      records: records,
      legacyClaims: const [],
    ),
  );
}

MapData _map() {
  return MapData(
    id: 'map_port',
    name: 'Port des Brisants',
    size: const GridSize(width: 12, height: 10),
    entities: const [
      MapEntity(
        id: 'npc_lysa',
        name: 'Lysa',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 2, y: 3),
      ),
    ],
    triggers: const [
      MapTrigger(
        id: 'zone_quay',
        name: 'Quai nord',
        type: TriggerType.event,
        area: MapRect(
          pos: GridPos(x: 4, y: 3),
          size: GridSize(width: 2, height: 1),
        ),
      ),
    ],
  );
}

NarrativeEventRecord _configured(
  String id,
  String name,
  NarrativeEventSourceRef source, {
  int priority = 0,
  int order = 0,
}) {
  return NarrativeEventRecord.configuredStructurallyUnchecked(
    NarrativeEventDefinition(
      id: id,
      name: name,
      source: source,
      conditions: const [],
      sceneId: 'scene_port',
      reusePolicy: NarrativeEventReusePolicy.oneShot,
      priority: priority,
      order: order,
    ),
    enabled: true,
  );
}

SceneAsset _scene() {
  return SceneAsset(
    id: 'scene_port',
    name: 'Rencontre au port',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'edge',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.defaultFlow,
        ),
      ],
    ),
  );
}
