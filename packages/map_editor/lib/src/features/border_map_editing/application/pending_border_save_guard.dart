import 'package:map_core/map_core.dart';

import 'apply_border_materialization.dart';
import 'border_preview_transaction.dart';

/// Explicit user choice when saving a map with a transient Border preview.
enum PendingBorderSaveDecision {
  applyAndSave,
  discardAndSave,
  cancelSave,
}

/// Work that may happen only after the candidate map was persisted.
enum PendingBorderPostSaveAction {
  none,
  commitAppliedPreview,
  discardPreview,
}

/// Observable outcome of the shared active-map save coordinator.
enum ActiveMapSaveOutcome {
  saved,
  pendingBorderDecisionRequired,
  cancelled,
  conflict,
  failed,
  unavailable,
  bulkPlacementLossBlocked,
}

sealed class PendingBorderSavePreparation {
  const PendingBorderSavePreparation();
}

final class PendingBorderSaveReady extends PendingBorderSavePreparation {
  const PendingBorderSaveReady({
    required this.candidateMap,
    required this.postSaveAction,
    this.transaction,
  });

  final MapData candidateMap;
  final PendingBorderPostSaveAction postSaveAction;
  final BorderPreviewTransaction? transaction;
}

final class PendingBorderSaveDecisionRequired
    extends PendingBorderSavePreparation {
  const PendingBorderSaveDecisionRequired();
}

final class PendingBorderSaveCancelled extends PendingBorderSavePreparation {
  const PendingBorderSaveCancelled();
}

final class PendingBorderSaveConflict extends PendingBorderSavePreparation {
  const PendingBorderSaveConflict(this.message, {this.cause});

  final String message;
  final Object? cause;
}

/// Pure save preflight. It never mutates or consumes a Border preview.
final class PendingBorderSaveGuard {
  PendingBorderSaveGuard({
    BorderPreviewMapApplier applier = applyBorderMaterialization,
  }) : _applier = applier;

  final BorderPreviewMapApplier _applier;

  PendingBorderSavePreparation prepare({
    required MapData currentMap,
    required BorderPreviewState previewState,
    required BorderPreviewContext? currentContext,
    required String? activeLayerId,
    required String? activeFeatureLayerId,
    required String? activeFeatureId,
    PendingBorderSaveDecision? decision,
  }) {
    final transaction = previewState.transaction;
    if (transaction == null) {
      return PendingBorderSaveReady(
        candidateMap: currentMap,
        postSaveAction: PendingBorderPostSaveAction.none,
      );
    }
    if (decision == null) {
      return const PendingBorderSaveDecisionRequired();
    }
    switch (decision) {
      case PendingBorderSaveDecision.cancelSave:
        return const PendingBorderSaveCancelled();
      case PendingBorderSaveDecision.discardAndSave:
        return PendingBorderSaveReady(
          candidateMap: currentMap,
          postSaveAction: PendingBorderPostSaveAction.discardPreview,
          transaction: transaction,
        );
      case PendingBorderSaveDecision.applyAndSave:
        return _prepareAppliedCandidate(
          currentMap: currentMap,
          previewState: previewState,
          transaction: transaction,
          currentContext: currentContext,
          activeLayerId: activeLayerId,
          activeFeatureLayerId: activeFeatureLayerId,
          activeFeatureId: activeFeatureId,
        );
    }
  }

  PendingBorderSavePreparation _prepareAppliedCandidate({
    required MapData currentMap,
    required BorderPreviewState previewState,
    required BorderPreviewTransaction transaction,
    required BorderPreviewContext? currentContext,
    required String? activeLayerId,
    required String? activeFeatureLayerId,
    required String? activeFeatureId,
  }) {
    if (previewState.phase != BorderPreviewPhase.resolved ||
        transaction.result?.canApply != true) {
      return const PendingBorderSaveConflict(
        'L’aperçu de bordure n’est pas dans un état applicable.',
      );
    }
    if (currentMap.id != transaction.mapId ||
        currentContext == null ||
        !identical(currentContext.mapIdentity, currentMap) ||
        !transaction.context.matches(currentContext) ||
        activeLayerId != transaction.layerId ||
        activeFeatureLayerId != transaction.layerId ||
        activeFeatureId != transaction.featureId) {
      return const PendingBorderSaveConflict(
        'La carte, le calque ou la bordure active a changé depuis l’aperçu.',
      );
    }
    try {
      final candidate = _applier(
        map: currentMap,
        transaction: transaction,
      );
      if (identical(candidate, currentMap)) {
        return const PendingBorderSaveConflict(
          'La bordure a changé depuis l’aperçu et ne peut plus être appliquée.',
        );
      }
      return PendingBorderSaveReady(
        candidateMap: candidate,
        postSaveAction: PendingBorderPostSaveAction.commitAppliedPreview,
        transaction: transaction,
      );
    } catch (error) {
      return PendingBorderSaveConflict(
        'Impossible de préparer l’aperçu de bordure pour la sauvegarde.',
        cause: error,
      );
    }
  }
}
