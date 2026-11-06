import 'package:map_core/map_core.dart';

import 'avelune_pokemon_media_source.dart';
import 'pokemon_move_localized_names.dart';

String? battleRecipeCatalogMoveId(String projectMoveId,
    {bool allowUnknown = false}) {
  const aliases = {
    'smoke_screen': 'smokescreen',
    'faint_attack': 'feint-attack',
    'selfdestruct': 'self-destruct',
  };
  final alias = aliases[projectMoveId];
  if (alias != null) return alias;
  final catalogId = projectMoveId.replaceAll('_', '-');
  if (!RegExp(r'^[a-z0-9][a-z0-9-]{0,127}$').hasMatch(catalogId) ||
      (!allowUnknown &&
          !pokemonMoveLocalizedNames.containsKey(projectMoveId))) {
    return null;
  }
  return catalogId;
}

final class BattleMoveRecipeCandidate {
  const BattleMoveRecipeCandidate({
    required this.catalogMoveId,
    required this.mediaId,
    required this.style,
    required this.binding,
  });

  final String catalogMoveId;
  final String mediaId;
  final String style;
  final BattleMoveRecipeBinding binding;
}

final class BattleMoveRecipeCatalogSource {
  const BattleMoveRecipeCatalogSource(this.media);

  final AvelunePokemonMediaSource media;

  Future<List<BattleMoveRecipeCandidate>> list(String projectMoveId,
      {bool manualSelection = false}) async {
    final catalogId =
        battleRecipeCatalogMoveId(projectMoveId, allowUnknown: manualSelection);
    if (catalogId == null) {
      throw const FormatException('Unknown move catalog identity.');
    }
    final entries = await media.listMoveMedia(catalogId);
    final choices = <BattleMoveRecipeCandidate>[];
    for (final entry in entries) {
      if (entry.usage != 'battle' || entry.representation != 'recipe') {
        continue;
      }
      final metadata = entry.metadata;
      final bindings = metadata['bindings'];
      if (entry.contentType != 'application/vnd.avelune.battle-recipe+json' ||
          (!manualSelection && metadata['moveSourceId'] != catalogId) ||
          bindings is! Map ||
          bindings.length > 256 ||
          bindings.entries.any((e) =>
              e.key is! String ||
              (e.key as String).isEmpty ||
              (e.key as String).trim() != e.key ||
              e.value is! String ||
              !RegExp(r'^[a-z0-9][a-z0-9-]{0,127}$')
                  .hasMatch(e.value as String))) {
        throw const FormatException('Invalid move recipe metadata.');
      }
      final binding = BattleMoveRecipeBinding.fromJson({
        'schemaVersion': 1,
        'projectMoveId': projectMoveId,
        'sourceMoveId': metadata['moveSourceId'],
        'catalogReleaseId': media.release,
        'recipeId': metadata['recipeId'],
        'variant': metadata['variant'],
        'revision': metadata['revision'],
        'recipeSha256': entry.sha256,
      });
      choices.add(BattleMoveRecipeCandidate(
          catalogMoveId: catalogId,
          mediaId: entry.id,
          style: entry.style,
          binding: binding));
    }
    return List.unmodifiable(choices);
  }
}

enum BattleMoveRecipeSelectionStatus {
  available,
  alreadyPresent,
  preserved,
  missing,
  ambiguous,
  custom,
  uncertain,
}

final class BattleMoveRecipeSelection {
  const BattleMoveRecipeSelection(this.status,
      {this.candidate, this.isPilotFallback = false});

  final BattleMoveRecipeSelectionStatus status;
  final BattleMoveRecipeCandidate? candidate;
  final bool isPilotFallback;
}

BattleMoveRecipeSelection selectBattleMoveRecipe(
    List<BattleMoveRecipeCandidate> candidates,
    {BattleRecipeProjectBinding? existing}) {
  if (candidates.isNotEmpty &&
      candidates.any((item) =>
          item.binding.projectMoveId !=
              candidates.first.binding.projectMoveId ||
          item.binding.catalogReleaseId !=
              candidates.first.binding.catalogReleaseId ||
          item.catalogMoveId != candidates.first.catalogMoveId)) {
    throw const FormatException('Recipe candidates belong to different moves.');
  }
  for (final style in ['gen5-bw2', 'gen5-pilot']) {
    final matching = candidates.where((item) => item.style == style).toList();
    if (matching.length > 1) {
      return const BattleMoveRecipeSelection(
          BattleMoveRecipeSelectionStatus.ambiguous);
    }
    if (matching.isEmpty) continue;
    final candidate = matching.single;
    if (existing != null) {
      final left = existing.binding.toJson();
      final right = candidate.binding.toJson();
      final same = existing.catalogMoveId == candidate.catalogMoveId &&
          existing.recipeMediaId == candidate.mediaId &&
          left.length == right.length &&
          left.entries.every((entry) => right[entry.key] == entry.value);
      return BattleMoveRecipeSelection(
          same
              ? BattleMoveRecipeSelectionStatus.alreadyPresent
              : BattleMoveRecipeSelectionStatus.preserved,
          candidate: candidate,
          isPilotFallback: style == 'gen5-pilot');
    }
    return BattleMoveRecipeSelection(BattleMoveRecipeSelectionStatus.available,
        candidate: candidate, isPilotFallback: style == 'gen5-pilot');
  }
  return BattleMoveRecipeSelection(existing == null
      ? BattleMoveRecipeSelectionStatus.missing
      : BattleMoveRecipeSelectionStatus.preserved);
}
