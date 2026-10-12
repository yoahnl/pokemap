import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/narrative_scene_runtime_execution.dart';
import 'package:map_runtime/src/application/scene_runtime/scene_runtime_host_callbacks.dart';
import 'package:map_runtime/src/application/scene_runtime/scene_fact_condition_runtime_resolver.dart';
import 'package:map_runtime/src/application/scene_runtime/scene_event_runtime_hook.dart';

void main() {
  for (final outcome in ['victory', 'captured']) {
    test(
      'unique $outcome preserves deferred gift retry without replaying battle',
      () async {
        final scene = _uniqueGiftScene();
        final project = _project(scene).copyWith(
          encounterTables: const [
            ProjectEncounterTable(
              id: 'unique',
              name: 'Unique',
              encounterKind: EncounterKind.special,
              tags: ['studio:unique'],
              entries: [
                ProjectEncounterEntry(
                  speciesId: 'magnemite',
                  minLevel: 30,
                  maxLevel: 30,
                ),
              ],
            ),
          ],
        );
        var battles = 0;
        Future<NarrativeSceneExecutionCompleted> play(GameState state) async {
          final result = await executeNarrativeEventScene(
            request: NarrativeSceneExecutionRequest(
              eventId: 'unique_gift',
              sceneId: scene.id,
              executionId: 'unique_gift',
              gameState: state,
            ),
            project: project,
            mapsById: const {},
            currentGameState: () => state,
            callbacks: _callbacks(
              state,
              battle: (_) {
                battles++;
                return outcome;
              },
            ),
          );
          expect(result, isA<NarrativeSceneExecutionCompleted>());
          return result as NarrativeSceneExecutionCompleted;
        }

        final pending = await play(
          const GameState(
            saveId: 'unique_gift',
            bag: Bag(
              entries: [
                BagEntry(itemId: 'tm23', quantity: maximumBagEntryQuantity),
              ],
            ),
          ),
        );
        expect(pending.consumeOneShot, isFalse);
        expect(
          pending.updatedGameState.storyFlags.activeFlags,
          contains(uniqueEncounterConsumedFlag('unique')),
        );
        final reloaded = GameState.fromJson(pending.updatedGameState.toJson());
        final space = const BagOperations().take(
          BagTakeRequest(bag: reloaded.bag, itemId: 'tm23', quantity: 1),
        );
        final received = await play(reloaded.copyWith(bag: space.bag));
        expect(received.qualifiedOutcomes.single.outcomeId, 'received');
        expect(received.consumeOneShot, isTrue);
        expect(battles, 1);
        expect(received.updatedGameState.bag, pending.updatedGameState.bag);
      },
    );
  }
  test(
    'event page hook buffers gift and badge before observing the receipt',
    () async {
      const initial = GameState(saveId: 'legacy');
      final scene = _scene();
      final event = MapEventDefinition(
        id: 'gift',
        title: 'Gift',
        position: const EventPosition(layerId: 'base', x: 0, y: 0),
        pages: [
          MapEventPage(
            pageNumber: 0,
            sceneTarget: MapEventSceneTarget(sceneId: scene.id),
          ),
        ],
      );
      final map = MapData(
        id: 'gym',
        name: 'Gym',
        size: const GridSize(width: 1, height: 1),
        layers: [
          MapLayer.tile(id: 'base', name: 'Base', cells: [0]),
        ],
        events: [event],
      );
      final result = await SceneEventRuntimeHook(callbacks: _callbacks(initial))
          .runForEventPage(
            project: _project(scene),
            map: map,
            event: event,
            page: event.pages.single,
            gameState: initial,
            currentGameState: () => initial,
          );
      expect(result.success, isTrue, reason: result.message);
      expect(result.updatedGameState!.trainerProfile.badgeIds, ['mineral']);
      expect(
        const BagOperations().quantityOf(result.updatedGameState!.bag, 'tm23'),
        1,
      );
      expect(initial.bag.entries, isEmpty);
    },
  );
  test(
    'full bag preserves badge and retry delivers exactly once after cold save',
    () async {
      final full = GameState(
        saveId: 'gift',
        bag: const Bag(
          entries: [
            BagEntry(itemId: 'tm23', quantity: maximumBagEntryQuantity),
          ],
        ),
      );
      final pending = await _run(full);
      expect(pending.qualifiedOutcomes.single.outcomeId, 'pending');
      expect(pending.consumeOneShot, isFalse);
      expect(pending.updatedGameState.trainerProfile.badgeIds, ['mineral']);
      expect(pending.updatedGameState.bag, full.bag);
      expect(
        pending.updatedGameState.narrativeFactRuntimeState.valuesByFactId,
        isEmpty,
      );
      final reloaded = GameState.fromJson(pending.updatedGameState.toJson());
      final space = const BagOperations().take(
        BagTakeRequest(bag: reloaded.bag, itemId: 'tm23', quantity: 1),
      );
      final received = await _run(reloaded.copyWith(bag: space.bag));
      expect(received.qualifiedOutcomes.single.outcomeId, 'received');
      expect(received.consumeOneShot, isTrue);
      expect(received.updatedGameState.bag, full.bag);
      final replay = await _run(
        GameState.fromJson(received.updatedGameState.toJson()),
      );
      expect(replay.updatedGameState, received.updatedGameState);
    },
  );

  test(
    'failed scene rolls back item receipt and buffered badge together',
    () async {
      const initial = GameState(saveId: 'rollback');
      final scene = _scene(rejectAfterGift: true);
      final result = await _execute(initial, scene);
      expect(result, isA<NarrativeSceneExecutionFailed>());
      expect(initial.bag.entries, isEmpty);
      expect(initial.trainerProfile.badgeIds, isEmpty);
      expect(initial.narrativeFactRuntimeState.valuesByFactId, isEmpty);
    },
  );
}

Future<NarrativeSceneExecutionCompleted> _run(GameState state) async {
  final result = await _execute(state, _scene());
  expect(result, isA<NarrativeSceneExecutionCompleted>());
  return result as NarrativeSceneExecutionCompleted;
}

Future<NarrativeSceneExecutionResult> _execute(
  GameState state,
  SceneAsset scene,
) => executeNarrativeEventScene(
  request: NarrativeSceneExecutionRequest(
    eventId: 'gift',
    sceneId: scene.id,
    executionId: 'gift_execution',
    gameState: state,
  ),
  project: _project(scene),
  mapsById: const {},
  currentGameState: () => state,
  callbacks: _callbacks(state),
);

ProjectManifest _project(SceneAsset scene) => ProjectManifest(
  name: 'Gift',
  maps: const [],
  tilesets: const [],
  badges: const [BadgeDefinition(id: 'mineral', label: 'Badge Mineral')],
  facts: [NarrativeFactDefinition(id: 'received', label: 'CT reçue')],
  scenes: [scene],
);

SceneRuntimeHostCallbacks _callbacks(
  GameState state, {
  SceneRuntimeIntentCallback? battle,
}) => SceneRuntimeHostCallbacks(
  evaluateCondition: (intent) {
    if (intent.conditionSource!.sourceKind ==
        SceneConditionSourceKind.factLikeStoryFlag) {
      return state.storyFlags.activeFlags.contains(
            intent.conditionSource!.sourceId,
          )
          ? 'true'
          : 'false';
    }
    if (intent.conditionSource!.sourceKind == SceneConditionSourceKind.badge) {
      return evaluateSceneBadgeCondition(
            source: intent.conditionSource!,
            gameState: state,
          )
          ? 'true'
          : 'false';
    }
    return evaluateCanonicalNarrativeFactSceneCondition(
          source: intent.conditionSource!,
          gameState: state,
          resolver: NarrativeFactRuntimeResolver.fromFacts([
            NarrativeFactDefinition(id: 'received', label: 'CT reçue'),
          ]),
        )
        ? 'true'
        : 'false';
  },
  showDialogue: (_) => throw StateError('Unexpected dialogue'),
  startBattle: battle ?? (_) => throw StateError('Unexpected battle'),
  playCinematic: (_) => throw StateError('Unexpected cinematic'),
  executeInteractiveCommand: (_) =>
      throw StateError('Gift must belong to the Scene transaction'),
);

SceneAsset _scene({bool rejectAfterGift = false}) {
  SceneNode action(String id, SceneConsequence consequence) => SceneNode(
    id: id,
    kind: SceneNodeKind.action,
    payload: SceneActionPayload.consequence(consequence),
  );
  SceneEdge edge(
    String id,
    String from,
    String port,
    String to, [
    SceneEdgeKind kind = SceneEdgeKind.defaultFlow,
  ]) => SceneEdge(
    id: id,
    fromNodeId: from,
    fromPortId: port,
    toNodeId: to,
    kind: kind,
  );
  return SceneAsset(
    id: 'gift',
    name: 'Badge et CT',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'receipt',
          kind: SceneNodeKind.condition,
          payload: SceneConditionPayload(
            conditionSource: SceneConditionSource(
              sourceKind: SceneConditionSourceKind.fact,
              sourceId: 'received',
              operator: SceneConditionOperator.isTrue,
              label: 'CT reçue',
            ),
          ),
        ),
        action('badge', SceneConsequence.awardBadge(badgeId: 'mineral')),
        SceneNode(
          id: 'badge_check',
          kind: SceneNodeKind.condition,
          payload: SceneConditionPayload(
            conditionSource: SceneConditionSource(
              sourceKind: SceneConditionSourceKind.badge,
              sourceId: 'mineral',
              operator: SceneConditionOperator.isTrue,
              label: 'Badge Mineral',
            ),
          ),
        ),
        SceneNode(
          id: 'gift',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.interactive(
            SceneInteractiveCommand.giveItem(itemId: 'tm23', quantity: 1),
          ),
        ),
        action(
          'received',
          SceneConsequence.setFact(factId: 'received', value: true),
        ),
        if (rejectAfterGift)
          action(
            'reject',
            SceneConsequence.takeItem(itemId: 'tm23', quantity: 2),
          ),
        SceneNode(
          id: 'end_received',
          kind: SceneNodeKind.end,
          payload: SceneEndPayload(
            sceneOutcomeId: 'received',
            outcomePolicy: SceneOutcomePolicy.progression,
          ),
        ),
        SceneNode(
          id: 'end_pending',
          kind: SceneNodeKind.end,
          payload: SceneEndPayload(
            sceneOutcomeId: 'pending',
            outcomePolicy: SceneOutcomePolicy.retryable,
          ),
        ),
      ],
      edges: [
        edge('start_receipt', 'start', 'completed', 'receipt'),
        edge(
          'receipt_true',
          'receipt',
          'true',
          'end_received',
          SceneEdgeKind.conditionTrue,
        ),
        edge(
          'receipt_false',
          'receipt',
          'false',
          'badge',
          SceneEdgeKind.conditionFalse,
        ),
        edge('badge_check', 'badge', 'completed', 'badge_check'),
        edge(
          'badge_true',
          'badge_check',
          'true',
          'gift',
          SceneEdgeKind.conditionTrue,
        ),
        edge(
          'badge_false',
          'badge_check',
          'false',
          'end_pending',
          SceneEdgeKind.conditionFalse,
        ),
        edge('gift_received', 'gift', 'received', 'received'),
        edge('gift_pending', 'gift', 'bagFull', 'end_pending'),
        edge(
          'received_end',
          'received',
          'completed',
          rejectAfterGift ? 'reject' : 'end_received',
        ),
        if (rejectAfterGift)
          edge('reject_end', 'reject', 'completed', 'end_received'),
      ],
    ),
    layout: SceneGraphLayout(nodeLayouts: const []),
    declaredOutcomes: [
      SceneOutcome(id: 'received', label: 'CT reçue'),
      SceneOutcome(id: 'pending', label: 'CT à récupérer'),
    ],
  );
}

SceneAsset _uniqueGiftScene() {
  final json = _scene().toJson();
  final graph = json['graph'] as Map<String, dynamic>;
  final nodes = graph['nodes'] as List;
  nodes.addAll(<Map<String, dynamic>>[
    SceneNode(
      id: 'unique_check',
      kind: SceneNodeKind.condition,
      payload: SceneConditionPayload(
        conditionSource: SceneConditionSource(
          sourceKind: SceneConditionSourceKind.factLikeStoryFlag,
          sourceId: uniqueEncounterConsumedFlag('unique'),
          operator: SceneConditionOperator.isTrue,
          label: 'Rencontre effectuée',
        ),
      ),
    ).toJson(),
    SceneNode(
      id: 'unique_battle',
      kind: SceneNodeKind.battle,
      payload: SceneBattlePayload(
        battleKind: 'wild',
        battleTemplateId: 'unique',
        declaredOutcomes: const ['victory', 'captured', 'defeat', 'runaway'],
      ),
    ).toJson(),
  ]);
  final edges = graph['edges'] as List;
  for (final edge in edges.cast<Map<String, dynamic>>()) {
    if (edge['id'] == 'receipt_false') edge['toNodeId'] = 'unique_check';
  }
  edges.addAll(<Map<String, dynamic>>[
    SceneEdge(
      id: 'unique_true',
      fromNodeId: 'unique_check',
      fromPortId: 'true',
      toNodeId: 'badge',
      kind: SceneEdgeKind.conditionTrue,
    ).toJson(),
    SceneEdge(
      id: 'unique_false',
      fromNodeId: 'unique_check',
      fromPortId: 'false',
      toNodeId: 'unique_battle',
      kind: SceneEdgeKind.conditionFalse,
    ).toJson(),
    for (final outcome in ['victory', 'captured', 'defeat', 'runaway'])
      SceneEdge(
        id: 'unique_$outcome',
        fromNodeId: 'unique_battle',
        fromPortId: outcome,
        toNodeId: outcome == 'victory' || outcome == 'captured'
            ? 'badge'
            : 'end_pending',
        kind: switch (outcome) {
          'victory' => SceneEdgeKind.battleVictory,
          'defeat' => SceneEdgeKind.battleDefeat,
          _ => SceneEdgeKind.branchOutcome,
        },
      ).toJson(),
  ]);
  return SceneAsset.fromJson(json);
}
