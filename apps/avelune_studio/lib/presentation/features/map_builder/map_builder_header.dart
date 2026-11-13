import 'dart:async';

import 'package:flutter/material.dart';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/project_session/application/project_draft.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_ambiance_binding.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:avelune_studio/presentation/shell/studio_top_bar.dart';

VoidCallback? mapBuilderHistoryStep(
  MapWorkspaceController maps, {
  required bool redo,
  required bool editable,
  MapBuilderAmbianceBinding? ambiance,
  MapBuilderStoryBinding? story,
}) {
  if (!editable) return null;
  return switch ((ambiance, story)) {
    (final ambiance?, _) =>
      (redo ? ambiance.canRedo : ambiance.canUndo)
          ? (redo ? ambiance.redo : ambiance.undo)
          : null,
    (_, final story?) =>
      (redo ? story.canRedo : story.canUndo)
          ? (redo ? story.redo : story.undo)
          : null,
    (null, null) =>
      (redo ? maps.active?.canRedo : maps.active?.canUndo) == true
          ? () => maps.restore(redo: redo)
          : null,
  };
}

class MapBuilderHeader extends StatelessWidget {
  const MapBuilderHeader({
    super.key,
    required this.maps,
    required this.draft,
    required this.projectName,
    required this.editable,
    required this.saveFailed,
    required this.onSave,
    required this.onTestMap,
    required this.testing,
    this.ambiance,
    this.story,
  });

  final MapWorkspaceController maps;
  final ProjectDraftPart draft;
  final String projectName;
  final bool editable;
  final bool saveFailed;
  final VoidCallback onSave;
  final VoidCallback onTestMap;
  final bool testing;
  final MapBuilderAmbianceBinding? ambiance;
  final MapBuilderStoryBinding? story;

  StudioSaveState get _saveState {
    if (draft.saving) return StudioSaveState.saving;
    if (saveFailed) return StudioSaveState.failed;
    return draft.unsaved ? StudioSaveState.unsaved : StudioSaveState.saved;
  }

  @override
  Widget build(BuildContext context) {
    final document = maps.active;
    return StudioTopBar(
      projectName: projectName,
      maps: maps.project?.maps ?? const [],
      activeMapId: document?.base.mapId,
      onSelectMap: editable ? (entry) => unawaited(maps.activate(entry)) : null,
      onUndo: mapBuilderHistoryStep(
        maps,
        redo: false,
        editable: editable,
        ambiance: ambiance,
        story: story,
      ),
      onRedo: mapBuilderHistoryStep(
        maps,
        redo: true,
        editable: editable,
        ambiance: ambiance,
        story: story,
      ),
      saveState: _saveState,
      onSave: editable && draft.unsaved ? onSave : null,
      onTestMap: editable && document != null && !testing ? onTestMap : null,
      testing: testing,
    );
  }
}
