import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

PeriodicRewardReference rewardReference({
  String nodeId = 'claim',
  String rewardId = 'daily',
}) => PeriodicRewardReference(
  sceneId: 'source',
  nodeId: nodeId,
  rewardId: rewardId,
);

SceneAsset rewardScene() {
  final command = SceneInteractiveCommand.claimPeriodicReward(
    definition: PeriodicItemRewardDefinition(
      rewardId: 'daily',
      label: 'Fruit',
      itemId: 'fruit',
      quantity: 1,
    ),
  );
  return SceneAsset(
    id: 'source',
    name: 'Source',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'claim',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.interactive(command),
        ),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'enter',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'claim',
          kind: SceneEdgeKind.defaultFlow,
        ),
        for (final port in command.outputPortIds)
          SceneEdge(
            id: port,
            fromNodeId: 'claim',
            fromPortId: port,
            toNodeId: 'end',
            kind: SceneEdgeKind.actionCompleted,
          ),
      ],
    ),
  );
}

GameState rewardState({bool claimed = false, bool initialized = true}) =>
    GameState(
      saveId: 'save',
      gameplayCalendarState: initialized
          ? GameplayCalendarState(
              observedLocalDay: '2026-10-31',
              dayRevision: 1,
            )
          : const GameplayCalendarState.empty(),
      periodicRewardState: claimed
          ? PeriodicRewardState(
              claimsById: {
                'daily': PeriodicRewardClaim(
                  revision: 1,
                  lastClaimDayRevision: 1,
                  lastClaimLocalDay: '2026-10-31',
                ),
              },
            )
          : const PeriodicRewardState.empty(),
    );

void main() {
  for (final deferred in [false, true]) {
    test('event catalog preserves data-only reward resolver deferred=$deferred', () {
      final requests = <String>[];
      final consumer = SceneAsset(id: 'consumer', name: 'Consumer',
        graph: SceneGraph(startNodeId: 'start', nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(id: 'end', kind: SceneNodeKind.end),
        ], edges: [SceneEdge(id: 'end', fromNodeId: 'start', fromPortId: 'completed',
          toNodeId: 'end', kind: SceneEdgeKind.defaultFlow)]),
      );
      final project = ProjectManifest(name: 'Consumer', maps: [
        const ProjectMapEntry(id: 'map', name: 'Map', relativePath: 'maps/map.json'),
      ], tilesets: [], scenes: [consumer]);
      final event = NarrativeEventRecord.configuredStructurallyUnchecked(
        NarrativeEventDefinition(id: 'evt_018f0f8c-7b8a-7def-8000-000000000001',
          name: 'Daily event', source: NarrativeEventSourceRef.mapEnter('map'),
          conditions: [NarrativeEventCondition.periodicRewardAvailable(
            reference: rewardReference(), expectedValue: true)],
          sceneId: 'consumer', reusePolicy: NarrativeEventReusePolicy.reusable,
          priority: 0, order: 0), enabled: false,
      );
      final catalog = buildNarrativeEventProjectCatalog(
        project: project, maps: [const MapData(id: 'map', name: 'Map',
          size: GridSize(width: 2, height: 2))], deferFingerprints: deferred,
        proposedRecords: [event],
        lookupRewardScenes: (id) {
          requests.add(id);
          return id == 'source' ? [rewardScene()] : const [];
        },
      );
      expect(catalog.scenes.single.scene.id, 'consumer');
      expect(catalog.hasBlockingDiagnostics, isFalse,
        reason: catalog.diagnostics.map((entry) => '${entry.code}: ${entry.path}').join('\n'));
      expect(catalog.resolveRewardReference(rewardReference()).isResolved, isTrue);
      expect(catalog.rewardScenes('source').single.id, 'source');
      expect(catalog.resolveRewardReference(rewardReference(nodeId: 'missing')).isResolved, isFalse);
      expect(requests, ['source', 'source', 'source', 'source']);
      expect(project.scenes, [consumer]);
    });
  }
  test(
    'resolver requests one scene and distinguishes absent claims from missing definitions',
    () {
      final requests = <String>[];
      Iterable<SceneAsset> lookup(String id) {
        requests.add(id);
        return [rewardScene()];
      }

      final result = evaluatePeriodicRewardCondition(
        reference: rewardReference(),
        expectedValue: true,
        gameState: rewardState(),
        lookupScenes: lookup,
      );
      expect(result.passed, isTrue);
      expect(result.unavailable, isFalse);
      expect(requests, ['source']);
      for (final reference in [
        rewardReference(nodeId: 'absent'),
        rewardReference(nodeId: 'end'),
        rewardReference(rewardId: 'wrong'),
      ]) {
        for (final expected in [true, false]) {
          final result = evaluatePeriodicRewardCondition(
            reference: reference,
            expectedValue: expected,
            gameState: rewardState(),
            lookupScenes: lookup,
          );
          expect(result.passed, isFalse);
          expect(result.unavailable, isTrue);
        }
      }
    },
  );
  test(
    'known claimed state is false while unknown calendar never matches either expectation',
    () {
      for (final expected in [true, false]) {
        final known = evaluatePeriodicRewardCondition(
          reference: rewardReference(),
          expectedValue: expected,
          gameState: rewardState(claimed: true),
          lookupScenes: (_) => [rewardScene()],
        );
        expect(known.passed, !expected);
        expect(known.unavailable, isFalse);
        final unknown = evaluatePeriodicRewardCondition(
          reference: rewardReference(),
          expectedValue: expected,
          gameState: rewardState(initialized: false),
          lookupScenes: (_) => [rewardScene()],
        );
        expect(unknown.passed, isFalse);
        expect(unknown.unavailable, isTrue);
      }
    },
  );
  test(
    'missing scene and ambiguous scene remain unavailable under nested negation',
    () {
      for (final scenes in <List<SceneAsset>>[
        [],
        [rewardScene(), rewardScene()],
      ]) {
        final expression = NarrativeEventConditionExpression.not(
          NarrativeEventConditionExpression.all([
            NarrativeEventConditionExpression.leaf(
              NarrativeEventCondition.periodicRewardAvailable(
                reference: rewardReference(),
                expectedValue: true,
              ),
            ),
          ]),
        );
        final result = evaluateNarrativeConditionExpression(
          expression,
          evaluateLeaf: (_) => evaluatePeriodicRewardCondition(
            reference: rewardReference(),
            expectedValue: true,
            gameState: rewardState(),
            lookupScenes: (_) => scenes,
          ),
        );
        expect(result.passed, isFalse);
        expect(result.unavailable, isTrue);
      }
    },
  );
  test(
    'real entity projection resolves one scene across validation and selection',
    () {
      final calls = <String>[];
      Iterable<SceneAsset> lookup(String id) {
        calls.add(id);
        return [rewardScene()];
      }

      final entity = MapEntity(
        id: 'tree',
        kind: MapEntityKind.custom,
        pos: const GridPos(x: 1, y: 1),
        presentation: MapEntityPresentation(
          variants: [
            MapEntityPresentationVariant(
              id: 'full',
              condition: NarrativeEventConditionExpression.leaf(
                NarrativeEventCondition.periodicRewardAvailable(
                  reference: rewardReference(),
                  expectedValue: true,
                ),
              ),
              blocksMovement: true,
            ),
          ],
        ),
      );
      final project = ProjectManifest(
        name: 'Test',
        maps: const [],
        tilesets: const [],
        scenes: [
          rewardScene(),
          for (var i = 0; i < 535; i++)
            SceneAsset(
              id: 'unrelated-$i',
              name: 'Unrelated',
              graph: SceneGraph(
                startNodeId: 'start',
                nodes: [SceneNode(id: 'start', kind: SceneNodeKind.start)],
                edges: const [],
              ),
            ),
        ],
      );
      final map = MapData(
        id: 'map',
        name: 'Map',
        size: const GridSize(width: 4, height: 4),
        entities: [entity],
      );
      expect(
        projectMapEntityPresentation(
          project: project,
          gameState: rewardState(),
          map: map,
          entity: entity,
          lookupRewardScenes: lookup,
        )?.id,
        'tree',
      );
      expect(calls, ['source']);
      expect(
        projectMapEntityPresentation(
          project: project,
          gameState: rewardState(),
          map: map,
          entity: entity,
        ),
        isNull,
      );
      expect(
        projectMapEntityPresentation(
          project: project,
          gameState: rewardState(claimed: true),
          map: map,
          entity: entity,
          lookupRewardScenes: lookup,
        ),
        isNull,
      );
    },
  );
  test(
    'real World Rule projection shares bounded lookup and refuses absent context',
    () {
      final calls = <String>[];
      Iterable<SceneAsset> lookup(String id) {
        calls.add(id);
        return [rewardScene()];
      }

      final project = ProjectManifest(
        name: 'Test',
        maps: const [
          ProjectMapEntry(
            id: 'map',
            name: 'Map',
            relativePath: 'maps/map.json',
          ),
        ],
        tilesets: const [],
        worldRules: [
          WorldRuleDefinition(
            id: 'rule',
            label: 'Rule',
            source: WorldRuleSource.periodicRewardAvailable(
              reference: rewardReference(),
              expectedValue: true,
            ),
            target: const WorldRuleTarget(
              kind: WorldRuleTargetKind.mapEntity,
              mapId: 'map',
              entityId: 'tree',
            ),
            effect: const WorldRuleEffect(
              kind: WorldRuleEffectKind.entityVisible,
            ),
          ),
        ],
      );
      final map = MapData(
        id: 'map',
        name: 'Map',
        size: const GridSize(width: 4, height: 4),
        entities: const [
          MapEntity(
            id: 'tree',
            kind: MapEntityKind.custom,
            pos: GridPos(x: 1, y: 1),
          ),
        ],
      );
      expect(
        projectWorldRuleEffects(
          project,
          rewardState(),
          maps: [map],
          lookupRewardScenes: lookup,
        ).length,
        1,
      );
      expect(calls, ['source']);
      expect(
        projectWorldRuleEffects(project, rewardState(), maps: [map]),
        isEmpty,
      );
    },
  );

  test('existing expression operators keep unknown through NOT and ALL', () {
    final unknown = NarrativeEventConditionExpression.leaf(
      NarrativeEventCondition.periodicRewardAvailable(
        reference: rewardReference(),
        expectedValue: true,
      ),
    );
    final knownFalse = NarrativeEventConditionExpression.leaf(
      NarrativeEventCondition.fact('false', true),
    );
    final knownTrue = NarrativeEventConditionExpression.leaf(
      NarrativeEventCondition.fact('true', true),
    );
    NarrativeConditionEvaluation evaluate(
      NarrativeEventConditionExpression expression,
    ) => evaluateNarrativeConditionExpression(
      expression,
      evaluateLeaf: (condition) => condition.rewardReference != null
          ? const NarrativeConditionEvaluation(passed: false, unavailable: true)
          : NarrativeConditionEvaluation(
              passed: condition.toJson()['factId'] == 'true',
            ),
    );
    for (final expression in [
      unknown,
      NarrativeEventConditionExpression.not(unknown),
      NarrativeEventConditionExpression.all([knownFalse, unknown]),
      NarrativeEventConditionExpression.not(
        NarrativeEventConditionExpression.all([knownFalse, unknown]),
      ),
      NarrativeEventConditionExpression.any([knownFalse, unknown]),
    ]) {
      expect(evaluate(expression).passed, isFalse);
      expect(evaluate(expression).unavailable, isTrue);
    }
    final any = evaluate(
      NarrativeEventConditionExpression.any([knownTrue, unknown]),
    );
    expect(any.passed, isTrue);
    expect(any.unavailable, isFalse);
  });
}
