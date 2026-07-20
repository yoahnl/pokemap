import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const _eventV2 = 'evt_019abcde-0000-7000-8000-000000000052';

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
      expect(readModel.worldRuleDiagnosticCount, 2);
      expect(
        readModel.worldRules.first.diagnostics.single.code,
        WorldRuleDiagnosticCode.worldRuleSourceNeverProduced,
      );
      expect(
        readModel.worldRules.first.humanSummary,
        'Si Gate open est vrai alors Event de map legacy désactivé sur Event de map legacy · Gate event',
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

    test('exposes categories roles and explicit runtime value presence', () {
      final project = _manifest(
        facts: [
          NarrativeFactDefinition(
            id: 'fact_false',
            label: 'Explicit false',
            category: 'Progression',
            defaultValue: false,
          ),
          NarrativeFactDefinition(
            id: 'fact_true',
            label: 'Runtime override',
            category: 'World',
            defaultValue: true,
          ),
        ],
        scenes: [_sceneReferencingAndProducingFact('fact_false')],
      );
      final dependencyIndex = buildNarrativeDependencyIndex(project: project);

      final readModel = buildFactsWorldRulesManagerReadModel(
        project,
        dependencyIndex: dependencyIndex,
        runtimeState: NarrativeFactRuntimeState(
          overridesByFactId: const {'fact_true': false},
        ),
      );

      expect(readModel.factCategories, ['', 'Progression', 'World']);
      final explicitFalse = readModel.factById('fact_false')!;
      expect(explicitFalse.initialValue, isFalse);
      expect(explicitFalse.hasRuntimeOverride, isFalse);
      expect(explicitFalse.effectiveValue, isFalse);
      expect(explicitFalse.readerUsages, isNotEmpty);
      expect(explicitFalse.writerUsages, isNotEmpty);
      final runtimeOverride = readModel.factById('fact_true')!;
      expect(runtimeOverride.initialValue, isTrue);
      expect(runtimeOverride.hasRuntimeOverride, isTrue);
      expect(runtimeOverride.runtimeOverrideValue, isFalse);
      expect(runtimeOverride.effectiveValue, isFalse);
    });

    test(
        'lists project-wide targets and labels legacy and V2 Events distinctly',
        () {
      final project = _manifest(
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.v2Only,
          records: [
            NarrativeEventRecord.draft(
              NarrativeEventDraft(
                id: _eventV2,
                name: 'Port arrival V2',
                conditions: const [],
                priority: 0,
                order: 0,
              ),
            ),
          ],
          legacyClaims: const [],
        ),
      );
      final inactiveMap = _mapWithEvent().copyWith(
        id: 'map_inactive',
        name: 'Inactive map',
      );

      final readModel = buildFactsWorldRulesManagerReadModel(
        project,
        maps: [_mapWithEvent(), inactiveMap],
      );

      expect(
        readModel.targetOptions.where(
          (option) =>
              option.kind == WorldRuleTargetKind.mapEvent &&
              option.mapId == 'map_inactive',
        ),
        isNotEmpty,
      );
      final legacy = readModel.targetOptions.firstWhere(
        (option) => option.kind == WorldRuleTargetKind.mapEvent,
      );
      final eventV2 = readModel.targetOptions.singleWhere(
        (option) => option.kind == WorldRuleTargetKind.narrativeEvent,
      );
      expect(legacy.subtitle, contains('Event de map legacy'));
      expect(eventV2.eventId, _eventV2);
      expect(eventV2.subtitle, contains('Narrative Event V2'));
    });
  });
}

ProjectManifest _manifest({
  List<NarrativeFactDefinition> facts = const [],
  List<ProjectDialogueEntry> dialogues = const [],
  List<SceneAsset> scenes = const [],
  List<WorldRuleDefinition> worldRules = const [],
  NarrativeEventRegistry? eventRegistry,
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
    eventRegistry: eventRegistry,
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
