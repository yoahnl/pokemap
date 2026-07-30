import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/world_map_tool_family.dart';
import '../../state/editor_notifier.dart';

@immutable
final class WorldMapPaintInspectionIntent {
  const WorldMapPaintInspectionIntent({
    required this.mapId,
    required this.layerId,
    required this.subtool,
  });

  final String mapId;
  final String layerId;
  final WorldMapPaintSubtool subtool;

  bool matches({
    required String? mapId,
    required String? layerId,
  }) {
    return this.mapId == mapId && this.layerId == layerId;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is WorldMapPaintInspectionIntent &&
            other.mapId == mapId &&
            other.layerId == layerId &&
            other.subtool == subtool;
  }

  @override
  int get hashCode => Object.hash(mapId, layerId, subtool);
}

final worldMapPaintInspectionIntentProvider = NotifierProvider<
    WorldMapPaintInspectionIntentController, WorldMapPaintInspectionIntent?>(
  WorldMapPaintInspectionIntentController.new,
);

final effectiveWorldMapPaintInspectionIntentProvider =
    Provider<WorldMapPaintInspectionIntent?>((ref) {
  final intent = ref.watch(worldMapPaintInspectionIntentProvider);
  if (intent == null) {
    return null;
  }
  final ownership = ref.watch(
    editorNotifierProvider.select(
      (editor) => (
        mapId: editor.activeMap?.id,
        layerId: editor.activeLayerId,
      ),
    ),
  );
  return intent.matches(
    mapId: ownership.mapId,
    layerId: ownership.layerId,
  )
      ? intent
      : null;
});

final class WorldMapPaintInspectionIntentController
    extends Notifier<WorldMapPaintInspectionIntent?> {
  @override
  WorldMapPaintInspectionIntent? build() {
    ref.watch(
      editorNotifierProvider.select(
        (editor) => (
          mapId: editor.activeMap?.id,
          layerId: editor.activeLayerId,
        ),
      ),
    );
    return null;
  }

  void showSetup({
    required String mapId,
    required String layerId,
    required WorldMapPaintSubtool subtool,
  }) {
    final normalizedMapId = mapId.trim();
    final normalizedLayerId = layerId.trim();
    if (normalizedMapId.isEmpty || normalizedLayerId.isEmpty) {
      throw ArgumentError(
        'Paint inspection setup requires a map and layer identity.',
      );
    }
    final next = WorldMapPaintInspectionIntent(
      mapId: normalizedMapId,
      layerId: normalizedLayerId,
      subtool: subtool,
    );
    if (state == next) {
      return;
    }
    state = next;
  }

  void clear() {
    if (state == null) {
      return;
    }
    state = null;
  }
}
