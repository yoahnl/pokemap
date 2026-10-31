import 'package:map_core/map_core.dart';
import 'package:test/test.dart';
import 'periodic_reward_condition_evaluation_test.dart'
    show rewardReference, rewardScene, rewardState;
import 'support/f1_runtime_catalog_fixture.dart';

const eventId = 'evt_019abcde-0000-7000-8000-000000000001';

NarrativeEventRecord record({NarrativeEventConditionExpression? expression}) =>
    NarrativeEventRecord.configuredStructurallyUnchecked(
      NarrativeEventDefinition(
        id: eventId,
        name: 'Daily',
        source: NarrativeEventSourceRef.mapEnter('map'),
        conditions: expression?.leaves ?? const [],
        conditionExpression: expression,
        sceneId: 'source',
        reusePolicy: NarrativeEventReusePolicy.reusable,
        priority: 0,
        order: 0,
      ),
      enabled: true,
    );

void main() {
  test(
    'dispatch uses one indexed scene lookup and blocks unknown calendar',
    () {
      final leaf = NarrativeEventConditionExpression.leaf(
        NarrativeEventCondition.periodicRewardAvailable(
          reference: rewardReference(),
          expectedValue: true,
        ),
      );
      final current = record(expression: leaf);
      final registry = NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.v2Only,
        records: [current],
        legacyClaims: const [],
      );
      final seed = f1ProjectCatalogForRegistry(
        NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.v2Only,
          records: [record()],
          legacyClaims: const [],
        ),
      );
      final catalog = NarrativeEventProjectCatalog(
        manifestHash: seed.manifestHash,
        mapHashes: seed.mapHashes,
        spatialSources: seed.spatialSources,
        outcomeSources: seed.outcomeSources,
        scenes: [
          NarrativeEventProjectSceneEntry(
            scene: rewardScene(),
            buildable: true,
          ),
        ],
        facts: const [],
        events: [
          NarrativeEventProjectEventEntry(
            record: current,
            proposed: false,
            inDependencyCycle: false,
            contextuallyValid: true,
          ),
        ],
        diagnostics: const [],
      );
      final calls = <String>[];
      final ready =
          NarrativeEventDispatchAuthority.prepare(
                registryResult: EventRegistryDecodeResult.decoded(registry),
                occurrence: NarrativeEventOccurrence(
                  source: NarrativeEventSourceRef.mapEnter('map'),
                ),
                factResolver: NarrativeFactRuntimeResolver.fromFacts(const []),
                projectCatalog: catalog,
                lookupRewardScenes: (id) {
                  calls.add(id);
                  return catalog.rewardScenes(id);
                },
              )
              as NarrativeEventDispatchAuthorityReady;
      expect(
        ready.plan(gameState: rewardState()),
        isA<NarrativeEventDispatchHandled>(),
      );
      expect(calls, ['source']);
      final unknown = ready.plan(gameState: rewardState(initialized: false));
      expect(unknown, isA<NarrativeEventDispatchNoMatch>());
      expect(
        unknown.reasons,
        contains(NarrativeEventDispatchReason.runtimeReferenceUnavailable),
      );
    },
  );
  test(
    'reward locator adds reference dependencies without scene execution cycles',
    () {
      final source = SceneConditionSource.periodicRewardAvailable(
        reference: rewardReference(),
        expectedValue: true,
      );
      final condition = SceneAsset(
        id: 'condition',
        name: 'Condition',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'check',
              kind: SceneNodeKind.condition,
              payload: SceneConditionPayload(conditionSource: source),
            ),
            SceneNode(id: 'end', kind: SceneNodeKind.end),
          ],
          edges: [
            SceneEdge(
              id: 'enter',
              fromNodeId: 'start',
              fromPortId: 'completed',
              toNodeId: 'check',
              kind: SceneEdgeKind.defaultFlow,
            ),
            SceneEdge(
              id: 'yes',
              fromNodeId: 'check',
              fromPortId: 'true',
              toNodeId: 'end',
              kind: SceneEdgeKind.conditionTrue,
            ),
            SceneEdge(
              id: 'no',
              fromNodeId: 'check',
              fromPortId: 'false',
              toNodeId: 'end',
              kind: SceneEdgeKind.conditionFalse,
            ),
          ],
        ),
      );
      final project = ProjectManifest(
        name: 'Test',
        maps: const [],
        tilesets: const [],
        scenes: [condition, rewardScene()],
      );
      final calls = <String>[];
      final index = buildNarrativeDependencyIndex(
        project: project,
        lookupRewardScenes: (id) {
          calls.add(id);
          return [rewardScene()];
        },
      );
      expect(calls, ['source']);
      expect(
        index.usages
            .where(
              (usage) =>
                  usage.owner.id == 'condition' &&
                  usage.target.kind == NarrativeDependencyTargetKind.scene,
            )
            .map((usage) => usage.target.id),
        contains('source'),
      );
      expect(
        index.usages
            .where(
              (usage) =>
                  usage.owner.id == 'condition' &&
                  usage.target.sourceKind == 'sceneNode',
            )
            .map((usage) => usage.target.id),
        contains('claim'),
      );
      expect(
        index.issues.where(
          (issue) => issue.kind == NarrativeDependencyIssueKind.forbiddenCycle,
        ),
        isEmpty,
      );
      final symbolic = solveNarrativeSceneSymbolically(condition);
      expect(
        symbolic.issues.any(
          (issue) =>
              issue.code == NarrativeSymbolicIssueCode.unsupportedCondition,
        ),
        isTrue,
      );
    },
  );
  test(
    'symbolic NOT ALL does not certify a missing reward while legacy evaluation stays unchanged',
    () {
      NarrativeEventConditionExpression expression(bool periodic) =>
          NarrativeEventConditionExpression.not(
            NarrativeEventConditionExpression.all([
              NarrativeEventConditionExpression.leaf(
                NarrativeEventCondition.fact('closed', true),
              ),
              if (periodic)
                NarrativeEventConditionExpression.leaf(
                  NarrativeEventCondition.periodicRewardAvailable(
                    reference: rewardReference(),
                    expectedValue: true,
                  ),
                ),
            ]),
          );
      NarrativeSymbolicReachabilityReport solve(bool periodic) {
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
          scenes: [rewardScene()],
          facts: [NarrativeFactDefinition(id: 'closed', label: 'Closed')],
          eventRegistry: NarrativeEventRegistry(
            schemaVersion: 1,
            mode: EventSystemMode.v2Only,
            records: [record(expression: expression(periodic))],
            legacyClaims: const [],
          ),
        );
        return solveNarrativeSymbolicReachability(
          project,
          maps: [
            MapData(
              id: 'map',
              name: 'Map',
              size: const GridSize(width: 4, height: 4),
            ),
          ],
        );
      }

      expect(
        solve(true).issues.any(
          (issue) =>
              issue.code == NarrativeSymbolicIssueCode.unsupportedCondition,
        ),
        isTrue,
      );
      expect(
        solve(false).issues.any(
          (issue) =>
              issue.code == NarrativeSymbolicIssueCode.unsupportedCondition,
        ),
        isFalse,
      );
    },
  );
  test(
    'full symbolic scene batches keep periodic reads separate from integer operands',
    () {
      final scene = SceneAsset(
        id: 'condition',
        name: 'Condition',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'condition',
              kind: SceneNodeKind.condition,
              payload: SceneConditionPayload(
                conditionSource: SceneConditionSource.periodicRewardAvailable(
                  reference: rewardReference(),
                  expectedValue: true,
                ),
              ),
            ),
            SceneNode(id: 'end', kind: SceneNodeKind.end),
          ],
          edges: [
            SceneEdge(
              id: 'enter',
              fromNodeId: 'start',
              fromPortId: 'completed',
              toNodeId: 'condition',
              kind: SceneEdgeKind.defaultFlow,
            ),
            SceneEdge(
              id: 'yes',
              fromNodeId: 'condition',
              fromPortId: 'true',
              toNodeId: 'end',
              kind: SceneEdgeKind.conditionTrue,
            ),
            SceneEdge(
              id: 'no',
              fromNodeId: 'condition',
              fromPortId: 'false',
              toNodeId: 'end',
              kind: SceneEdgeKind.conditionFalse,
            ),
          ],
        ),
      );
      final event = NarrativeEventRecord.configuredStructurallyUnchecked(
        NarrativeEventDefinition(
          id: eventId,
          name: 'Condition',
          source: NarrativeEventSourceRef.mapEnter('map'),
          conditions: const [],
          sceneId: 'condition',
          reusePolicy: NarrativeEventReusePolicy.reusable,
          priority: 0,
          order: 0,
        ),
        enabled: true,
      );
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
        scenes: [scene, rewardScene()],
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.v2Only,
          records: [event],
          legacyClaims: const [],
        ),
      );
      final report = solveNarrativeSymbolicReachability(
        project,
        maps: [
          MapData(
            id: 'map',
            name: 'Map',
            size: const GridSize(width: 4, height: 4),
          ),
        ],
      );
      expect(
        report.issues.any(
          (issue) =>
              issue.code == NarrativeSymbolicIssueCode.unsupportedCondition,
        ),
        isTrue,
      );
    },
  );
  test('calendar-dependent World Rules cannot receive a symbolic pass', () {
    final project = ProjectManifest(
      name: 'Test',
      maps: const [
        ProjectMapEntry(id: 'map', name: 'Map', relativePath: 'maps/map.json'),
      ],
      tilesets: const [],
      scenes: [rewardScene()],
      worldRules: [
        WorldRuleDefinition(
          id: 'daily',
          label: 'Daily',
          source: WorldRuleSource.periodicRewardAvailable(
            reference: rewardReference(),
            expectedValue: false,
          ),
          target: const WorldRuleTarget(
            kind: WorldRuleTargetKind.mapEntity,
            mapId: 'map',
            entityId: 'tree',
          ),
          effect: const WorldRuleEffect(kind: WorldRuleEffectKind.entityHidden),
        ),
      ],
    );
    final report = solveNarrativeSymbolicReachability(
      project,
      maps: [
        MapData(
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
        ),
      ],
    );
    expect(
      report.issues.any(
        (issue) =>
            issue.code == NarrativeSymbolicIssueCode.unsupportedCondition,
      ),
      isTrue,
    );
    expect(report.verdict, NarrativeSymbolicVerdict.indeterminate);
  });
}
