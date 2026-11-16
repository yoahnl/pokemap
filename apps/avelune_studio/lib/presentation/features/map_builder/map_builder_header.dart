import 'dart:async';

import 'package:flutter/material.dart';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/project_session/application/project_draft.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_ambiance_binding.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:avelune_studio/presentation/shell/studio_top_bar.dart';
import 'package:avelune_studio/features/story_workspace/application/story_history_scope.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

VoidCallback? mapBuilderHistoryStep(
  MapWorkspaceController maps, {
  required bool redo,
  required bool editable,
  MapBuilderAmbianceBinding? ambiance,
  MapBuilderStoryBinding? story,
  StoryHistoryScope? scope,
}) {
  if (!editable) return null;
  if (scope != null) {
    return story != null && story.canStepScope(scope, redo: redo)
        ? (redo ? story.redo : story.undo)
        : null;
  }
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
      maps.canStepHistory(redo: redo)
          ? () => unawaited(maps.stepHistory(redo: redo))
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
    this.history = true,
    this.scope,
    this.pendingInput = false,
    this.onHistoryStep,
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
  final bool history;
  final StoryHistoryScope? scope;
  final bool pendingInput;
  final ValueChanged<bool>? onHistoryStep;

  StudioSaveState get _saveState {
    if (draft.saving) return StudioSaveState.saving;
    if (saveFailed) return StudioSaveState.failed;
    return draft.unsaved ? StudioSaveState.unsaved : StudioSaveState.saved;
  }

  String? _unavailableReason(BuildContext context, {required bool redo}) {
    final story = this.story;
    final scope = this.scope;
    if (story == null ||
        scope == null ||
        !(redo ? story.canRedo : story.canUndo) ||
        story.canStepScope(scope, redo: redo)) {
      return null;
    }
    return context.l10n.storyHistoryOtherContext;
  }

  @override
  Widget build(BuildContext context) {
    final document = maps.active;
    VoidCallback? historyStep(bool redo) {
      final step = mapBuilderHistoryStep(
        maps,
        redo: redo,
        editable: editable && history,
        ambiance: ambiance,
        story: story,
        scope: scope,
      );
      return step == null || onHistoryStep == null
          ? step
          : () => onHistoryStep!(redo);
    }

    return StudioTopBar(
      projectName: projectName,
      maps: maps.project?.maps ?? const [],
      activeMapId: document?.base.mapId,
      onSelectMap: editable ? (entry) => unawaited(maps.activate(entry)) : null,
      onUndo: historyStep(false),
      onRedo: historyStep(true),
      saveState: _saveState,
      undoUnavailableReason: _unavailableReason(context, redo: false),
      redoUnavailableReason: _unavailableReason(context, redo: true),
      onSave: editable && (draft.unsaved || pendingInput) ? onSave : null,
      onTestMap: editable && document != null && !testing ? onTestMap : null,
      testing: testing,
    );
  }
}
