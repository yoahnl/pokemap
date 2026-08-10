import 'package:flutter/foundation.dart' show immutable, listEquals;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/world_map_tool_activation.dart';
import '../../application/world_map_tool_family.dart';
import '../../state/editor_notifier.dart';

enum WorldMapPaintInspectionIntentKind {
  setup,
  layerChoice,
  missingLayer,
}

@immutable
final class WorldMapPaintInspectionIntent {
  const WorldMapPaintInspectionIntent({
    required this.scope,
    required this.layerId,
    required this.subtool,
    this.kind = WorldMapPaintInspectionIntentKind.setup,
    this.compatibleLayerIds = const <String>[],
  });

  final WorldMapDocumentScope scope;
  final String? layerId;
  final WorldMapPaintSubtool subtool;
  final WorldMapPaintInspectionIntentKind kind;
  final List<String> compatibleLayerIds;

  String get mapId => scope.activeMapId!;

  bool matches({
    required WorldMapDocumentScope scope,
    required String? layerId,
  }) {
    if (this.scope != scope) {
      return false;
    }
    return kind != WorldMapPaintInspectionIntentKind.setup ||
        this.layerId == layerId;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is WorldMapPaintInspectionIntent &&
            other.scope == scope &&
            other.layerId == layerId &&
            other.subtool == subtool &&
            other.kind == kind &&
            listEquals(other.compatibleLayerIds, compatibleLayerIds);
  }

  @override
  int get hashCode => Object.hash(
        scope,
        layerId,
        subtool,
        kind,
        Object.hashAll(compatibleLayerIds),
      );
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
        scope: worldMapDocumentScopeFromState(editor),
        layerId: editor.activeLayerId,
      ),
    ),
  );
  return intent.matches(
    scope: ownership.scope,
    layerId: ownership.layerId,
  )
      ? intent
      : null;
});

final class WorldMapPaintInspectionIntentController
    extends Notifier<WorldMapPaintInspectionIntent?> {
  @override
  WorldMapPaintInspectionIntent? build() {
    ref.listen(
      editorNotifierProvider.select(
        (editor) => (
          scope: worldMapDocumentScopeFromState(editor),
          layerId: editor.activeLayerId,
        ),
      ),
      (_, _) => clear(),
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
    final scope = _scopeForMapId(normalizedMapId);
    final next = WorldMapPaintInspectionIntent(
      scope: scope,
      layerId: normalizedLayerId,
      subtool: subtool,
    );
    _set(next);
  }

  void showLayerChoice({
    required String mapId,
    required WorldMapPaintSubtool subtool,
    required List<String> compatibleLayerIds,
  }) {
    final normalizedMapId = mapId.trim();
    final normalizedLayerIds = compatibleLayerIds
        .map((layerId) => layerId.trim())
        .where((layerId) => layerId.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (normalizedMapId.isEmpty || normalizedLayerIds.length < 2) {
      throw ArgumentError(
        'Paint layer choice requires a map and at least two layers.',
      );
    }
    final scope = _scopeForMapId(normalizedMapId);
    _set(
      WorldMapPaintInspectionIntent(
        scope: scope,
        layerId: null,
        subtool: subtool,
        kind: WorldMapPaintInspectionIntentKind.layerChoice,
        compatibleLayerIds: normalizedLayerIds,
      ),
    );
  }

  void showMissingLayer({
    required String mapId,
    required WorldMapPaintSubtool subtool,
  }) {
    final normalizedMapId = mapId.trim();
    if (normalizedMapId.isEmpty) {
      throw ArgumentError('Missing paint layer guidance requires a map.');
    }
    final scope = _scopeForMapId(normalizedMapId);
    _set(
      WorldMapPaintInspectionIntent(
        scope: scope,
        layerId: null,
        subtool: subtool,
        kind: WorldMapPaintInspectionIntentKind.missingLayer,
      ),
    );
  }

  WorldMapDocumentScope _scopeForMapId(String mapId) {
    final scope = worldMapDocumentScopeFromState(
      ref.read(editorNotifierProvider),
    );
    if (scope.activeMapId?.trim() != mapId) {
      throw ArgumentError(
        'Paint inspection scope must own the requested map.',
      );
    }
    return scope;
  }

  void _set(WorldMapPaintInspectionIntent next) {
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
