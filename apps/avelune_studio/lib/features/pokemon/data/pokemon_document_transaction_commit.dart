part of 'pokemon_document_transaction.dart';

extension _PokemonDocumentCommit on PokemonDocumentTransaction {
  List<AuthoringResourceChange> _plannedChanges(
    AuthoringMutationPlanResult planned,
    Set<String> changedPaths,
  ) {
    final changes = planned.plan.changeSet.changes;
    final expectedPaths = {...changedPaths};
    if (session.storage == ProjectSessionStorage.workingCatalog) {
      if (planned.plan.catalogDelta == null) {
        throw const PokemonWorkspaceFailure(
          'La transaction Pokémon ne contient pas de mise à jour du catalogue.',
        );
      }
      planned.plan.requireCatalogDelta();
      expectedPaths.add(CatalogStorageStore.headStorageKey);
    }
    final plannedPaths = {for (final change in changes) change.storageKey};
    if (plannedPaths.length != changes.length ||
        plannedPaths.length != expectedPaths.length ||
        plannedPaths.any((path) => !expectedPaths.contains(path))) {
      throw const PokemonWorkspaceFailure(
        'La transaction Pokémon touche un autre document que prévu.',
      );
    }
    return changes;
  }

  Future<void> _applyOrRecover({
    required LocalMapAuthoringMutationApi api,
    required OpenedProject opened,
    required AuthoringMutationPlanResult planned,
    required String operation,
    required List<PokemonDocumentReadDependency> dependencies,
    required bool mediaOnly,
  }) async {
    try {
      await api.applyMutation(
        opened.projectHandle,
        planId: planned.planId,
        operationId: operation,
        precondition: () async {
          for (final dependency in dependencies) {
            if (!_sameBytes(
              await _readOptional(dependency.relativePath),
              dependency.beforeBytes,
            )) {
              throw PokemonWorkspaceFailure(
                '${dependency.relativePath} a changé depuis l’aperçu. '
                'Reprévisualisez.',
              );
            }
          }
        },
      );
    } on Object catch (failure, stack) {
      if (mediaOnly) {
        final status = await api.recoveryStatus(
          opened.projectHandle,
          operationId: operation,
        );
        if (status['disposition'] == 'notFound') {
          Error.throwWithStackTrace(failure, stack);
        }
      }
      try {
        final recovered = await api.recoverMutation(
          opened.projectHandle,
          operationId: operation,
        );
        if (recovered.receipt.extensions['recoveryOutcome'] != 'resumed' &&
            !(mediaOnly && recovered.receipt.status.name == 'applied')) {
          throw PokemonWorkspaceFailure(
            'Transaction interrompue ; vérifiez le projet avant de réessayer : $failure',
          );
        }
      } on Object {
        throw PokemonWorkspaceFailure(
          'État de la transaction incertain ; rouvrez le projet et vérifiez '
          'les documents avant de réessayer. Référence $operation : $failure',
        );
      }
    }
  }

  Future<List<int>?> _verifyCommitted({
    required List<AuthoringResourceChange> changes,
    required List<PokemonDocumentWriteRequest> documents,
    required bool mediaOnly,
    required ({ProjectManifest manifest, String revision}) baseline,
    required String operation,
    required String actionId,
  }) async {
    List<int>? savedMediaBytes;
    try {
      for (final change in changes) {
        final actual = await reader.readBytes(
          projectRoot: session.directoryPath,
          relativePath: change.storageKey,
        );
        if (!_sameBytes(actual, change.afterBytes)) {
          throw StateError(
            'Le document ${change.storageKey} ne correspond pas au reçu.',
          );
        }
        if (mediaOnly && change.storageKey == documents.single.relativePath) {
          savedMediaBytes = List.unmodifiable(actual);
        }
      }
      final revision = await mapAdapter.resourceRevision(session);
      final head = changes.where(
        (change) => change.storageKey == CatalogStorageStore.headStorageKey,
      );
      if (head.isNotEmpty &&
          !_sameBytes(
            await _readOptional(CatalogStorageStore.headStorageKey),
            head.single.afterBytes,
          )) {
        throw StateError('Le catalogue a changé après la transaction.');
      }
      await mapAdapter.acceptResourceMutation(
        session,
        ResourceMutationReceipt(
          before: baseline.manifest,
          manifest: baseline.manifest,
          beforeRevision: baseline.revision,
          revision: revision,
          changedPaths: [for (final change in changes) change.storageKey],
          operationId: operation,
          actionId: actionId,
        ),
      );
    } on Object catch (failure) {
      throw PokemonWorkspaceFailure(
        'Écriture confirmée ; vérification ou actualisation impossible. '
        'Rouvrez le projet avant de continuer : $failure',
      );
    }
    if (mediaOnly && savedMediaBytes == null) {
      throw const PokemonWorkspaceFailure(
        'Écriture confirmée mais préimage enregistrée indisponible. '
        'Rouvrez le projet avant de continuer.',
      );
    }
    return savedMediaBytes;
  }
}
