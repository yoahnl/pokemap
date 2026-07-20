import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const _eventV2 = 'evt_019abcde-5300-7000-8000-000000000001';

void main() {
  group('Narrative world state simulation', () {
    test('round-trips an immutable reproducible input snapshot', () {
      final input = NarrativeWorldStateSimulationInput(
        gameState: GameState(
          saveId: 'simulation',
          narrativeFactRuntimeState: NarrativeFactRuntimeState(
            overridesByFactId: {'fact_gate': true},
          ),
          progression: const PlayerProgression(
            completedStepIds: ['step_port'],
          ),
        ),
        hypotheticalOutcomes: [
          NarrativeOutcomeRef(
            producerKind: NarrativeOutcomeProducerKind.battle,
            producerId: 'battle_rival',
            outcomeId: 'victory',
          ),
        ],
      );

      final decoded = NarrativeWorldStateSimulationInput.fromJson(
        input.toJson(),
      );

      expect(decoded, input);
      expect(
        () => decoded.hypotheticalOutcomes.clear(),
        throwsUnsupportedError,
      );
      expect(
        input
            .withStepCompletion('step_port', completed: false)
            .gameState
            .progression
            .completedStepIds,
        isNot(contains('step_port')),
      );
      expect(
        input
            .withOutcome(
              NarrativeOutcomeRef(
                producerKind: NarrativeOutcomeProducerKind.battle,
                producerId: 'battle_rival',
                outcomeId: 'defeat',
              ),
            )
            .hypotheticalOutcomes
            .last
            .outcomeId,
        'defeat',
      );
    });

    test('explains applicable rules, contributors and priority winners', () {
      final project = _project(
        worldRules: [
          _entityRule(
            id: 'rule_hide_low',
            effect: WorldRuleEffectKind.entityHidden,
            priority: 1,
          ),
          _entityRule(
            id: 'rule_show_high',
            effect: WorldRuleEffectKind.entityVisible,
            priority: 9,
          ),
          _mapEventRule(),
          _eventV2Rule(),
          _dialogueRule(),
        ],
      );
      final map = _map();
      final projectBefore = project.toJson();
      final mapBefore = map.toJson();

      final report = simulateNarrativeWorldState(
        project: project,
        maps: [map],
        input: _activeInput(),
      );

      final entity = report.entityStates.single;
      expect(entity.visible, isTrue);
      expect(entity.dialogueId, 'dialogue_after');
      expect(entity.contributorRuleIds,
          containsAll(['rule_hide_low', 'rule_show_high', 'rule_dialogue']));
      expect(report.mapEventStates.single.active, isFalse);
      expect(report.mapEventStates.single.hidden, isTrue);
      expect(report.narrativeEventStates.single.active, isFalse);
      expect(report.narrativeEventStates.single.hidden, isFalse);
      expect(
        report.rules
            .singleWhere((rule) => rule.ruleId == 'rule_show_high')
            .winner,
        isTrue,
      );
      expect(
        report.rules
            .singleWhere((rule) => rule.ruleId == 'rule_hide_low')
            .winner,
        isFalse,
      );
      expect(
        report.diagnostics.where(
          (diagnostic) =>
              diagnostic.severity == WorldRuleDiagnosticSeverity.error,
        ),
        isEmpty,
      );
      expect(project.toJson(), projectBefore);
      expect(map.toJson(), mapBefore);
    });

    test('keeps defaults when a Fact is absent', () {
      final report = simulateNarrativeWorldState(
        project: _project(
          facts: const [],
          worldRules: [
            _entityRule(
              id: 'rule_missing_fact',
              effect: WorldRuleEffectKind.entityHidden,
              priority: 0,
            ),
          ],
        ),
        maps: [_map()],
        input: NarrativeWorldStateSimulationInput(
          gameState: const GameState(saveId: 'absent'),
        ),
      );

      expect(report.entityStates.single.visible, isTrue);
      expect(report.applicableRules, isEmpty);
      expect(
        report.diagnostics.map((diagnostic) => diagnostic.code),
        contains(WorldRuleDiagnosticCode.worldRuleSourceUnknown),
      );
    });

    test('reports equal-priority conflicts and deleted targets', () {
      final project = _project(
        worldRules: [
          _entityRule(
            id: 'rule_visible',
            effect: WorldRuleEffectKind.entityVisible,
            priority: 4,
          ),
          _entityRule(
            id: 'rule_hidden',
            effect: WorldRuleEffectKind.entityHidden,
            priority: 4,
          ),
          WorldRuleDefinition(
            id: 'rule_deleted_target',
            label: 'Deleted target',
            source: _factSource(),
            target: const WorldRuleTarget(
              kind: WorldRuleTargetKind.mapEntity,
              mapId: 'map_port',
              entityId: 'npc_deleted',
            ),
            effect: const WorldRuleEffect(
              kind: WorldRuleEffectKind.entityHidden,
            ),
          ),
        ],
      );

      final report = simulateNarrativeWorldState(
        project: project,
        maps: [_map()],
        input: _activeInput(),
      );

      expect(
        report.diagnostics.map((diagnostic) => diagnostic.code),
        containsAll([
          WorldRuleDiagnosticCode.worldRuleConflict,
          WorldRuleDiagnosticCode.worldRuleTargetUnknown,
        ]),
      );
      expect(report.applicableRules, isEmpty);
      expect(report.entityStates.single.visible, isTrue);
    });
  });
}

NarrativeWorldStateSimulationInput _activeInput() =>
    NarrativeWorldStateSimulationInput(
      gameState: GameState(
        saveId: 'active',
        narrativeFactRuntimeState: NarrativeFactRuntimeState(
          overridesByFactId: {'fact_gate': true},
        ),
      ),
    );

ProjectManifest _project({
  List<NarrativeFactDefinition>? facts,
  List<WorldRuleDefinition> worldRules = const [],
}) {
  return ProjectManifest(
    name: 'World simulation',
    maps: const [
      ProjectMapEntry(
        id: 'map_port',
        name: 'Port',
        relativePath: 'maps/port.json',
      ),
    ],
    tilesets: const [],
    facts: facts ??
        [NarrativeFactDefinition(id: 'fact_gate', label: 'Gate state')],
    dialogues: const [
      ProjectDialogueEntry(
        id: 'dialogue_after',
        name: 'After',
        relativePath: 'dialogues/after.yarn',
      ),
    ],
    scenes: [_scene()],
    worldRules: worldRules,
    eventRegistry: NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.v2Only,
      records: [
        NarrativeEventRecord.configuredStructurallyUnchecked(
          NarrativeEventDefinition(
            id: _eventV2,
            name: 'Port V2',
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
  );
}

SceneAsset _scene() => SceneAsset(
      id: 'scene_port',
      name: 'Port',
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: [SceneNode(id: 'start', kind: SceneNodeKind.start)],
        edges: const [],
      ),
    );

MapData _map() => const MapData(
      id: 'map_port',
      name: 'Port',
      size: GridSize(width: 8, height: 8),
      entities: [
        MapEntity(
          id: 'npc_guard',
          name: 'Guard',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 2, y: 2),
          npc: MapEntityNpcData(
            displayName: 'Guard',
            dialogue: DialogueRef(dialogueId: 'dialogue_before'),
          ),
        ),
      ],
      events: [
        MapEventDefinition(
          id: 'event_gate',
          title: 'Gate',
          pages: [MapEventPage(pageNumber: 0)],
          position: EventPosition(layerId: 'events', x: 3, y: 3),
        ),
      ],
    );

WorldRuleSource _factSource() => const WorldRuleSource(
      kind: WorldRuleSourceKind.fact,
      sourceId: 'fact_gate',
      predicate: WorldRuleSourcePredicate.isTrue,
    );

WorldRuleDefinition _entityRule({
  required String id,
  required WorldRuleEffectKind effect,
  required int priority,
}) =>
    WorldRuleDefinition(
      id: id,
      label: id,
      source: _factSource(),
      target: const WorldRuleTarget(
        kind: WorldRuleTargetKind.mapEntity,
        mapId: 'map_port',
        entityId: 'npc_guard',
      ),
      effect: WorldRuleEffect(kind: effect),
      priority: priority,
    );

WorldRuleDefinition _dialogueRule() => WorldRuleDefinition(
      id: 'rule_dialogue',
      label: 'Dialogue',
      source: _factSource(),
      target: const WorldRuleTarget(
        kind: WorldRuleTargetKind.npcDialogue,
        mapId: 'map_port',
        entityId: 'npc_guard',
      ),
      effect: const WorldRuleEffect(
        kind: WorldRuleEffectKind.npcDialogueOverride,
        dialogueId: 'dialogue_after',
      ),
    );

WorldRuleDefinition _mapEventRule() => WorldRuleDefinition(
      id: 'rule_map_event',
      label: 'Map Event',
      source: _factSource(),
      target: const WorldRuleTarget(
        kind: WorldRuleTargetKind.mapEvent,
        mapId: 'map_port',
        eventId: 'event_gate',
      ),
      effect: const WorldRuleEffect(kind: WorldRuleEffectKind.eventHidden),
    );

WorldRuleDefinition _eventV2Rule() => WorldRuleDefinition(
      id: 'rule_event_v2',
      label: 'Event V2',
      source: _factSource(),
      target: const WorldRuleTarget(
        kind: WorldRuleTargetKind.narrativeEvent,
        mapId: 'map_port',
        eventId: _eventV2,
      ),
      effect: const WorldRuleEffect(kind: WorldRuleEffectKind.eventDisabled),
    );
