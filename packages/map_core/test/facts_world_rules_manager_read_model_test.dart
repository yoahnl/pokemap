import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Facts and World Rules manager read model', () {
    test('lists facts with usages from scenes and world rules', () {
      final manifest = _manifest(
        facts: [
          NarrativeFactDefinition(
            id: 'fact_gate_open',
            label: 'Gate open',
            description: 'Persistent gate state.',
            category: 'World',
            defaultValue: true,
          ),
        ],
        scenes: [_sceneReferencingAndProducingFact('fact_gate_open')],
        worldRules: [_eventRuleForFact('fact_gate_open')],
      );

      final readModel = buildFactsWorldRulesManagerReadModel(
        manifest,
        maps: [_mapWithEvent()],
      );

      expect(readModel.factCount, 1);
      expect(readModel.usedFactCount, 1);
      expect(readModel.unusedFactCount, 0);
      expect(readModel.facts.single.fact.id, 'fact_gate_open');
      expect(readModel.facts.single.usages.map((usage) => usage.kind), [
        FactManagerUsageKind.sceneCondition,
        FactManagerUsageKind.sceneConsequence,
        FactManagerUsageKind.worldRuleSource,
      ]);
      expect(
        readModel.facts.single.usages.map((usage) => usage.ownerLabel),
        containsAll([
          'Gate scene',
          'Gate scene',
          'Disable gate event',
        ]),
      );
    });

    test('builds world rule summaries, diagnostics and picker options', () {
      final manifest = _manifest(
        facts: [
          NarrativeFactDefinition(id: 'fact_gate_open', label: 'Gate open'),
        ],
        dialogues: const [
          ProjectDialogueEntry(
            id: 'dialogue_guard',
            name: 'Guard dialogue',
            relativePath: 'dialogues/guard.yarn',
          ),
        ],
        worldRules: [
          _eventRuleForFact('fact_gate_open'),
          _unknownFactRule(),
        ],
      );

      final readModel = buildFactsWorldRulesManagerReadModel(
        manifest,
        maps: [_mapWithEvent()],
      );

      expect(readModel.worldRuleCount, 2);
      expect(readModel.enabledWorldRuleCount, 2);
      expect(readModel.worldRuleDiagnosticCount, 1);
      expect(
        readModel.worldRules.first.humanSummary,
        'Si Gate open est vrai alors Event désactivé sur Gate event',
      );
      expect(
        readModel.worldRules.last.diagnostics.single.code,
        WorldRuleDiagnosticCode.worldRuleSourceUnknown,
      );
      expect(
        readModel.sourceOptions.map((option) => option.label),
        contains('Gate open'),
      );
      expect(
        readModel.targetOptions.map((option) => option.label),
        containsAll(['Gate entity', 'Gate event']),
      );
      expect(
        readModel.effectOptions
            .where((option) =>
                option.compatibleTargetKind == WorldRuleTargetKind.mapEvent)
            .map((option) => option.effectKind),
        containsAll([
          WorldRuleEffectKind.eventEnabled,
          WorldRuleEffectKind.eventDisabled,
          WorldRuleEffectKind.eventHidden,
        ]),
      );
      expect(
        readModel.dialogueOptions.map((option) => option.label),
        contains('Guard dialogue'),
      );
    });
  });
}

ProjectManifest _manifest({
  List<NarrativeFactDefinition> facts = const [],
  List<ProjectDialogueEntry> dialogues = const [],
  List<SceneAsset> scenes = const [],
  List<WorldRuleDefinition> worldRules = const [],
}) {
  return ProjectManifest(
    name: 'Facts manager test',
    maps: const [
      ProjectMapEntry(
        id: 'map_gate',
        name: 'Gate map',
        relativePath: 'maps/gate.json',
      ),
    ],
    tilesets: const [],
    dialogues: dialogues,
    facts: facts,
    scenes: scenes,
    worldRules: worldRules,
  );
}

SceneAsset _sceneReferencingAndProducingFact(String factId) {
  return SceneAsset(
    id: 'scene_gate',
    name: 'Gate scene',
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'node_condition',
          kind: SceneNodeKind.condition,
          payload: SceneConditionPayload(
            conditionSource: SceneConditionSource(
              sourceKind: SceneConditionSourceKind.fact,
              sourceId: factId,
              operator: SceneConditionOperator.isTrue,
              label: 'Gate open',
            ),
          ),
        ),
        SceneNode(
          id: 'node_action',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.setFact(
              factId: factId,
              value: true,
              label: 'Open gate',
            ),
          ),
        ),
        SceneNode(id: 'node_end', kind: SceneNodeKind.end),
      ],
      edges: const [],
    ),
  );
}

WorldRuleDefinition _eventRuleForFact(String factId) {
  return WorldRuleDefinition(
    id: 'world_rule_disable_gate_event',
    label: 'Disable gate event',
    source: WorldRuleSource(
      kind: WorldRuleSourceKind.fact,
      sourceId: factId,
      predicate: WorldRuleSourcePredicate.isTrue,
    ),
    target: const WorldRuleTarget(
      kind: WorldRuleTargetKind.mapEvent,
      mapId: 'map_gate',
      eventId: 'event_gate',
    ),
    effect: const WorldRuleEffect(kind: WorldRuleEffectKind.eventDisabled),
  );
}

WorldRuleDefinition _unknownFactRule() {
  return WorldRuleDefinition(
    id: 'world_rule_unknown_fact',
    label: 'Unknown fact rule',
    source: const WorldRuleSource(
      kind: WorldRuleSourceKind.fact,
      sourceId: 'fact_missing',
      predicate: WorldRuleSourcePredicate.isTrue,
    ),
    target: const WorldRuleTarget(
      kind: WorldRuleTargetKind.mapEvent,
      mapId: 'map_gate',
      eventId: 'event_gate',
    ),
    effect: const WorldRuleEffect(kind: WorldRuleEffectKind.eventHidden),
  );
}

MapData _mapWithEvent() {
  return const MapData(
    id: 'map_gate',
    name: 'Gate map',
    size: GridSize(width: 10, height: 8),
    entities: [
      MapEntity(
        id: 'entity_gate',
        name: 'Gate entity',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 2, y: 3),
        npc: MapEntityNpcData(displayName: 'Gate entity'),
      ),
    ],
    events: [
      MapEventDefinition(
        id: 'event_gate',
        title: 'Gate event',
        pages: [
          MapEventPage(pageNumber: 0),
        ],
        position: EventPosition(layerId: 'events', x: 1, y: 1),
      ),
    ],
  );
}
