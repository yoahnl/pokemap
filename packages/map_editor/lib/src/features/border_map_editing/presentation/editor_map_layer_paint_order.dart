import 'package:flutter/foundation.dart' show immutable;
import 'package:map_core/map_core.dart';

enum EditorMapAuthoredLayerPaintKind {
  smartTile,
  tileBackground,
  border,
  objectLayer,
  environmentNoop,
}

@immutable
final class EditorMapAuthoredLayerPaintEntry {
  const EditorMapAuthoredLayerPaintEntry({
    required this.kind,
    required this.layer,
  });

  final EditorMapAuthoredLayerPaintKind kind;
  final MapLayer layer;
}

@immutable
final class EditorMapLayerPaintOrder {
  EditorMapLayerPaintOrder({
    required this.compositionPlan,
    required List<EditorMapAuthoredLayerPaintEntry> authoredLayers,
    required List<CollisionLayer> collisionOverlayLayers,
  })  : authoredLayers = List.unmodifiable(authoredLayers),
        collisionOverlayLayers = List.unmodifiable(collisionOverlayLayers);

  final MapVisualCompositionPlan compositionPlan;
  final List<EditorMapAuthoredLayerPaintEntry> authoredLayers;
  final List<CollisionLayer> collisionOverlayLayers;
}

@immutable
final class EditorMapLayerPaintOrderBuildResult {
  EditorMapLayerPaintOrderBuildResult({
    required this.order,
    required List<MapVisualCompositionDiagnostic> diagnostics,
  }) : diagnostics = List.unmodifiable(diagnostics);

  final EditorMapLayerPaintOrder? order;
  final List<MapVisualCompositionDiagnostic> diagnostics;

  bool get requiresReadOnly => order == null;
  bool get canCompose => order != null;
}

/// Projects the shared pure composition plan into editor-facing entry types.
///
/// This adapter contains no ordering rule of its own. Consequently a future
/// semantics version cannot accidentally fall back to the historical editor
/// renderer.
EditorMapLayerPaintOrderBuildResult buildEditorMapLayerPaintOrderResult(
  MapData map,
) {
  final coreResult = buildMapVisualCompositionPlan(
    map,
    includeDataLayers: true,
  );
  final plan = coreResult.plan;
  if (plan == null) {
    return EditorMapLayerPaintOrderBuildResult(
      order: null,
      diagnostics: coreResult.diagnostics,
    );
  }
  return EditorMapLayerPaintOrderBuildResult(
    order: EditorMapLayerPaintOrder(
      compositionPlan: plan,
      authoredLayers: <EditorMapAuthoredLayerPaintEntry>[
        for (final step in plan.authoredLayerSteps)
          EditorMapAuthoredLayerPaintEntry(
            kind: switch (step.kind) {
              MapVisualCompositionStepKind.smartTileLayer =>
                EditorMapAuthoredLayerPaintKind.smartTile,
              MapVisualCompositionStepKind.tileBackgroundLayer =>
                EditorMapAuthoredLayerPaintKind.tileBackground,
              MapVisualCompositionStepKind.borderLayer =>
                EditorMapAuthoredLayerPaintKind.border,
              MapVisualCompositionStepKind.objectLayer =>
                EditorMapAuthoredLayerPaintKind.objectLayer,
              MapVisualCompositionStepKind.environmentNoop =>
                EditorMapAuthoredLayerPaintKind.environmentNoop,
              _ => throw StateError(
                  'Non-authored step exposed as an authored layer: '
                  '${step.kind.name}',
                ),
            },
            layer: step.layer!,
          ),
      ],
      collisionOverlayLayers: plan.visibleCollisionLayersInPaintOrder,
    ),
    diagnostics: coreResult.diagnostics,
  );
}

EditorMapLayerPaintOrder buildEditorMapLayerPaintOrder(MapData map) {
  final result = buildEditorMapLayerPaintOrderResult(map);
  final order = result.order;
  if (order != null) return order;
  throw UnsupportedError(
    result.diagnostics.map((diagnostic) => diagnostic.message).join(' '),
  );
}
