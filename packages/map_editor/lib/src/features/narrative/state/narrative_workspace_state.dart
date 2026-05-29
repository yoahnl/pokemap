import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Vue active du studio narratif dans l'îlot central.
enum NarrativeWorkspaceView {
  globalStory,
  scenes,
  step,
  cutscene,
}

/// Etat de sélection du studio narratif.
///
/// Cet état est volontairement séparé de `EditorState`:
/// - `EditorState` conserve les états cœur map/tileset.
/// - le studio narratif a sa propre navigation et ses propres sélections.
///
/// Cela évite de gonfler l'état historique de l'éditeur avec des champs
/// narratifs expérimentaux non liés au workflow de peinture de map.
@immutable
class NarrativeWorkspaceState {
  const NarrativeWorkspaceState({
    this.view = NarrativeWorkspaceView.globalStory,
    this.selectedGlobalStoryId,
    this.selectedStepId,
    this.selectedCutsceneId,
    this.selectedOutcomeId,
  });

  final NarrativeWorkspaceView view;
  final String? selectedGlobalStoryId;
  final String? selectedStepId;
  final String? selectedCutsceneId;
  final String? selectedOutcomeId;

  NarrativeWorkspaceState copyWith({
    NarrativeWorkspaceView? view,
    Object? selectedGlobalStoryId = _unset,
    Object? selectedStepId = _unset,
    Object? selectedCutsceneId = _unset,
    Object? selectedOutcomeId = _unset,
  }) {
    return NarrativeWorkspaceState(
      view: view ?? this.view,
      selectedGlobalStoryId: identical(selectedGlobalStoryId, _unset)
          ? this.selectedGlobalStoryId
          : selectedGlobalStoryId as String?,
      selectedStepId: identical(selectedStepId, _unset)
          ? this.selectedStepId
          : selectedStepId as String?,
      selectedCutsceneId: identical(selectedCutsceneId, _unset)
          ? this.selectedCutsceneId
          : selectedCutsceneId as String?,
      selectedOutcomeId: identical(selectedOutcomeId, _unset)
          ? this.selectedOutcomeId
          : selectedOutcomeId as String?,
    );
  }
}

const Object _unset = Object();

/// Contrôleur explicite de navigation/sélection narrative.
///
/// Objectif produit:
/// - navigation fluide gauche <-> centre <-> droite
/// - état déterministe et facile à déboguer
/// - API lisible pour les widgets (pas de logique cachée dans les vues)
class NarrativeWorkspaceController
    extends StateNotifier<NarrativeWorkspaceState> {
  NarrativeWorkspaceController() : super(const NarrativeWorkspaceState());

  void openGlobalStory({String? scenarioId}) {
    state = state.copyWith(
      view: NarrativeWorkspaceView.globalStory,
      selectedGlobalStoryId: scenarioId ?? state.selectedGlobalStoryId,
    );
  }

  void openStep({String? stepId, String? globalScenarioId}) {
    state = state.copyWith(
      view: NarrativeWorkspaceView.step,
      selectedStepId: stepId ?? state.selectedStepId,
      selectedGlobalStoryId: globalScenarioId ?? state.selectedGlobalStoryId,
    );
  }

  void openScenes() {
    state = state.copyWith(view: NarrativeWorkspaceView.scenes);
  }

  void openCutscene({String? cutsceneScenarioId}) {
    state = state.copyWith(
      view: NarrativeWorkspaceView.cutscene,
      selectedCutsceneId: cutsceneScenarioId ?? state.selectedCutsceneId,
    );
  }

  void selectGlobalStory(String scenarioId) {
    state = state.copyWith(
      selectedGlobalStoryId: scenarioId,
    );
  }

  void selectStep(String stepId) {
    state = state.copyWith(
      selectedStepId: stepId,
    );
  }

  void selectCutscene(String scenarioId) {
    state = state.copyWith(
      selectedCutsceneId: scenarioId,
    );
  }

  void selectOutcome(String? outcomeId) {
    state = state.copyWith(selectedOutcomeId: outcomeId);
  }
}

final narrativeWorkspaceControllerProvider = StateNotifierProvider<
    NarrativeWorkspaceController, NarrativeWorkspaceState>(
  (ref) => NarrativeWorkspaceController(),
);
