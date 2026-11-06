part of 'pokemon_workspace_controller.dart';

extension PokemonMoveRecipeCommands on PokemonWorkspaceController {
  bool get supportsMoveRecipes =>
      port is PokemonMoveRecipePort &&
      (port as PokemonMoveRecipePort).supportsMoveRecipes;

  bool get supportsMoveRecipeBatch =>
      supportsMoveRecipes && port is PokemonMoveRecipeBatchPort;

  void stopMoveRecipeBatch() {
    if (!recipeBatchActive) return;
    recipeBatchStopRequested = true;
    _notify();
  }

  Future<void> importMoveRecipeBatch() async {
    if (!supportsMoveRecipeBatch ||
        operationActive ||
        recipePreparing ||
        hasPendingChanges ||
        index?.moves.available != true ||
        _disposed) {
      return;
    }
    final source = port as PokemonMoveRecipeBatchPort;
    recipeBatchActive = true;
    recipeBatchStopRequested = false;
    recipeBatchPreparing = false;
    recipeBatchTotal = null;
    recipeBatchProcessed = 0;
    recipeBatchResults = [];
    recipeBatchStopped = null;
    _notify();
    var nextIndex = 0;
    String? revision;
    try {
      final operationId =
          'studio_batch_${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}';
      do {
        final result = await source.importMoveRecipeBatch(
          operationId: operationId,
          startIndex: nextIndex,
          limit: revision == null
              ? 1
              : BattleMoveRecipeBatchImporter.maximumBatchSize,
          expectedInventoryRevision: revision,
          isCancelled: () => _disposed || recipeBatchStopRequested,
          onProgress: (entry) {
            if (_disposed) return;
            recipeBatchProcessed = entry.index + 1;
            _notify();
          },
        );
        if (_disposed) return;
        recipeBatchResults = [...recipeBatchResults, ...result.results];
        for (final entry in result.results) {
          if (entry.status == BattleMoveRecipeBatchStatus.failed) {
            developer.log(
              'Import échoué : ${entry.projectMoveId}, motif ${entry.reason}, opération ${entry.operationId}',
              name: 'avelune.move_recipe_batch',
            );
          }
        }
        recipeBatchTotal = result.total;
        recipeBatchProcessed = result.nextIndex;
        recipeBatchStopped = result.stopped;
        revision = result.inventoryRevision;
        if (result.stopped != null) break;
        if (result.nextIndex == nextIndex && result.remaining > 0) {
          recipeBatchStopped = 'unexpected';
          break;
        }
        nextIndex = result.nextIndex;
        _notify();
        if (recipeBatchStopRequested) {
          recipeBatchStopped = 'cancelled';
          break;
        }
      } while (nextIndex < recipeBatchTotal!);
    } on CatalogStorageException catch (error, stack) {
      developer.log(
        'Import groupé interrompu',
        name: 'avelune.move_recipe_batch',
        error: error,
        stackTrace: stack,
      );
      if (!_disposed) {
        recipeBatchStopped = error.code == 'catalog.revision_conflict'
            ? 'projectChanged'
            : 'unexpected';
      }
    } on Object catch (error, stack) {
      developer.log(
        'Import groupé interrompu',
        name: 'avelune.move_recipe_batch',
        error: error,
        stackTrace: stack,
      );
      if (!_disposed) recipeBatchStopped = 'unexpected';
    } finally {
      recipeBatchActive = false;
      _notify();
    }
  }

  Future<void> prepareMoveRecipeBatchProject() async {
    if (!supportsMoveRecipeBatch ||
        operationActive ||
        hasPendingChanges ||
        recipeBatchStopped != 'preparationRequired' ||
        _disposed) {
      return;
    }
    recipeBatchActive = true;
    recipeBatchPreparing = true;
    recipeBatchStopped = null;
    _notify();
    try {
      await (port as PokemonMoveRecipeBatchPort)
          .prepareMoveRecipeBatchProject();
      if (!_disposed) recipeBatchStopped = 'prepared';
    } on Object catch (error, stack) {
      developer.log(
        'Préparation du projet impossible',
        name: 'avelune.move_recipe_batch',
        error: error,
        stackTrace: stack,
      );
      if (!_disposed) recipeBatchStopped = 'preparationFailed';
    } finally {
      recipeBatchActive = false;
      recipeBatchPreparing = false;
      _notify();
    }
  }

  Future<void> prepareMoveRecipes() async {
    if (!supportsMoveRecipes || recipeReady || recipePreparing || _disposed) {
      return;
    }
    recipePreparing = true;
    recipeError = null;
    _notify();
    try {
      await (port as PokemonMoveRecipePort).prepareMoveRecipes();
      if (!_disposed) recipeReady = true;
    } on Object {
      if (!_disposed) {
        recipeError =
            'Préparation impossible. Réessayez d’ouvrir les animations.';
      }
    } finally {
      recipePreparing = false;
      _notify();
    }
  }

  Future<void> findMoveRecipes() async {
    final id = selectedMoveId;
    if (id == null ||
        port is! PokemonMoveRecipePort ||
        !recipeReady ||
        operationActive ||
        hasPendingChanges) {
      return;
    }
    final source = port as PokemonMoveRecipePort;
    if (!source.supportsMoveRecipes) return;
    final request = ++_recipeRequest;
    recipeBusy = true;
    recipeChoices = null;
    recipeError = null;
    recipeNotice = null;
    _notify();
    try {
      final choices = await source.listMoveRecipes(id);
      if (!_disposed && request == _recipeRequest && selectedMoveId == id) {
        recipeChoices = choices;
      }
    } on Object {
      if (!_disposed && request == _recipeRequest && selectedMoveId == id) {
        recipeError =
            'Recherche impossible. Vérifiez votre connexion puis réessayez.';
      }
    } finally {
      recipeBusy = false;
      _notify();
    }
  }

  Future<void> importMoveRecipe(PokemonMoveRecipeChoice choice) async {
    final id = selectedMoveId;
    if (id == null ||
        port is! PokemonMoveRecipePort ||
        operationActive ||
        hasPendingChanges ||
        !(recipeChoices?.contains(choice) ?? false)) {
      return;
    }
    final source = port as PokemonMoveRecipePort;
    if (!source.supportsMoveRecipes) return;
    final request = _recipeRequest;
    bool isCurrent() =>
        !_disposed && request == _recipeRequest && selectedMoveId == id;
    recipeBusy = true;
    committing = true;
    recipeError = null;
    recipeNotice = null;
    _notify();
    try {
      final changed = await source.importMoveRecipe(
        id,
        choice,
        isCurrent: isCurrent,
      );
      if (isCurrent()) {
        recipeNotice = changed
            ? 'Animation ajoutée au projet.'
            : 'Cette animation est déjà présente dans le projet.';
      }
    } on PokemonWorkspaceFailure catch (failure) {
      if (isCurrent()) recipeError = failure.message;
    } on Object {
      if (isCurrent()) {
        recipeError = 'Import impossible. Actualisez la liste et vérifiez qu’aucune autre animation n’est déjà associée.';
      }
    } finally {
      recipeBusy = false;
      committing = false;
      _notify();
    }
  }
}
