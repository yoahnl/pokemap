import 'package:map_authoring/map_authoring.dart';

import 'pokemon_move_recipe_choice.dart';

abstract interface class PokemonMoveRecipePort {
  bool get supportsMoveRecipes;

  Future<void> prepareMoveRecipes();

  Future<List<PokemonMoveRecipeChoice>> listMoveRecipes(String projectMoveId);

  Future<bool> importMoveRecipe(
    String projectMoveId,
    PokemonMoveRecipeChoice choice, {
    bool Function()? isCurrent,
  });
}

abstract interface class PokemonMoveRecipeBatchPort {
  Future<BattleMoveRecipeBatchResult> importMoveRecipeBatch({
    required String operationId,
    int startIndex = 0,
    int limit = BattleMoveRecipeBatchImporter.maximumBatchSize,
    String? expectedInventoryRevision,
    bool Function()? isCancelled,
    void Function(BattleMoveRecipeBatchEntry entry)? onProgress,
  });
}
