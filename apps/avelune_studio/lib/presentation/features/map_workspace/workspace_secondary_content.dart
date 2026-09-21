import '../../../features/presentations/application/presentation_workspace_controller.dart';
import '../../../features/scenes/domain/scene_presentation_creation_request.dart';
import '../../../features/cinematics/application/cinematic_workspace_controller.dart';
import '../cinematics/cinematic_workspace_page.dart';
import '../cinematics/cinematic_view_state.dart';
import 'package:flutter/material.dart';
import '../../../features/dialogues/application/dialogue_workspace_controller.dart';
import '../dialogues/dialogue_workspace_page.dart';
import '../dialogues/dialogue_view_state.dart';
import '../../../features/events/application/event_workspace_controller.dart';
import 'package:map_core/map_core_domain.dart';
import '../events/event_workspace_page.dart';
import '../events/event_view_state.dart';
import '../events/event_map_loader.dart';
import '../../../features/stories/application/story_workspace_controller.dart';
import '../stories/story_progression_page.dart';
import '../stories/story_progression_view_store.dart';
import '../../../features/scenes/application/scene_workspace_controller.dart';
import '../../../presentation/features/scenes/scene_builder_page.dart';
import '../../../features/narrative/application/narrative_workspace_controller.dart';
import '../narrative/narrative_interaction_pane.dart';
import '../narrative/narrative_story_pane.dart';
import '../narrative/narrative_overview_view_state.dart';
import '../resources/resource_navigation.dart';
import '../resources/resource_image_import.dart';
import '../resources/resource_workspace_pane.dart';
import 'map_workspace_visuals.dart';

enum WorkspaceSpace {
  map,
  resources,
  story,
  interaction,
  scene,
  progression,
  events,
  dialogue,
  cinematic,
  presentation,
}

class WorkspaceReturn {
  const WorkspaceReturn(this.space, {this.documentId});
  static const story = WorkspaceReturn(WorkspaceSpace.story);
  final WorkspaceSpace space;
  final String? documentId;
}

Widget? workspaceSecondaryContent({
  required WorkspaceSpace space,
  PresentationWorkspaceController? presentations,
  VoidCallback? onPresentations,
  Future<void> Function(ScenePresentationCinematicPayload)? onScenePresentation,
  Future<void> Function(ScenePresentationCreationRequest)? onCreatePresentation,
  required CinematicWorkspaceController? cinematics,
  required CinematicViewStore cinematicViews,
  required WorkspaceSpace cinematicOrigin,
  required VoidCallback onCinematics,
  required VoidCallback onCinematicBack,
  required Future<void> Function(SceneCinematicPayload) onSceneCinematic,
  required Future<void> Function(String) onCinematicDialogue,
  required Future<String?> Function(String) onCinematicLocate,
  required DialogueWorkspaceController? dialogues,
  required DialogueViewStore dialogueViews,
  required WorkspaceSpace dialogueOrigin,
  required VoidCallback onDialogues,
  required VoidCallback onDialogueBack,
  required Future<void> Function(SceneYarnDialoguePayload) onSceneDialogue,
  required EventWorkspaceController? events,
  required EventViewState eventView,
  required EventMapLoader eventMaps,
  required VoidCallback onEvents,
  required VoidCallback onReturnEvents,
  required VoidCallback onEventBack,
  required Future<String?> Function(NarrativeEventSourceRef) onEventLocate,
  required Future<void> Function() onEventTest,
  required NarrativeWorkspaceController? narrative,
  required SceneWorkspaceController? scenes,
  required SceneBuilderViewStore sceneViews,
  required StoryWorkspaceController? stories,
  required StoryProgressionViewStore progressionViews,
  required WorkspaceReturn sceneOrigin,
  Future<void> Function(String?)? onReturnPresentation,
  required VoidCallback onProgression,
  required VoidCallback onReturnProgression,
  required VoidCallback onScenes,
  required Future<String?> Function(String) onOpenScene,
  required ResourceNavigation? resources,
  required MapWorkspaceVisuals? visuals,
  required VoidCallback onMap,
  required NarrativeOverviewViewState storyViewState,
  required WorkspaceSpace interactionOrigin,
  required VoidCallback onStory,
  required Future<String?> Function(String) onOpenInteraction,
  required Future<String?> Function(String) onLocateInteraction,
  required VoidCallback onCreateInteraction,
  required VoidCallback onTest,
  required PickResourceImage? imagePicker,
}) {
  if (space == WorkspaceSpace.cinematic &&
      cinematics != null &&
      visuals != null) {
    return CinematicWorkspacePage(
      controller: cinematics,
      onPresentations: onPresentations,
      dialogues: dialogues,
      views: cinematicViews,
      loader: eventMaps,
      visuals: visuals,
      onBack: onCinematicBack,
      backLabel: cinematicOrigin == WorkspaceSpace.scene
          ? 'la scène'
          : 'Histoire',
      onDialogue: onCinematicDialogue,
      onLocate: onCinematicLocate,
    );
  }
  if (space == WorkspaceSpace.dialogue && dialogues != null) {
    return DialogueWorkspacePage(
      controller: dialogues,
      views: dialogueViews,
      onBack: onDialogueBack,
      backLabel: dialogueOrigin == WorkspaceSpace.scene
          ? 'la scène'
          : dialogueOrigin == WorkspaceSpace.cinematic
          ? 'la cinématique'
          : 'Histoire',
    );
  }
  if (space == WorkspaceSpace.events && events != null && visuals != null) {
    return EventWorkspacePage(
      controller: events,
      view: eventView,
      loader: eventMaps,
      visuals: visuals,
      scenes: scenes,
      onBack: onEventBack,
      onScene: onOpenScene,
      onLocate: onEventLocate,
      onTest: onEventTest,
    );
  }
  if (space == WorkspaceSpace.progression && stories != null) {
    return StoryProgressionPage(
      controller: stories,
      views: progressionViews,
      onBack: onStory,
      onOpenScene: onOpenScene,
    );
  }
  if (space == WorkspaceSpace.scene && scenes != null) {
    return SceneBuilderPage(
      onPresentation: onScenePresentation,
      onCreatePresentation: onCreatePresentation,
      presentationFor: presentations?.assetFor,
      presentationEntries: presentations == null
          ? null
          : () => presentations.entries,
      dialogues: dialogues,
      onCinematic: cinematics == null ? null : onSceneCinematic,
      onDialogue: dialogues == null ? null : onSceneDialogue,
      controller: scenes,
      views: sceneViews,
      narrative: narrative,
      onBack:
          sceneOrigin.space == WorkspaceSpace.presentation &&
              onReturnPresentation != null
          ? () => onReturnPresentation(sceneOrigin.documentId)
          : sceneOrigin.space == WorkspaceSpace.events
          ? onReturnEvents
          : sceneOrigin.space == WorkspaceSpace.progression
          ? onReturnProgression
          : onStory,
      onBackLabel: sceneOrigin.space == WorkspaceSpace.presentation
          ? 'la présentation'
          : sceneOrigin.space == WorkspaceSpace.events
          ? 'Événements'
          : sceneOrigin.space == WorkspaceSpace.progression
          ? 'Histoires et progression'
          : 'Histoire',
      onTest: onTest,
    );
  }
  if (space == WorkspaceSpace.interaction && narrative?.active != null) {
    return NarrativeInteractionPane(
      controller: narrative!,
      visuals: visuals!,
      onBack: interactionOrigin == WorkspaceSpace.story ? onStory : onMap,
      onBackLabel: interactionOrigin == WorkspaceSpace.story
          ? 'Retour à Histoire'
          : 'Retour à la carte',
      onTest: onTest,
    );
  }
  if (space == WorkspaceSpace.story && narrative != null) {
    return NarrativeStoryPane(
      onDialogues: dialogues == null ? null : onDialogues,
      onCinematics: cinematics == null ? null : onCinematics,
      controller: narrative,
      viewState: storyViewState,
      onOpen: onOpenInteraction,
      onLocate: onLocateInteraction,
      onCreateInteraction: onCreateInteraction,
      onScenes: scenes == null ? null : onScenes,
      onEvents: events == null ? null : onEvents,
      onProgression: stories == null ? null : onProgression,
      onOpenScene: scenes == null ? null : onOpenScene,
    );
  }
  if (space == WorkspaceSpace.resources && resources != null) {
    return ResourceWorkspacePane(
      navigation: resources,
      picker: imagePicker ?? () async => null,
      onBack: onMap,
    );
  }
  return null;
}
