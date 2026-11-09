import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  const source = GameState(
      saveId: 'contextual',
      currentMapId: 'alpha',
      playerPosition: GridPos(x: 6, y: 3),
      playerFacing: EntityFacing.north);
  const first = ContextualItemUseRule(
      id: 'first',
      itemId: 'rope',
      sceneId: 'secret',
      priority: 10,
      position: GridPos(x: 6, y: 3),
      facing: EntityFacing.north);
  ProjectManifest project() =>
      ProjectManifest(name: 'Test', maps: [], tilesets: [], scenes: [
        SceneAsset(
            id: 'secret',
            name: 'Secret',
            graph: SceneGraph(startNodeId: 'start', nodes: [
              SceneNode(id: 'start', kind: SceneNodeKind.start),
              SceneNode(id: 'end', kind: SceneNodeKind.end)
            ], edges: [
              SceneEdge(
                  id: 'edge',
                  fromNodeId: 'start',
                  fromPortId: 'completed',
                  toNodeId: 'end',
                  kind: SceneEdgeKind.defaultFlow)
            ]))
      ]);
  MapData map(List<ContextualItemUseRule> rules) => MapData(
      id: 'alpha',
      name: 'Alpha',
      size: const GridSize(width: 12, height: 12),
      mapMetadata:
          MapMetadata(allowEscapeRope: false, contextualItemUses: rules));

  test(
      'rule matches item position and facing even when ordinary rope is forbidden',
      () {
    final result = selectContextualItemUse(
        map: map([first]), project: project(), state: source, itemId: 'rope');
    expect(
        result,
        isA<ContextualItemUseMatched>()
            .having((r) => r.rule.id, 'rule', 'first'));
    expect(source.bag.entries, isEmpty);
  });
  test('no match is explicit for another item cell or orientation', () {
    for (final state in [
      source.copyWith(playerFacing: EntityFacing.south),
      source.copyWith(playerPosition: const GridPos(x: 7, y: 3))
    ]) {
      expect(
          selectContextualItemUse(
              map: map([first]),
              project: project(),
              state: state,
              itemId: 'rope'),
          isA<ContextualItemUseNoMatch>());
    }
    expect(
        selectContextualItemUse(
            map: map([first]),
            project: project(),
            state: source,
            itemId: 'potion'),
        isA<ContextualItemUseNoMatch>());
  });
  test(
      'highest priority wins and equal priority refuses instead of sorting IDs',
      () {
    const lower =
        ContextualItemUseRule(id: 'lower', itemId: 'rope', sceneId: 'secret');
    final selected = selectContextualItemUse(
        map: map([lower, first]),
        project: project(),
        state: source,
        itemId: 'rope');
    expect(selected,
        isA<ContextualItemUseMatched>().having((r) => r.rule, 'rule', first));
    const tie = ContextualItemUseRule(
        id: 'another', itemId: 'rope', sceneId: 'secret', priority: 10);
    expect(
        selectContextualItemUse(
            map: map([tie, first]),
            project: project(),
            state: source,
            itemId: 'rope'),
        isA<ContextualItemUseRefused>().having(
            (r) => r.reason, 'reason', ContextualItemUseRefusal.ambiguous));
  });
  test('missing condition reference refuses and cannot silently fall back', () {
    final conditional = ContextualItemUseRule(
        id: 'guarded',
        itemId: 'rope',
        sceneId: 'secret',
        conditionExpression: NarrativeEventConditionExpression.leaf(
            NarrativeEventCondition.fact('missing', true)));
    expect(
        selectContextualItemUse(
            map: map([conditional]),
            project: project(),
            state: source,
            itemId: 'rope'),
        isA<ContextualItemUseRefused>().having((r) => r.reason, 'reason',
            ContextualItemUseRefusal.unavailableCondition));
  });
  test(
      'a false valid condition produces no match while a missing Scene refuses',
      () {
    final guarded = ContextualItemUseRule(
        id: 'guarded',
        itemId: 'rope',
        sceneId: 'secret',
        conditionExpression: NarrativeEventConditionExpression.leaf(
            NarrativeEventCondition.fact('ready', true)));
    final known = project().copyWith(
        facts: [NarrativeFactDefinition(id: 'ready', label: 'Ready')]);
    expect(
        selectContextualItemUse(
            map: map([guarded]), project: known, state: source, itemId: 'rope'),
        isA<ContextualItemUseNoMatch>());
    expect(
        selectContextualItemUse(
            map: map([first]),
            project: project().copyWith(scenes: []),
            state: source,
            itemId: 'rope'),
        isA<ContextualItemUseRefused>().having((result) => result.reason,
            'reason', ContextualItemUseRefusal.unavailableScene));
  });
}
