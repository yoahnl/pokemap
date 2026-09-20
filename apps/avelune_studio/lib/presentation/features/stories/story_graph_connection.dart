import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'story_graph_geometry.dart';

Future<StorylineProgressionConnectRequest?> chooseStoryGraphConnection(
  BuildContext context,
  StoryGraphGeometry graph,
  StorylineProgressionNode source,
  StorylineProgressionNode target,
  Offset global,
) async {
  final choices = switch (source.kind) {
    StorylineProgressionNodeKind.sceneOutcome => [
      'Activer cette étape',
      'Terminer cette étape',
    ],
    StorylineProgressionNodeKind.fact => [
      'Entrée · vrai',
      'Entrée · faux',
      'Achèvement · vrai',
      'Achèvement · faux',
    ],
    StorylineProgressionNodeKind.storyline => [
      'Nécessite cette histoire',
      'Bloque cette histoire',
      'Converge vers cette histoire',
    ],
    _ => <String>[],
  };
  if (choices.isEmpty) return null;
  final choice = await showMenu<int>(
    context: context,
    position: RelativeRect.fromLTRB(global.dx, global.dy, global.dx, global.dy),
    items: [
      for (var i = 0; i < choices.length; i++)
        PopupMenuItem(value: i, child: Text(choices[i])),
    ],
  );
  if (choice == null) return null;
  if (source.kind == StorylineProgressionNodeKind.sceneOutcome) {
    final outcome = graph.outcomeSources[source.id]!;
    return StorylineProgressionConnectRequest.outcomeEffect(
      storylineId: source.storylineId!,
      sceneLinkId: outcome.link.id,
      outcomeLinkId: outcome.outcomeLinkId,
      outcomeId: outcome.pending ? outcome.outcomeId : null,
      effectType: choice == 0
          ? StorylineEffectType.activateStep
          : StorylineEffectType.completeStep,
      targetStepId: target.stepId!,
    );
  }
  if (source.kind == StorylineProgressionNodeKind.fact) {
    return StorylineProgressionConnectRequest.factCondition(
      storylineId: target.storylineId!,
      chapterId: target.chapterId!,
      stepId: target.stepId!,
      slot: choice < 2
          ? StorylineProgressionConditionSlot.entry
          : StorylineProgressionConditionSlot.completion,
      factId: source.canonicalId,
      expectedValue: choice.isEven,
    );
  }
  return StorylineProgressionConnectRequest.relationship(
    relationshipId: 'relation-${DateTime.now().microsecondsSinceEpoch}',
    kind: [
      StorylineRelationshipKind.requires,
      StorylineRelationshipKind.blocks,
      StorylineRelationshipKind.convergesTo,
    ][choice],
    sourceStorylineId: source.canonicalId,
    targetStorylineId: target.canonicalId,
  );
}

String storyGraphEdgeLabel(StorylineProgressionEdge edge) =>
    switch (edge.kind) {
      StorylineProgressionEdgeKind.contains => 'Contient',
      StorylineProgressionEdgeKind.authorOrder => 'Ordre de présentation',
      StorylineProgressionEdgeKind.outcomeActivatesStep => 'Active l’étape',
      StorylineProgressionEdgeKind.outcomeCompletesStep => 'Termine l’étape',
      StorylineProgressionEdgeKind.requires => 'Nécessite',
      StorylineProgressionEdgeKind.blocks => 'Bloque',
      StorylineProgressionEdgeKind.convergesTo => 'Converge vers',
      StorylineProgressionEdgeKind.sideQuestAvailability =>
        'Disponibilité secondaire',
      StorylineProgressionEdgeKind.entryCondition => 'Condition d’entrée',
      StorylineProgressionEdgeKind.completionCondition =>
        'Condition d’achèvement',
    };
