import 'dart:async';

import 'package:flutter/material.dart';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/rendering/contracts/map_workspace_visuals.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_ambiance_binding.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_gameplay_binding.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_gameplay_panel.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_library.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_resource_binding.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_resource_panel.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_space.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_space_outline.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_space_panel.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_panel.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class MapBuilderSidePanel extends StatelessWidget {
  const MapBuilderSidePanel({
    super.key,
    required this.space,
    required this.story,
    required this.gameplay,
    required this.ambiance,
    required this.resources,
    required this.maps,
    required this.visuals,
    required this.enabled,
  });

  final MapBuilderSpace space;
  final MapBuilderStoryBinding story;
  final MapBuilderGameplayBinding gameplay;
  final MapBuilderAmbianceBinding ambiance;
  final MapBuilderResourceBinding resources;
  final MapWorkspaceController maps;
  final MapWorkspaceVisuals? visuals;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final outline = mapBuilderSpaceOutline(space, context.l10n);
    if (outline != null && space == MapBuilderSpace.gameplay) {
      return MapBuilderGameplayPanel(
        outline: outline,
        binding: gameplay,
        enabled: enabled,
      );
    }
    if (outline != null && space == MapBuilderSpace.story) {
      return MapBuilderStoryPanel(outline: outline, binding: story);
    }
    if (outline != null && space == MapBuilderSpace.ambiance) {
      return MapBuilderSpacePanel(
        outline: outline,
        liveRubrics: mapBuilderAmbianceRubrics,
        selectedRubric: ambiance.rubric,
        onRubric: ambiance.openRubric,
      );
    }
    if (outline != null) return MapBuilderSpacePanel(outline: outline);
    final project = maps.project;
    final mapId = maps.active?.base.mapId;
    return MapBuilderLibrary(
      groups: project?.groups ?? const [],
      maps: project?.maps ?? const [],
      activeMapId: mapId,
      onSelectMap: enabled ? (entry) => unawaited(maps.activate(entry)) : null,
      resources: MapBuilderResourcePanel(
        project: resources.catalog,
        mapId: mapId,
        visuals: visuals,
        selection: resources.selection,
        onSelection: (value) => unawaited(resources.select(value)),
        loading: resources.loading,
        armed: resources.armed?.identity,
        onUse: enabled ? (item) => unawaited(resources.use(item)) : null,
      ),
    );
  }
}
