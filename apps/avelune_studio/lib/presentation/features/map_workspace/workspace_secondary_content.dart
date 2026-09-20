import 'package:flutter/material.dart';
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

enum WorkspaceSpace { map, resources, story, interaction, scene }

Widget? workspaceSecondaryContent({
  required WorkspaceSpace space,
  required NarrativeWorkspaceController? narrative,
  required SceneWorkspaceController? scenes,
  required SceneBuilderViewStore sceneViews,
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
  if (space == WorkspaceSpace.scene && scenes != null) {
    return SceneBuilderPage(
      controller: scenes,
      views: sceneViews,
      narrative: narrative,
      onBack: onStory,
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
