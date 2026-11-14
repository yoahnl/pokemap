import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';

import 'narrative_title_fixture.dart';

SceneEdge _edge(
        String id, String from, String port, String to, SceneEdgeKind kind) =>
    SceneEdge(
        id: id, fromNodeId: from, fromPortId: port, toNodeId: to, kind: kind);

SceneAsset narrativeUsageScene(String id,
        {String read = 'fact_fact_0',
        String written = 'fact_fact_1',
        String? input}) =>
    SceneAsset(
      id: id,
      name: 'Gate $id',
      graph: SceneGraph(startNodeId: 'start', nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
            id: 'check',
            kind: SceneNodeKind.condition,
            payload: SceneConditionPayload(
                conditionSource: SceneConditionSource(
                    sourceKind: SceneConditionSourceKind.fact,
                    sourceId: read,
                    operator: SceneConditionOperator.isTrue,
                    label: 'Gate open'))),
        SceneNode(
            id: 'open',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.consequence(
                SceneConsequence.setFact(factId: written, value: true))),
        if (input != null)
          SceneNode(
              id: 'ask',
              kind: SceneNodeKind.action,
              payload: SceneActionPayload(
                  interactiveCommand: SceneInputIntegerToFactInteractiveCommand(
                      factId: input,
                      prompt: SceneInteractionPrompt(localizationKey: 'ask'),
                      digits: 2,
                      minimum: 0,
                      maximum: 99))),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ], edges: [
        _edge(
            'enter', 'start', 'completed', 'check', SceneEdgeKind.defaultFlow),
        _edge('yes', 'check', 'true', 'open', SceneEdgeKind.conditionTrue),
        _edge('no', 'check', 'false', 'end', SceneEdgeKind.conditionFalse),
        _edge('done', 'open', 'completed', 'end', SceneEdgeKind.defaultFlow),
      ]),
    );

WorldRuleDefinition narrativeUsageRule(
        {String fact = 'fact_fact_3',
        String entity = 'tree',
        String label = 'Tree'}) =>
    WorldRuleDefinition(
        id: 'world_rule_tree',
        label: label,
        source: WorldRuleSource(
            kind: WorldRuleSourceKind.fact,
            sourceId: fact,
            predicate: WorldRuleSourcePredicate.isTrue),
        target: WorldRuleTarget(
            kind: WorldRuleTargetKind.mapEntity,
            mapId: 'town',
            entityId: entity),
        effect: const WorldRuleEffect(kind: WorldRuleEffectKind.entityHidden));

StorylineAsset narrativeUsageStoryline() => StorylineAsset(
      id: 'main',
      type: StorylineType.main,
      title: 'Main quest',
      chapters: [
        StorylineChapter(id: 'intro', title: 'Intro', order: 0, steps: [
          StorylineStep(
              id: 'leave',
              title: 'Leave',
              order: 0,
              completionCondition: const ScriptCondition(
                  type: ScriptConditionType.factEquals,
                  params: {
                    ScriptConditionParams.factId: 'fact_fact_0',
                    ScriptConditionParams.value: 'true'
                  })),
        ]),
      ],
      sceneLinks: [
        StorylineSceneLink(
            id: 'link',
            chapterId: 'intro',
            label: 'Link',
            state: StorylineSceneLinkState.placeholder,
            role: StorylineSceneLinkRole.primary,
            order: 0,
            outcomeLinks: [
              StorylineSceneOutcomeLink(id: 'won', outcomeId: 'won', effects: [
                StorylineEffect(
                    type: StorylineEffectType.emitFact,
                    targetId: 'fact_fact_3'),
              ]),
            ]),
      ],
    );

CinematicAsset narrativeUsageCinematic() => CinematicAsset(
      id: 'arrival',
      title: 'Arrival',
      mapId: 'town',
      stageContext: CinematicStageContext(movementTargetBindings: [
        CinematicMovementTargetBinding(
            targetId: 'to-npc',
            kind: CinematicMovementTargetBindingKind.mapEntity,
            sourceId: 'npc'),
      ]),
      timeline: CinematicTimeline(steps: const []),
    );

NarrativeEventRecord narrativeUsageEvent(int index,
        {String fact = 'fact_fact_1', String entity = 'npc'}) =>
    NarrativeEventRecord.draft(NarrativeEventDraft(
        id: narrativeTitleEvent(index),
        name: 'Talk $index',
        source: NarrativeEventSourceRef.entityInteract('town', entity),
        conditions: [NarrativeEventCondition.fact(fact, true)],
        priority: 0,
        order: index));

ProjectManifest narrativeUsageProject({int unrelated = 0}) =>
    narrativeTitleProject(unrelated: unrelated, facts: 4).copyWith(
      tilesets: const [
        ProjectTilesetEntry(
            id: 'atlas', name: 'Atlas', relativePath: 'assets/atlas.png'),
      ],
      maps: [
        const ProjectMapEntry(
            id: 'town', name: 'Town', relativePath: 'maps/town.json'),
        ...narrativeTitleProject(unrelated: unrelated).maps,
      ],
      scenes: [narrativeUsageScene('gate')],
      worldRules: [narrativeUsageRule()],
      storylines: [narrativeUsageStoryline()],
      cinematics: [narrativeUsageCinematic()],
      eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.v2Only,
          records: [
            narrativeUsageEvent(1),
            narrativeUsageEvent(2, entity: 'sign')
          ],
          legacyClaims: const []),
    );

Future<NarrativeTitleFixture> createNarrativeUsageFixture(
    {int unrelated = 0, Directory? at}) async {
  final fixture = await NarrativeTitleFixture.create(
      project: narrativeUsageProject(unrelated: unrelated), at: at);
  final file = File('${fixture.root.path}/maps/town.json');
  await file.parent.create(recursive: true);
  await file.writeAsString(jsonEncode(MapData(
      id: 'town',
      name: 'Town',
      size: const GridSize(width: 8, height: 8),
      tilesetId: 'atlas',
      layers: [
        ObjectLayer(id: 'objects', name: 'Objects')
      ],
      entities: [
        for (final (index, id) in ['tree', 'npc', 'sign', 'well'].indexed)
          MapEntity(
              id: id,
              kind: MapEntityKind.npc,
              pos: GridPos(x: index, y: 1),
              npc: MapEntityNpcData(displayName: id)),
      ]).toJson()));
  return fixture;
}
