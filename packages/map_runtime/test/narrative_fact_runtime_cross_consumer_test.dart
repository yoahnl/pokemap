import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  group('Narrative Fact runtime cross consumer matrix', () {
    for (final testCase in _cases()) {
      test(testCase.name, () {
        final resolver =
            NarrativeFactRuntimeResolver.fromFacts([testCase.fact]);
        final direct = resolver.resolve(
          factId: testCase.fact.id,
          runtimeState: testCase.state.narrativeFactRuntimeState,
          storyFlags: testCase.state.storyFlags,
        ) as NarrativeFactRuntimeResolved;
        final project = _project(testCase.fact);
        final worldRule = projectWorldRuleEffects(
          project,
          testCase.state,
          maps: const [_map],
          mapId: 'map_test',
        );
        final sceneCondition = evaluateCanonicalNarrativeFactSceneCondition(
          source: SceneConditionSource(
            sourceKind: SceneConditionSourceKind.fact,
            sourceId: testCase.fact.id,
            operator: SceneConditionOperator.isTrue,
          ),
          gameState: testCase.state,
          resolver: resolver,
        );
        final scriptCondition = const ScriptConditionEvaluator().evaluate(
          ScriptConditionFactory.flagIsSet(testCase.fact.id),
          testCase.state,
          context: ScriptEvaluationContext(
            narrativeFactResolver: resolver,
          ),
        );

        expect(direct.value, testCase.expected);
        expect(worldRule.isNotEmpty, testCase.expected);
        expect(sceneCondition, testCase.expected);
        expect(scriptCondition, testCase.expected);
      });
    }

    test('supports isFalse and equals boolean operators', () {
      final fact = NarrativeFactDefinition(
        id: 'fact_false',
        label: 'False',
      );
      final resolver = NarrativeFactRuntimeResolver.fromFacts([fact]);
      const state = GameState(saveId: 'scene_operators');

      expect(
        evaluateCanonicalNarrativeFactSceneCondition(
          source: SceneConditionSource(
            sourceKind: SceneConditionSourceKind.fact,
            sourceId: fact.id,
            operator: SceneConditionOperator.isFalse,
          ),
          gameState: state,
          resolver: resolver,
        ),
        isTrue,
      );
      expect(
        evaluateCanonicalNarrativeFactSceneCondition(
          source: SceneConditionSource(
            sourceKind: SceneConditionSourceKind.fact,
            sourceId: fact.id,
            operator: SceneConditionOperator.equals,
            value: 'false',
          ),
          gameState: state,
          resolver: resolver,
        ),
        isTrue,
      );
    });

    test('supports typed Scene integer and Unicode string comparisons', () {
      final facts = [
        NarrativeFactDefinition(
          id: 'fact_reputation',
          label: 'Réputation',
          initialValue: NarrativeValue.integer(4),
        ),
        NarrativeFactDefinition(
          id: 'fact_codename',
          label: 'Nom de code',
          initialValue: const NarrativeValue.string('Selbrume 🌫️'),
        ),
      ];
      final resolver = NarrativeFactRuntimeResolver.fromFacts(facts);

      expect(
        evaluateCanonicalNarrativeFactSceneCondition(
          source: SceneConditionSource.factValue(
            factId: 'fact_reputation',
            operator: NarrativeFactOperator.greaterThan,
            expectedValue: NarrativeValue.integer(3),
          ),
          gameState: const GameState(saveId: 'typed_scene'),
          resolver: resolver,
        ),
        isTrue,
      );
      expect(
        evaluateCanonicalNarrativeFactSceneCondition(
          source: SceneConditionSource.factValue(
            factId: 'fact_codename',
            operator: NarrativeFactOperator.equals,
            expectedValue: const NarrativeValue.string('Selbrume 🌫️'),
          ),
          gameState: const GameState(saveId: 'typed_scene'),
          resolver: resolver,
        ),
        isTrue,
      );
    });

    test('fails closed for unknown and ambiguous canonical Facts', () {
      const state = GameState(saveId: 'scene_invalid');
      final unknown = NarrativeFactRuntimeResolver.fromFacts(const []);
      final ambiguous = NarrativeFactRuntimeResolver.fromFacts([
        NarrativeFactDefinition(id: 'fact_dup', label: 'A'),
        NarrativeFactDefinition(id: 'fact_dup', label: 'B'),
      ]);

      expect(
        () => evaluateCanonicalNarrativeFactSceneCondition(
          source: SceneConditionSource(
            sourceKind: SceneConditionSourceKind.fact,
            sourceId: 'fact_missing',
            operator: SceneConditionOperator.isTrue,
          ),
          gameState: state,
          resolver: unknown,
        ),
        throwsStateError,
      );
      expect(
        () => evaluateCanonicalNarrativeFactSceneCondition(
          source: SceneConditionSource(
            sourceKind: SceneConditionSourceKind.fact,
            sourceId: 'fact_dup',
            operator: SceneConditionOperator.isTrue,
          ),
          gameState: state,
          resolver: ambiguous,
        ),
        throwsStateError,
      );
    });

    test('EventPageResolver resolves authored Fact bindings canonically', () {
      final fact = NarrativeFactDefinition(
        id: 'fact_page',
        label: 'Page',
        defaultValue: true,
      );
      final resolver = NarrativeFactRuntimeResolver.fromFacts([fact]);
      final state = GameState(
        saveId: 'page_binding',
        narrativeFactRuntimeState: NarrativeFactRuntimeState(
          overridesByFactId: const {'fact_page': false},
        ),
      );
      final event = MapEventDefinition(
        id: 'event_page',
        position: const EventPosition(layerId: 'events', x: 0, y: 0),
        pages: [
          MapEventPage(
            pageNumber: 0,
            condition: ScriptConditionFactory.flagIsSet('fact_page'),
            metadata: const {
              EventBuilderMetadataKeys.schemaVersion:
                  EventBuilderMetadataKeys.currentSchemaVersion,
            },
          ),
          const MapEventPage(pageNumber: 1),
        ],
      );

      final context = ScriptEvaluationContext(narrativeFactResolver: resolver);
      final active = const RuntimeStoryBranching().pageResolver.resolve(
            event,
            state,
            contextForPage: (page) =>
                hasEventBuilderPageProvenance(page) ? context : null,
          );

      expect(active, isNotNull);
      expect(active!.pageIndex, 1);
    });

    test('keeps a colliding legacy MapEvent condition raw', () {
      final resolver = NarrativeFactRuntimeResolver.fromFacts([
        NarrativeFactDefinition(
          id: 'quest_gate',
          label: 'Quest gate',
          legacyFlagName: 'canonical_quest_gate',
        ),
      ]);
      const state = GameState(
        saveId: 'legacy_page_collision',
        storyFlags: StoryFlags(activeFlags: {'quest_gate'}),
      );
      final event = MapEventDefinition(
        id: 'legacy_event',
        position: const EventPosition(layerId: 'events', x: 0, y: 0),
        pages: [
          MapEventPage(
            pageNumber: 0,
            condition: ScriptConditionFactory.flagIsSet('quest_gate'),
          ),
          const MapEventPage(pageNumber: 1),
        ],
      );
      final context = ScriptEvaluationContext(narrativeFactResolver: resolver);

      final active = const RuntimeStoryBranching().pageResolver.resolve(
            event,
            state,
            contextForPage: (page) =>
                hasEventBuilderPageProvenance(page) ? context : null,
          );

      expect(active, isNotNull);
      expect(active!.pageIndex, 0);
    });

    test('resolves legacy Event Builder reuse metadata canonically', () {
      final resolver = NarrativeFactRuntimeResolver.fromFacts([
        NarrativeFactDefinition(
          id: 'fact_started',
          label: 'Started',
        ),
      ]);
      final state = GameState(
        saveId: 'legacy_event_builder_page',
        narrativeFactRuntimeState: NarrativeFactRuntimeState(
          overridesByFactId: const {'fact_started': true},
        ),
      );
      final event = MapEventDefinition(
        id: 'legacy_event_builder_event',
        position: const EventPosition(layerId: 'events', x: 0, y: 0),
        pages: [
          MapEventPage(
            pageNumber: 0,
            condition: ScriptConditionFactory.flagIsSet('fact_started'),
            metadata: const {
              EventBuilderMetadataKeys.reusePolicy: 'oneShot',
            },
          ),
          const MapEventPage(pageNumber: 1),
        ],
      );
      final context = ScriptEvaluationContext(narrativeFactResolver: resolver);

      final active = const RuntimeStoryBranching().pageResolver.resolve(
            event,
            state,
            contextForPage: (page) =>
                hasEventBuilderPageProvenance(page) ? context : null,
          );

      expect(active, isNotNull);
      expect(active!.pageIndex, 0);
    });

    test('keeps a future Event Builder schema raw', () {
      final resolver = NarrativeFactRuntimeResolver.fromFacts([
        NarrativeFactDefinition(
          id: 'future_gate',
          label: 'Future gate',
          legacyFlagName: 'canonical_future_gate',
        ),
      ]);
      const state = GameState(
        saveId: 'future_event_builder_page',
        storyFlags: StoryFlags(activeFlags: {'future_gate'}),
      );
      final event = MapEventDefinition(
        id: 'future_event_builder_event',
        position: const EventPosition(layerId: 'events', x: 0, y: 0),
        pages: [
          MapEventPage(
            pageNumber: 0,
            condition: ScriptConditionFactory.flagIsSet('future_gate'),
            metadata: const {
              EventBuilderMetadataKeys.schemaVersion: '2',
              EventBuilderMetadataKeys.reusePolicy: 'oneShot',
            },
          ),
          const MapEventPage(pageNumber: 1),
        ],
      );
      final context = ScriptEvaluationContext(narrativeFactResolver: resolver);

      final active = const RuntimeStoryBranching().pageResolver.resolve(
            event,
            state,
            contextForPage: (page) =>
                hasEventBuilderPageProvenance(page) ? context : null,
          );

      expect(active, isNotNull);
      expect(active!.pageIndex, 0);
    });
  });
}

List<_FactCase> _cases() {
  return [
    _FactCase(
      name: 'default false without flag or override',
      fact: NarrativeFactDefinition(id: 'fact_matrix', label: 'Matrix'),
      state: const GameState(saveId: 'matrix_default_false'),
      expected: false,
    ),
    _FactCase(
      name: 'default true without flag or override',
      fact: NarrativeFactDefinition(
        id: 'fact_matrix',
        label: 'Matrix',
        defaultValue: true,
      ),
      state: const GameState(saveId: 'matrix_default_true'),
      expected: true,
    ),
    _FactCase(
      name: 'active legacy alias without override',
      fact: NarrativeFactDefinition(
        id: 'fact_matrix',
        label: 'Matrix',
        legacyFlagName: 'legacy_matrix',
      ),
      state: const GameState(
        saveId: 'matrix_alias',
        storyFlags: StoryFlags(activeFlags: {'legacy_matrix'}),
      ),
      expected: true,
    ),
    _FactCase(
      name: 'explicit false overrides a true default',
      fact: NarrativeFactDefinition(
        id: 'fact_matrix',
        label: 'Matrix',
        defaultValue: true,
      ),
      state: GameState(
        saveId: 'matrix_override_false',
        narrativeFactRuntimeState: NarrativeFactRuntimeState(
          overridesByFactId: const {'fact_matrix': false},
        ),
      ),
      expected: false,
    ),
    _FactCase(
      name: 'explicit false overrides an active alias',
      fact: NarrativeFactDefinition(
        id: 'fact_matrix',
        label: 'Matrix',
        legacyFlagName: 'legacy_matrix',
      ),
      state: GameState(
        saveId: 'matrix_alias_override_false',
        storyFlags: const StoryFlags(activeFlags: {'legacy_matrix'}),
        narrativeFactRuntimeState: NarrativeFactRuntimeState(
          overridesByFactId: const {'fact_matrix': false},
        ),
      ),
      expected: false,
    ),
    _FactCase(
      name: 'explicit true overrides a false default',
      fact: NarrativeFactDefinition(id: 'fact_matrix', label: 'Matrix'),
      state: GameState(
        saveId: 'matrix_override_true',
        narrativeFactRuntimeState: NarrativeFactRuntimeState(
          overridesByFactId: const {'fact_matrix': true},
        ),
      ),
      expected: true,
    ),
  ];
}

ProjectManifest _project(NarrativeFactDefinition fact) {
  return ProjectManifest(
    name: 'Cross consumer project',
    maps: const [
      ProjectMapEntry(
        id: 'map_test',
        name: 'Map test',
        relativePath: 'maps/map_test.json',
      ),
    ],
    tilesets: const [],
    facts: [fact],
    worldRules: [
      WorldRuleDefinition(
        id: 'world_rule_fact',
        label: 'Fact rule',
        source: const WorldRuleSource(
          kind: WorldRuleSourceKind.fact,
          sourceId: 'fact_matrix',
          predicate: WorldRuleSourcePredicate.isTrue,
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
}

const _map = MapData(
  id: 'map_test',
  name: 'Map test',
  size: GridSize(width: 4, height: 4),
  entities: [
    MapEntity(
      id: 'npc_test',
      name: 'NPC test',
      kind: MapEntityKind.npc,
      pos: GridPos(x: 1, y: 1),
      npc: MapEntityNpcData(displayName: 'NPC test'),
    ),
  ],
);

final class _FactCase {
  const _FactCase({
    required this.name,
    required this.fact,
    required this.state,
    required this.expected,
  });

  final String name;
  final NarrativeFactDefinition fact;
  final GameState state;
  final bool expected;
}
