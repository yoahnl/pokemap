part of 'pokemon_workspace_controller.dart';

extension PokemonMoveRecipeCommands on PokemonWorkspaceController {
  bool get supportsMoveRecipes =>
      port is PokemonMoveRecipePort &&
      (port as PokemonMoveRecipePort).supportsMoveRecipes;

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
            ? 'Animation ajoutée au projet. Le Player conserve son animation actuelle pour le moment.'
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
