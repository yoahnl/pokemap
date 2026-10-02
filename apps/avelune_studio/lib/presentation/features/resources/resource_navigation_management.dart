part of 'resource_navigation.dart';

extension ResourceNavigationManagement on ResourceNavigation {
  bool get managementDialogActive => _managementDialogs > 0;
  void beginManagementDialog() {
    _managementDialogs++;
  }

  void endManagementDialog() {
    if (_managementDialogs > 0) _managementDialogs--;
  }

  ResourceUsagePort get usages => port is ResourceUsageProvider
      ? (port as ResourceUsageProvider).usages
      : const UnavailableResourceUsagePort();

  List<String> get usageDraftOwners => [
    for (final document in workspace.documents.values)
      if (document.dirty) 'Carte · ${document.current.name}',
    for (final draft in decors.values) 'Décor · ${draft.name}',
    for (final draft in terrains.values)
      if (draft.dirty) 'Terrain · ${draft.draft.name}',
    if (characters.dirty) 'Personnages',
    ...?additionalDraftOwners?.call(),
  ];

  ResourceMutationPreparationPort get _preparationPort {
    if (port case final ResourceMutationPreparationPort preparation) {
      return preparation;
    }
    throw const ResourceFailure(
      'La gestion des informations est indisponible.',
    );
  }

  Future<String> captureResourceRevision() =>
      _preparationPort.captureResourceRevision();
  Future<String?> resourceFingerprint(String tilesetId, String revision) =>
      _preparationPort.resourceFingerprint(tilesetId, revision);

  Future<ResourceMutationPreparation> prepareOperation(
    String actionId,
    Map<String, Object?> parameters, {
    String? expectedSnapshotRevision,
  }) {
    final problem = _managementProblem(actionId, parameters);
    if (problem != null) return Future.error(ResourceFailure(problem));
    return _preparationPort.prepareOperation(
      actionId,
      parameters,
      expectedSnapshotRevision: expectedSnapshotRevision,
    );
  }

  String? _managementProblem(String actionId, Map<String, Object?> parameters) {
    if (_disposed || workspace.isDisposed) return 'Le projet a été fermé.';
    if (pendingReceipt != null) {
      return 'Relisez la publication précédente avant une nouvelle modification.';
    }
    if (actionId == 'element.category.assign' &&
        decors.values.any(
          (draft) => draft.original?.id == parameters['elementId'],
        )) {
      return 'Enregistrez ou annulez la préparation de ce décor avant de le déplacer.';
    }
    if (actionId == 'smart_tile.preset.category.assign' &&
        terrains.values.any(
          (draft) =>
              draft.dirty &&
              draft.draft.targetPresetId == parameters['presetId'],
        )) {
      return 'Enregistrez ou annulez la préparation de ce terrain avant de le déplacer.';
    }
    return null;
  }

  Future<ProjectManifest> applyPrepared(
    ResourceMutationPreparation preparation, {
    bool confirmDestructive = false,
  }) async {
    if (busy) throw const ResourceFailure('Une opération est déjà en cours.');
    final problem = _managementProblem(
      preparation.actionId,
      preparation.parameters,
    );
    if (problem != null) throw ResourceFailure(problem);
    busy = true;
    changed();
    try {
      final receipt = await _preparationPort.applyPrepared(
        preparation,
        confirmDestructive: confirmDestructive,
        validateBeforeApply: () =>
            _managementProblem(preparation.actionId, preparation.parameters),
      );
      return await accept(receipt);
    } on ResourceFailure catch (failure) {
      if (failure.partialReceipt != null) {
        pendingReceipt = failure.partialReceipt;
      }
      error = failure.message;
      rethrow;
    } finally {
      busy = false;
      if (!_disposed) changed();
    }
  }

  Future<bool> retryReconciliation() async {
    final receipt = pendingReceipt;
    if (receipt == null || busy || _disposed) return false;
    busy = true;
    changed();
    try {
      if (port case final ResourceMutationPreparationPort preparation) {
        await preparation.reconcileReceipt(receipt);
      }
      await accept(receipt);
      error = null;
      return true;
    } on Object catch (failure) {
      error = '$failure';
      return false;
    } finally {
      busy = false;
      if (!_disposed) changed();
    }
  }

  bool canOpenUsageOwner(ResourceUsageEntry entry) =>
      openUsage != null && (canOpenUsage?.call(entry) ?? false);

  Future<bool> openUsageOwner(ResourceUsageEntry entry) async {
    if (_disposed || !canOpenUsageOwner(entry)) return false;
    return await openUsage!(entry);
  }
}

Future<ProjectManifest> _acceptResourceReceipt(
  ResourceNavigation navigation,
  ResourceMutationReceipt receipt,
) async {
  navigation.pendingReceipt = receipt;
  try {
    if (navigation._disposed || navigation.workspace.isDisposed) {
      throw const ResourceFailure(
        'Le projet a été fermé après la publication.',
      );
    }
    if (navigation.workspace.project != receipt.manifest) {
      navigation.workspace.acceptResources(receipt.before, receipt.manifest);
    }
    navigation.characters.refreshClean();
    for (final model in navigation.terrains.values) {
      model.manifest = receipt.manifest;
    }
    if (navigation.visuals case final ResourceWorkspaceVisuals resources) {
      await resources.updateCatalog(
        receipt.manifest,
        changedRelativePaths: receipt.changedPaths.toSet(),
      );
    }
    if (navigation._disposed) {
      throw const ResourceFailure(
        'Le projet a été fermé après la publication.',
      );
    }
    navigation.pendingReceipt = null;
    navigation.changed();
    return receipt.manifest;
  } on Object catch (failure) {
    throw ResourceFailure(
      'La publication a réussi, mais l’interface n’a pas pu être actualisée. Relisez sans relancer la mutation. $failure',
      partialReceipt: receipt,
    );
  }
}

Future<ProjectManifest> _mutateResources(
  ResourceNavigation navigation,
  String action,
  Map<String, Object?> parameters,
) async {
  final wasBusy = navigation.busy;
  navigation.busy = true;
  navigation.changed();
  try {
    return await navigation.accept(
      await navigation.port.mutate(action, parameters),
    );
  } on ResourceFailure catch (failure) {
    if (failure.partialReceipt != null) {
      navigation.pendingReceipt = failure.partialReceipt;
    }
    navigation.error = failure.message;
    rethrow;
  } finally {
    navigation.busy = wasBusy;
    navigation.changed();
  }
}
