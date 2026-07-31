import 'package:flutter/foundation.dart';

import 'world_map_target_editor_intent.dart';

enum MapContextCommand {
  move,
  rotateClockwise,
  rotateCounterClockwise,
  rotateHalfTurn,
  resetRotation,
  openTargetEditor,
  delete,
  eraseCell,
  activateLayer,
  copyCoordinates,
  renameLayer,
  moveLayerUp,
  moveLayerDown,
  deleteLayer,
}

@immutable
final class MapContextCommandEntry {
  const MapContextCommandEntry({
    required this.command,
    required this.label,
    required this.enabled,
    this.shortcutLabel,
    this.disabledReason,
    this.destructive = false,
    this.startsSection = false,
  });

  final MapContextCommand command;
  final String label;
  final bool enabled;
  final String? shortcutLabel;
  final String? disabledReason;
  final bool destructive;
  final bool startsSection;
}

@immutable
final class MapContextCommandProjection {
  const MapContextCommandProjection({
    required this.entries,
    this.targetEditorResolution,
  });

  final List<MapContextCommandEntry> entries;
  final WorldMapTargetEditorResolution? targetEditorResolution;
}
