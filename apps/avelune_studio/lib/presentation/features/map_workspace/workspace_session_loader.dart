import 'package:flutter/foundation.dart';
import '../../../features/narrative/application/narrative_workspace_controller.dart';
import '../narrative/narrative_navigation.dart';
import '../resources/resource_catalog.dart';
import '../resources/resource_navigation.dart';
import 'map_workspace_screen.dart';
import 'map_workspace_visuals.dart';
import 'map_workspace_view_state.dart';
import '../characters/character_workspace_visuals.dart';

void retainWorkspaceBrush(
  MapWorkspaceVisuals? visuals,
  MapWorkspaceViewState? view,
) {
  if (visuals case final CharacterWorkspaceVisuals characters
      when view?.character != null) {
    characters.setCharacterBrush(view?.character);
  } else if (visuals case final ResourceWorkspaceVisuals resources
      when view?.terrain != null) {
    resources.setTerrainBrush(view?.terrain);
  } else {
    visuals?.setBrush(view?.brush, view?.tile);
  }
}

Future<
  ({
    MapWorkspaceVisuals visuals,
    ResourceNavigation? resources,
    NarrativeWorkspaceController? narrative,
  })?
>
loadWorkspaceSession(
  MapWorkspaceScreen widget, {
  required bool Function() mounted,
  required VoidCallback changed,
  required Future<void> Function(ResourceItem) onUse,
}) async {
  final workspace = widget.controller;
  await workspace.initialize();
  final project = workspace.project;
  if (!mounted() || project == null) return null;
  final visuals = await widget.loadVisuals(workspace.session, project);
  if (!mounted()) {
    await visuals.dispose();
    return null;
  }
  final narrative = widget.narrativePort == null
      ? null
      : NarrativeWorkspaceController(
          workspace,
          widget.narrativePort!,
          changed,
          (manifest, paths) async {
            if (visuals is ResourceWorkspaceVisuals) {
              await (visuals as ResourceWorkspaceVisuals).updateCatalog(
                manifest,
                changedRelativePaths: paths,
              );
            }
          },
        );
  if (narrative != null) {
    workspace.historyGuard = (before, after) =>
        guardNarrativeHistory(narrative, before, after);
  }
  final resources = widget.resourcePort == null
      ? null
      : ResourceNavigation(
          workspace: workspace,
          port: widget.resourcePort!,
          visuals: visuals,
          onUse: onUse,
        );
  resources?.addListener(changed);
  visuals.addListener(changed);
  return (visuals: visuals, resources: resources, narrative: narrative);
}
