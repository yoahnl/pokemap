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
    for (final draft in environments.values)
      if (draft.dirty) 'Environnement · ${draft.name}',
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

  bool get resourceIndexPreparationAvailable =>
      port is ResourceIndexPreparationPort &&
      (port as ResourceIndexPreparationPort).resourceIndexPreparationAvailable;

  Future<void> prepareResourceIndexes() async {
    if (!resourceIndexPreparationAvailable || busy || pendingReceipt != null) {
      throw const ResourceFailure(
        'La préparation est indisponible pour le moment.',
      );
    }
    if (usageDraftOwners.isNotEmpty) {
      throw const ResourceFailure(
        'Enregistrez ou annulez les brouillons avant de préparer les usages.',
      );
    }
    busy = true;
    changed();
    try {
      final revision = await captureResourceRevision();
      final receipt = await (port as ResourceIndexPreparationPort)
          .prepareResourceIndexes(expectedSnapshotRevision: revision);
      await accept(receipt);
    } finally {
      busy = false;
      changed();
    }
  }

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
    if (actionId == 'resource.classify' && parameters['mapId'] != null) {
      final entry = workspace.project!.resourceLibraryCatalog.entryFor(
        parameters['resourceKind'] as String,
        parameters['resourceId'] as String,
      );
      if (parameters['mapId'] != entry?.mapId && usageDraftOwners.isNotEmpty) {
        return 'Enregistrez ou annulez les brouillons avant de réserver cette '
            'ressource à une carte : ${usageDraftOwners.join(', ')}.';
      }
    }
    if (actionId == 'environment.preset.delete') {
      final id = parameters['presetId'];
      final owners = [
        if (environments[id]?.dirty == true) 'Environnement',
        for (final document in workspace.documents.values)
          if (document.dirty &&
              document.current.layers.whereType<EnvironmentLayer>().any(
                (layer) =>
                    layer.content.areas.any((area) => area.presetId == id),
              ))
            'Carte · ${document.current.name}',
      ];
      if (owners.isNotEmpty) {
        return 'Enregistrez ou annulez les propriétaires concernés : ${owners.join(', ')}.';
      }
    }
    if (actionId == 'resource.usages.replace' && usageDraftOwners.isNotEmpty) {
      return 'Enregistrez ou annulez les brouillons avant de remplacer les '
          'usages : ${usageDraftOwners.join(', ')}.';
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
      final manifest = await accept(receipt);
      error = null;
      return manifest;
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
    if (packTransfer?.requiresReconciliation == true) {
      return packTransfer!.retryReconciliation();
    }
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
