import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../editor/state/editor_notifier.dart';
import '../application/narrative_workspace_projection.dart';
import 'narrative_workspace_state.dart';

/// Projection narrative "prête UI" basée sur le projet actif.
///
/// Ce provider évite de disperser la logique de dérivation dans plusieurs
/// widgets (gauche, centre, droite). Les trois colonnes lisent donc une même
/// vue cohérente de la donnée narrative.
final narrativeWorkspaceProjectionProvider =
    Provider<NarrativeWorkspaceProjection?>((ref) {
  final project = ref.watch(editorNotifierProvider.select((s) => s.project));
  if (project == null) {
    return null;
  }
  return buildNarrativeWorkspaceProjection(project);
});

/// Sélectionne le scénario "global story" actuellement pointé par l'état
/// narratif, s'il existe encore dans la projection active.
final selectedGlobalStorySummaryProvider =
    Provider<NarrativeScenarioSummary?>((ref) {
  final projection = ref.watch(narrativeWorkspaceProjectionProvider);
  final narrative =
      ref.watch(narrativeWorkspaceControllerProvider.select((s) => s.selectedGlobalStoryId));
  if (projection == null || narrative == null) {
    return null;
  }
  return projection.scenarioById[narrative];
});

/// Sélectionne la cutscene actuellement pointée par l'état narratif.
final selectedCutsceneSummaryProvider =
    Provider<NarrativeScenarioSummary?>((ref) {
  final projection = ref.watch(narrativeWorkspaceProjectionProvider);
  final narrative =
      ref.watch(narrativeWorkspaceControllerProvider.select((s) => s.selectedCutsceneId));
  if (projection == null || narrative == null) {
    return null;
  }
  return projection.scenarioById[narrative];
});

/// Sélectionne l'étape narrative courante à partir de l'id piloté par le
/// contrôleur de workspace narratif.
final selectedNarrativeStepSummaryProvider =
    Provider<NarrativeStepSummary?>((ref) {
  final projection = ref.watch(narrativeWorkspaceProjectionProvider);
  final selectedStepId =
      ref.watch(narrativeWorkspaceControllerProvider.select((s) => s.selectedStepId));
  if (projection == null || selectedStepId == null) {
    return null;
  }
  for (final step in projection.steps) {
    if (step.id == selectedStepId) {
      return step;
    }
  }
  return null;
});

/// Sélectionne l'outcome narratif courant, si l'id référencé existe dans la
/// projection. Cela évite aux widgets d'écrire eux-mêmes la recherche.
final selectedNarrativeOutcomeSummaryProvider =
    Provider<NarrativeOutcomeSummary?>((ref) {
  final projection = ref.watch(narrativeWorkspaceProjectionProvider);
  final selectedOutcomeId =
      ref.watch(narrativeWorkspaceControllerProvider.select((s) => s.selectedOutcomeId));
  if (projection == null || selectedOutcomeId == null) {
    return null;
  }
  for (final outcome in projection.outcomes) {
    if (outcome.id == selectedOutcomeId) {
      return outcome;
    }
  }
  return null;
});
