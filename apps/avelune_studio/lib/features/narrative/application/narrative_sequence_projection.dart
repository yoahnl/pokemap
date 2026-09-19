import 'package:map_core/map_core_domain.dart';

import 'narrative_interaction.dart';

class NarrativeSequenceProjection {
  NarrativeSequenceProjection(this.draft);

  final NarrativeInteractionDraft draft;
  final cinematics = <CinematicAsset>[];
  final _nodes = <SceneNode>[];
  final _edges = <SceneEdge>[];

  SceneAsset build() {
    _nodes.add(SceneNode(id: 'start', kind: SceneNodeKind.start));
    _nodes.add(
      SceneNode(
        id: 'dialogue',
        kind: SceneNodeKind.yarnDialogue,
        payload: SceneYarnDialoguePayload(
          dialogueId: draft.dialogueId,
          yarnNodeName: 'Start',
          expectedOutcomes: draft.branches.keys.toList(),
        ),
      ),
    );
    _connect('start', 'completed', 'dialogue', SceneEdgeKind.defaultFlow);
    _sequence('completed', draft.steps);
    for (final branch in draft.branches.entries) {
      _sequence(branch.key, [...branch.value, ...draft.steps]);
    }
    return SceneAsset(
      id: draft.sceneId,
      name: draft.name,
      graph: SceneGraph(startNodeId: 'start', nodes: _nodes, edges: _edges),
    );
  }

  void _sequence(String outcome, List<NarrativeSequenceStep> steps) {
    var previous = 'dialogue';
    var port = outcome;
    var edgeKind = outcome == 'completed'
        ? SceneEdgeKind.defaultFlow
        : SceneEdgeKind.dialogueOutcome;
    for (final indexed in steps.indexed) {
      final id =
          'branch_${draft.branches.keys.toList().indexOf(outcome) + 1}_${indexed.$1}';
      final step = indexed.$2;
      final payload = _payload(id, step);
      _nodes.add(SceneNode(id: id, kind: payload.kind, payload: payload));
      _connect(previous, port, id, edgeKind);
      previous = id;
      port = 'completed';
      edgeKind = switch (step.kind) {
        NarrativeSequenceKind.dialogue => SceneEdgeKind.defaultFlow,
        NarrativeSequenceKind.facing ||
        NarrativeSequenceKind.wait => SceneEdgeKind.cinematicCompleted,
        _ => SceneEdgeKind.actionCompleted,
      };
    }
    final end = 'end_${draft.branches.keys.toList().indexOf(outcome) + 1}';
    _nodes.add(SceneNode(id: end, kind: SceneNodeKind.end));
    _connect(previous, port, end, edgeKind);
  }

  SceneNodePayload _payload(String id, NarrativeSequenceStep step) {
    switch (step.kind) {
      case NarrativeSequenceKind.dialogue:
        return SceneYarnDialoguePayload(
          dialogueId: step.targetId,
          yarnNodeName: 'Start',
        );
      case NarrativeSequenceKind.setFact:
        return SceneActionPayload.consequence(
          SceneConsequence.setFact(factId: step.targetId, value: step.value),
        );
      case NarrativeSequenceKind.completeStep:
        return SceneActionPayload.consequence(
          SceneConsequence.completeStoryStep(stepId: step.targetId),
        );
      case NarrativeSequenceKind.wait:
      case NarrativeSequenceKind.facing:
        if (step.milliseconds < 0) {
          throw ArgumentError('La durée ne peut pas être négative.');
        }
        final facing = step.kind == NarrativeSequenceKind.facing;
        final cinematic = CinematicAsset(
          id: '${draft.sceneId}_$id',
          title: facing ? 'Orientation' : 'Attente',
          mapId: draft.mapId,
          requiredActors: [
            if (facing)
              CinematicActorRef(actorId: 'actor', entityId: step.targetId),
          ],
          stageContext: CinematicStageContext(
            actorBindings: [
              if (facing)
                CinematicActorBinding(
                  actorId: 'actor',
                  kind: CinematicActorBindingKind.mapEntity,
                  mapEntityId: step.targetId,
                ),
            ],
          ),
          timeline: CinematicTimeline(
            steps: [
              CinematicTimelineStep(
                id: 'step',
                kind: facing
                    ? CinematicTimelineStepKind.actorFace
                    : CinematicTimelineStepKind.wait,
                actorId: facing ? 'actor' : null,
                durationMs: facing ? null : step.milliseconds,
                metadata: {
                  if (facing)
                    cinematicTimelineActorDirectionMetadataKey:
                        switch (step.facing) {
                          EntityFacing.north => 'up',
                          EntityFacing.south => 'down',
                          EntityFacing.east => 'right',
                          EntityFacing.west => 'left',
                        },
                },
              ),
            ],
          ),
        );
        cinematics.add(cinematic);
        return SceneCinematicPayload(cinematicId: cinematic.id);
    }
  }

  void _connect(String from, String port, String to, SceneEdgeKind kind) {
    _edges.add(
      SceneEdge(
        id: 'edge_${_edges.length}',
        fromNodeId: from,
        fromPortId: port,
        toNodeId: to,
        kind: kind,
      ),
    );
  }
}
