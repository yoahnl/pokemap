import 'dart:async';

import 'package:flutter/material.dart';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_ambiance_binding.dart';
import 'package:avelune_studio/presentation/shell/studio_top_bar.dart';

class MapBuilderHeader extends StatelessWidget {
  const MapBuilderHeader({
    super.key,
    required this.maps,
    required this.projectName,
    required this.editable,
    required this.saveFailed,
    required this.onSave,
    required this.onTestMap,
    required this.testing,
    this.ambiance,
  });

  final MapWorkspaceController maps;
  final String projectName;
  final bool editable;
  final bool saveFailed;
  final VoidCallback onSave;
  final VoidCallback onTestMap;
  final bool testing;
  final MapBuilderAmbianceBinding? ambiance;

  StudioSaveState get _saveState {
    if (maps.saving) return StudioSaveState.saving;
    if (saveFailed) return StudioSaveState.failed;
    return maps.dirty ? StudioSaveState.unsaved : StudioSaveState.saved;
  }

  @override
  Widget build(BuildContext context) {
    final document = maps.active;
    return StudioTopBar(
      projectName: projectName,
      maps: maps.project?.maps ?? const [],
      activeMapId: document?.base.mapId,
      onSelectMap: editable ? (entry) => unawaited(maps.activate(entry)) : null,
      onUndo: switch (ambiance) {
        final ambiance? => editable && ambiance.canUndo ? ambiance.undo : null,
        null =>
          editable && document?.canUndo == true
              ? () => maps.restore(redo: false)
              : null,
      },
      onRedo: switch (ambiance) {
        final ambiance? => editable && ambiance.canRedo ? ambiance.redo : null,
        null =>
          editable && document?.canRedo == true
              ? () => maps.restore(redo: true)
              : null,
      },
      saveState: _saveState,
      onSave: editable && maps.dirty ? onSave : null,
      onTestMap: editable && document != null && !testing ? onTestMap : null,
      testing: testing,
    );
  }
}
