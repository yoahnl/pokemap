import 'package:map_core/map_core_domain.dart';
import '../../../features/narrative/application/narrative_overview.dart';
import '../../../features/narrative/application/narrative_overview_context.dart';
import 'event_condition_labels.dart';

List<String> eventSceneEffects(SceneAsset scene, ProjectManifest project) {
  final names = NarrativeOverviewContext(
    project,
    project.storylines,
    project.facts,
    const [],
  );
  String label(NarrativeOverviewReferenceKind kind, String id) =>
      names.reference(kind, id).label;
  return {
    for (final node in scene.graph.nodes)
      switch (node.payload) {
        SceneYarnDialoguePayload(:final dialogueId) =>
          'Dialogue · ${label(NarrativeOverviewReferenceKind.dialogue, dialogueId)}',
        SceneActionPayload(
          consequence: SceneSetFactConsequence(
            :final factId,
            :final narrativeValue,
          ),
        ) =>
          '${label(NarrativeOverviewReferenceKind.fact, factId)} devient ${eventValueLabel(narrativeValue)}',
        SceneActionPayload(
          consequence: SceneCompleteStoryStepConsequence(:final stepId),
        ) =>
          'Terminer · ${label(NarrativeOverviewReferenceKind.step, stepId)}',
        SceneActionPayload(
          consequence: SceneMarkEventConsumedConsequence(:final eventId),
        ) =>
          'Consommer · ${label(NarrativeOverviewReferenceKind.event, eventId)}',
        SceneActionPayload() => 'Action de scène · ${node.title}',
        SceneCinematicPayload(:final cinematicId) =>
          'Cinématique · ${label(NarrativeOverviewReferenceKind.cinematic, cinematicId)}',
        SceneEndPayload(:final sceneOutcomeId) when sceneOutcomeId != null =>
          'Résultat · ${scene.declaredOutcomes.where((o) => o.id == sceneOutcomeId).firstOrNull?.label ?? sceneOutcomeId}',
        _ => '',
      },
  }.where((text) => text.isNotEmpty).toList();
}
