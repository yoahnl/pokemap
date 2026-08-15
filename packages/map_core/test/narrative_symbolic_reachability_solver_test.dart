import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Narrative symbolic reachability solver', () {
    test('memoizes the semantic key of an immutable symbolic state', () {
      final state = NarrativeSymbolicState(
        factValues: {
          'fact_started': NarrativeValue.boolean(true),
          'fact_score': NarrativeValue.integer(7),
        },
        completedStepIds: const {'step_intro'},
        consumedEventIds: const {'event_intro'},
        badgeIds: const {'badge_first'},
        unlockedFieldAbilities: const {FieldAbility.surf},
        emittedOutcomeKeys: const {'scene_intro.completed'},
        executedEventIds: const {'event_intro'},
      );

      final firstKey = state.semanticKey;
      final secondKey = state.semanticKey;

      expect(secondKey, firstKey);
      expect(identical(secondKey, firstKey), isTrue);
    });

    test('keeps mutually exclusive branches correlated', () {
      final report = solveNarrativeSceneSymbolically(
        _choiceScene(
          leftConsequence: SceneConsequence.setFact(
            factId: 'fact_a',
            value: true,
          ),
          rightConsequence: SceneConsequence.setFact(
            factId: 'fact_b',
            value: true,
          ),
        ),
      );

      expect(report.verdict, NarrativeSymbolicVerdict.pass);
      expect(report.terminalStates, hasLength(2));
      expect(report.canSatisfyAllTrueFacts({'fact_a'}), isTrue);
      expect(report.canSatisfyAllTrueFacts({'fact_b'}), isTrue);
      expect(report.canSatisfyAllTrueFacts({'fact_a', 'fact_b'}), isFalse);
      expect(
        report.terminalStates.every(
          (state) => state.provenance.any(
            (entry) => entry.description.contains('Branche exclusive'),
          ),
        ),
        isTrue,
      );
    });

    test('converges equivalent branch states without losing provenance', () {
      final report = solveNarrativeSceneSymbolically(
        _choiceScene(
          leftConsequence: SceneConsequence.setFact(
            factId: 'fact_done',
            value: true,
          ),
          rightConsequence: SceneConsequence.setFact(
            factId: 'fact_done',
            value: true,
          ),
          converge: true,
        ),
      );

      expect(report.verdict, NarrativeSymbolicVerdict.pass);
      expect(report.terminalStates, hasLength(1));
      expect(report.canSatisfyAllTrueFacts({'fact_done'}), isTrue);
    });

    test('tracks badge and field ability grants as symbolic state', () {
      final report = solveNarrativeSceneSymbolically(
        _consequenceSequenceScene(<SceneConsequence>[
          SceneConsequence.healParty(),
          SceneConsequence.awardBadge(badgeId: 'badge_tide'),
          SceneConsequence.unlockFieldAbility(ability: FieldAbility.surf),
        ]),
      );

      expect(report.verdict, NarrativeSymbolicVerdict.pass);
      expect(report.terminalStates.single.badgeIds, {'badge_tide'});
      expect(
        report.terminalStates.single.unlockedFieldAbilities,
        {FieldAbility.surf},
      );
    });

    test('reports a cycle as fail with reproducible provenance', () {
      final scene = SceneAsset(
        id: 'scene_cycle',
        name: 'Cycle',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(id: 'merge', kind: SceneNodeKind.merge),
          ],
          edges: [
            _edge('start_merge', 'start', 'completed', 'merge'),
            _edge('merge_cycle', 'merge', 'completed', 'merge'),
          ],
        ),
      );

      final report = solveNarrativeSceneSymbolically(scene);

      expect(report.verdict, NarrativeSymbolicVerdict.fail);
      expect(
        report.issues.single.code,
        NarrativeSymbolicIssueCode.cycleDetected,
      );
      expect(report.issues.single.sceneId, 'scene_cycle');
      expect(report.issues.single.nodeId, 'merge');
    });

    test('reports a path with no exit as fail', () {
      final scene = SceneAsset(
        id: 'scene_no_exit',
        name: 'No exit',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'action',
              kind: SceneNodeKind.action,
              payload: SceneActionPayload.consequence(
                SceneConsequence.setFact(factId: 'fact_done', value: true),
              ),
            ),
          ],
          edges: [_edge('start_action', 'start', 'completed', 'action')],
        ),
      );

      final report = solveNarrativeSceneSymbolically(scene);

      expect(report.verdict, NarrativeSymbolicVerdict.fail);
      expect(
        report.issues.single.code,
        NarrativeSymbolicIssueCode.pathWithoutExit,
      );
    });

    test('budget exhaustion is indeterminate and never pass', () {
      final nodes = <SceneNode>[
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        for (var index = 0; index < 8; index++)
          SceneNode(id: 'merge_$index', kind: SceneNodeKind.merge),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ];
      final edges = <SceneEdge>[
        _edge('edge_start', 'start', 'completed', 'merge_0'),
        for (var index = 0; index < 7; index++)
          _edge(
            'edge_$index',
            'merge_$index',
            'completed',
            'merge_${index + 1}',
          ),
        _edge('edge_end', 'merge_7', 'completed', 'end'),
      ];

      final report = solveNarrativeSceneSymbolically(
        SceneAsset(
          id: 'scene_budget',
          name: 'Budget',
          graph: SceneGraph(
            startNodeId: 'start',
            nodes: nodes,
            edges: edges,
          ),
        ),
        explorationBudget: 4,
      );

      expect(report.verdict, NarrativeSymbolicVerdict.indeterminate);
      expect(
        report.issues.single.code,
        NarrativeSymbolicIssueCode.budgetExceeded,
      );
    });

    test('budget boundary is fail-closed below and passes at the exact bound',
        () {
      final scene = _linearScene('scene_budget_boundary');

      final below = solveNarrativeSceneSymbolically(
        scene,
        explorationBudget: 1,
      );
      final exact = solveNarrativeSceneSymbolically(
        scene,
        explorationBudget: 2,
      );

      expect(below.exploredStateCount, 1);
      expect(below.verdict, NarrativeSymbolicVerdict.indeterminate);
      expect(
        below.issues.map((issue) => issue.code),
        contains(NarrativeSymbolicIssueCode.budgetExceeded),
      );
      expect(exact.exploredStateCount, 2);
      expect(exact.verdict, NarrativeSymbolicVerdict.pass);
      expect(exact.issues, isEmpty);
    });

    test('project budget exhaustion between sibling Events never throws', () {
      const map = MapData(
        id: 'map_port',
        name: 'Port',
        size: GridSize(width: 8, height: 8),
      );
      final project = ProjectManifest(
        name: 'Bounded siblings',
        maps: const [
          ProjectMapEntry(
            id: 'map_port',
            name: 'Port',
            relativePath: 'maps/port.json',
          ),
        ],
        tilesets: const [],
        scenes: [_linearScene('scene_a'), _linearScene('scene_b')],
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.v2Only,
          records: [
            for (var index = 0; index < 2; index++)
              NarrativeEventRecord.configuredStructurallyUnchecked(
                NarrativeEventDefinition(
                  id: index == 0
                      ? 'evt_019abcde-5500-7000-8000-000000000001'
                      : 'evt_019abcde-5500-7000-8000-000000000002',
                  name: 'Event $index',
                  source: NarrativeEventSourceRef.mapEnter('map_port'),
                  conditions: const [],
                  sceneId: index == 0 ? 'scene_a' : 'scene_b',
                  reusePolicy: NarrativeEventReusePolicy.oneShot,
                  priority: 0,
                  order: index,
                ),
                enabled: true,
              ),
          ],
          legacyClaims: const [],
        ),
      );

      final report = solveNarrativeSymbolicReachability(
        project,
        maps: const [map],
        explorationBudget: 2,
      );

      expect(report.verdict, NarrativeSymbolicVerdict.indeterminate);
      expect(
        report.issues.map((issue) => issue.code),
        contains(NarrativeSymbolicIssueCode.budgetExceeded),
      );
    });

    test(
        'independent Events use authored order instead of exploring equivalent permutations',
        () {
      const map = MapData(
        id: 'map_port',
        name: 'Port',
        size: GridSize(width: 8, height: 8),
      );
      final project = ProjectManifest(
        name: 'Canonical event scheduling',
        maps: const [
          ProjectMapEntry(
            id: 'map_port',
            name: 'Port',
            relativePath: 'maps/port.json',
          ),
        ],
        tilesets: const [],
        facts: [
          for (var index = 0; index < 6; index++)
            NarrativeFactDefinition(
              id: 'fact_$index',
              label: 'Fact $index',
            ),
          NarrativeFactDefinition(id: 'fact_done', label: 'Done'),
        ],
        scenes: [
          for (var index = 0; index < 6; index++)
            _factScene('scene_$index', 'fact_$index'),
          _factScene('scene_done', 'fact_done'),
        ],
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.v2Only,
          records: [
            for (var index = 0; index < 6; index++)
              NarrativeEventRecord.configuredStructurallyUnchecked(
                NarrativeEventDefinition(
                  id: 'evt_019abcde-5600-7000-8000-00000000000${index + 1}',
                  name: 'Independent Event $index',
                  source: NarrativeEventSourceRef.mapEnter('map_port'),
                  conditions: const [],
                  sceneId: 'scene_$index',
                  reusePolicy: NarrativeEventReusePolicy.oneShot,
                  priority: 0,
                  order: index,
                ),
                enabled: true,
              ),
            NarrativeEventRecord.configuredStructurallyUnchecked(
              NarrativeEventDefinition(
                id: 'evt_019abcde-5600-7000-8000-000000000007',
                name: 'Dependent Event',
                source: NarrativeEventSourceRef.mapEnter('map_port'),
                conditions: [NarrativeEventCondition.fact('fact_5', true)],
                sceneId: 'scene_done',
                reusePolicy: NarrativeEventReusePolicy.oneShot,
                priority: 0,
                order: 6,
              ),
              enabled: true,
            ),
          ],
          legacyClaims: const [],
        ),
      );

      final report = solveNarrativeSymbolicReachability(
        project,
        maps: const [map],
        explorationBudget: 36,
      );

      expect(report.verdict, NarrativeSymbolicVerdict.pass);
      expect(report.terminalStates, hasLength(1));
      expect(report.terminalStates.single.hasTrueFact('fact_done'), isTrue);
      expect(
        report.issues.map((issue) => issue.code),
        isNot(contains(NarrativeSymbolicIssueCode.budgetExceeded)),
      );
    });

    test(
        'decomposes independent side quests instead of multiplying their branches',
        () {
      const map = MapData(
        id: 'map_port',
        name: 'Port',
        size: GridSize(width: 8, height: 8),
      );
      final project = ProjectManifest(
        name: 'Independent side quests',
        maps: const [
          ProjectMapEntry(
            id: 'map_port',
            name: 'Port',
            relativePath: 'maps/port.json',
          ),
        ],
        tilesets: const [],
        facts: [
          for (var quest = 0; quest < 4; quest++) ...[
            NarrativeFactDefinition(
              id: 'fact_quest_${quest}_left',
              label: 'Quest $quest left',
            ),
            NarrativeFactDefinition(
              id: 'fact_quest_${quest}_right',
              label: 'Quest $quest right',
            ),
          ],
        ],
        scenes: [
          _linearScene('scene_start'),
          for (var quest = 0; quest < 4; quest++) _optionalChoiceScene(quest),
          _optionalStepScene(),
        ],
        storylines: [
          for (var quest = 0; quest < 4; quest++)
            StorylineAsset(
              id: 'story_optional_$quest',
              type: StorylineType.sideQuest,
              status: StorylineStatus.active,
              title: 'Optional $quest',
            ),
          StorylineAsset(
            id: 'story_optional_step',
            type: StorylineType.sideQuest,
            status: StorylineStatus.active,
            title: 'Optional step',
          ),
        ],
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.v2Only,
          records: [
            for (var quest = 0; quest < 4; quest++)
              NarrativeEventRecord.configuredStructurallyUnchecked(
                NarrativeEventDefinition(
                  id: 'evt_019abcde-5700-7000-8000-00000000000${quest + 1}',
                  name: 'Optional Event $quest',
                  source: NarrativeEventSourceRef.mapEnter('map_port'),
                  conditions: const [],
                  sceneId: 'scene_optional_$quest',
                  reusePolicy: NarrativeEventReusePolicy.oneShot,
                  priority: 0,
                  order: quest,
                ),
                enabled: true,
              ),
            NarrativeEventRecord.configuredStructurallyUnchecked(
              NarrativeEventDefinition(
                id: 'evt_019abcde-5700-7000-8000-000000000005',
                name: 'Optional Step Event',
                source: NarrativeEventSourceRef.mapEnter('map_port'),
                conditions: const [],
                sceneId: 'scene_optional_step',
                reusePolicy: NarrativeEventReusePolicy.oneShot,
                priority: 0,
                order: 4,
              ),
              enabled: true,
            ),
          ],
          legacyClaims: const [],
        ),
        newGame: const ProjectNewGameConfig(
          enabled: true,
          preSessionSceneId: 'scene_start',
        ),
      );

      final report = solveNarrativeSymbolicReachability(
        project,
        maps: const [map],
        explorationBudget: 80,
      );

      expect(report.verdict, NarrativeSymbolicVerdict.pass);
      expect(report.exploredStateCount, lessThan(80));
      for (var quest = 0; quest < 4; quest++) {
        expect(report.trueFactIds, contains('fact_quest_${quest}_left'));
        expect(report.trueFactIds, contains('fact_quest_${quest}_right'));
      }
      expect(report.completedStepIds, contains('step_optional'));
      expect(
        report.canSatisfyAllTrueFacts({
          'fact_quest_0_left',
          'fact_quest_1_left',
          'fact_quest_2_right',
          'fact_quest_3_left',
        }),
        isTrue,
      );
      expect(
        report.canSatisfyAllTrueFacts({
          'fact_quest_0_left',
          'fact_quest_0_right',
        }),
        isFalse,
      );
      expect(
        report.issues.map((issue) => issue.code),
        isNot(contains(NarrativeSymbolicIssueCode.budgetExceeded)),
      );
    });

    test('never dispatches an optional event from an intra-scene fact', () {
      const map = MapData(
        id: 'map_port',
        name: 'Port',
        size: GridSize(width: 8, height: 8),
      );
      final project = ProjectManifest(
        name: 'Event boundary evidence',
        maps: const [
          ProjectMapEntry(
            id: 'map_port',
            name: 'Port',
            relativePath: 'maps/port.json',
          ),
        ],
        tilesets: const [],
        facts: [
          NarrativeFactDefinition(id: 'fact_gate', label: 'Gate'),
          NarrativeFactDefinition(id: 'fact_optional', label: 'Optional'),
        ],
        scenes: [
          _factToggleScene(
            id: 'scene_starter',
            factId: 'fact_gate',
          ),
          _optionalFactScene(
            id: 'scene_optional',
            storylineId: 'story_optional',
            factId: 'fact_optional',
          ),
        ],
        storylines: [
          StorylineAsset(
            id: 'story_optional',
            type: StorylineType.sideQuest,
            status: StorylineStatus.active,
            title: 'Optional',
          ),
        ],
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.v2Only,
          records: [
            NarrativeEventRecord.configuredStructurallyUnchecked(
              NarrativeEventDefinition(
                id: 'evt_019abcde-5900-7000-8000-000000000001',
                name: 'Transiently eligible optional event',
                source: NarrativeEventSourceRef.mapEnter('map_port'),
                conditions: [
                  NarrativeEventCondition.fact('fact_gate', true),
                ],
                sceneId: 'scene_optional',
                reusePolicy: NarrativeEventReusePolicy.oneShot,
                priority: 0,
                order: 0,
              ),
              enabled: true,
            ),
          ],
          legacyClaims: const [],
        ),
        newGame: const ProjectNewGameConfig(
          enabled: true,
          preSessionSceneId: 'scene_starter',
        ),
      );

      final report = solveNarrativeSymbolicReachability(
        project,
        maps: const [map],
      );

      expect(report.verdict, NarrativeSymbolicVerdict.pass);
      expect(report.trueFactIds, isNot(contains('fact_gate')));
      expect(report.trueFactIds, isNot(contains('fact_optional')));
      expect(report.reachableSceneIds, isNot(contains('scene_optional')));
    });

    test('keeps an optional component correlated with its main-story seed', () {
      const map = MapData(
        id: 'map_port',
        name: 'Port',
        size: GridSize(width: 8, height: 8),
      );
      final project = ProjectManifest(
        name: 'Seed-correlated side quest',
        maps: const [
          ProjectMapEntry(
            id: 'map_port',
            name: 'Port',
            relativePath: 'maps/port.json',
          ),
        ],
        tilesets: const [],
        facts: [
          NarrativeFactDefinition(id: 'fact_main_a', label: 'Main A'),
          NarrativeFactDefinition(id: 'fact_main_b', label: 'Main B'),
          NarrativeFactDefinition(id: 'fact_optional', label: 'Optional'),
          NarrativeFactDefinition(
            id: 'fact_optional_all',
            label: 'Optional on every branch',
          ),
        ],
        scenes: [
          _choiceScene(
            leftConsequence: SceneConsequence.setFact(
              factId: 'fact_main_a',
              value: true,
            ),
            rightConsequence: SceneConsequence.setFact(
              factId: 'fact_main_b',
              value: true,
            ),
          ),
          _optionalFactScene(
            id: 'scene_optional',
            storylineId: 'story_optional',
            factId: 'fact_optional',
          ),
          _optionalFactScene(
            id: 'scene_optional_all',
            storylineId: 'story_optional_all',
            factId: 'fact_optional_all',
          ),
        ],
        storylines: [
          StorylineAsset(
            id: 'story_optional',
            type: StorylineType.sideQuest,
            status: StorylineStatus.active,
            title: 'Optional',
          ),
          StorylineAsset(
            id: 'story_optional_all',
            type: StorylineType.sideQuest,
            status: StorylineStatus.active,
            title: 'Optional on every branch',
          ),
        ],
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.v2Only,
          records: [
            NarrativeEventRecord.configuredStructurallyUnchecked(
              NarrativeEventDefinition(
                id: 'evt_019abcde-5a00-7000-8000-000000000001',
                name: 'Optional after branch A',
                source: NarrativeEventSourceRef.mapEnter('map_port'),
                conditions: [
                  NarrativeEventCondition.fact('fact_main_a', true),
                ],
                sceneId: 'scene_optional',
                reusePolicy: NarrativeEventReusePolicy.oneShot,
                priority: 0,
                order: 0,
              ),
              enabled: true,
            ),
            NarrativeEventRecord.configuredStructurallyUnchecked(
              NarrativeEventDefinition(
                id: 'evt_019abcde-5a00-7000-8000-000000000002',
                name: 'Optional after either main branch',
                source: NarrativeEventSourceRef.mapEnter('map_port'),
                conditions: const [],
                sceneId: 'scene_optional_all',
                reusePolicy: NarrativeEventReusePolicy.oneShot,
                priority: 0,
                order: 1,
              ),
              enabled: true,
            ),
          ],
          legacyClaims: const [],
        ),
        newGame: const ProjectNewGameConfig(
          enabled: true,
          preSessionSceneId: 'scene_choice',
        ),
      );

      final report = solveNarrativeSymbolicReachability(
        project,
        maps: const [map],
      );

      expect(report.verdict, NarrativeSymbolicVerdict.pass);
      expect(
        report.canSatisfyAllTrueFacts({
          'fact_main_a',
          'fact_optional',
        }),
        isTrue,
      );
      expect(
        report.canSatisfyAllTrueFacts({
          'fact_main_b',
          'fact_optional',
        }),
        isFalse,
      );
      expect(
        report.canSatisfyAllTrueFacts({
          'fact_main_a',
          'fact_optional_all',
        }),
        isTrue,
      );
      expect(
        report.canSatisfyAllTrueFacts({
          'fact_main_b',
          'fact_optional_all',
        }),
        isTrue,
      );
    });

    test('keeps dependent side quests in the same symbolic component', () {
      const map = MapData(
        id: 'map_port',
        name: 'Port',
        size: GridSize(width: 8, height: 8),
      );
      final project = ProjectManifest(
        name: 'Dependent side quests',
        maps: const [
          ProjectMapEntry(
            id: 'map_port',
            name: 'Port',
            relativePath: 'maps/port.json',
          ),
        ],
        tilesets: const [],
        facts: [
          NarrativeFactDefinition(id: 'fact_a', label: 'A'),
          NarrativeFactDefinition(id: 'fact_b', label: 'B'),
        ],
        scenes: [
          _linearScene('scene_start'),
          _optionalFactScene(
            id: 'scene_optional_a',
            storylineId: 'story_optional_a',
            factId: 'fact_a',
          ),
          _optionalFactScene(
            id: 'scene_optional_b',
            storylineId: 'story_optional_b',
            factId: 'fact_b',
          ),
        ],
        storylines: [
          StorylineAsset(
            id: 'story_optional_a',
            type: StorylineType.sideQuest,
            status: StorylineStatus.active,
            title: 'Optional A',
          ),
          StorylineAsset(
            id: 'story_optional_b',
            type: StorylineType.sideQuest,
            status: StorylineStatus.active,
            title: 'Optional B',
          ),
        ],
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.v2Only,
          records: [
            NarrativeEventRecord.configuredStructurallyUnchecked(
              NarrativeEventDefinition(
                id: 'evt_019abcde-5800-7000-8000-000000000001',
                name: 'Optional A',
                source: NarrativeEventSourceRef.mapEnter('map_port'),
                conditions: const [],
                sceneId: 'scene_optional_a',
                reusePolicy: NarrativeEventReusePolicy.oneShot,
                priority: 0,
                order: 0,
              ),
              enabled: true,
            ),
            NarrativeEventRecord.configuredStructurallyUnchecked(
              NarrativeEventDefinition(
                id: 'evt_019abcde-5800-7000-8000-000000000002',
                name: 'Optional B after A',
                source: NarrativeEventSourceRef.mapEnter('map_port'),
                conditions: [
                  NarrativeEventCondition.fact('fact_a', true),
                ],
                sceneId: 'scene_optional_b',
                reusePolicy: NarrativeEventReusePolicy.oneShot,
                priority: 0,
                order: 1,
              ),
              enabled: true,
            ),
          ],
          legacyClaims: const [],
        ),
        newGame: const ProjectNewGameConfig(
          enabled: true,
          preSessionSceneId: 'scene_start',
        ),
      );

      final report = solveNarrativeSymbolicReachability(
        project,
        maps: const [map],
      );

      expect(report.verdict, NarrativeSymbolicVerdict.pass);
      expect(report.trueFactIds, containsAll(<String>['fact_a', 'fact_b']));
    });

    test('unknown legacy command backend is indeterminate', () {
      final scene = SceneAsset(
        id: 'scene_unknown_command',
        name: 'Unknown command',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'unknown',
              kind: SceneNodeKind.action,
              payload: SceneActionPayload(actionKind: 'custom_script'),
            ),
            SceneNode(id: 'end', kind: SceneNodeKind.end),
          ],
          edges: [
            _edge('start_unknown', 'start', 'completed', 'unknown'),
            _edge('unknown_end', 'unknown', 'completed', 'end'),
          ],
        ),
      );

      final report = solveNarrativeSceneSymbolically(scene);

      expect(report.verdict, NarrativeSymbolicVerdict.indeterminate);
      expect(
        report.issues.single.code,
        NarrativeSymbolicIssueCode.unsupportedCommand,
      );
    });

    test('a broken active side quest does not fail the mandatory project', () {
      const optionalEventId = 'evt_019abcde-5400-7000-8000-000000000003';
      final mainScene = _linearScene('scene_main');
      final optionalScene = SceneAsset(
        id: 'scene_optional',
        name: 'Optional',
        storylineId: 'story_optional',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
          ],
        ),
      );
      final project = ProjectManifest(
        name: 'Optional quest',
        maps: const [
          ProjectMapEntry(
            id: 'map_port',
            name: 'Port',
            relativePath: 'maps/port.json',
          ),
        ],
        tilesets: const [],
        scenes: [mainScene, optionalScene],
        storylines: [
          StorylineAsset(
            id: 'story_optional',
            type: StorylineType.sideQuest,
            status: StorylineStatus.active,
            title: 'Optional',
          ),
        ],
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.v2Only,
          records: [
            NarrativeEventRecord.configuredStructurallyUnchecked(
              NarrativeEventDefinition(
                id: optionalEventId,
                name: 'Optional broken path',
                source: NarrativeEventSourceRef.mapEnter('map_port'),
                conditions: const [],
                sceneId: 'scene_optional',
                reusePolicy: NarrativeEventReusePolicy.oneShot,
                priority: 0,
                order: 0,
              ),
              enabled: true,
            ),
          ],
          legacyClaims: const [],
        ),
        newGame: const ProjectNewGameConfig(
          enabled: true,
          preSessionSceneId: 'scene_main',
        ),
      );
      const map = MapData(
        id: 'map_port',
        name: 'Port',
        size: GridSize(width: 8, height: 8),
      );

      final report = solveNarrativeSymbolicReachability(
        project,
        maps: const [map],
      );

      expect(report.verdict, NarrativeSymbolicVerdict.pass);
      expect(report.reachableSceneIds, contains('scene_main'));
      expect(report.reachableSceneIds, contains('scene_optional'));
      expect(report.issues.single.optional, isTrue);
      expect(
        report.issues.single.code,
        NarrativeSymbolicIssueCode.pathWithoutExit,
      );
    });

    test('project validator rejects a conjunction built from exclusive paths',
        () {
      const producerEventId = 'evt_019abcde-5400-7000-8000-000000000001';
      const consumerEventId = 'evt_019abcde-5400-7000-8000-000000000002';
      final map = const MapData(
        id: 'map_port',
        name: 'Port',
        size: GridSize(width: 8, height: 8),
      );
      final project = ProjectManifest(
        name: 'Correlated validation',
        maps: const [
          ProjectMapEntry(
            id: 'map_port',
            name: 'Port',
            relativePath: 'maps/port.json',
          ),
        ],
        tilesets: const [],
        facts: [
          NarrativeFactDefinition(id: 'fact_a', label: 'A'),
          NarrativeFactDefinition(id: 'fact_b', label: 'B'),
        ],
        scenes: [
          _choiceScene(
            leftConsequence: SceneConsequence.setFact(
              factId: 'fact_a',
              value: true,
            ),
            rightConsequence: SceneConsequence.setFact(
              factId: 'fact_b',
              value: true,
            ),
          ),
          _linearScene('scene_consumer'),
        ],
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.v2Only,
          records: [
            NarrativeEventRecord.configuredStructurallyUnchecked(
              NarrativeEventDefinition(
                id: producerEventId,
                name: 'Choose',
                source: NarrativeEventSourceRef.mapEnter('map_port'),
                conditions: const [],
                sceneId: 'scene_choice',
                reusePolicy: NarrativeEventReusePolicy.oneShot,
                priority: 10,
                order: 0,
              ),
              enabled: true,
            ),
            NarrativeEventRecord.configuredStructurallyUnchecked(
              NarrativeEventDefinition(
                id: consumerEventId,
                name: 'Impossible consumer',
                source: NarrativeEventSourceRef.mapEnter('map_port'),
                conditions: [
                  NarrativeEventCondition.fact('fact_a', true),
                  NarrativeEventCondition.fact('fact_b', true),
                ],
                sceneId: 'scene_consumer',
                reusePolicy: NarrativeEventReusePolicy.oneShot,
                priority: 0,
                order: 1,
              ),
              enabled: true,
            ),
          ],
          legacyClaims: const [],
        ),
      );

      final symbolic = solveNarrativeSymbolicReachability(
        project,
        maps: [map],
      );
      final validation = validateNarrativeProject(project, maps: [map]);

      expect(symbolic.verdict, NarrativeSymbolicVerdict.fail);
      expect(
        symbolic.issues.map((issue) => issue.code),
        contains(NarrativeSymbolicIssueCode.mutuallyExclusiveRequirements),
      );
      expect(
        validation.byCode('narrativeMutuallyExclusiveRequirements'),
        hasLength(1),
      );
      expect(validation.narrativelySolvable, NarrativeSymbolicVerdict.fail);
      expect(validation.isPlayable, isFalse);
    });
  });
}

SceneAsset _choiceScene({
  required SceneConsequence leftConsequence,
  required SceneConsequence rightConsequence,
  bool converge = false,
}) {
  return SceneAsset(
    id: 'scene_choice',
    name: 'Choice',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'choice',
          kind: SceneNodeKind.yarnDialogue,
          payload: SceneYarnDialoguePayload(
            dialogueId: 'dialogue_choice',
            expectedOutcomes: const ['left', 'right'],
          ),
        ),
        SceneNode(
          id: 'left',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(leftConsequence),
        ),
        SceneNode(
          id: 'right',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(rightConsequence),
        ),
        if (converge) SceneNode(id: 'merge', kind: SceneNodeKind.merge),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: [
        _edge('start_choice', 'start', 'completed', 'choice'),
        SceneEdge(
          id: 'choice_left',
          fromNodeId: 'choice',
          fromPortId: 'left',
          toNodeId: 'left',
          kind: SceneEdgeKind.dialogueOutcome,
        ),
        SceneEdge(
          id: 'choice_right',
          fromNodeId: 'choice',
          fromPortId: 'right',
          toNodeId: 'right',
          kind: SceneEdgeKind.dialogueOutcome,
        ),
        _edge(
          'left_next',
          'left',
          'completed',
          converge ? 'merge' : 'end',
          kind: SceneEdgeKind.actionCompleted,
        ),
        _edge(
          'right_next',
          'right',
          'completed',
          converge ? 'merge' : 'end',
          kind: SceneEdgeKind.actionCompleted,
        ),
        if (converge) _edge('merge_end', 'merge', 'completed', 'end'),
      ],
    ),
  );
}

SceneAsset _optionalChoiceScene(int quest) {
  final scene = _choiceScene(
    leftConsequence: SceneConsequence.setFact(
      factId: 'fact_quest_${quest}_left',
      value: true,
    ),
    rightConsequence: SceneConsequence.setFact(
      factId: 'fact_quest_${quest}_right',
      value: true,
    ),
  );
  return SceneAsset(
    id: 'scene_optional_$quest',
    name: 'Optional $quest',
    storylineId: 'story_optional_$quest',
    graph: scene.graph,
  );
}

SceneAsset _optionalFactScene({
  required String id,
  required String storylineId,
  required String factId,
}) {
  final scene = _factScene(id, factId);
  return SceneAsset(
    id: id,
    name: id,
    storylineId: storylineId,
    graph: scene.graph,
  );
}

SceneAsset _optionalStepScene() {
  final scene = _consequenceSequenceScene([
    SceneConsequence.completeStoryStep(stepId: 'step_optional'),
  ]);
  return SceneAsset(
    id: 'scene_optional_step',
    name: 'Optional step',
    storylineId: 'story_optional_step',
    graph: scene.graph,
  );
}

SceneAsset _linearScene(String id) => SceneAsset(
      id: id,
      name: id,
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(id: 'end', kind: SceneNodeKind.end),
        ],
        edges: [_edge('start_end', 'start', 'completed', 'end')],
      ),
    );

SceneAsset _consequenceSequenceScene(List<SceneConsequence> consequences) {
  return SceneAsset(
    id: 'scene_consequences',
    name: 'Consequences',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: <SceneNode>[
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        for (var index = 0; index < consequences.length; index++)
          SceneNode(
            id: 'action_$index',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.consequence(consequences[index]),
          ),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: <SceneEdge>[
        _edge('start_action', 'start', 'completed', 'action_0'),
        for (var index = 0; index < consequences.length - 1; index++)
          _edge(
            'action_${index}_next',
            'action_$index',
            'completed',
            'action_${index + 1}',
            kind: SceneEdgeKind.actionCompleted,
          ),
        _edge(
          'action_end',
          'action_${consequences.length - 1}',
          'completed',
          'end',
          kind: SceneEdgeKind.actionCompleted,
        ),
      ],
    ),
  );
}

SceneAsset _factScene(String id, String factId) => SceneAsset(
      id: id,
      name: id,
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'set_fact',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.consequence(
              SceneConsequence.setFact(factId: factId, value: true),
            ),
          ),
          SceneNode(id: 'end', kind: SceneNodeKind.end),
        ],
        edges: [
          _edge('start_action', 'start', 'completed', 'set_fact'),
          _edge(
            'action_end',
            'set_fact',
            'completed',
            'end',
            kind: SceneEdgeKind.actionCompleted,
          ),
        ],
      ),
    );

SceneAsset _factToggleScene({
  required String id,
  required String factId,
}) =>
    SceneAsset(
      id: id,
      name: id,
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'set_true',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.consequence(
              SceneConsequence.setFact(factId: factId, value: true),
            ),
          ),
          SceneNode(
            id: 'set_false',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.consequence(
              SceneConsequence.setFact(factId: factId, value: false),
            ),
          ),
          SceneNode(id: 'end', kind: SceneNodeKind.end),
        ],
        edges: [
          _edge('start_true', 'start', 'completed', 'set_true'),
          _edge(
            'true_false',
            'set_true',
            'completed',
            'set_false',
            kind: SceneEdgeKind.actionCompleted,
          ),
          _edge(
            'false_end',
            'set_false',
            'completed',
            'end',
            kind: SceneEdgeKind.actionCompleted,
          ),
        ],
      ),
    );

SceneEdge _edge(
  String id,
  String from,
  String port,
  String to, {
  SceneEdgeKind kind = SceneEdgeKind.defaultFlow,
}) =>
    SceneEdge(
      id: id,
      fromNodeId: from,
      fromPortId: port,
      toNodeId: to,
      kind: kind,
    );
