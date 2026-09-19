import 'package:map_core/map_core_domain.dart';

import 'narrative_interaction.dart';

NarrativeInteractionDraft? readStudioInteraction(
  NarrativeEventRecord record,
  ProjectManifest project,
) {
  final definition = record.definitionOrNull;
  if (definition == null) return null;
  if (definition.conditions.any(
    (condition) => condition.whenTyped(
      fact: (_, operator, value) =>
          operator != NarrativeFactOperator.equals ||
          value.kind != NarrativeValueKind.boolean,
      narrativeEventConsumed: (_, _) => true,
    ),
  )) {
    return null;
  }
  final scene = project.scenes
      .where((item) => item.id == definition.sceneId)
      .firstOrNull;
  if (scene == null || scene.id != 'scene_${definition.id}') return null;
  final mapId = definition.source.when(
    entityInteract: (map, _) => map,
    triggerEnter: (map, _) => map,
    mapEnter: (map) => map,
    outcomeReceived: (_) => '',
  );
  if (mapId.isEmpty) return null;
  final opening = scene.graph.nodes
      .where((node) => node.id == 'dialogue')
      .firstOrNull;
  if (opening?.payload case final SceneYarnDialoguePayload dialogue) {
    try {
      final common = _readSequence(project, scene, 'completed');
      final branches = <String, List<NarrativeSequenceStep>>{};
      for (final outcome in dialogue.expectedOutcomes) {
        final steps = _readSequence(project, scene, outcome);
        if (steps.length < common.length) return null;
        branches[outcome] = steps.take(steps.length - common.length).toList();
      }
      final draft = NarrativeInteractionDraft(
        id: definition.id,
        name: definition.name,
        mapId: mapId,
        source: definition.source,
        dialogueId: dialogue.dialogueId,
        conditions: definition.conditions,
        oneShot: definition.reusePolicy == NarrativeEventReusePolicy.oneShot,
        priority: definition.priority,
        order: definition.order,
        steps: common,
        branches: branches,
      );
      final rebuilt = draft.project();
      if (rebuilt.scene != scene || rebuilt.event != record) return null;
      for (final cinematic in rebuilt.cinematics) {
        if (!project.cinematics.contains(cinematic)) return null;
      }
      return draft;
    } on Object {
      return null;
    }
  }
  return null;
}

List<NarrativeSequenceStep> _readSequence(
  ProjectManifest project,
  SceneAsset scene,
  String outcome,
) {
  final result = <NarrativeSequenceStep>[];
  var current = 'dialogue';
  var port = outcome;
  final visited = <String>{};
  while (visited.add(current)) {
    final edge = scene.graph.edges.singleWhere(
      (edge) => edge.fromNodeId == current && edge.fromPortId == port,
    );
    final node = scene.graph.nodes.singleWhere(
      (node) => node.id == edge.toNodeId,
    );
    if (node.kind == SceneNodeKind.end) return result;
    result.add(_readStep(project, node.payload));
    current = node.id;
    port = 'completed';
  }
  throw StateError('Séquence cyclique');
}

NarrativeSequenceStep _readStep(
  ProjectManifest project,
  SceneNodePayload payload,
) {
  if (payload case SceneYarnDialoguePayload(:final dialogueId)) {
    return NarrativeSequenceStep(
      kind: NarrativeSequenceKind.dialogue,
      targetId: dialogueId,
    );
  }
  if (payload case SceneActionPayload(:final consequence)) {
    if (consequence case SceneSetFactConsequence(:final factId, :final value)) {
      return NarrativeSequenceStep(
        kind: NarrativeSequenceKind.setFact,
        targetId: factId,
        value: value,
      );
    }
    if (consequence case SceneCompleteStoryStepConsequence(:final stepId)) {
      return NarrativeSequenceStep(
        kind: NarrativeSequenceKind.completeStep,
        targetId: stepId,
      );
    }
  }
  if (payload case SceneCinematicPayload(:final cinematicId)) {
    final cinematic = project.cinematics.singleWhere(
      (item) => item.id == cinematicId,
    );
    final step = cinematic.timeline.steps.single;
    if (step.kind == CinematicTimelineStepKind.wait) {
      return NarrativeSequenceStep(
        kind: NarrativeSequenceKind.wait,
        milliseconds: step.durationMs!,
      );
    }
    if (step.kind == CinematicTimelineStepKind.actorFace) {
      return NarrativeSequenceStep(
        kind: NarrativeSequenceKind.facing,
        targetId: cinematic.requiredActors.single.entityId!,
        facing:
            switch (step.metadata[cinematicTimelineActorDirectionMetadataKey]) {
              'up' => EntityFacing.north,
              'down' => EntityFacing.south,
              'left' => EntityFacing.west,
              'right' => EntityFacing.east,
              _ => throw StateError('Orientation inconnue'),
            },
      );
    }
  }
  throw StateError('Action avancée non représentable');
}
