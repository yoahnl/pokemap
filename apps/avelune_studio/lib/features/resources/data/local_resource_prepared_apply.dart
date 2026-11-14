part of 'local_resource_adapter.dart';

extension _LocalResourcePreparedApply on LocalResourceAdapter {
  Future<ResourceMutationReceipt> _applyPrepared(
    ResourceMutationPreparation preparation, {
    required bool confirmDestructive,
    required String? Function()? validateBeforeApply,
  }) async {
    _requireAvailable();
    if (preparation.actionId == 'characterStudio.character.deletePlan') {
      throw const ResourceFailure(
        'L’inspection ne peut pas être appliquée. Préparez le retrait après avoir choisi une résolution.',
      );
    }
    if (preparation.sessionId != session.sessionId ||
        !_appliedPreparations.add(preparation)) {
      throw const ResourceFailure(
        'Cette préparation est déjà appliquée ou appartient à un autre projet.',
      );
    }
    try {
      if (_isCatalogClassification(this, preparation.actionId)) {
        return await _applyCatalogClassification(
          this,
          preparation,
          validateBeforeApply: validateBeforeApply,
        );
      }
      if (_lifecycleActions.contains(preparation.actionId)) {
        return await _applyLifecycleOperation(
          this,
          preparation,
          confirmDestructive: confirmDestructive,
          validateBeforeApply: validateBeforeApply,
        );
      }
      return await _run(
        preparation.actionId,
        (_) => preparation.parameters,
        expectedBeforeRevision: preparation.manifestRevision,
        expectedSnapshotRevision: preparation.snapshotRevision,
        confirmDestructive: confirmDestructive,
        validateBeforeApply: validateBeforeApply,
      );
    } on ResourceFailure catch (failure) {
      if (failure.partialReceipt == null) {
        _appliedPreparations.remove(preparation);
      }
      rethrow;
    }
  }
}
