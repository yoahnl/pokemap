final class PokemonMoveRecipeChoice {
  const PokemonMoveRecipeChoice({
    required this.catalogMoveId,
    required this.mediaId,
    required this.sourceMoveId,
    required this.recipeSha256,
    required this.variant,
    required this.revision,
    required this.style,
  });

  final String catalogMoveId;
  final String mediaId;
  final String sourceMoveId;
  final String recipeSha256;
  final String variant;
  final String revision;
  final String style;
}
