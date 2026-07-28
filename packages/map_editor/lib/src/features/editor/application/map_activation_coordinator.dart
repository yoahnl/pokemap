/// Explicit choice made before leaving a map with unsaved authoring changes.
enum DirtyMapActivationDecision {
  save,
  discard,
  cancel,
}

/// Side-effect-free plan used by every active-map navigation entry point.
enum MapActivationPlan {
  activate,
  saveThenActivate,
  requiresDecision,
  stay,
}

/// Observable result of an active-map navigation request.
enum MapActivationOutcome {
  activated,
  requiresDecision,
  cancelled,
  saveBlocked,
  busy,
  failed,
  unavailable,
}

/// Centralizes the dirty-document decision matrix.
///
/// Keeping this policy pure prevents individual tree, canvas, or connection
/// entry points from inventing different rules for unsaved work.
final class MapActivationCoordinator {
  const MapActivationCoordinator();

  MapActivationPlan plan({
    required bool isDirty,
    bool hasPendingPreview = false,
    DirtyMapActivationDecision? decision,
  }) {
    if (!isDirty && !hasPendingPreview) {
      return MapActivationPlan.activate;
    }
    return switch (decision) {
      null => MapActivationPlan.requiresDecision,
      DirtyMapActivationDecision.save => MapActivationPlan.saveThenActivate,
      DirtyMapActivationDecision.discard => MapActivationPlan.activate,
      DirtyMapActivationDecision.cancel => MapActivationPlan.stay,
    };
  }
}
