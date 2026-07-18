import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('World rule diagnostics', () {
    test('reports unknown source and unknown target references', () {
      final project = _manifest(
        worldRules: [
          WorldRuleDefinition(
            id: 'world_rule_unknown_refs',
            label: 'Unknown refs',
            source: const WorldRuleSource(
              kind: WorldRuleSourceKind.fact,
              sourceId: 'fact_missing',
              predicate: WorldRuleSourcePredicate.isTrue,
            ),
            target: const WorldRuleTarget(
              kind: WorldRuleTargetKind.mapEntity,
              mapId: 'map_test',
              entityId: 'entity_missing',
            ),
            effect: const WorldRuleEffect(
              kind: WorldRuleEffectKind.entityHidden,
            ),
          ),
        ],
      );

      final report = diagnoseWorldRules(project, maps: [_mapWithNpc()]);

      expect(report.hasErrors, isTrue);
      expect(
        report.byCode(WorldRuleDiagnosticCode.worldRuleSourceUnknown),
        hasLength(1),
      );
      expect(
        report.byCode(WorldRuleDiagnosticCode.worldRuleTargetUnknown),
        hasLength(1),
      );
    });

    test('reports effect target mismatch and raw technical labels', () {
      final project = _manifest(
        facts: [
          NarrativeFactDefinition(id: 'fact_known', label: 'Known'),
        ],
        dialogues: const [
          ProjectDialogueEntry(
            id: 'dialogue_known',
            name: 'Known',
            relativePath: 'dialogues/known.yarn',
          ),
        ],
        worldRules: [
          WorldRuleDefinition(
            id: 'world_rule_raw',
            label: 'world_rule_raw',
            debugTechnicalLabel: 'ScriptCondition(flag: fact_known)',
            source: const WorldRuleSource(
              kind: WorldRuleSourceKind.fact,
              sourceId: 'fact_known',
              predicate: WorldRuleSourcePredicate.isTrue,
            ),
            target: const WorldRuleTarget(
              kind: WorldRuleTargetKind.mapEntity,
              mapId: 'map_test',
              entityId: 'npc_test',
            ),
            effect: const WorldRuleEffect(
              kind: WorldRuleEffectKind.npcDialogueOverride,
              dialogueId: 'dialogue_known',
            ),
          ),
        ],
      );

      final report = diagnoseWorldRules(project, maps: [_mapWithNpc()]);

      expect(report.hasErrors, isTrue);
      expect(
        report.byCode(WorldRuleDiagnosticCode.worldRuleEffectTargetMismatch),
        hasLength(1),
      );
      expect(
        report.byCode(WorldRuleDiagnosticCode.worldRuleUsesRawTechnicalId),
        hasLength(1),
      );
      expect(
        report.byCode(WorldRuleDiagnosticCode.worldRuleLegacyPredicateLeak),
        hasLength(1),
      );
    });

    test('reports unsupported predicates and conflicting same target priority',
        () {
      final first = _validRule(
        id: 'world_rule_first',
        label: 'First',
      );
      final second = _validRule(
        id: 'world_rule_second',
        label: 'Second',
      );
      final project = _manifest(
        facts: [
          NarrativeFactDefinition(id: 'fact_known', label: 'Known'),
        ],
        worldRules: [
          first,
          second,
          WorldRuleDefinition(
            id: 'world_rule_bad_predicate',
            label: 'Bad predicate',
            source: const WorldRuleSource(
              kind: WorldRuleSourceKind.fact,
              sourceId: 'fact_known',
              predicate: WorldRuleSourcePredicate.completed,
            ),
            target: const WorldRuleTarget(
              kind: WorldRuleTargetKind.mapEntity,
              mapId: 'map_test',
              entityId: 'npc_test',
            ),
            effect: const WorldRuleEffect(
              kind: WorldRuleEffectKind.entityVisible,
            ),
          ),
        ],
      );

      final report = diagnoseWorldRules(project, maps: [_mapWithNpc()]);

      expect(
        report.byCode(WorldRuleDiagnosticCode.worldRuleSourceUnsupported),
        hasLength(1),
      );
      expect(
        report.byCode(WorldRuleDiagnosticCode.worldRuleConflict),
        isNotEmpty,
      );
      expect(report.warningCount, greaterThanOrEqualTo(1));
    });

    test('rejects opposing effects on the same target and priority', () {
      final project = _manifest(
        facts: [
          NarrativeFactDefinition(
            id: 'fact_known',
            label: 'Known',
            defaultValue: true,
          ),
        ],
        worldRules: [
          _validRule(id: 'world_rule_visible', label: 'Visible'),
          WorldRuleDefinition(
            id: 'world_rule_hidden',
            label: 'Hidden',
            source: const WorldRuleSource(
              kind: WorldRuleSourceKind.fact,
              sourceId: 'fact_known',
              predicate: WorldRuleSourcePredicate.isTrue,
            ),
            target: const WorldRuleTarget(
              kind: WorldRuleTargetKind.mapEntity,
              mapId: 'map_test',
              entityId: 'npc_test',
            ),
            effect: const WorldRuleEffect(
              kind: WorldRuleEffectKind.entityHidden,
            ),
          ),
        ],
      );

      final report = diagnoseWorldRules(project, maps: [_mapWithNpc()]);

      final conflicts =
          report.byCode(WorldRuleDiagnosticCode.worldRuleConflict);
      expect(conflicts, hasLength(2));
      expect(
        conflicts.map((diagnostic) => diagnostic.severity),
        everyElement(WorldRuleDiagnosticSeverity.error),
      );
      expect(
        projectWorldRuleEffects(
          project,
          const GameState(saveId: 'save'),
          maps: [_mapWithNpc()],
        ),
        isEmpty,
      );
    });

    test('reports a Fact predicate that no initial state or Scene can produce',
        () {
      final project = _manifest(
        facts: [
          NarrativeFactDefinition(
            id: 'fact_known',
            label: 'Known',
            defaultValue: false,
          ),
        ],
        worldRules: [
          _validRule(id: 'world_rule_unproducible', label: 'Unproducible'),
        ],
      );

      final report = diagnoseWorldRules(project, maps: [_mapWithNpc()]);

      expect(
        report.byCode(
          WorldRuleDiagnosticCode.worldRuleSourceNeverProduced,
        ),
        hasLength(1),
      );
    });

    test('accepts a Fact predicate already satisfied by its default value', () {
      final project = _manifest(
        facts: [
          NarrativeFactDefinition(
            id: 'fact_known',
            label: 'Known',
            defaultValue: true,
          ),
        ],
        worldRules: [
          _validRule(id: 'world_rule_producible', label: 'Producible'),
        ],
      );

      final report = diagnoseWorldRules(project, maps: [_mapWithNpc()]);

      expect(
        report.byCode(
          WorldRuleDiagnosticCode.worldRuleSourceNeverProduced,
        ),
        isEmpty,
      );
    });

    test('accepts a Fact value produced by a legacy Scenario action', () {
      final project = _manifest(
        facts: [
          NarrativeFactDefinition(
            id: 'fact_known',
            label: 'Known',
            legacyFlagName: 'legacy_known',
          ),
        ],
        scenarios: [
          const ScenarioAsset(
            id: 'scenario_fact',
            name: 'Scenario fact',
            entryNodeId: 'node_set',
            nodes: [
              ScenarioNode(
                id: 'node_set',
                binding: ScenarioNodeBinding(flagName: 'legacy_known'),
                payload: ScenarioNodePayload(actionKind: 'setFlag'),
              ),
            ],
          ),
        ],
        worldRules: [
          _validRule(id: 'world_rule_scenario_fact', label: 'Scenario fact'),
        ],
      );

      final report = diagnoseWorldRules(project, maps: [_mapWithNpc()]);

      expect(
        report.byCode(
          WorldRuleDiagnosticCode.worldRuleSourceNeverProduced,
        ),
        isEmpty,
      );
    });

    test('reports a completed Story Step that has no completion producer', () {
      final project = _manifest(
        storylines: [
          StorylineAsset(
            id: 'storyline_test',
            type: StorylineType.main,
            title: 'Storyline test',
            chapters: [
              StorylineChapter(
                id: 'chapter_test',
                title: 'Chapter test',
                order: 0,
                steps: [
                  StorylineStep(
                    id: 'step_locked',
                    title: 'Locked step',
                    order: 0,
                  ),
                ],
              ),
            ],
          ),
        ],
        worldRules: [
          WorldRuleDefinition(
            id: 'world_rule_step_locked',
            label: 'Unlock after step',
            source: const WorldRuleSource(
              kind: WorldRuleSourceKind.storyStepCompletion,
              sourceId: 'step_locked',
              predicate: WorldRuleSourcePredicate.completed,
            ),
            target: const WorldRuleTarget(
              kind: WorldRuleTargetKind.mapEntity,
              mapId: 'map_test',
              entityId: 'npc_test',
            ),
            effect: const WorldRuleEffect(
              kind: WorldRuleEffectKind.entityHidden,
            ),
          ),
        ],
      );

      final report = diagnoseWorldRules(project, maps: [_mapWithNpc()]);

      expect(
        report.byCode(
          WorldRuleDiagnosticCode.worldRuleSourceNeverProduced,
        ),
        hasLength(1),
      );
      expect(
        report.byCode(
          WorldRuleDiagnosticCode.worldRuleBlockingEntityNeverReleased,
        ),
        hasLength(1),
      );
    });

    test('does not treat a merely linked Scene as a Story Step producer', () {
      final project = _manifest(
        scenes: [
          SceneAsset(
            id: 'scene_linked',
            name: 'Linked without completion',
            graph: SceneGraph(
              startNodeId: 'start',
              nodes: [
                SceneNode(id: 'start', kind: SceneNodeKind.start),
                SceneNode(id: 'end', kind: SceneNodeKind.end),
              ],
              edges: [
                SceneEdge(
                  id: 'start_end',
                  fromNodeId: 'start',
                  fromPortId: 'completed',
                  toNodeId: 'end',
                  kind: SceneEdgeKind.defaultFlow,
                ),
              ],
            ),
          ),
        ],
        storylines: [
          StorylineAsset(
            id: 'storyline_test',
            type: StorylineType.main,
            title: 'Storyline test',
            chapters: [
              StorylineChapter(
                id: 'chapter_test',
                title: 'Chapter test',
                order: 0,
                steps: [
                  StorylineStep(
                    id: 'step_linked_only',
                    title: 'Linked only',
                    order: 0,
                    sceneLinkIds: const ['scene_linked'],
                  ),
                ],
              ),
            ],
          ),
        ],
        worldRules: [
          WorldRuleDefinition(
            id: 'world_rule_step_linked_only',
            label: 'Unlock after linked step',
            source: const WorldRuleSource(
              kind: WorldRuleSourceKind.storyStepCompletion,
              sourceId: 'step_linked_only',
              predicate: WorldRuleSourcePredicate.completed,
            ),
            target: const WorldRuleTarget(
              kind: WorldRuleTargetKind.mapEntity,
              mapId: 'map_test',
              entityId: 'npc_test',
            ),
            effect: const WorldRuleEffect(
              kind: WorldRuleEffectKind.entityHidden,
            ),
          ),
        ],
      );

      final report = diagnoseWorldRules(project, maps: [_mapWithNpc()]);

      expect(
        report.byCode(
          WorldRuleDiagnosticCode.worldRuleSourceNeverProduced,
        ),
        hasLength(1),
      );
      expect(
        report.byCode(
          WorldRuleDiagnosticCode.worldRuleBlockingEntityNeverReleased,
        ),
        hasLength(1),
      );
    });

    test('accepts a Story Step completed by a legacy Scenario action', () {
      final project = _manifest(
        storylines: [
          StorylineAsset(
            id: 'storyline_test',
            type: StorylineType.main,
            title: 'Storyline test',
            chapters: [
              StorylineChapter(
                id: 'chapter_test',
                title: 'Chapter test',
                order: 0,
                steps: [
                  StorylineStep(
                    id: 'step_locked',
                    title: 'Locked step',
                    order: 0,
                  ),
                ],
              ),
            ],
          ),
        ],
        scenarios: [
          const ScenarioAsset(
            id: 'scenario_step',
            name: 'Scenario step',
            entryNodeId: 'node_complete',
            nodes: [
              ScenarioNode(
                id: 'node_complete',
                payload: ScenarioNodePayload(
                  actionKind: 'completeStep',
                  params: {'stepId': 'step_locked'},
                ),
              ),
            ],
          ),
        ],
        worldRules: [
          WorldRuleDefinition(
            id: 'world_rule_step_scenario',
            label: 'Unlock after scenario step',
            source: const WorldRuleSource(
              kind: WorldRuleSourceKind.storyStepCompletion,
              sourceId: 'step_locked',
              predicate: WorldRuleSourcePredicate.completed,
            ),
            target: const WorldRuleTarget(
              kind: WorldRuleTargetKind.mapEntity,
              mapId: 'map_test',
              entityId: 'npc_test',
            ),
            effect: const WorldRuleEffect(
              kind: WorldRuleEffectKind.entityHidden,
            ),
          ),
        ],
      );

      final report = diagnoseWorldRules(project, maps: [_mapWithNpc()]);

      expect(
        report.byCode(
          WorldRuleDiagnosticCode.worldRuleSourceNeverProduced,
        ),
        isEmpty,
      );
      expect(
        report.byCode(
          WorldRuleDiagnosticCode.worldRuleBlockingEntityNeverReleased,
        ),
        isEmpty,
      );
    });
  });
}

ProjectManifest _manifest({
  List<NarrativeFactDefinition> facts = const [],
  List<ProjectDialogueEntry> dialogues = const [],
  List<ScenarioAsset> scenarios = const [],
  List<SceneAsset> scenes = const [],
  List<StorylineAsset> storylines = const [],
  List<WorldRuleDefinition> worldRules = const [],
}) {
  return ProjectManifest(
    name: 'Diagnostics project',
    maps: const [
      ProjectMapEntry(
        id: 'map_test',
        name: 'Map test',
        relativePath: 'maps/map_test.json',
      ),
    ],
    tilesets: const [],
    dialogues: dialogues,
    facts: facts,
    scenarios: scenarios,
    scenes: scenes,
    storylines: storylines,
    worldRules: worldRules,
  );
}

MapData _mapWithNpc() {
  return const MapData(
    id: 'map_test',
    name: 'Map test',
    size: GridSize(width: 10, height: 8),
    entities: [
      MapEntity(
        id: 'npc_test',
        name: 'NPC test',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 2, y: 3),
        npc: MapEntityNpcData(displayName: 'NPC test'),
      ),
    ],
    events: [
      MapEventDefinition(
        id: 'event_test',
        title: 'Event test',
        pages: [
          MapEventPage(pageNumber: 0),
        ],
        position: EventPosition(layerId: 'events', x: 1, y: 1),
      ),
    ],
  );
}

WorldRuleDefinition _validRule({
  required String id,
  required String label,
}) {
  return WorldRuleDefinition(
    id: id,
    label: label,
    source: const WorldRuleSource(
      kind: WorldRuleSourceKind.fact,
      sourceId: 'fact_known',
      predicate: WorldRuleSourcePredicate.isTrue,
    ),
    target: const WorldRuleTarget(
      kind: WorldRuleTargetKind.mapEntity,
      mapId: 'map_test',
      entityId: 'npc_test',
    ),
    effect: const WorldRuleEffect(kind: WorldRuleEffectKind.entityVisible),
  );
}
