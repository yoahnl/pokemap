import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('NarrativeDependencyIndex contract', () {
    test('indexes map and warp references from interactive Scene commands', () {
      final scene = SceneAsset(
        id: 'scene.warp',
        name: 'Warp',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'warp',
              kind: SceneNodeKind.action,
              payload: SceneActionPayload.interactive(
                SceneInteractiveCommand.warp(
                  destinationMapId: 'map.port',
                  warpId: 'warp.arrival',
                ),
              ),
            ),
            SceneNode(id: 'end', kind: SceneNodeKind.end),
          ],
          edges: [
            SceneEdge(
              id: 'start-warp',
              fromNodeId: 'start',
              fromPortId: 'completed',
              toNodeId: 'warp',
              kind: SceneEdgeKind.defaultFlow,
            ),
            SceneEdge(
              id: 'warp-end',
              fromNodeId: 'warp',
              fromPortId: 'completed',
              toNodeId: 'end',
              kind: SceneEdgeKind.actionCompleted,
            ),
          ],
        ),
      );
      final index = buildNarrativeDependencyIndex(
        project: _project().copyWith(scenes: [scene]),
      );

      final sceneUsages = index.usagesOwnedBy(
        const NarrativeDependencyKey.scene('scene.warp'),
      );
      expect(
        sceneUsages.map((usage) => usage.path),
        containsAll([
          contains('interactiveCommand.destinationMapId'),
          contains('interactiveCommand.warpId'),
        ]),
      );
    });

    test('builds an empty immutable index for an empty project', () {
      final index = buildNarrativeDependencyIndex(
        project: _project(),
      );

      expect(index.definitions, isEmpty);
      expect(index.usages, isEmpty);
      expect(index.issues, isEmpty);
      expect(
        () => index.definitions.add(
          NarrativeDependencyDefinition(
            key: const NarrativeDependencyKey(
              NarrativeDependencyTargetKind.fact,
              'fact.any',
            ),
            label: 'Any',
          ),
        ),
        throwsUnsupportedError,
      );
    });

    test('sorts definitions and usages and supports both query directions', () {
      const factA = NarrativeDependencyKey(
        NarrativeDependencyTargetKind.fact,
        'a',
      );
      const factB = NarrativeDependencyKey(
        NarrativeDependencyTargetKind.fact,
        'b',
      );
      const scene = NarrativeDependencyKey(
        NarrativeDependencyTargetKind.scene,
        'scene.main',
      );
      final index = NarrativeDependencyIndex(
        definitions: <NarrativeDependencyDefinition>[
          NarrativeDependencyDefinition(key: factB, label: 'B'),
          NarrativeDependencyDefinition(key: scene, label: 'Scene'),
          NarrativeDependencyDefinition(key: factA, label: 'A'),
        ],
        usages: const <NarrativeDependencyUsage>[
          NarrativeDependencyUsage(
            target: factB,
            owner: scene,
            path: 'graph.nodes[2].condition',
            criticality: NarrativeDependencyCriticality.authoringWarning,
          ),
          NarrativeDependencyUsage(
            target: factA,
            owner: scene,
            path: 'graph.nodes[1].condition',
            criticality: NarrativeDependencyCriticality.runtimeBlocking,
          ),
        ],
      );

      expect(
          index.definitions.map((entry) => entry.key), [factA, factB, scene]);
      expect(index.usages.map((entry) => entry.target), [factA, factB]);
      expect(index.definitionsFor(factA), hasLength(1));
      expect(index.usagesFor(factB), hasLength(1));
      expect(index.usagesOwnedBy(scene), hasLength(2));
      expect(() => index.usages.clear(), throwsUnsupportedError);
    });

    test('exposes a neutral navigation intent', () {
      const intent = NarrativeDependencyNavigationIntent(
        kind: NarrativeDependencyTargetKind.scene,
        assetId: 'scene.main',
        parentId: 'story.main',
        context: 'chapter.intro',
      );

      expect(intent.kind, NarrativeDependencyTargetKind.scene);
      expect(intent.assetId, 'scene.main');
      expect(intent.parentId, 'story.main');
      expect(intent.context, 'chapter.intro');
    });

    test('qualified navigation intent preserves the complete target key', () {
      const key = NarrativeDependencyKey.mapSource(
        mapId: 'map.port',
        sourceKind: 'entity',
        sourceId: 'npc.lysa',
      );
      final intent = NarrativeDependencyNavigationIntent.fromKey(
        key,
        context: 'maps[map.port].entities[0]',
      );

      expect(intent.kind, NarrativeDependencyTargetKind.sourceMap);
      expect(intent.assetId, 'npc.lysa');
      expect(intent.scope, 'map');
      expect(intent.parentId, 'map.port');
      expect(intent.mapId, 'map.port');
      expect(intent.sourceKind, 'entity');
      expect(intent.context, 'maps[map.port].entities[0]');
      expect(
        intent,
        NarrativeDependencyNavigationIntent.fromKey(
          key,
          context: 'maps[map.port].entities[0]',
        ),
      );
    });

    test('indexed Chapter and Step intents preserve their authoring hierarchy',
        () {
      final index = buildNarrativeDependencyIndex(
        project: _project(storylines: <StorylineAsset>[_storyline()]),
      );
      final chapter = index
          .definitionsFor(
            const NarrativeDependencyKey(
              NarrativeDependencyTargetKind.chapter,
              'chapter.intro',
            ),
          )
          .single
          .navigationIntent;
      final step = index
          .definitionsFor(
            const NarrativeDependencyKey(
              NarrativeDependencyTargetKind.step,
              'step.intro',
            ),
          )
          .single
          .navigationIntent;

      expect(chapter?.parentId, 'story.main');
      expect(chapter?.rootId, isNull);
      expect(step?.parentId, 'chapter.intro');
      expect(step?.rootId, 'story.main');
    });

    test('fully orders equal-prefix entries independently of input order', () {
      const fact = NarrativeDependencyKey(
        NarrativeDependencyTargetKind.fact,
        'fact.same',
      );
      const scene = NarrativeDependencyKey.scene('scene.same');
      final definitions = <NarrativeDependencyDefinition>[
        NarrativeDependencyDefinition(
          key: fact,
          label: 'Same',
          path: 'same.path',
          navigationIntent: const NarrativeDependencyNavigationIntent(
            kind: NarrativeDependencyTargetKind.fact,
            assetId: 'fact.same',
            context: 'z-context',
          ),
          metadata: const <String, String>{'z': '2'},
        ),
        NarrativeDependencyDefinition(
          key: fact,
          label: 'Same',
          path: 'same.path',
          navigationIntent: const NarrativeDependencyNavigationIntent(
            kind: NarrativeDependencyTargetKind.fact,
            assetId: 'fact.same',
            context: 'a-context',
          ),
          metadata: const <String, String>{'a': '1'},
        ),
      ];
      const usages = <NarrativeDependencyUsage>[
        NarrativeDependencyUsage(
          target: fact,
          owner: scene,
          path: 'same.path',
          criticality: NarrativeDependencyCriticality.runtimeBlocking,
          resolution: NarrativeDependencyResolution.missing,
        ),
        NarrativeDependencyUsage(
          target: fact,
          owner: scene,
          path: 'same.path',
          criticality: NarrativeDependencyCriticality.authoringWarning,
          resolution: NarrativeDependencyResolution.resolved,
        ),
      ];
      const issues = <NarrativeDependencyIssue>[
        NarrativeDependencyIssue(
          kind: NarrativeDependencyIssueKind.missingReference,
          target: fact,
          owner: scene,
          path: 'same.path',
          criticality: NarrativeDependencyCriticality.runtimeBlocking,
          message: 'z-message',
        ),
        NarrativeDependencyIssue(
          kind: NarrativeDependencyIssueKind.missingReference,
          target: fact,
          owner: scene,
          path: 'same.path',
          criticality: NarrativeDependencyCriticality.authoringWarning,
          message: 'a-message',
        ),
      ];

      List<String> snapshot(NarrativeDependencyIndex index) => <String>[
            for (final definition in index.definitions)
              'definition|${definition.key}|${definition.label}|'
                  '${definition.path}|${definition.navigationIntent?.context}|'
                  '${definition.metadata}',
            for (final usage in index.usages)
              'usage|${usage.target}|${usage.owner}|${usage.path}|'
                  '${usage.criticality.name}|${usage.resolution.name}|'
                  '${usage.navigationIntent?.context}',
            for (final issue in index.issues)
              'issue|${issue.target}|${issue.owner}|${issue.path}|'
                  '${issue.kind.name}|${issue.criticality.name}|${issue.message}',
          ];

      final forward = NarrativeDependencyIndex(
        definitions: definitions,
        usages: usages,
        issues: issues,
      );
      final reversed = NarrativeDependencyIndex(
        definitions: definitions.reversed,
        usages: usages.reversed,
        issues: issues.reversed,
      );

      expect(snapshot(forward), snapshot(reversed));
      expect(
        () => forward.definitions.first.metadata['forbidden'] = 'mutation',
        throwsUnsupportedError,
      );
    });
  });

  group('New Game, Event V2 and Scene collectors', () {
    test('indexes New Game facts, map and starter Scene with resolutions', () {
      final project = _project(
        maps: const <ProjectMapEntry>[
          ProjectMapEntry(
            id: 'map.port',
            name: 'Port',
            relativePath: 'maps/port.json',
          ),
        ],
        facts: <NarrativeFactDefinition>[
          NarrativeFactDefinition(id: 'party.exists', label: 'Party exists'),
          NarrativeFactDefinition(id: 'intro.seen', label: 'Intro seen'),
        ],
        newGame: const ProjectNewGameConfig(
          enabled: true,
          startMapId: 'map.port',
          initialFacts: <String, bool>{
            'missing.fact': false,
            'intro.seen': true,
          },
          existingPartyFactId: 'party.exists',
          starterSelectionSceneId: 'scene.missing',
        ),
      );

      final index = buildNarrativeDependencyIndex(project: project);
      final usages = index.usagesOwnedBy(_newGameOwner);

      expect(
        usages.map((usage) => (usage.path, usage.resolution)),
        containsAll(<(String, NarrativeDependencyResolution)>[
          (
            'newGame.startMapId',
            NarrativeDependencyResolution.unavailable,
          ),
          (
            'newGame.initialFacts[intro.seen]',
            NarrativeDependencyResolution.resolved,
          ),
          (
            'newGame.initialFacts[missing.fact]',
            NarrativeDependencyResolution.missing,
          ),
          (
            'newGame.existingPartyFactId',
            NarrativeDependencyResolution.resolved,
          ),
          (
            'newGame.starterSelectionSceneId',
            NarrativeDependencyResolution.missing,
          ),
        ]),
      );
    });

    test('indexes the configured New Game spawn inside its start map', () {
      final project = _project(
        maps: const <ProjectMapEntry>[
          ProjectMapEntry(
            id: 'map.port',
            name: 'Port',
            relativePath: 'maps/port.json',
          ),
        ],
        newGame: const ProjectNewGameConfig(
          enabled: true,
          startMapId: 'map.port',
          startSpawnId: 'spawn.player',
        ),
      );
      final map = MapData(
        id: 'map.port',
        name: 'Port',
        size: const GridSize(width: 5, height: 5),
        entities: const <MapEntity>[
          MapEntity(
            id: 'spawn.player',
            kind: MapEntityKind.spawn,
            pos: GridPos(x: 1, y: 1),
            spawn: MapEntitySpawnData(),
          ),
        ],
      );

      final index = buildNarrativeDependencyIndex(
        project: project,
        maps: <MapData>[map],
      );
      final spawnUsage = index
          .usagesOwnedBy(_newGameOwner)
          .singleWhere((usage) => usage.path == 'newGame.startSpawnId');

      expect(
        spawnUsage.target,
        const NarrativeDependencyKey.mapSource(
          mapId: 'map.port',
          sourceKind: 'entity',
          sourceId: 'spawn.player',
        ),
      );
      expect(spawnUsage.resolution, NarrativeDependencyResolution.resolved);
    });

    test('distinguishes unavailable and missing New Game spawn data', () {
      final project = _project(
        maps: const <ProjectMapEntry>[
          ProjectMapEntry(
            id: 'map.port',
            name: 'Port',
            relativePath: 'maps/port.json',
          ),
        ],
        newGame: const ProjectNewGameConfig(
          enabled: true,
          startMapId: 'map.port',
          startSpawnId: 'spawn.missing',
        ),
      );

      final unavailable = buildNarrativeDependencyIndex(project: project);
      final missing = buildNarrativeDependencyIndex(
        project: project,
        maps: <MapData>[_emptyMap('map.port')],
      );

      NarrativeDependencyResolution spawnResolution(
        NarrativeDependencyIndex index,
      ) =>
          index
              .usagesOwnedBy(_newGameOwner)
              .singleWhere((usage) => usage.path == 'newGame.startSpawnId')
              .resolution;

      expect(
        spawnResolution(unavailable),
        NarrativeDependencyResolution.unavailable,
      );
      expect(
        spawnResolution(missing),
        NarrativeDependencyResolution.missing,
      );
    });

    test('keeps disabled New Game references as authoring dependencies', () {
      final project = _project(
        maps: const <ProjectMapEntry>[
          ProjectMapEntry(
            id: 'map.port',
            name: 'Port',
            relativePath: 'maps/port.json',
          ),
        ],
        facts: <NarrativeFactDefinition>[
          NarrativeFactDefinition(id: 'fact.ready', label: 'Ready'),
        ],
        scenes: <SceneAsset>[_emptyScene('scene.starter')],
        newGame: const ProjectNewGameConfig(
          enabled: false,
          startMapId: 'map.port',
          startSpawnId: 'spawn.player',
          initialFacts: <String, bool>{'fact.ready': true},
          existingPartyFactId: 'fact.ready',
          starterSelectionSceneId: 'scene.starter',
        ),
      );
      final map = MapData(
        id: 'map.port',
        name: 'Port',
        size: const GridSize(width: 5, height: 5),
        entities: const <MapEntity>[
          MapEntity(
            id: 'spawn.player',
            kind: MapEntityKind.spawn,
            pos: GridPos(x: 1, y: 1),
            spawn: MapEntitySpawnData(),
          ),
        ],
      );

      final usages = buildNarrativeDependencyIndex(
        project: project,
        maps: <MapData>[map],
      ).usagesOwnedBy(_newGameOwner);

      expect(
        usages.map((usage) => usage.path),
        containsAll(<String>[
          'newGame.startMapId',
          'newGame.startSpawnId',
          'newGame.initialFacts[fact.ready]',
          'newGame.existingPartyFactId',
          'newGame.starterSelectionSceneId',
        ]),
      );
      expect(
        usages.every(
          (usage) =>
              usage.criticality ==
                  NarrativeDependencyCriticality.authoringWarning &&
              usage.resolution == NarrativeDependencyResolution.resolved,
        ),
        isTrue,
      );
    });

    test('indexes Event V2 source, conditions and produced Scene', () {
      final event = _event(
        id: _eventA,
        sceneId: 'scene.event',
        source: NarrativeEventSourceRef.entityInteract('map.port', 'npc.rival'),
        conditions: <NarrativeEventCondition>[
          NarrativeEventCondition.fact('rival.ready', true),
        ],
      );
      final project = _project(
        maps: const <ProjectMapEntry>[
          ProjectMapEntry(
            id: 'map.port',
            name: 'Port',
            relativePath: 'maps/port.json',
          ),
        ],
        facts: <NarrativeFactDefinition>[
          NarrativeFactDefinition(id: 'rival.ready', label: 'Rival ready'),
        ],
        scenes: <SceneAsset>[_emptyScene('scene.event')],
        eventRegistry: _registry(<NarrativeEventDefinition>[event]),
      );

      final index = buildNarrativeDependencyIndex(project: project);
      final owner = NarrativeDependencyKey(
        NarrativeDependencyTargetKind.eventV2,
        _eventA,
      );
      final usages = index.usagesOwnedBy(owner);

      expect(
        index.definitionsFor(owner).single.label,
        'Event $_eventA',
      );
      expect(
        usages.map((usage) => usage.path),
        containsAll(<String>[
          'eventRegistry.records[$_eventA].source.mapId',
          'eventRegistry.records[$_eventA].source.entityId',
          'eventRegistry.records[$_eventA].conditions[0].factId',
          'eventRegistry.records[$_eventA].sceneId',
        ]),
      );
      expect(
        usages
            .firstWhere((usage) => usage.path.endsWith('.source.mapId'))
            .resolution,
        NarrativeDependencyResolution.unavailable,
      );
    });

    test('indexes legacy claim sources, provenances and Event V2 targets', () {
      final claim = _legacyClaim(
        targetEventIds: const <String>[_eventA, _eventB],
      );
      final project = _project(
        maps: const <ProjectMapEntry>[
          ProjectMapEntry(
            id: 'map_port',
            name: 'Port',
            relativePath: 'maps/port.json',
          ),
        ],
        scenes: <SceneAsset>[_emptyScene('scene.event')],
        scenarios: const <ScenarioAsset>[
          ScenarioAsset(
            id: 'scenario_arrival',
            name: 'Arrival',
            entryNodeId: 'source',
            nodes: <ScenarioNode>[
              ScenarioNode(id: 'source', type: ScenarioNodeType.reference),
            ],
          ),
        ],
        eventRegistry: _registry(
          <NarrativeEventDefinition>[
            _event(
              id: _eventA,
              sceneId: 'scene.event',
              source: NarrativeEventSourceRef.mapEnter('map_port'),
            ),
            _event(
              id: _eventB,
              sceneId: 'scene.event',
              source: NarrativeEventSourceRef.mapEnter('map_port'),
            ),
          ],
          legacyClaims: <LegacySourceClaim>[claim],
        ),
      );
      final map = MapData(
        id: 'map_port',
        name: 'Port',
        size: const GridSize(width: 5, height: 5),
        events: const <MapEventDefinition>[
          MapEventDefinition(
            id: 'lysa',
            title: 'Lysa',
            pages: <MapEventPage>[],
            position: EventPosition(layerId: 'base', x: 1, y: 1),
          ),
        ],
      );

      final index = buildNarrativeDependencyIndex(
        project: project,
        maps: <MapData>[map],
      );
      final claimOwner = NarrativeDependencyKey.legacySourceClaim(
        claim.cohortId,
      );
      final usages = index.usagesOwnedBy(claimOwner);

      expect(index.definitionsFor(claimOwner), hasLength(1));
      expect(
        usages.map((usage) => usage.target),
        containsAll(<NarrativeDependencyKey>[
          const NarrativeDependencyKey.map('map_port'),
          const NarrativeDependencyKey.mapSource(
            mapId: 'map_port',
            sourceKind: 'event',
            sourceId: 'lysa',
          ),
          const NarrativeDependencyKey.legacyScenario(
            'scenario_arrival',
          ),
          const NarrativeDependencyKey.legacyScenarioNode(
            scenarioId: 'scenario_arrival',
            nodeId: 'source',
          ),
          const NarrativeDependencyKey.eventV2(_eventA),
          const NarrativeDependencyKey.eventV2(_eventB),
        ]),
      );
      expect(
        usages
            .singleWhere(
              (usage) => usage.path.endsWith('.targetEventIds[$_eventA]'),
            )
            .resolution,
        NarrativeDependencyResolution.resolved,
      );
      expect(
        usages
            .singleWhere(
              (usage) => usage.path.endsWith('.members[0].provenance.eventId'),
            )
            .resolution,
        NarrativeDependencyResolution.resolved,
      );
    });

    test('reports broken legacy claim dependencies in their own namespace', () {
      final claim = _legacyClaim(targetEventIds: const <String>[_eventA]);
      final project = _project(
        maps: const <ProjectMapEntry>[
          ProjectMapEntry(
            id: 'map_port',
            name: 'Port',
            relativePath: 'maps/port.json',
          ),
        ],
        scenarios: const <ScenarioAsset>[
          ScenarioAsset(
            id: 'scenario_arrival',
            name: 'Arrival',
            entryNodeId: 'other',
            nodes: <ScenarioNode>[
              ScenarioNode(id: 'other', type: ScenarioNodeType.reference),
            ],
          ),
        ],
        eventRegistry: _registry(
          const <NarrativeEventDefinition>[],
          legacyClaims: <LegacySourceClaim>[claim],
        ),
      );

      final index = buildNarrativeDependencyIndex(project: project);
      final owner = NarrativeDependencyKey.legacySourceClaim(claim.cohortId);
      final usages = index.usagesOwnedBy(owner);

      expect(
        usages
            .singleWhere(
              (usage) => usage.path.endsWith('.targetEventIds[$_eventA]'),
            )
            .resolution,
        NarrativeDependencyResolution.missing,
      );
      expect(
        usages.where((usage) => usage.target.physicalMapId == 'map_port').every(
              (usage) =>
                  usage.resolution == NarrativeDependencyResolution.unavailable,
            ),
        isTrue,
      );
      expect(
        usages
            .singleWhere(
              (usage) => usage.path.endsWith('.provenance.scenarioId'),
            )
            .resolution,
        NarrativeDependencyResolution.resolved,
      );
      expect(
        usages
            .singleWhere(
              (usage) => usage.path.endsWith('.provenance.nodeId'),
            )
            .resolution,
        NarrativeDependencyResolution.missing,
      );
      expect(
        usages.where(
          (usage) =>
              usage.path.contains('Fingerprint') ||
              usage.path.contains('migrationReceiptId'),
        ),
        isEmpty,
      );
    });

    test('indexes Scene parents, typed nodes, conditions and consequences', () {
      final scene = SceneAsset(
        id: 'scene.full',
        name: 'Full scene',
        storylineId: 'story.main',
        chapterId: 'chapter.intro',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: <SceneNode>[
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'condition',
              kind: SceneNodeKind.condition,
              payload: SceneConditionPayload(
                conditionSource: SceneConditionSource(
                  sourceKind: SceneConditionSourceKind.fact,
                  sourceId: 'intro.ready',
                  operator: SceneConditionOperator.isTrue,
                ),
              ),
            ),
            SceneNode(
              id: 'legacy-condition',
              kind: SceneNodeKind.condition,
              payload: SceneConditionPayload(
                conditionSource: SceneConditionSource(
                  sourceKind: SceneConditionSourceKind.factLikeStoryFlag,
                  sourceId: 'legacy.intro.ready',
                  operator: SceneConditionOperator.isTrue,
                ),
              ),
            ),
            SceneNode(
              id: 'dialogue',
              kind: SceneNodeKind.yarnDialogue,
              payload: SceneYarnDialoguePayload(dialogueId: 'dialogue.intro'),
            ),
            SceneNode(
              id: 'cinematic',
              kind: SceneNodeKind.cinematic,
              payload: SceneCinematicPayload(cinematicId: 'cine.intro'),
            ),
            SceneNode(
              id: 'action',
              kind: SceneNodeKind.action,
              payload: SceneActionPayload.consequence(
                SceneConsequence.completeStoryStep(stepId: 'step.intro'),
              ),
            ),
          ],
        ),
      );
      final project = _project(
        facts: <NarrativeFactDefinition>[
          NarrativeFactDefinition(id: 'intro.ready', label: 'Intro ready'),
          NarrativeFactDefinition(
            id: 'intro.legacy-ready',
            label: 'Legacy intro ready',
            legacyFlagName: 'legacy.intro.ready',
          ),
        ],
        dialogues: const <ProjectDialogueEntry>[
          ProjectDialogueEntry(
            id: 'dialogue.intro',
            name: 'Intro',
            relativePath: 'dialogues/intro.yarn',
          ),
        ],
        cinematics: <CinematicAsset>[
          CinematicAsset(
            id: 'cine.intro',
            title: 'Intro',
            timeline: CinematicTimeline(),
          ),
        ],
        storylines: <StorylineAsset>[_storyline()],
        scenes: <SceneAsset>[scene],
      );

      final index = buildNarrativeDependencyIndex(project: project);
      const owner = NarrativeDependencyKey(
        NarrativeDependencyTargetKind.scene,
        'scene.full',
      );

      expect(
        index.usagesOwnedBy(owner).map((usage) => usage.target),
        containsAll(<NarrativeDependencyKey>[
          const NarrativeDependencyKey(
            NarrativeDependencyTargetKind.storyline,
            'story.main',
          ),
          const NarrativeDependencyKey(
            NarrativeDependencyTargetKind.chapter,
            'chapter.intro',
          ),
          const NarrativeDependencyKey(
            NarrativeDependencyTargetKind.fact,
            'intro.ready',
          ),
          const NarrativeDependencyKey(
            NarrativeDependencyTargetKind.fact,
            'intro.legacy-ready',
          ),
          const NarrativeDependencyKey(
            NarrativeDependencyTargetKind.dialogue,
            'dialogue.intro',
          ),
          const NarrativeDependencyKey(
            NarrativeDependencyTargetKind.cinematic,
            'cine.intro',
          ),
          const NarrativeDependencyKey(
            NarrativeDependencyTargetKind.step,
            'step.intro',
          ),
        ]),
      );
      expect(
        index.usagesOwnedBy(owner).every(
              (usage) =>
                  usage.resolution == NarrativeDependencyResolution.resolved,
            ),
        isTrue,
      );
    });

    test('indexes mark-event-consumed map and event fields separately', () {
      final scene = SceneAsset(
        id: 'scene.consume',
        name: 'Consume legacy event',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: <SceneNode>[
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'action',
              kind: SceneNodeKind.action,
              payload: SceneActionPayload.consequence(
                SceneConsequence.markEventConsumed(
                  mapId: 'map.port',
                  eventId: 'event.legacy',
                ),
              ),
            ),
          ],
        ),
      );
      final index = buildNarrativeDependencyIndex(
        project: _project(
          maps: const <ProjectMapEntry>[
            ProjectMapEntry(
              id: 'map.port',
              name: 'Port',
              relativePath: 'maps/port.json',
            ),
          ],
          scenes: <SceneAsset>[scene],
        ),
      );
      final usages = index.usagesOwnedBy(
        const NarrativeDependencyKey.scene('scene.consume'),
      );

      expect(
        usages.singleWhere((usage) => usage.path.endsWith('.mapId')).target,
        const NarrativeDependencyKey.map('map.port'),
      );
      expect(
        usages.singleWhere((usage) => usage.path.endsWith('.eventId')).target,
        const NarrativeDependencyKey.mapSource(
          mapId: 'map.port',
          sourceKind: 'event',
          sourceId: 'event.legacy',
        ),
      );
    });

    test('keeps legacy consumed-event and World Rule condition namespaces', () {
      final scene = SceneAsset(
        id: 'scene.conditions',
        name: 'Condition namespaces',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: <SceneNode>[
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'consumed',
              kind: SceneNodeKind.condition,
              payload: SceneConditionPayload(
                conditionSource: SceneConditionSource(
                  sourceKind: SceneConditionSourceKind.consumedEvent,
                  sourceId: 'event.legacy',
                  operator: SceneConditionOperator.isTrue,
                ),
              ),
            ),
            SceneNode(
              id: 'world',
              kind: SceneNodeKind.condition,
              payload: SceneConditionPayload(
                conditionSource: SceneConditionSource(
                  sourceKind: SceneConditionSourceKind.worldState,
                  sourceId: 'rule.story',
                  operator: SceneConditionOperator.isTrue,
                ),
              ),
            ),
          ],
        ),
      );
      final index = buildNarrativeDependencyIndex(
        project: _project(
          maps: const <ProjectMapEntry>[
            ProjectMapEntry(
              id: 'map.pending',
              name: 'Pending map',
              relativePath: 'maps/pending.json',
            ),
          ],
          scenes: <SceneAsset>[scene],
          worldRules: <WorldRuleDefinition>[_worldRule()],
        ),
      );
      final usages = index.usagesOwnedBy(
        const NarrativeDependencyKey.scene('scene.conditions'),
      );
      final targets = usages.map((usage) => usage.target);

      expect(
        targets,
        containsAll(<NarrativeDependencyKey>[
          const NarrativeDependencyKey.synthetic(
            sourceKind: 'legacyMapEvent',
            sourceId: 'event.legacy',
          ),
          const NarrativeDependencyKey(
            NarrativeDependencyTargetKind.worldRule,
            'rule.story',
          ),
        ]),
      );
      expect(
        usages
            .singleWhere(
              (usage) => usage.target.sourceKind == 'legacyMapEvent',
            )
            .resolution,
        NarrativeDependencyResolution.unavailable,
      );
    });

    test('marks a duplicated definition as ambiguous', () {
      final project = _project(
        facts: <NarrativeFactDefinition>[
          NarrativeFactDefinition(id: 'fact.duplicate', label: 'First'),
          NarrativeFactDefinition(id: 'fact.duplicate', label: 'Second'),
        ],
        newGame: const ProjectNewGameConfig(
          enabled: true,
          initialFacts: <String, bool>{'fact.duplicate': true},
        ),
      );

      final index = buildNarrativeDependencyIndex(project: project);

      expect(index.usages.single.resolution,
          NarrativeDependencyResolution.ambiguous);
      expect(
        index.issues.where(
          (issue) => issue.kind == NarrativeDependencyIssueKind.duplicateId,
        ),
        hasLength(1),
      );
    });
  });

  group('Map, Storyline, Cinematic, WorldRule and legacy collectors', () {
    test('indexes loaded map sources and every authored dialogue reference',
        () {
      final map = MapData(
        id: 'map.port',
        name: 'Port',
        size: const GridSize(width: 10, height: 10),
        entities: <MapEntity>[
          MapEntity(
            id: 'npc.rival',
            kind: MapEntityKind.npc,
            pos: const GridPos(x: 1, y: 1),
            npc: const MapEntityNpcData(
              displayName: 'Rival',
              dialogue: DialogueRef(dialogueId: 'dialogue.default'),
              defeatDialogueRef: DialogueRef(dialogueId: 'dialogue.alt'),
              conditionalDialogues: <MapEntityConditionalDialogue>[
                MapEntityConditionalDialogue(
                  when: MapEntityRuntimePredicate(
                    kind: MapEntityRuntimePredicateKind.storyFlagSet,
                    refId: 'legacy.ready',
                  ),
                  dialogue: DialogueRef(dialogueId: 'dialogue.alt'),
                ),
              ],
            ),
          ),
        ],
        placedElements: <MapPlacedElement>[
          MapPlacedElement(
            id: 'chest',
            layerId: 'objects',
            elementId: 'element.chest',
            pos: const GridPos(x: 2, y: 2),
            behaviors: const <MapPlacedElementBehavior>[
              MapPlacedElementBehavior(
                effect: MapPlacedElementEffect(
                  type: MapPlacedElementEffectType.openDialogue,
                  dialogue: DialogueRef(dialogueId: 'dialogue.alt'),
                ),
              ),
            ],
          ),
        ],
        triggers: const <MapTrigger>[
          MapTrigger(
            id: 'trigger.arrival',
            type: TriggerType.event,
            area: MapRect(
              pos: GridPos(x: 0, y: 0),
              size: GridSize(width: 2, height: 2),
            ),
          ),
        ],
        gameplayZones: const <MapGameplayZone>[
          MapGameplayZone(
            id: 'zone.harbor',
            name: 'Harbor zone',
            kind: GameplayZoneKind.special,
            area: MapRect(
              pos: GridPos(x: 4, y: 4),
              size: GridSize(width: 2, height: 2),
            ),
          ),
        ],
        warps: const <MapWarp>[
          MapWarp(
            id: 'warp.exit',
            pos: GridPos(x: 9, y: 9),
            targetMapId: 'map.other',
            targetPos: GridPos(x: 0, y: 0),
          ),
        ],
        events: <MapEventDefinition>[
          MapEventDefinition(
            id: 'event.legacy',
            pages: <MapEventPage>[
              MapEventPage(
                pageNumber: 0,
                condition: ScriptConditionFactory.flagIsSet('legacy.ready'),
                sceneTarget: const MapEventSceneTarget(sceneId: 'scene.map'),
              ),
            ],
            position: const EventPosition(layerId: 'objects', x: 3, y: 3),
          ),
        ],
      );
      final project = _project(
        maps: const <ProjectMapEntry>[
          ProjectMapEntry(
            id: 'map.port',
            name: 'Port',
            relativePath: 'maps/port.json',
          ),
        ],
        dialogues: const <ProjectDialogueEntry>[
          ProjectDialogueEntry(
            id: 'dialogue.default',
            name: 'Default',
            relativePath: 'dialogues/default.yarn',
          ),
          ProjectDialogueEntry(
            id: 'dialogue.alt',
            name: 'Alternate',
            relativePath: 'dialogues/alt.yarn',
          ),
        ],
        facts: <NarrativeFactDefinition>[
          NarrativeFactDefinition(
            id: 'fact.ready',
            label: 'Ready',
            legacyFlagName: 'legacy.ready',
          ),
        ],
        scenes: <SceneAsset>[_emptyScene('scene.map')],
        scenarios: const <ScenarioAsset>[
          ScenarioAsset(
            id: 'scenario.warp',
            name: 'Warp consumer',
            entryNodeId: 'start',
            nodes: <ScenarioNode>[
              ScenarioNode(
                id: 'start',
                type: ScenarioNodeType.reference,
                binding: ScenarioNodeBinding(
                  mapId: 'map.port',
                  warpId: 'warp.exit',
                ),
              ),
            ],
          ),
        ],
      );

      final index = buildNarrativeDependencyIndex(
        project: project,
        maps: <MapData>[map, _emptyMap('map.other')],
      );

      for (final key in <NarrativeDependencyKey>[
        const NarrativeDependencyKey.map('map.port'),
        const NarrativeDependencyKey(
          NarrativeDependencyTargetKind.sourceMap,
          'npc.rival',
          scope: 'map',
          parentId: 'map.port',
          sourceKind: 'entity',
        ),
        const NarrativeDependencyKey(
          NarrativeDependencyTargetKind.sourceMap,
          'trigger.arrival',
          scope: 'map',
          parentId: 'map.port',
          sourceKind: 'trigger',
        ),
        const NarrativeDependencyKey.mapSource(
          mapId: 'map.port',
          sourceKind: 'gameplayZone',
          sourceId: 'zone.harbor',
        ),
        const NarrativeDependencyKey.mapSource(
          mapId: 'map.port',
          sourceKind: 'warp',
          sourceId: 'warp.exit',
        ),
        const NarrativeDependencyKey(
          NarrativeDependencyTargetKind.sourceMap,
          'event.legacy',
          scope: 'map',
          parentId: 'map.port',
          sourceKind: 'event',
        ),
      ]) {
        expect(
          index.definitionsFor(key),
          hasLength(1),
        );
      }
      expect(
        index
            .definitionsFor(
              const NarrativeDependencyKey.mapSource(
                mapId: 'map.port',
                sourceKind: 'entity',
                sourceId: 'npc.rival',
              ),
            )
            .single
            .metadata,
        const {'entityKind': 'npc'},
      );
      expect(
        index.usagesFor(
          const NarrativeDependencyKey(
            NarrativeDependencyTargetKind.dialogue,
            'dialogue.alt',
          ),
        ),
        hasLength(3),
      );
      expect(
        index.usagesFor(
          const NarrativeDependencyKey(
            NarrativeDependencyTargetKind.fact,
            'fact.ready',
          ),
        ),
        isNotEmpty,
      );
      expect(
        index.usagesFor(
          const NarrativeDependencyKey.mapSource(
            mapId: 'map.port',
            sourceKind: 'warp',
            sourceId: 'warp.exit',
          ),
        ),
        hasLength(1),
      );
      expect(
        index.usages
            .where(
              (usage) => usage.owner.parentId == 'map.port',
            )
            .every(
              (usage) =>
                  usage.resolution == NarrativeDependencyResolution.resolved,
            ),
        isTrue,
      );
    });

    test('keeps explicit dialogue script overrides outside the registry', () {
      final map = MapData(
        id: 'map.override',
        name: 'Override map',
        size: const GridSize(width: 4, height: 4),
        entities: const <MapEntity>[
          MapEntity(
            id: 'npc.external',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 1, y: 1),
            npc: MapEntityNpcData(
              displayName: 'External NPC',
              dialogue: DialogueRef(
                dialogueId: 'external.node',
                scriptPathRelative: 'scripts/external.yarn',
              ),
            ),
          ),
        ],
      );
      final index = buildNarrativeDependencyIndex(
        project: _project(),
        maps: <MapData>[map],
      );
      final usage = index
          .usagesOwnedBy(
            const NarrativeDependencyKey.mapSource(
              mapId: 'map.override',
              sourceKind: 'entity',
              sourceId: 'npc.external',
            ),
          )
          .single;

      expect(usage.target.kind, NarrativeDependencyTargetKind.sourceMap);
      expect(usage.target.sourceKind, 'legacyDialogueScript');
      expect(usage.target.id, 'scripts/external.yarn');
      expect(usage.resolution, NarrativeDependencyResolution.legacyExternal);
      expect(
        index.issues.where(
          (issue) => issue.target.id == 'external.node',
        ),
        isEmpty,
      );
    });

    test('indexes Storyline links, relationships, anchors and effects', () {
      final storyline = StorylineAsset(
        id: 'story.main',
        type: StorylineType.main,
        title: 'Main',
        chapters: <StorylineChapter>[
          StorylineChapter(
            id: 'chapter.main',
            title: 'Chapter',
            order: 0,
            directSceneLinkIds: const <String>['scene.chapter'],
            steps: <StorylineStep>[
              StorylineStep(
                id: 'step.main',
                title: 'Step',
                order: 0,
                sceneLinkIds: const <String>['scene.main'],
              ),
            ],
          ),
        ],
        sceneLinks: <StorylineSceneLink>[
          StorylineSceneLink(
            id: 'link.main',
            chapterId: 'chapter.main',
            stepId: 'step.main',
            label: 'Legacy bridge',
            state: StorylineSceneLinkState.linkedScenario,
            role: StorylineSceneLinkRole.primary,
            sceneRef: StorylineSceneRef(
              kind: StorylineSceneRefKind.scenario,
              targetId: 'scenario.legacy',
            ),
            order: 0,
            outcomeLinks: <StorylineSceneOutcomeLink>[
              StorylineSceneOutcomeLink(
                id: 'outcome.main',
                outcomeId: 'completed',
                effects: <StorylineEffect>[
                  StorylineEffect(
                    type: StorylineEffectType.emitFact,
                    targetId: 'fact.story',
                  ),
                  StorylineEffect(
                    type: StorylineEffectType.setWorldRule,
                    targetId: 'rule.story',
                  ),
                  StorylineEffect(
                    type: StorylineEffectType.unlockStoryline,
                    targetId: 'story.side',
                  ),
                ],
              ),
            ],
          ),
        ],
        relationships: <StorylineRelationship>[
          StorylineRelationship(
            id: 'relationship.side',
            kind: StorylineRelationshipKind.sideQuestUnlockedBy,
            sourceStorylineId: 'story.main',
            targetStorylineId: 'story.side',
            anchor: StorylineAnchor(
              kind: StorylineAnchorKind.step,
              targetId: 'step.main',
            ),
          ),
        ],
        legacySource: StorylineLegacySource(
          kind: 'globalStory',
          sourceId: 'scenario.legacy',
        ),
      );
      final project = _project(
        facts: <NarrativeFactDefinition>[
          NarrativeFactDefinition(
            id: 'fact.story',
            label: 'Story fact',
            legacyFlagName: 'legacy.story',
          ),
        ],
        scenes: <SceneAsset>[
          _emptyScene('scene.main'),
          _emptyScene('scene.chapter'),
        ],
        storylines: <StorylineAsset>[
          storyline,
          StorylineAsset(
            id: 'story.side',
            type: StorylineType.sideQuest,
            title: 'Side',
          ),
        ],
        worldRules: <WorldRuleDefinition>[_worldRule()],
        scenarios: const <ScenarioAsset>[
          ScenarioAsset(
            id: 'scenario.legacy',
            name: 'Legacy',
            scope: ScenarioScope.globalStory,
            entryNodeId: 'start',
            nodes: <ScenarioNode>[
              ScenarioNode(
                id: 'start',
                type: ScenarioNodeType.start,
                payload: ScenarioNodePayload(
                  condition: ScriptCondition(
                    type: ScriptConditionType.flagIsSet,
                    params: <String, String>{
                      ScriptConditionParams.flagName: 'legacy.story',
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      );

      final index = buildNarrativeDependencyIndex(project: project);
      const owner = NarrativeDependencyKey(
        NarrativeDependencyTargetKind.storyline,
        'story.main',
      );

      expect(
        index.usagesOwnedBy(owner).map((usage) => usage.target),
        containsAll(<NarrativeDependencyKey>[
          const NarrativeDependencyKey(
            NarrativeDependencyTargetKind.scene,
            'scene.main',
          ),
          const NarrativeDependencyKey.scene('scene.chapter'),
          const NarrativeDependencyKey(
            NarrativeDependencyTargetKind.storyline,
            'story.side',
          ),
          const NarrativeDependencyKey(
            NarrativeDependencyTargetKind.step,
            'step.main',
          ),
          const NarrativeDependencyKey(
            NarrativeDependencyTargetKind.chapter,
            'chapter.main',
          ),
          const NarrativeDependencyKey(
            NarrativeDependencyTargetKind.fact,
            'fact.story',
          ),
          const NarrativeDependencyKey(
            NarrativeDependencyTargetKind.worldRule,
            'rule.story',
          ),
        ]),
      );
      expect(
        index
            .usagesOwnedBy(owner)
            .singleWhere(
              (usage) =>
                  usage.target ==
                  const NarrativeDependencyKey.scene('scene.chapter'),
            )
            .path,
        'storylines[story.main].chapters[0].directSceneLinkIds[0]',
      );
      expect(
        index
            .usagesOwnedBy(owner)
            .where(
              (usage) => usage.path.contains('legacy'),
            )
            .every(
              (usage) =>
                  usage.resolution ==
                  NarrativeDependencyResolution.legacyExternal,
            ),
        isTrue,
      );
      expect(
        index
            .usagesFor(
              const NarrativeDependencyKey(
                NarrativeDependencyTargetKind.fact,
                'fact.story',
              ),
            )
            .any(
              (usage) =>
                  usage.owner ==
                  const NarrativeDependencyKey.legacyScenario(
                    'scenario.legacy',
                  ),
            ),
        isTrue,
      );
      expect(
        index
            .usagesOwnedBy(owner)
            .singleWhere(
              (usage) => usage.path.endsWith(
                'relationships[0].sourceStorylineId',
              ),
            )
            .target,
        const NarrativeDependencyKey(
          NarrativeDependencyTargetKind.storyline,
          'story.main',
        ),
      );
    });

    test('indexes legacy global-story document structure and metadata', () {
      final scenario = ScenarioAsset(
        id: 'global_story',
        name: 'Legacy global story',
        scope: ScenarioScope.globalStory,
        entryNodeId: 'start',
        nodes: const <ScenarioNode>[
          ScenarioNode(id: 'start', type: ScenarioNodeType.start),
        ],
        metadata: const <String, String>{
          'authoring.owner': 'narrative-studio',
          'authoring.globalStoryStudioDocument': '''
{
  "chapters": [
    {
      "id": "chapter_intro",
      "name": "Intro chapter",
      "description": "Legacy chapter",
      "order": 2,
      "stepIds": ["step_intro"]
    }
  ]
}
''',
          'authoring.stepStudioDocument': '''
{
  "steps": [
    {
      "id": "step_intro",
      "name": "Intro step",
      "description": "Legacy step",
      "order": 3
    }
  ]
}
''',
        },
      );
      final index = buildNarrativeDependencyIndex(
        project: _project(scenarios: <ScenarioAsset>[scenario]),
      );
      const scenarioKey = NarrativeDependencyKey.legacyScenario('global_story');
      const chapterKey = NarrativeDependencyKey.legacyGlobalStoryPart(
        scenarioId: 'global_story',
        partKind: 'globalStoryChapter',
        partId: 'chapter_intro',
      );
      const stepKey = NarrativeDependencyKey.legacyGlobalStoryPart(
        scenarioId: 'global_story',
        partKind: 'globalStoryStep',
        partId: 'step_intro',
      );

      final scenarioDefinition = index.definitionsFor(scenarioKey).single;
      final chapterDefinition = index.definitionsFor(chapterKey).single;
      final stepDefinition = index.definitionsFor(stepKey).single;

      expect(scenarioDefinition.metadata['scope'], 'globalStory');
      expect(scenarioDefinition.metadata['entryNodeId'], 'start');
      expect(
        scenarioDefinition.metadata['authoring.owner'],
        'narrative-studio',
      );
      expect(chapterDefinition.owner, scenarioKey);
      expect(
        chapterDefinition.metadata,
        containsPair(
          'legacyDocument',
          'authoring.globalStoryStudioDocument',
        ),
      );
      expect(chapterDefinition.metadata['order'], '2');
      expect(stepDefinition.owner, chapterKey);
      expect(
        stepDefinition.metadata,
        containsPair('legacyDocument', 'authoring.stepStudioDocument'),
      );
      expect(stepDefinition.metadata['order'], '3');
    });

    test('indexes Cinematic parents and WorldRule source, target and effect',
        () {
      final map = MapData(
        id: 'map.port',
        name: 'Port',
        size: const GridSize(width: 5, height: 5),
        entities: const <MapEntity>[
          MapEntity(
            id: 'npc.rival',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 1, y: 1),
            npc: MapEntityNpcData(displayName: 'Rival'),
          ),
        ],
      );
      final cinematic = CinematicAsset(
        id: 'cine.port',
        title: 'Port',
        storylineId: 'story.main',
        chapterId: 'chapter.intro',
        mapId: 'map.port',
        stageContext: CinematicStageContext(
          movementTargetBindings: <CinematicMovementTargetBinding>[
            CinematicMovementTargetBinding(
              targetId: 'target.entity',
              kind: CinematicMovementTargetBindingKind.mapEntity,
              sourceId: 'npc.rival',
            ),
            CinematicMovementTargetBinding(
              targetId: 'target.event',
              kind: CinematicMovementTargetBindingKind.mapEvent,
              sourceId: 'event.arrival',
            ),
            CinematicMovementTargetBinding(
              targetId: 'target.abstract',
              kind: CinematicMovementTargetBindingKind.abstractPoint,
            ),
          ],
        ),
        timeline: CinematicTimeline(),
        legacyBridge: CinematicLegacyBridge(
          sourceKind: CinematicLegacyBridgeSourceKind.scenarioAsset,
          scenarioId: 'scenario.legacy',
        ),
      );
      final project = _project(
        maps: const <ProjectMapEntry>[
          ProjectMapEntry(
            id: 'map.port',
            name: 'Port',
            relativePath: 'maps/port.json',
          ),
        ],
        facts: <NarrativeFactDefinition>[
          NarrativeFactDefinition(id: 'fact.story', label: 'Story fact'),
        ],
        dialogues: const <ProjectDialogueEntry>[
          ProjectDialogueEntry(
            id: 'dialogue.rival',
            name: 'Rival',
            relativePath: 'dialogues/rival.yarn',
          ),
        ],
        storylines: <StorylineAsset>[_storyline()],
        cinematics: <CinematicAsset>[cinematic],
        worldRules: <WorldRuleDefinition>[_worldRule()],
      );

      final index = buildNarrativeDependencyIndex(
        project: project,
        maps: <MapData>[map],
      );
      const cinematicOwner = NarrativeDependencyKey(
        NarrativeDependencyTargetKind.cinematic,
        'cine.port',
      );
      const ruleOwner = NarrativeDependencyKey(
        NarrativeDependencyTargetKind.worldRule,
        'rule.story',
      );

      expect(
        index.usagesOwnedBy(cinematicOwner).map((usage) => usage.target),
        containsAll(<NarrativeDependencyKey>[
          const NarrativeDependencyKey(
            NarrativeDependencyTargetKind.storyline,
            'story.main',
          ),
          const NarrativeDependencyKey(
            NarrativeDependencyTargetKind.chapter,
            'chapter.intro',
          ),
          const NarrativeDependencyKey.map('map.port'),
          const NarrativeDependencyKey.mapSource(
            mapId: 'map.port',
            sourceKind: 'entity',
            sourceId: 'npc.rival',
          ),
          const NarrativeDependencyKey.mapSource(
            mapId: 'map.port',
            sourceKind: 'event',
            sourceId: 'event.arrival',
          ),
        ]),
      );
      expect(
        index
            .usagesOwnedBy(cinematicOwner)
            .singleWhere(
              (usage) => usage.path.endsWith('legacyBridge.scenarioId'),
            )
            .resolution,
        NarrativeDependencyResolution.legacyExternal,
      );
      expect(
        index.usagesOwnedBy(ruleOwner).map((usage) => usage.target),
        containsAll(<NarrativeDependencyKey>[
          const NarrativeDependencyKey(
            NarrativeDependencyTargetKind.fact,
            'fact.story',
          ),
          const NarrativeDependencyKey.map('map.port'),
          const NarrativeDependencyKey(
            NarrativeDependencyTargetKind.sourceMap,
            'npc.rival',
            scope: 'map',
            parentId: 'map.port',
            sourceKind: 'entity',
          ),
          const NarrativeDependencyKey(
            NarrativeDependencyTargetKind.dialogue,
            'dialogue.rival',
          ),
        ]),
      );
    });

    test('uses the actor binding, not a placement decoy, for fromMapEntity',
        () {
      final cinematic = CinematicAsset(
        id: 'cine.spawn',
        title: 'Spawn',
        mapId: 'map.port',
        stageContext: CinematicStageContext(
          actorBindings: <CinematicActorBinding>[
            CinematicActorBinding(
              actorId: 'actor.rival',
              kind: CinematicActorBindingKind.mapEntity,
              mapEntityId: 'npc.rival',
            ),
          ],
          initialPlacements: <CinematicActorInitialPlacement>[
            CinematicActorInitialPlacement(
              actorId: 'actor.rival',
              kind: CinematicActorInitialPlacementKind.fromMapEntity,
              targetId: 'npc.decoy',
            ),
          ],
        ),
        timeline: CinematicTimeline(),
      );
      final map = MapData(
        id: 'map.port',
        name: 'Port',
        size: const GridSize(width: 5, height: 5),
        entities: const <MapEntity>[
          MapEntity(
            id: 'npc.rival',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 1, y: 1),
            npc: MapEntityNpcData(displayName: 'Rival'),
          ),
        ],
      );
      final index = buildNarrativeDependencyIndex(
        project: _project(
          maps: const <ProjectMapEntry>[
            ProjectMapEntry(
              id: 'map.port',
              name: 'Port',
              relativePath: 'maps/port.json',
            ),
          ],
          cinematics: <CinematicAsset>[cinematic],
        ),
        maps: <MapData>[map],
      );
      const owner = NarrativeDependencyKey(
        NarrativeDependencyTargetKind.cinematic,
        'cine.spawn',
      );

      final usages = index.usagesOwnedBy(owner);
      final usage = usages.singleWhere(
        (entry) => entry.path.endsWith('actorBindings[0].mapEntityId'),
      );
      expect(
        usage.target,
        const NarrativeDependencyKey.mapSource(
          mapId: 'map.port',
          sourceKind: 'entity',
          sourceId: 'npc.rival',
        ),
      );
      expect(usage.resolution, NarrativeDependencyResolution.resolved);
      expect(
        usages.where(
          (entry) =>
              entry.path.contains('initialPlacements') ||
              entry.target.id == 'npc.decoy',
        ),
        isEmpty,
      );
    });

    test('keeps consumed WorldRule sources in the legacy Map Event namespace',
        () {
      final event = _event(
        id: _eventA,
        sceneId: 'scene.event',
        source: NarrativeEventSourceRef.mapEnter('map.port'),
      );
      final rule = WorldRuleDefinition(
        id: 'rule.event',
        label: 'Event rule',
        source: const WorldRuleSource(
          kind: WorldRuleSourceKind.consumedEvent,
          sourceId: _eventA,
          predicate: WorldRuleSourcePredicate.isTrue,
        ),
        target: const WorldRuleTarget(
          kind: WorldRuleTargetKind.mapEntity,
          mapId: 'map.port',
          entityId: 'npc.rival',
        ),
        effect: const WorldRuleEffect(kind: WorldRuleEffectKind.entityHidden),
      );
      final index = buildNarrativeDependencyIndex(
        project: _project(
          scenes: <SceneAsset>[_emptyScene('scene.event')],
          eventRegistry: _registry(<NarrativeEventDefinition>[event]),
          worldRules: <WorldRuleDefinition>[rule],
        ),
      );
      const owner = NarrativeDependencyKey(
        NarrativeDependencyTargetKind.worldRule,
        'rule.event',
      );

      final usage = index.usagesOwnedBy(owner).singleWhere(
            (entry) => entry.path.endsWith('.source.sourceId'),
          );
      expect(
        usage.target,
        const NarrativeDependencyKey.synthetic(
          sourceKind: 'legacyMapEvent',
          sourceId: _eventA,
        ),
      );
      expect(usage.resolution, NarrativeDependencyResolution.missing);
      expect(
        index
            .usagesFor(const NarrativeDependencyKey.eventV2(_eventA))
            .where((entry) => entry.owner == owner),
        isEmpty,
      );
    });

    test('indexes legacy Scenario completeStep payload parameters', () {
      final storyline = _storyline();
      const scenario = ScenarioAsset(
        id: 'scenario.complete',
        name: 'Complete',
        scope: ScenarioScope.globalStory,
        entryNodeId: 'complete',
        nodes: <ScenarioNode>[
          ScenarioNode(
            id: 'complete',
            type: ScenarioNodeType.action,
            payload: ScenarioNodePayload(
              actionKind: 'completeStep',
              params: <String, String>{'stepId': 'step.intro'},
            ),
          ),
        ],
      );
      final index = buildNarrativeDependencyIndex(
        project: _project(
          storylines: <StorylineAsset>[storyline],
          scenarios: const <ScenarioAsset>[scenario],
        ),
      );
      const owner = NarrativeDependencyKey.legacyScenario('scenario.complete');

      final usage = index.usagesOwnedBy(owner).singleWhere(
            (entry) => entry.path.endsWith('.payload.params.stepId'),
          );
      expect(
        usage.target,
        const NarrativeDependencyKey(
          NarrativeDependencyTargetKind.step,
          'step.intro',
        ),
      );
      expect(usage.resolution, NarrativeDependencyResolution.resolved);
    });
  });

  group('diagnostics, cycles and load', () {
    test('reports consumed Event V2 cycles as runtime blocking', () {
      final project = _project(
        scenes: <SceneAsset>[_emptyScene('scene.event')],
        eventRegistry: _registry(<NarrativeEventDefinition>[
          _event(
            id: _eventA,
            sceneId: 'scene.event',
            source: NarrativeEventSourceRef.mapEnter('map.loaded'),
            conditions: <NarrativeEventCondition>[
              NarrativeEventCondition.narrativeEventConsumed(_eventB, true),
            ],
          ),
          _event(
            id: _eventB,
            sceneId: 'scene.event',
            source: NarrativeEventSourceRef.mapEnter('map.loaded'),
            conditions: <NarrativeEventCondition>[
              NarrativeEventCondition.narrativeEventConsumed(_eventA, true),
            ],
          ),
        ]),
      );

      final index = buildNarrativeDependencyIndex(
        project: project,
        maps: <MapData>[_emptyMap('map.loaded')],
      );
      final cycles = index.issues.where(
        (issue) => issue.kind == NarrativeDependencyIssueKind.forbiddenCycle,
      );

      expect(cycles, hasLength(2));
      expect(
        cycles.every(
          (issue) =>
              issue.target.kind == NarrativeDependencyTargetKind.eventV2 &&
              issue.criticality ==
                  NarrativeDependencyCriticality.runtimeBlocking,
        ),
        isTrue,
      );
    });

    test('ignores false and mixed consumed Event conditions for cycles', () {
      NarrativeDependencyIndex buildWithExpectations(bool a, bool b) {
        return buildNarrativeDependencyIndex(
          project: _project(
            scenes: <SceneAsset>[_emptyScene('scene.event')],
            eventRegistry: _registry(<NarrativeEventDefinition>[
              _event(
                id: _eventA,
                sceneId: 'scene.event',
                source: NarrativeEventSourceRef.mapEnter('map.loaded'),
                conditions: <NarrativeEventCondition>[
                  NarrativeEventCondition.narrativeEventConsumed(_eventB, a),
                ],
              ),
              _event(
                id: _eventB,
                sceneId: 'scene.event',
                source: NarrativeEventSourceRef.mapEnter('map.loaded'),
                conditions: <NarrativeEventCondition>[
                  NarrativeEventCondition.narrativeEventConsumed(_eventA, b),
                ],
              ),
            ]),
          ),
          maps: <MapData>[_emptyMap('map.loaded')],
        );
      }

      for (final index in <NarrativeDependencyIndex>[
        buildWithExpectations(false, false),
        buildWithExpectations(true, false),
      ]) {
        expect(
          index.issues.where(
            (issue) =>
                issue.kind == NarrativeDependencyIssueKind.forbiddenCycle,
          ),
          isEmpty,
        );
      }
    });

    test('marks a multiply claimed legacy Fact alias as ambiguous', () {
      final map = MapData(
        id: 'map.alias',
        name: 'Alias',
        size: const GridSize(width: 2, height: 2),
        events: <MapEventDefinition>[
          MapEventDefinition(
            id: 'event.alias',
            pages: <MapEventPage>[
              MapEventPage(
                pageNumber: 0,
                condition: ScriptConditionFactory.flagIsSet('legacy.shared'),
              ),
            ],
            position: const EventPosition(layerId: 'objects', x: 0, y: 0),
          ),
        ],
      );
      final index = buildNarrativeDependencyIndex(
        project: _project(
          maps: const <ProjectMapEntry>[
            ProjectMapEntry(
              id: 'map.alias',
              name: 'Alias',
              relativePath: 'maps/alias.json',
            ),
          ],
          facts: <NarrativeFactDefinition>[
            NarrativeFactDefinition(
              id: 'fact.first',
              label: 'First',
              legacyFlagName: 'legacy.shared',
            ),
            NarrativeFactDefinition(
              id: 'fact.second',
              label: 'Second',
              legacyFlagName: 'legacy.shared',
            ),
          ],
        ),
        maps: <MapData>[map],
      );
      final usage = index.usages.singleWhere(
        (usage) => usage.path.endsWith('.condition.params.flagName'),
      );

      expect(usage.resolution, NarrativeDependencyResolution.ambiguous);
      expect(
        index.issues.where(
          (issue) =>
              issue.kind.name == 'ambiguousReference' &&
              issue.owner == usage.owner &&
              issue.path == usage.path,
        ),
        hasLength(1),
      );
    });

    test('keeps slash-containing map scopes distinct for dialogue queries', () {
      MapData mapWithDialogue(String mapId, String dialogueId) => MapData(
            id: mapId,
            name: mapId,
            size: const GridSize(width: 2, height: 2),
            entities: <MapEntity>[
              MapEntity(
                id: 'npc',
                kind: MapEntityKind.npc,
                pos: const GridPos(x: 0, y: 0),
                npc: MapEntityNpcData(
                  dialogue: DialogueRef(dialogueId: dialogueId),
                ),
              ),
            ],
          );
      final foo = mapWithDialogue('foo', 'dialogue.foo');
      final fooBar = mapWithDialogue('foo/bar', 'dialogue.foo-bar');
      final index = buildNarrativeDependencyIndex(
        project: _project(
          maps: const <ProjectMapEntry>[
            ProjectMapEntry(
              id: 'foo',
              name: 'Foo',
              relativePath: 'maps/foo.json',
            ),
            ProjectMapEntry(
              id: 'foo/bar',
              name: 'Foo bar',
              relativePath: 'maps/foo-bar.json',
            ),
          ],
          dialogues: const <ProjectDialogueEntry>[
            ProjectDialogueEntry(
              id: 'dialogue.foo',
              name: 'Foo',
              relativePath: 'dialogues/foo.yarn',
            ),
            ProjectDialogueEntry(
              id: 'dialogue.foo-bar',
              name: 'Foo bar',
              relativePath: 'dialogues/foo-bar.yarn',
            ),
          ],
        ),
        maps: <MapData>[foo, fooBar],
      );

      expect(
        collectDialogueIdsReferencedOnMap(foo, dependencyIndex: index),
        <String>{'dialogue.foo'},
      );
      expect(
        collectDialogueIdsReferencedOnMap(fooBar, dependencyIndex: index),
        <String>{'dialogue.foo-bar'},
      );
    });

    test('detects duplicated map manifest IDs without loaded map data', () {
      final index = buildNarrativeDependencyIndex(
        project: _project(
          maps: const <ProjectMapEntry>[
            ProjectMapEntry(
              id: 'map.duplicate',
              name: 'First',
              relativePath: 'maps/first.json',
            ),
            ProjectMapEntry(
              id: 'map.duplicate',
              name: 'Second',
              relativePath: 'maps/second.json',
            ),
          ],
        ),
      );

      expect(
        index.issues.where(
          (issue) =>
              issue.kind == NarrativeDependencyIssueKind.duplicateId &&
              issue.target.kind == NarrativeDependencyTargetKind.sourceMap &&
              issue.target.id == 'map.duplicate',
        ),
        hasLength(1),
      );
    });

    test('reports unavailable map data without a missing-reference issue', () {
      final index = buildNarrativeDependencyIndex(
        project: _project(
          maps: const <ProjectMapEntry>[
            ProjectMapEntry(
              id: 'map.pending',
              name: 'Pending',
              relativePath: 'maps/pending.json',
            ),
          ],
          newGame: const ProjectNewGameConfig(
            enabled: true,
            startMapId: 'map.pending',
          ),
        ),
      );

      expect(index.usages.single.resolution,
          NarrativeDependencyResolution.unavailable);
      expect(
        index.issues.where(
          (issue) => issue.kind.name == 'unavailableReference',
        ),
        hasLength(1),
      );
      expect(
        index.issues.where(
          (issue) =>
              issue.kind == NarrativeDependencyIssueKind.missingReference,
        ),
        isEmpty,
      );
    });

    test('resolves a known legacy event despite an unrelated unloaded map', () {
      final scene = SceneAsset(
        id: 'scene.known-event',
        name: 'Known event',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: <SceneNode>[
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'condition',
              kind: SceneNodeKind.condition,
              payload: SceneConditionPayload(
                conditionSource: SceneConditionSource(
                  sourceKind: SceneConditionSourceKind.consumedEvent,
                  sourceId: 'event.known',
                  operator: SceneConditionOperator.isTrue,
                ),
              ),
            ),
          ],
        ),
      );
      final loadedMap = MapData(
        id: 'map.loaded',
        name: 'Loaded',
        size: const GridSize(width: 4, height: 4),
        events: <MapEventDefinition>[
          MapEventDefinition(
            id: 'event.known',
            pages: <MapEventPage>[MapEventPage(pageNumber: 0)],
            position: const EventPosition(layerId: 'objects', x: 1, y: 1),
          ),
        ],
      );
      final index = buildNarrativeDependencyIndex(
        project: _project(
          maps: const <ProjectMapEntry>[
            ProjectMapEntry(
              id: 'map.loaded',
              name: 'Loaded',
              relativePath: 'maps/loaded.json',
            ),
            ProjectMapEntry(
              id: 'map.pending',
              name: 'Pending',
              relativePath: 'maps/pending.json',
            ),
          ],
          scenes: <SceneAsset>[scene],
        ),
        maps: <MapData>[loadedMap],
      );

      expect(
        index
            .usagesFor(
              const NarrativeDependencyKey.synthetic(
                sourceKind: 'legacyMapEvent',
                sourceId: 'event.known',
              ),
            )
            .single
            .resolution,
        NarrativeDependencyResolution.resolved,
      );
    });

    test('reports Scene graph cycles but invents no Storyline cycle rule', () {
      final cyclicScene = SceneAsset(
        id: 'scene.cycle',
        name: 'Cycle',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: <SceneNode>[
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(id: 'merge', kind: SceneNodeKind.merge),
          ],
          edges: <SceneEdge>[
            SceneEdge(
              id: 'edge.a',
              fromNodeId: 'start',
              fromPortId: 'completed',
              toNodeId: 'merge',
              kind: SceneEdgeKind.defaultFlow,
            ),
            SceneEdge(
              id: 'edge.b',
              fromNodeId: 'merge',
              fromPortId: 'completed',
              toNodeId: 'start',
              kind: SceneEdgeKind.defaultFlow,
            ),
          ],
        ),
      );
      final storyA = StorylineAsset(
        id: 'story.a',
        type: StorylineType.main,
        title: 'A',
        relationships: <StorylineRelationship>[
          StorylineRelationship(
            id: 'a-to-b',
            kind: StorylineRelationshipKind.requires,
            sourceStorylineId: 'story.a',
            targetStorylineId: 'story.b',
          ),
        ],
      );
      final storyB = StorylineAsset(
        id: 'story.b',
        type: StorylineType.sideQuest,
        title: 'B',
        relationships: <StorylineRelationship>[
          StorylineRelationship(
            id: 'b-to-a',
            kind: StorylineRelationshipKind.requires,
            sourceStorylineId: 'story.b',
            targetStorylineId: 'story.a',
          ),
        ],
      );

      final index = buildNarrativeDependencyIndex(
        project: _project(
          scenes: <SceneAsset>[cyclicScene],
          storylines: <StorylineAsset>[storyA, storyB],
        ),
      );
      final cycles = index.issues.where(
        (issue) => issue.kind == NarrativeDependencyIssueKind.forbiddenCycle,
      );

      expect(cycles, hasLength(1));
      expect(cycles.single.target.id, 'scene.cycle');
      expect(
        cycles.single.criticality,
        NarrativeDependencyCriticality.authoringWarning,
      );
    });

    test('detects Chapter and Step duplicates globally without double issue',
        () {
      StorylineAsset story(String id) => StorylineAsset(
            id: id,
            type: StorylineType.main,
            title: id,
            chapters: <StorylineChapter>[
              StorylineChapter(
                id: 'chapter.shared',
                title: 'Shared',
                order: 0,
                steps: <StorylineStep>[
                  StorylineStep(
                    id: 'step.shared',
                    title: 'Shared',
                    order: 0,
                  ),
                ],
              ),
            ],
          );
      final index = buildNarrativeDependencyIndex(
        project: _project(
          storylines: <StorylineAsset>[story('story.a'), story('story.b')],
          scenes: <SceneAsset>[
            SceneAsset(
              id: 'scene.ambiguous',
              name: 'Ambiguous',
              chapterId: 'chapter.shared',
              graph: SceneGraph(
                startNodeId: 'start',
                nodes: <SceneNode>[
                  SceneNode(id: 'start', kind: SceneNodeKind.start),
                ],
              ),
            ),
          ],
        ),
      );

      expect(
        index.issues.where(
          (issue) => issue.kind == NarrativeDependencyIssueKind.duplicateId,
        ),
        hasLength(2),
      );
      expect(
        index.issues.where(
          (issue) =>
              issue.kind == NarrativeDependencyIssueKind.missingReference &&
              issue.target.id == 'chapter.shared',
        ),
        isEmpty,
      );
      expect(
        index.usages
            .singleWhere(
              (usage) => usage.target.id == 'chapter.shared',
            )
            .resolution,
        NarrativeDependencyResolution.ambiguous,
      );
    });

    test('is stack safe and deterministic for 10000 Event dependencies', () {
      final events = <NarrativeEventDefinition>[];
      for (var index = 0; index < 10000; index++) {
        final id = _largeEventId(index);
        events.add(
          _event(
            id: id,
            sceneId: 'scene.event',
            source: NarrativeEventSourceRef.mapEnter('map.loaded'),
            conditions: index == 0
                ? const <NarrativeEventCondition>[]
                : <NarrativeEventCondition>[
                    NarrativeEventCondition.narrativeEventConsumed(
                      _largeEventId(index - 1),
                      true,
                    ),
                  ],
          ),
        );
      }
      final project = _project(
        scenes: <SceneAsset>[_emptyScene('scene.event')],
        eventRegistry: _registry(events),
      );

      final first = buildNarrativeDependencyIndex(
        project: project,
        maps: <MapData>[_emptyMap('map.loaded')],
      );
      final second = buildNarrativeDependencyIndex(
        project: project,
        maps: <MapData>[_emptyMap('map.loaded')],
      );

      expect(
        first.issues.where(
          (issue) => issue.kind == NarrativeDependencyIssueKind.forbiddenCycle,
        ),
        isEmpty,
      );
      expect(first.definitions, hasLength(10002));
      expect(
        first.usages.map((usage) => '${usage.target}|${usage.path}').toList(),
        second.usages.map((usage) => '${usage.target}|${usage.path}').toList(),
      );
    }, timeout: const Timeout(Duration(seconds: 30)));
  });

  group('progressive legacy read-model delegation', () {
    test('map dialogue collector delegates to the canonical map slice', () {
      final map = MapData(
        id: 'map.dialogue',
        name: 'Dialogue',
        size: const GridSize(width: 3, height: 3),
        entities: const <MapEntity>[
          MapEntity(
            id: 'npc',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 0, y: 0),
            npc: MapEntityNpcData(
              dialogue: DialogueRef(dialogueId: 'dialogue.default'),
              conditionalDialogues: <MapEntityConditionalDialogue>[
                MapEntityConditionalDialogue(
                  when: MapEntityRuntimePredicate(
                    kind: MapEntityRuntimePredicateKind.storyFlagSet,
                    refId: 'legacy.flag',
                  ),
                  dialogue: DialogueRef(dialogueId: 'dialogue.conditional'),
                ),
              ],
            ),
          ),
        ],
        placedElements: const <MapPlacedElement>[
          MapPlacedElement(
            id: 'object',
            layerId: 'objects',
            elementId: 'object',
            pos: GridPos(x: 1, y: 1),
            behaviors: <MapPlacedElementBehavior>[
              MapPlacedElementBehavior(
                effect: MapPlacedElementEffect(
                  type: MapPlacedElementEffectType.openDialogue,
                  dialogue: DialogueRef(dialogueId: 'dialogue.object'),
                ),
              ),
            ],
          ),
        ],
      );
      final project = _project(
        dialogues: const <ProjectDialogueEntry>[
          ProjectDialogueEntry(
            id: 'dialogue.default',
            name: 'Default',
            relativePath: 'default.yarn',
          ),
          ProjectDialogueEntry(
            id: 'dialogue.conditional',
            name: 'Conditional',
            relativePath: 'conditional.yarn',
          ),
          ProjectDialogueEntry(
            id: 'dialogue.object',
            name: 'Object',
            relativePath: 'object.yarn',
          ),
        ],
      );
      final index = buildNarrativeDependencyIndex(
        project: project,
        maps: <MapData>[map],
      );

      expect(collectDialogueIdsReferencedOnMap(map), {'dialogue.default'});
      expect(
        collectDialogueIdsReferencedOnMap(map, dependencyIndex: index),
        {'dialogue.default', 'dialogue.conditional', 'dialogue.object'},
      );
    });

    test('Storyline links retain the canonical missing resolution', () {
      final project = _project(
        storylines: <StorylineAsset>[
          StorylineAsset(
            id: 'story.links',
            type: StorylineType.main,
            title: 'Links',
            chapters: <StorylineChapter>[
              StorylineChapter(
                id: 'chapter.links',
                title: 'Links',
                order: 0,
                steps: <StorylineStep>[
                  StorylineStep(
                    id: 'step.links',
                    title: 'Links',
                    order: 0,
                    sceneLinkIds: const <String>['scene.missing'],
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      final storyline = project.storylines.single;
      final chapter = storyline.chapters.single;
      final index = buildNarrativeDependencyIndex(project: project);

      final model = buildStorylineStepSceneLinksReadModel(
        project: project,
        storyline: storyline,
        chapter: chapter,
        step: chapter.steps.single,
        dependencyIndex: index,
      );

      expect(model.linkedScenes.single.exists, isFalse);
      expect(
        model.linkedScenes.single.referenceResolution,
        NarrativeDependencyResolution.missing,
      );
    });

    test('Facts manager sees New Game and Event V2 consumers', () {
      final project = _project(
        facts: <NarrativeFactDefinition>[
          NarrativeFactDefinition(id: 'fact.shared', label: 'Shared'),
        ],
        scenes: <SceneAsset>[_emptyScene('scene.event')],
        newGame: const ProjectNewGameConfig(
          enabled: true,
          initialFacts: <String, bool>{'fact.shared': true},
        ),
        eventRegistry: _registry(<NarrativeEventDefinition>[
          _event(
            id: _eventA,
            sceneId: 'scene.event',
            source: NarrativeEventSourceRef.mapEnter('map.loaded'),
            conditions: <NarrativeEventCondition>[
              NarrativeEventCondition.fact('fact.shared', true),
            ],
          ),
        ]),
      );
      final maps = <MapData>[_emptyMap('map.loaded')];
      final index = buildNarrativeDependencyIndex(
        project: project,
        maps: maps,
      );

      final model = buildFactsWorldRulesManagerReadModel(
        project,
        maps: maps,
        dependencyIndex: index,
      );

      expect(
        model.facts.single.usages.map((usage) => usage.kind),
        containsAll(<FactManagerUsageKind>[
          FactManagerUsageKind.newGame,
          FactManagerUsageKind.eventV2,
        ]),
      );
      expect(
        model.facts.single.usages.every(
          (usage) =>
              usage.referenceResolution ==
              NarrativeDependencyResolution.resolved,
        ),
        isTrue,
      );
    });

    test('Cinematics library retains a broken reference resolution', () {
      final project = _project(
        scenes: <SceneAsset>[
          _sceneWithCinematic('scene.cinematic', 'cine.missing'),
        ],
      );
      final index = buildNarrativeDependencyIndex(project: project);

      final model = buildCinematicsLibraryReadModel(
        project,
        dependencyIndex: index,
      );

      expect(model.unknownUsages, hasLength(1));
      expect(
        model.unknownUsages.single.referenceResolution,
        NarrativeDependencyResolution.missing,
      );
    });

    test('Event builder receives canonical dependency diagnostics', () {
      final project = _project(
        scenes: <SceneAsset>[_emptyScene('scene.event')],
        eventRegistry: _registry(<NarrativeEventDefinition>[
          _event(
            id: _eventA,
            sceneId: 'scene.event',
            source: NarrativeEventSourceRef.mapEnter('map.loaded'),
            conditions: <NarrativeEventCondition>[
              NarrativeEventCondition.narrativeEventConsumed(_eventB, true),
            ],
          ),
          _event(
            id: _eventB,
            sceneId: 'scene.event',
            source: NarrativeEventSourceRef.mapEnter('map.loaded'),
            conditions: <NarrativeEventCondition>[
              NarrativeEventCondition.narrativeEventConsumed(_eventA, true),
            ],
          ),
        ]),
      );
      final maps = <MapData>[_emptyMap('map.loaded')];
      final index = buildNarrativeDependencyIndex(
        project: project,
        maps: maps,
      );

      final model = buildNarrativeEventBuilderProjectReadModel(
        project: project,
        maps: maps,
        dependencyIndex: index,
      );

      expect(
        model.events
            .where((event) => event.origin == NarrativeEventProjectOrigin.v2)
            .every(
              (event) => event.diagnostics.any(
                (diagnostic) =>
                    diagnostic.code == 'canonicalDependency.forbiddenCycle',
              ),
            ),
        isTrue,
      );
    });
  });

  group('Narrative dependency inspection', () {
    const target = NarrativeDependencyKey(
      NarrativeDependencyTargetKind.cinematic,
      'cinematic.intro',
    );
    const sceneA = NarrativeDependencyKey.scene('scene.a');
    const sceneB = NarrativeDependencyKey.scene('scene.b');
    const unrelatedOwner = NarrativeDependencyKey.scene('scene.unrelated');
    const unrelatedTarget = NarrativeDependencyKey(
      NarrativeDependencyTargetKind.fact,
      'fact.unrelated',
    );

    test('collects deterministic deduplicated target and consumer issues', () {
      const usages = <NarrativeDependencyUsage>[
        NarrativeDependencyUsage(
          target: target,
          owner: sceneA,
          path: 'scenes[scene.a].graph.nodes[cinematic].payload.cinematicId',
          criticality: NarrativeDependencyCriticality.runtimeBlocking,
        ),
        NarrativeDependencyUsage(
          target: target,
          owner: sceneB,
          path: 'scenes[scene.b].graph.nodes[cinematic].payload.cinematicId',
          criticality: NarrativeDependencyCriticality.runtimeBlocking,
        ),
      ];
      const targetIssue = NarrativeDependencyIssue(
        kind: NarrativeDependencyIssueKind.ambiguousReference,
        target: target,
        owner: sceneA,
        path: 'target.path',
        criticality: NarrativeDependencyCriticality.runtimeBlocking,
        message: 'Target issue',
      );
      const consumerIssue = NarrativeDependencyIssue(
        kind: NarrativeDependencyIssueKind.missingReference,
        target: unrelatedTarget,
        owner: sceneB,
        path: 'consumer.path',
        criticality: NarrativeDependencyCriticality.authoringWarning,
        message: 'Consumer issue',
      );
      const unrelatedIssue = NarrativeDependencyIssue(
        kind: NarrativeDependencyIssueKind.missingReference,
        target: unrelatedTarget,
        owner: unrelatedOwner,
        path: 'unrelated.path',
        criticality: NarrativeDependencyCriticality.authoringWarning,
        message: 'Unrelated issue',
      );
      final definitions = <NarrativeDependencyDefinition>[
        NarrativeDependencyDefinition(key: target, label: 'Introduction'),
      ];

      NarrativeDependencyInspectionReadModel inspect(
        Iterable<NarrativeDependencyIssue> issues,
      ) {
        return inspectNarrativeDependency(
          NarrativeDependencyIndex(
            definitions: definitions,
            usages: usages,
            issues: issues,
          ),
          target,
        );
      }

      final forward = inspect(const [
        targetIssue,
        consumerIssue,
        targetIssue,
        unrelatedIssue,
      ]);
      final reversed = inspect(const [
        unrelatedIssue,
        targetIssue,
        consumerIssue,
        targetIssue,
      ]);

      expect(forward.definitions, hasLength(1));
      expect(forward.usages, hasLength(2));
      expect(
        forward.issues.map((issue) => issue.message),
        containsAll(<String>['Target issue', 'Consumer issue']),
      );
      expect(forward.issues, hasLength(2));
      expect(
        forward.issues.map((issue) => issue.message),
        reversed.issues.map((issue) => issue.message),
      );
      expect(forward.isMissing, isFalse);
      expect(forward.isAmbiguous, isFalse);
      expect(() => forward.usages.clear(), throwsUnsupportedError);
      expect(() => forward.issues.clear(), throwsUnsupportedError);
    });

    test('reports missing and ambiguous targets from definition count', () {
      final missing = inspectNarrativeDependency(
        NarrativeDependencyIndex(),
        target,
      );
      final ambiguous = inspectNarrativeDependency(
        NarrativeDependencyIndex(
          definitions: <NarrativeDependencyDefinition>[
            NarrativeDependencyDefinition(key: target, label: 'One'),
            NarrativeDependencyDefinition(key: target, label: 'Two'),
          ],
        ),
        target,
      );

      expect(missing.isMissing, isTrue);
      expect(missing.isAmbiguous, isFalse);
      expect(ambiguous.isMissing, isFalse);
      expect(ambiguous.isAmbiguous, isTrue);
    });

    test('publishes draft, published and inactive Event metadata', () {
      const draftId = 'evt_00000000-0000-7000-8000-000000000011';
      const publishedId = 'evt_00000000-0000-7000-8000-000000000012';
      const inactiveId = 'evt_00000000-0000-7000-8000-000000000013';
      final configuredPublished = _event(
        id: publishedId,
        sceneId: 'scene.event',
        source: NarrativeEventSourceRef.mapEnter('map.port'),
      );
      final configuredInactive = _event(
        id: inactiveId,
        sceneId: 'scene.event',
        source: NarrativeEventSourceRef.mapEnter('map.port'),
      );
      final project = _project(
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.v2Only,
          legacyClaims: const [],
          records: <NarrativeEventRecord>[
            NarrativeEventRecord.draft(
              NarrativeEventDraft(
                id: draftId,
                name: 'Draft',
                conditions: const [],
                priority: 0,
                order: 0,
              ),
            ),
            NarrativeEventRecord.configuredStructurallyUnchecked(
              configuredPublished,
              enabled: true,
            ),
            NarrativeEventRecord.configuredStructurallyUnchecked(
              configuredInactive,
              enabled: false,
            ),
          ],
        ),
      );

      final index = buildNarrativeDependencyIndex(project: project);

      String status(String id) => index
          .definitionsFor(NarrativeDependencyKey.eventV2(id))
          .single
          .metadata['publicationStatus']!;

      expect(status(draftId), 'draft');
      expect(status(publishedId), 'published');
      expect(status(inactiveId), 'inactive');
    });
  });
}

ProjectManifest _project({
  List<ProjectMapEntry> maps = const <ProjectMapEntry>[],
  List<ProjectDialogueEntry> dialogues = const <ProjectDialogueEntry>[],
  List<NarrativeFactDefinition> facts = const <NarrativeFactDefinition>[],
  List<SceneAsset> scenes = const <SceneAsset>[],
  List<StorylineAsset> storylines = const <StorylineAsset>[],
  List<CinematicAsset> cinematics = const <CinematicAsset>[],
  List<WorldRuleDefinition> worldRules = const <WorldRuleDefinition>[],
  List<ScenarioAsset> scenarios = const <ScenarioAsset>[],
  NarrativeEventRegistry? eventRegistry,
  ProjectNewGameConfig newGame = const ProjectNewGameConfig(),
}) {
  return ProjectManifest(
    name: 'Dependency index test',
    maps: maps,
    tilesets: const [],
    dialogues: dialogues,
    facts: facts,
    scenes: scenes,
    storylines: storylines,
    cinematics: cinematics,
    worldRules: worldRules,
    scenarios: scenarios,
    eventRegistry: eventRegistry,
    newGame: newGame,
  );
}

const _eventA = 'evt_00000000-0000-7000-8000-000000000001';
const _eventB = 'evt_00000000-0000-7000-8000-000000000002';

const _newGameOwner = NarrativeDependencyKey.projectNewGame();

NarrativeEventDefinition _event({
  required String id,
  required String sceneId,
  required NarrativeEventSourceRef source,
  List<NarrativeEventCondition> conditions = const <NarrativeEventCondition>[],
}) {
  return NarrativeEventDefinition(
    id: id,
    name: 'Event $id',
    source: source,
    conditions: conditions,
    sceneId: sceneId,
    reusePolicy: NarrativeEventReusePolicy.oneShot,
    priority: 0,
    order: 0,
  );
}

NarrativeEventRegistry _registry(
  List<NarrativeEventDefinition> events, {
  List<LegacySourceClaim> legacyClaims = const <LegacySourceClaim>[],
}) {
  return NarrativeEventRegistry(
    schemaVersion: 1,
    mode: EventSystemMode.v2Only,
    records: <NarrativeEventRecord>[
      for (final event in events)
        NarrativeEventRecord.configuredStructurallyUnchecked(
          event,
          enabled: true,
        ),
    ],
    legacyClaims: legacyClaims,
  );
}

LegacySourceClaim _legacyClaim({required List<String> targetEventIds}) {
  return LegacySourceClaim(
    cohortId:
        'lsc_65e30267a6ef9fe6e351b4a3789377d563a35b7b8e3ccb47f7bc34f3499dcda3',
    source: NarrativeEventSourceRef.mapEnter('map_port'),
    members: <LegacySourceClaimMember>[
      LegacySourceClaimMember(
        provenance: LegacySourceRef.mapEvent('map_port', 'lysa'),
        sourceFingerprint:
            'sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      ),
      LegacySourceClaimMember(
        provenance: LegacySourceRef.scenarioSourceNode(
          'scenario_arrival',
          'source',
        ),
        sourceFingerprint:
            'sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      ),
    ],
    cohortFingerprint:
        'sha256:f24177958517d13922af29bc3e8a8b18cee0e4649ad6323144f61b45bb5fdb2f',
    targetEventIds: targetEventIds,
    migrationReceiptId: 'evmr_test',
  );
}

SceneAsset _emptyScene(String id) {
  return SceneAsset(
    id: id,
    name: id,
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: <SceneNode>[
        SceneNode(id: 'start', kind: SceneNodeKind.start),
      ],
    ),
  );
}

SceneAsset _sceneWithCinematic(String id, String cinematicId) {
  return SceneAsset(
    id: id,
    name: id,
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: <SceneNode>[
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'cinematic',
          kind: SceneNodeKind.cinematic,
          payload: SceneCinematicPayload(cinematicId: cinematicId),
        ),
      ],
    ),
  );
}

MapData _emptyMap(String id) {
  return MapData(
    id: id,
    name: id,
    size: const GridSize(width: 1, height: 1),
  );
}

String _largeEventId(int index) {
  return 'evt_00000000-0000-7000-8000-${index.toString().padLeft(12, '0')}';
}

StorylineAsset _storyline() {
  return StorylineAsset(
    id: 'story.main',
    type: StorylineType.main,
    title: 'Main',
    chapters: <StorylineChapter>[
      StorylineChapter(
        id: 'chapter.intro',
        title: 'Intro',
        order: 0,
        steps: <StorylineStep>[
          StorylineStep(id: 'step.intro', title: 'Intro', order: 0),
        ],
      ),
    ],
  );
}

WorldRuleDefinition _worldRule() {
  return WorldRuleDefinition(
    id: 'rule.story',
    label: 'Story rule',
    source: const WorldRuleSource(
      kind: WorldRuleSourceKind.fact,
      sourceId: 'fact.story',
      predicate: WorldRuleSourcePredicate.isTrue,
    ),
    target: const WorldRuleTarget(
      kind: WorldRuleTargetKind.npcDialogue,
      mapId: 'map.port',
      entityId: 'npc.rival',
    ),
    effect: const WorldRuleEffect(
      kind: WorldRuleEffectKind.npcDialogueOverride,
      dialogueId: 'dialogue.rival',
    ),
  );
}
