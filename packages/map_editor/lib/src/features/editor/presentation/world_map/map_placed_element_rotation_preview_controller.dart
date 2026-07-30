import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../application/map_placed_element_rotation_planner.dart';
import '../../state/editor_notifier.dart';
import '../../tools/editor_tool.dart';

/// One transient editor-only rotation projection.
///
/// The state owns no mutable map draft: [plan] remains the pure Task 4
/// transaction projection, so previewing cannot write history or persisted data.
@immutable
final class MapPlacedElementRotationPreviewState {
  const MapPlacedElementRotationPreviewState({
    required this.instanceId,
    required this.targetQuarterTurns,
    required this.plan,
  });

  final String instanceId;
  final int targetQuarterTurns;
  final MapPlacedElementRotationPlan plan;
}

final mapPlacedElementRotationPreviewProvider = NotifierProvider<
    MapPlacedElementRotationPreviewController,
    MapPlacedElementRotationPreviewState?>(
  MapPlacedElementRotationPreviewController.new,
);

final class MapPlacedElementRotationPreviewController
    extends Notifier<MapPlacedElementRotationPreviewState?> {
  @override
  MapPlacedElementRotationPreviewState? build() {
    ref.listen<_MapPlacedElementRotationPreviewContext>(
      editorNotifierProvider.select(
        (editor) => _MapPlacedElementRotationPreviewContext(
          map: editor.activeMap,
          selectedInstanceId: editor.selectedPlacedElementInstanceId,
          tool: editor.activeTool,
        ),
      ),
      (previous, next) {
        if (previous != null && previous != next) {
          state = null;
        }
      },
    );
    return null;
  }

  void preview({
    required MapData? map,
    required ProjectManifest? project,
    required String instanceId,
    required int targetQuarterTurns,
  }) {
    final plan = planMapPlacedElementRotation(
      map: map,
      project: project,
      instanceId: instanceId,
      targetQuarterTurns: targetQuarterTurns,
    );
    state = MapPlacedElementRotationPreviewState(
      instanceId: instanceId,
      targetQuarterTurns: targetQuarterTurns,
      plan: plan,
    );
  }

  bool apply() {
    final current = state;
    if (current == null || !current.plan.canCommit) return false;
    final committed = ref
        .read(editorNotifierProvider.notifier)
        .setPlacedElementInstanceQuarterTurns(
          instanceId: current.instanceId,
          quarterTurns: current.targetQuarterTurns,
        );
    if (committed) state = null;
    return committed;
  }

  void cancel() => state = null;
}

@immutable
final class _MapPlacedElementRotationPreviewContext {
  const _MapPlacedElementRotationPreviewContext({
    required this.map,
    required this.selectedInstanceId,
    required this.tool,
  });

  final MapData? map;
  final String? selectedInstanceId;
  final EditorToolType tool;

  @override
  bool operator ==(Object other) {
    return other is _MapPlacedElementRotationPreviewContext &&
        identical(other.map, map) &&
        other.selectedInstanceId == selectedInstanceId &&
        other.tool == tool;
  }

  @override
  int get hashCode => Object.hash(
        identityHashCode(map),
        selectedInstanceId,
        tool,
      );
}
