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
    if (const {
      'characterStudio.character.deletePlan',
      'characterStudio.character.delete',
    }.contains(actionId)) {
      final owners = characterManagementOwners(actionId, parameters);
      if (owners.isNotEmpty) {
        return 'Enregistrez ou annulez les propriétaires concernés : ${owners.join(', ')}.';
      }
    }
    if (const {
      'border.blueprint.delete',
      'border.blueprint.set_deprecated',
    }.contains(actionId)) {
      final owners = borderManagementOwners(actionId, parameters);
      if (owners.isNotEmpty) {
        return 'Enregistrez ou annulez les propriétaires concernés : ${owners.join(', ')}.';
      }
    }
    if (const {
      'smart_tile.preset.rename',
      'smart_tile.preset.duplicate',
      'smart_tile.preset.delete',
      'smart_tile.preset.draft.delete',
    }.contains(actionId)) {
      final owners = terrainManagementOwners(actionId, parameters);
      if (owners.isNotEmpty) {
        return 'Enregistrez ou annulez les propriétaires concernés : ${owners.join(', ')}.';
      }
    }
    if (const {
      'element.delete',
      'element.duplicate',
      'tileset.remove',
      'tileset.source.replace',
    }.contains(actionId)) {
      final owners = _lifecycleDraftOwners(actionId, parameters);
      if (owners.isNotEmpty) {
        return 'Enregistrez ou annulez les propriétaires concernés : ${owners.join(', ')}.';
      }
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
    String? validate() =>
        _managementProblem(preparation.actionId, preparation.parameters) ??
        _characterPublicationProblem(this, preparation);
    final problem = validate();
    if (problem != null) throw ResourceFailure(problem);
    busy = true;
    changed();
    try {
      final receipt = await _preparationPort.applyPrepared(
        preparation,
        confirmDestructive: confirmDestructive,
        validateBeforeApply: validate,
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
      navigation.workspace.acceptResourceMaps({
        for (final entry in receipt.changedMaps.entries)
          entry.key: MapWorkspaceDocument(
            map: entry.value,
            revision: receipt.mapRevisions[entry.key]!,
            mapId: entry.key,
          ),
      });
      navigation.workspace.acceptResources(receipt.before, receipt.manifest);
    }
    navigation.characters.refreshClean();
    navigation.reconcileCharacterManagement(receipt);
    if (receipt.actionId == 'characterStudio.character.delete') {
      navigation.characterSourcesChanged?.call({
        for (final entry in receipt.before.dialogues)
          if (receipt.changedPaths.contains(entry.relativePath)) entry.id,
      });
    }
    navigation.reconcileTerrainManagement(receipt);
    navigation.reconcileBorderManagement(receipt);
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

String? _characterPublicationProblem(
  ResourceNavigation navigation,
  ResourceMutationPreparation preparation,
) {
  if (preparation.actionId != 'characterStudio.character.delete') return null;
  return navigation.characterSourceProblem?.call({
    for (final entry in navigation.workspace.project!.dialogues)
      if (preparation.changedPaths.contains(entry.relativePath)) entry.id,
  });
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
