import 'package:flutter/material.dart';
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
}

Widget? workspaceSecondaryContent({
  required WorkspaceSpace space,
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
  required WorkspaceSpace sceneOrigin,
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
      controller: scenes,
      views: sceneViews,
      narrative: narrative,
      onBack: sceneOrigin == WorkspaceSpace.events
          ? onReturnEvents
          : sceneOrigin == WorkspaceSpace.progression
          ? onReturnProgression
          : onStory,
      onBackLabel: sceneOrigin == WorkspaceSpace.events
          ? 'Événements'
          : sceneOrigin == WorkspaceSpace.progression
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
