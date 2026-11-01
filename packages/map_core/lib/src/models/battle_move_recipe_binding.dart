import 'package:crypto/crypto.dart';

import 'battle_move_animation_recipe.dart';
import 'battle_recipe_json.dart';

final class BattleMoveRecipeBinding {
  const BattleMoveRecipeBinding._({
    required this.projectMoveId,
    required this.sourceMoveId,
    required this.catalogReleaseId,
    required this.recipeId,
    required this.variant,
    required this.revision,
    required this.recipeSha256,
  });

  final String projectMoveId;
  final String sourceMoveId;
  final String catalogReleaseId;
  final String recipeId;
  final String variant;
  final String revision;
  final String recipeSha256;

  factory BattleMoveRecipeBinding.fromJson(Map<String, dynamic> json) {
    const keys = {
      'schemaVersion',
      'projectMoveId',
      'sourceMoveId',
      'catalogReleaseId',
      'recipeId',
      'variant',
      'revision',
      'recipeSha256',
    };
    if (json.keys.any((key) => !keys.contains(key)) ||
        json['schemaVersion'] is! int ||
        json['schemaVersion'] != 1) {
      throw const FormatException('Unsupported recipe binding');
    }
    String field(String key) {
      final value = json[key];
      if (value is! String || value.isEmpty || value.trim() != value) {
        throw FormatException('Invalid $key');
      }
      return value;
    }

    final hash = field('recipeSha256');
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(hash)) {
      throw const FormatException('Invalid recipe hash');
    }
    return BattleMoveRecipeBinding._(
      projectMoveId: field('projectMoveId'),
      sourceMoveId: field('sourceMoveId'),
      catalogReleaseId: field('catalogReleaseId'),
      recipeId: field('recipeId'),
      variant: field('variant'),
      revision: field('revision'),
      recipeSha256: hash,
    );
  }

  Map<String, dynamic> toJson() => {
    'schemaVersion': 1,
    'projectMoveId': projectMoveId,
    'sourceMoveId': sourceMoveId,
    'catalogReleaseId': catalogReleaseId,
    'recipeId': recipeId,
    'variant': variant,
    'revision': revision,
    'recipeSha256': recipeSha256,
  };

  BattleMoveAnimationRecipe resolve(
    List<int> recipeBytes,
    Map<String, List<int>> resources, {
    required Set<String> availableCapabilities,
  }) {
    if (recipeBytes.length > 1048576 ||
        sha256.convert(recipeBytes).toString() != recipeSha256) {
      throw const FormatException('Recipe bytes do not match binding');
    }
    final decoded = decodeBoundedBattleJson(
      recipeBytes,
      maxDepth: 72,
      label: 'Recipe',
    );
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Recipe must be a JSON object');
    }
    if (decoded['moveSourceId'] != sourceMoveId ||
        decoded['recipeId'] != recipeId ||
        decoded['variant'] != variant ||
        decoded['revision'] != revision) {
      throw const FormatException('Recipe identity does not match binding');
    }
    final recipe = BattleMoveAnimationRecipe.fromJson(decoded);
    recipe.validateBundle(
      resources,
      availableCapabilities: availableCapabilities,
    );
    return recipe;
  }
}
