import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

const _eventV2 = 'evt_019abcde-5300-7000-8000-000000000002';

void main() {
  test('pure world simulation matches the runtime projection hook', () {
    final fixture = _fixture();
    final input = NarrativeWorldStateSimulationInput(
      gameState: GameState(
        saveId: 'parity',
        narrativeFactRuntimeState: NarrativeFactRuntimeState(
          overridesByFactId: const {'fact_active': true},
        ),
      ),
    );

    final simulation = simulateNarrativeWorldState(
      project: fixture.project,
      maps: [fixture.map],
      input: input,
    );
    final runtime = const RuntimeWorldRuleProjectionHook().resolve(
      project: fixture.project,
      gameState: input.gameState,
      map: fixture.map,
    );

    expect(
      simulation.entityStates
          .where((state) => !state.visible)
          .map((state) => state.entityId)
          .toSet(),
      runtime.hiddenEntityIds,
    );
    expect(
      simulation.mapEventStates
          .where((state) => !state.active && !state.hidden)
          .map((state) => state.eventId)
          .toSet(),
      runtime.disabledEventIds,
    );
    expect(
      simulation.narrativeEventStates
          .where((state) => state.hidden)
          .map((state) => state.eventId)
          .toSet(),
      runtime.hiddenNarrativeEventIds,
    );
    expect(simulation.winnerRules, hasLength(3));
  });
}

({ProjectManifest project, MapData map}) _fixture() {
  const map = MapData(
    id: 'map_port',
    name: 'Port',
    size: GridSize(width: 5, height: 5),
    entities: [
      MapEntity(
        id: 'npc_guard',
        name: 'Guard',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 1, y: 1),
        npc: MapEntityNpcData(displayName: 'Guard'),
      ),
    ],
    events: [
      MapEventDefinition(
        id: 'event_gate',
        title: 'Gate',
        pages: [MapEventPage(pageNumber: 0)],
        position: EventPosition(layerId: 'events', x: 2, y: 2),
      ),
    ],
  );
  const source = WorldRuleSource(
    kind: WorldRuleSourceKind.fact,
    sourceId: 'fact_active',
    predicate: WorldRuleSourcePredicate.isTrue,
  );
  final project = ProjectManifest(
    name: 'Parity',
    maps: const [
      ProjectMapEntry(
        id: 'map_port',
        name: 'Port',
        relativePath: 'maps/port.json',
      ),
    ],
    tilesets: const [],
    facts: [NarrativeFactDefinition(id: 'fact_active', label: 'Active')],
    scenes: [
      SceneAsset(
        id: 'scene_port',
        name: 'Port',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [SceneNode(id: 'start', kind: SceneNodeKind.start)],
          edges: const [],
        ),
      ),
    ],
    eventRegistry: NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.v2Only,
      records: [
        NarrativeEventRecord.configuredStructurallyUnchecked(
          NarrativeEventDefinition(
            id: _eventV2,
            name: 'V2',
            source: NarrativeEventSourceRef.mapEnter('map_port'),
            conditions: const [],
            sceneId: 'scene_port',
            reusePolicy: NarrativeEventReusePolicy.reusable,
            priority: 0,
            order: 0,
          ),
          enabled: true,
        ),
      ],
      legacyClaims: const [],
    ),
    worldRules: [
      WorldRuleDefinition(
        id: 'rule_hide_guard',
        label: 'Hide guard',
        source: source,
        target: const WorldRuleTarget(
          kind: WorldRuleTargetKind.mapEntity,
          mapId: 'map_port',
          entityId: 'npc_guard',
        ),
        effect: const WorldRuleEffect(
          kind: WorldRuleEffectKind.entityHidden,
        ),
      ),
      WorldRuleDefinition(
        id: 'rule_disable_gate',
        label: 'Disable gate',
        source: source,
        target: const WorldRuleTarget(
          kind: WorldRuleTargetKind.mapEvent,
          mapId: 'map_port',
          eventId: 'event_gate',
        ),
        effect: const WorldRuleEffect(
          kind: WorldRuleEffectKind.eventDisabled,
        ),
      ),
      WorldRuleDefinition(
        id: 'rule_hide_v2',
        label: 'Hide V2',
        source: source,
        target: const WorldRuleTarget(
          kind: WorldRuleTargetKind.narrativeEvent,
          mapId: 'map_port',
          eventId: _eventV2,
        ),
        effect: const WorldRuleEffect(
          kind: WorldRuleEffectKind.eventHidden,
        ),
      ),
    ],
  );
  return (project: project, map: map);
}
