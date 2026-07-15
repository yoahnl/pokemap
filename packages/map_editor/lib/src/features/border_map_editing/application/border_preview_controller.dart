import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import 'apply_border_materialization.dart';
import 'border_preview_transaction.dart';

/// Owns the transient draw/resolve/apply lifecycle for one Border feature.
final class BorderPreviewController extends StateNotifier<BorderPreviewState> {
  BorderPreviewController({
    BorderFeatureResolver? resolver,
    BorderPreviewMapApplier? applier,
  })  : _resolver = resolver ?? resolveBorderFeature,
        _applier = applier ?? applyBorderMaterialization,
        super(const BorderPreviewState.idle());

  final BorderFeatureResolver _resolver;
  final BorderPreviewMapApplier _applier;

  BorderPreviewState get current => state;

  /// Starts and resolves an explicit refresh of the persisted authored state.
  ///
  /// The old materialization stays on [map] until the shared Apply transaction
  /// succeeds. Merely opening this preview therefore cannot alter map history.
  void beginUpdatePreview({
    required MapData map,
    required String layerId,
    required String featureId,
    required BorderPreviewContext context,
    required BorderBlueprintRevision? blueprintRevision,
    required GridSize tileSizePx,
    required Iterable<BorderVisualSnapshot> visualSnapshots,
    required int resolverVersion,
  }) {
    begin(
      map: map,
      layerId: layerId,
      featureId: featureId,
      context: context,
    );
    resolve(
      blueprintRevision: blueprintRevision,
      tileSizePx: tileSizePx,
      visualSnapshots: visualSnapshots,
      resolverVersion: resolverVersion,
    );
  }

  void begin({
    required MapData map,
    required String layerId,
    required String featureId,
    required BorderPreviewContext context,
  }) {
    if (!identical(context.mapIdentity, map)) {
      throw ArgumentError.value(
        context.mapIdentity,
        'context.mapIdentity',
        'must identify the map used to begin the preview',
      );
    }
    final feature = _feature(map, layerId: layerId, featureId: featureId);
    state = BorderPreviewState(
      phase: BorderPreviewPhase.drawing,
      transaction: BorderPreviewTransaction(
        context: context,
        mapId: map.id,
        mapSize: map.size,
        layerId: layerId,
        featureId: featureId,
        baseFeatureFingerprint: computeBorderFeatureEditFingerprint(feature),
        proposedFeature: _copyFeature(feature, materialization: null),
        variationOrdinal: 0,
      ),
    );
  }

  void updateGeometry(BorderFeatureGeometry geometry) {
    final transaction = _requireTransaction(BorderPreviewPhase.drawing);
    state = BorderPreviewState(
      phase: BorderPreviewPhase.drawing,
      transaction: transaction.withDraftFeature(
        _copyFeature(transaction.proposedFeature, geometry: geometry),
      ),
    );
  }

  /// Resolves the current organic-region draft without ending the drag.
  void previewGeometry(
    BorderFeatureGeometry geometry, {
    required BorderBlueprintRevision? blueprintRevision,
    required GridSize tileSizePx,
    required Iterable<BorderVisualSnapshot> visualSnapshots,
    required int resolverVersion,
  }) {
    final transaction = _requireTransaction(BorderPreviewPhase.drawing);
    final feature = _copyFeature(
      transaction.proposedFeature,
      geometry: geometry,
    );
    final request = BorderResolutionRequest(
      mapSize: transaction.mapSize,
      tileSizePx: tileSizePx,
      blueprintId: feature.blueprintId,
      blueprintRevision: blueprintRevision,
      feature: feature,
      visualSnapshots: visualSnapshots,
      resolverVersion: resolverVersion,
    );
    final result = _resolver(request);
    state = BorderPreviewState(
      phase: BorderPreviewPhase.drawing,
      transaction: transaction.withResolution(
        feature: feature,
        request: request,
        result: result,
        variationOrdinal: transaction.variationOrdinal,
      ),
    );
  }

  /// Resolves a complete transient authored draft through the shared preview.
  ///
  /// Local corrections use this seam so overrides and keep-outs never need to
  /// be written to the map before Apply. The draft must still target the
  /// transaction's feature and blueprint, and persisted output is always
  /// discarded before resolution.
  void previewFeatureDraft(
    BorderFeature feature, {
    required BorderBlueprintRevision? blueprintRevision,
    required GridSize tileSizePx,
    required Iterable<BorderVisualSnapshot> visualSnapshots,
    required int resolverVersion,
  }) {
    final transaction = _requireTransaction(BorderPreviewPhase.drawing);
    if (feature.id != transaction.featureId ||
        feature.blueprintId != transaction.proposedFeature.blueprintId) {
      throw ArgumentError(
        'A Border feature draft must keep the transaction feature and '
        'blueprint identities',
      );
    }
    final draft = BorderFeature(
      id: feature.id,
      name: feature.name,
      blueprintId: feature.blueprintId,
      seed: feature.seed,
      geometry: feature.geometry,
      paramsOverride: feature.paramsOverride,
      overrides: feature.overrides,
      keepOutRegions: feature.keepOutRegions,
      materialization: null,
    );
    final request = BorderResolutionRequest(
      mapSize: transaction.mapSize,
      tileSizePx: tileSizePx,
      blueprintId: draft.blueprintId,
      blueprintRevision: blueprintRevision,
      feature: draft,
      visualSnapshots: visualSnapshots,
      resolverVersion: resolverVersion,
    );
    _publishResolution(
      transaction: transaction,
      feature: draft,
      request: request,
      variationOrdinal: transaction.variationOrdinal,
    );
  }

  /// Freezes the last transient result as resolved or invalid on release.
  void finishDrawing() {
    final transaction = _requireTransaction(BorderPreviewPhase.drawing);
    final result = transaction.result;
    if (result == null) {
      throw StateError('A Border drag must be previewed before it is finished');
    }
    state = BorderPreviewState(
      phase: result.canApply
          ? BorderPreviewPhase.resolved
          : BorderPreviewPhase.invalid,
      transaction: transaction,
    );
  }

  void resolve({
    required BorderBlueprintRevision? blueprintRevision,
    required GridSize tileSizePx,
    required Iterable<BorderVisualSnapshot> visualSnapshots,
    required int resolverVersion,
  }) {
    final transaction = _requireTransaction(BorderPreviewPhase.drawing);
    final request = BorderResolutionRequest(
      mapSize: transaction.mapSize,
      tileSizePx: tileSizePx,
      blueprintId: transaction.proposedFeature.blueprintId,
      blueprintRevision: blueprintRevision,
      feature: transaction.proposedFeature,
      visualSnapshots: visualSnapshots,
      resolverVersion: resolverVersion,
    );
    _publishResolution(
      transaction: transaction,
      feature: transaction.proposedFeature,
      request: request,
      variationOrdinal: transaction.variationOrdinal,
    );
  }

  /// Changes only the proposed seed, then resolves the exact same draft.
  void newVariation() {
    final transaction = state.transaction;
    final previousRequest = transaction?.request;
    if (transaction == null ||
        previousRequest == null ||
        (state.phase != BorderPreviewPhase.resolved &&
            state.phase != BorderPreviewPhase.invalid)) {
      throw StateError('New Variation requires a resolved Border preview');
    }
    final ordinal = transaction.variationOrdinal + 1;
    final feature = _copyFeature(
      transaction.proposedFeature,
      seed: _nextSeed(
        transaction.proposedFeature.seed,
        featureId: transaction.featureId,
        ordinal: ordinal,
      ),
    );
    final request = BorderResolutionRequest(
      mapSize: previousRequest.mapSize,
      tileSizePx: previousRequest.tileSizePx,
      blueprintId: previousRequest.blueprintId,
      blueprintRevision: previousRequest.blueprintRevision,
      feature: feature,
      visualSnapshots: previousRequest.visualSnapshots,
      resolverVersion: previousRequest.resolverVersion,
    );
    _publishResolution(
      transaction: transaction,
      feature: feature,
      request: request,
      variationOrdinal: ordinal,
    );
  }

  BorderPreviewApplyOutcome apply(
    MapData currentMap, {
    required BorderPreviewContext context,
  }) {
    final transaction = state.transaction;
    if (state.phase != BorderPreviewPhase.resolved ||
        transaction == null ||
        transaction.result?.canApply != true ||
        !transaction.context.matches(context) ||
        !identical(context.mapIdentity, currentMap)) {
      return BorderPreviewApplyOutcome(map: currentMap, applied: false);
    }

    state = BorderPreviewState(
      phase: BorderPreviewPhase.applying,
      transaction: transaction,
    );
    try {
      final updated = _applier(map: currentMap, transaction: transaction);
      if (identical(updated, currentMap)) {
        state = BorderPreviewState(
          phase: BorderPreviewPhase.resolved,
          transaction: transaction,
        );
        return BorderPreviewApplyOutcome(map: currentMap, applied: false);
      }
      state = const BorderPreviewState.idle();
      return BorderPreviewApplyOutcome(map: updated, applied: true);
    } catch (_) {
      state = BorderPreviewState(
        phase: BorderPreviewPhase.resolved,
        transaction: transaction,
      );
      rethrow;
    }
  }

  void cancel() {
    state = const BorderPreviewState.idle();
  }

  /// Keeps the persisted output exactly as-is and dismisses any repair preview.
  void keepMaterialized() => cancel();

  /// Drops a transient proposal as soon as its owning editor document drifts.
  void reconcileContext(BorderPreviewContext? context) {
    final transaction = state.transaction;
    if (transaction == null) return;
    if (context == null || !transaction.context.matches(context)) {
      cancel();
    }
  }

  void _publishResolution({
    required BorderPreviewTransaction transaction,
    required BorderFeature feature,
    required BorderResolutionRequest request,
    required int variationOrdinal,
  }) {
    final result = _resolver(request);
    state = BorderPreviewState(
      phase: result.canApply
          ? BorderPreviewPhase.resolved
          : BorderPreviewPhase.invalid,
      transaction: transaction.withResolution(
        feature: feature,
        request: request,
        result: result,
        variationOrdinal: variationOrdinal,
      ),
    );
  }

  BorderPreviewTransaction _requireTransaction(BorderPreviewPhase phase) {
    final transaction = state.transaction;
    if (state.phase != phase || transaction == null) {
      throw StateError('Expected Border preview phase ${phase.name}');
    }
    return transaction;
  }
}

BorderFeature _feature(
  MapData map, {
  required String layerId,
  required String featureId,
}) {
  for (final layer in map.layers) {
    if (layer.id != layerId || layer is! BorderLayer) continue;
    final feature = layer.content.featureById(featureId);
    if (feature != null) return feature;
  }
  throw StateError('Border feature not found: $layerId/$featureId');
}

BorderFeature _copyFeature(
  BorderFeature feature, {
  String? name,
  BorderSignedInt64? seed,
  BorderFeatureGeometry? geometry,
  BorderMaterialization? materialization,
}) =>
    BorderFeature(
      id: feature.id,
      name: name ?? feature.name,
      blueprintId: feature.blueprintId,
      seed: seed ?? feature.seed,
      geometry: geometry ?? feature.geometry,
      paramsOverride: feature.paramsOverride,
      overrides: feature.overrides,
      keepOutRegions: feature.keepOutRegions,
      materialization: materialization,
    );

BorderSignedInt64 _nextSeed(
  BorderSignedInt64 current, {
  required String featureId,
  required int ordinal,
}) {
  final unsigned = BorderDeterministicRng.fromComponents(
    <BorderRngKeyComponent>[
      const BorderRngKeyComponent.text('border-preview-variation-v1'),
      BorderRngKeyComponent.text(featureId),
      BorderRngKeyComponent.signedInt64(current),
      BorderRngKeyComponent.text(ordinal.toString()),
    ],
  ).nextUint64();
  final signed =
      unsigned >= (BigInt.one << 63) ? unsigned - (BigInt.one << 64) : unsigned;
  final next = BorderSignedInt64(signed);
  if (next != current) return next;
  return current == BorderSignedInt64.maximum
      ? BorderSignedInt64.minimum
      : BorderSignedInt64(current.value + BigInt.one);
}
