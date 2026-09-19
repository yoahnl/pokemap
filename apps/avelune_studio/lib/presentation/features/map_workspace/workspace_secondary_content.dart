import 'package:flutter/material.dart';
import '../../../features/narrative/application/narrative_workspace_controller.dart';
import '../narrative/narrative_interaction_pane.dart';
import '../narrative/narrative_story_pane.dart';
import '../resources/resource_navigation.dart';
import '../resources/resource_image_import.dart';
import '../resources/resource_workspace_pane.dart';
import 'map_workspace_visuals.dart';

enum WorkspaceSpace { map, resources, story, interaction }

Widget? workspaceSecondaryContent({
  required WorkspaceSpace space,
  required NarrativeWorkspaceController? narrative,
  required ResourceNavigation? resources,
  required MapWorkspaceVisuals? visuals,
  required VoidCallback onMap,
  required VoidCallback onInteraction,
  required VoidCallback onTest,
  required PickResourceImage? imagePicker,
}) {
  if (space == WorkspaceSpace.interaction && narrative?.active != null) {
    return NarrativeInteractionPane(
      controller: narrative!,
      visuals: visuals!,
      onBack: onMap,
      onTest: onTest,
    );
  }
  if (space == WorkspaceSpace.story && narrative != null) {
    return NarrativeStoryPane(controller: narrative, onOpen: onInteraction);
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
