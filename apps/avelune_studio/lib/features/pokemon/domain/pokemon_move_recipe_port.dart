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
