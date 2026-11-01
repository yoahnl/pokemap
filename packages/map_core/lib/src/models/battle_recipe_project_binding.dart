import 'battle_move_recipe_binding.dart';
import 'battle_recipe_project_paths.dart';

final class BattleRecipeProjectBinding {
  BattleRecipeProjectBinding({
    required this.binding,
    this.catalogMoveId,
    this.recipeMediaId,
  }) {
    battleRecipeBindingPath(binding.projectMoveId);
    if ((catalogMoveId == null) != (recipeMediaId == null) ||
        (catalogMoveId != null && !_catalogId.hasMatch(catalogMoveId!)) ||
        (recipeMediaId != null && !_catalogId.hasMatch(recipeMediaId!))) {
      throw const FormatException('Invalid battle recipe catalog provenance');
    }
  }

  static final _catalogId = RegExp(r'^[a-z0-9][a-z0-9-]{0,127}$');
  final BattleMoveRecipeBinding binding;
  final String? catalogMoveId;
  final String? recipeMediaId;

  factory BattleRecipeProjectBinding.fromJson(Map<String, dynamic> json) {
    if (json.keys.any(
          (key) => !const {
            'kind',
            'schemaVersion',
            'unsupportedBehavior',
            'binding',
            'catalogMoveId',
            'recipeMediaId',
          }.contains(key),
        ) ||
        json['kind'] != 'avelune.battle-recipe-binding' ||
        json['schemaVersion'] is! int ||
        json['schemaVersion'] != 1 ||
        json['unsupportedBehavior'] != 'legacy' ||
        json['binding'] is! Map ||
        (json['catalogMoveId'] != null && json['catalogMoveId'] is! String) ||
        (json['recipeMediaId'] != null && json['recipeMediaId'] is! String)) {
      throw const FormatException('Invalid battle recipe project binding');
    }
    return BattleRecipeProjectBinding(
      binding: BattleMoveRecipeBinding.fromJson(
        Map<String, dynamic>.from(json['binding'] as Map),
      ),
      catalogMoveId: json['catalogMoveId'] as String?,
      recipeMediaId: json['recipeMediaId'] as String?,
    );
  }

  Map<String, Object?> toJson() => {
    'kind': 'avelune.battle-recipe-binding',
    'schemaVersion': 1,
    'unsupportedBehavior': 'legacy',
    'binding': binding.toJson(),
    if (catalogMoveId != null) 'catalogMoveId': catalogMoveId,
    if (recipeMediaId != null) 'recipeMediaId': recipeMediaId,
  };
}
