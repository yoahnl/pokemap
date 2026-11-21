import 'package:map_core/map_core.dart';

({SceneAsset scene, NarrativeEventRecord event}) certificationTrainerEncounter({
  required ProjectTrainerEntry trainer,
  required String mapId,
  required String entityId,
  required String eventId,
  required int order,
}) {
  final sceneId = 'scene.certification.${trainer.id}';
  final beforeDialogue = trainer.preBattleDialogueId;
  final afterDialogue = trainer.victoryDialogueId;
  final encounterStart = beforeDialogue == null ? 'battle' : 'before';
  final victoryTarget = afterDialogue == null ? 'end' : 'victory';

  final scene = SceneAsset(
    id: sceneId,
    name: trainer.name,
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        if (beforeDialogue != null)
          SceneNode(
            id: 'before',
            kind: SceneNodeKind.yarnDialogue,
            payload: SceneYarnDialoguePayload(dialogueId: beforeDialogue),
          ),
        SceneNode(
          id: 'battle',
          kind: SceneNodeKind.battle,
          payload: SceneBattlePayload(
            battleKind: 'trainer',
            trainerId: trainer.id,
            npcEntityId: entityId,
            defeatRecovery: SceneBattleDefeatRecovery.returnToRecoveryPoint,
            declaredOutcomes: const ['victory', 'defeat'],
          ),
        ),
        if (afterDialogue != null)
          SceneNode(
            id: 'victory',
            kind: SceneNodeKind.yarnDialogue,
            payload: SceneYarnDialoguePayload(dialogueId: afterDialogue),
          ),
        SceneNode(
          id: 'end',
          kind: SceneNodeKind.end,
          payload: SceneEndPayload(outcomePolicy: SceneOutcomePolicy.progression),
        ),
        SceneNode(
          id: 'retry',
          kind: SceneNodeKind.end,
          payload: SceneEndPayload(outcomePolicy: SceneOutcomePolicy.retryable),
        ),
      ],
      edges: [
        _edge('start', 'completed', encounterStart),
        if (beforeDialogue != null) _edge('before', 'completed', 'battle'),
        _edge('battle', 'victory', victoryTarget, SceneEdgeKind.battleVictory),
        _edge('battle', 'defeat', 'retry', SceneEdgeKind.battleDefeat),
        if (afterDialogue != null) _edge('victory', 'completed', 'end'),
      ],
    ),
  );
  final event = NarrativeEventRecord.configuredStructurallyUnchecked(
    NarrativeEventDefinition(
      id: eventId,
      name: trainer.name,
      source: NarrativeEventSourceRef.entityInteract(mapId, entityId),
      conditions: const [],
      sceneId: sceneId,
      reusePolicy: NarrativeEventReusePolicy.reusable,
      priority: 0,
      order: order,
    ),
    enabled: true,
  );
  return (scene: scene, event: event);
}

SceneEdge _edge(
  String from,
  String port,
  String to, [
  SceneEdgeKind kind = SceneEdgeKind.defaultFlow,
]) => SceneEdge(
  id: '$from-$port-$to',
  fromNodeId: from,
  fromPortId: port,
  toNodeId: to,
  kind: kind,
);
