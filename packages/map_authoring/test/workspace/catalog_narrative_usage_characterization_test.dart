import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../support/narrative_usage_fixture.dart';

bool _relevant(NarrativeDependencyUsage usage) =>
    usage.target.kind == NarrativeDependencyTargetKind.fact ||
    (usage.target.isPhysicalMapSource && usage.target.sourceKind != 'map');

Set<String> _usages(ProjectManifest project) => {
      for (final usage in buildNarrativeDependencyIndex(project: project)
          .usages
          .where(_relevant))
        '${usage.owner.kind.name}:${usage.owner.id}|${usage.target}|${usage.path}'
    };

List<ProjectManifest> _documents(ProjectManifest project) {
  final empty =
      ProjectManifest(name: 'owner', maps: const [], tilesets: const []);
  return [
    for (final scene in project.scenes) empty.copyWith(scenes: [scene]),
    for (final rule in project.worldRules) empty.copyWith(worldRules: [rule]),
    for (final storyline in project.storylines)
      empty.copyWith(storylines: [storyline]),
    for (final cinematic in project.cinematics)
      empty.copyWith(cinematics: [cinematic]),
    for (final record in project.eventRegistry!.records)
      empty.copyWith(
          eventRegistry: NarrativeEventRegistry(
              schemaVersion: 1,
              mode: EventSystemMode.v2Only,
              records: [record],
              legacyClaims: const [])),
  ];
}

void main() {
  test('one-document analyses reproduce the whole-project usages', () {
    final project = narrativeUsageProject()
        .copyWith(scenes: [narrativeUsageScene('gate', input: 'fact_fact_2')]);
    final whole = _usages(project);
    expect({for (final document in _documents(project)) ..._usages(document)},
        whole);
    expect(
        whole,
        containsAll([
          'scene:gate|fact:fact_fact_0|scenes[gate].graph.nodes[1].payload.conditionSource.sourceId',
          'scene:gate|fact:fact_fact_1|scenes[gate].graph.nodes[2].payload.consequence.factId',
          'scene:gate|fact:fact_fact_2|scenes[gate].graph.nodes[3].payload.interactiveCommand.factId',
          'worldRule:world_rule_tree|fact:fact_fact_3|worldRules[world_rule_tree].source.sourceId',
          'storyline:main|fact:fact_fact_0|storylines[main].chapters[0].steps[0].completionCondition.params.factId',
          'storyline:main|fact:fact_fact_3|storylines[main].sceneLinks[0].outcomeLinks[0].effects[0].targetId',
        ]));
    expect(
        whole
            .where((usage) => usage.contains('sourceMap:'))
            .map((usage) => usage.substring(0, usage.lastIndexOf('|'))),
        containsAll([
          'worldRule:world_rule_tree|sourceMap:tree (scope=map, parent=town, sourceKind=entity)',
          'cinematic:arrival|sourceMap:npc (scope=map, parent=town, sourceKind=entity)',
        ]));
  });

  test(
      'a legacy flag alias resolves only when the Fact definitions are present',
      () {
    final scene = SceneAsset(
        id: 'legacy',
        name: 'Legacy',
        graph: SceneGraph(startNodeId: 'start', nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
              id: 'check',
              kind: SceneNodeKind.condition,
              payload: SceneConditionPayload(
                  conditionSource: SceneConditionSource(
                      sourceKind: SceneConditionSourceKind.factLikeStoryFlag,
                      sourceId: 'OLD_FLAG',
                      operator: SceneConditionOperator.isTrue,
                      label: 'Old'))),
        ], edges: const []));
    final alone =
        ProjectManifest(name: 'owner', maps: const [], tilesets: const [])
            .copyWith(scenes: [scene]);
    final withFacts = alone.copyWith(facts: [
      NarrativeFactDefinition(
          id: 'fact_old', label: 'Old', legacyFlagName: 'OLD_FLAG')
    ]);
    expect(_usages(alone).single, contains('fact:OLD_FLAG|'));
    expect(_usages(withFacts).single, contains('fact:fact_old|'));
  });
}
