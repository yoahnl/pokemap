import 'package:flutter/material.dart';

import '../../../features/pokemon/domain/pokemon_workspace_models.dart';
import '../../theme/studio_tokens.dart';
import 'pokemon_ui_parts.dart';

class PokemonMoveEmblem extends StatelessWidget {
  const PokemonMoveEmblem({super.key, required this.move, this.size = 42});

  final PokemonMoveSummary move;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = StudioPokemonTypeColors.forType(move.type, scheme.primary);
    final strength = (move.power ?? 0).clamp(0, 150) / 150;
    final near = Color.lerp(
      scheme.surfaceContainerHigh,
      accent,
      .43 + strength * .27,
    )!;
    final far = Color.lerp(
      scheme.surfaceContainerHigh,
      accent,
      .63 + strength * .34,
    )!;
    final category = pokemonMoveCategoryLabel(move.category);
    final type = move.type == null
        ? 'Type inconnu'
        : pokemonTypeLabel(move.type!);
    final description =
        '$type · $category'
        '${move.power == null ? '' : ' · puissance ${move.power}'}'
        '${move.userCreated ? ' · créée dans le projet' : ''}';
    return Semantics(
      label: description,
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: size,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [near, far],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accent.withValues(alpha: .7)),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    pokemonMoveTypeIcon(move.type),
                    size: size * .49,
                    color: scheme.onSurface,
                  ),
                ),
                Positioned(
                  right: 1,
                  bottom: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.surface.withValues(alpha: .88),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        pokemonMoveCategoryIcon(move.category),
                        size: size * .31,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                ),
                if (move.userCreated)
                  Positioned(
                    right: 2,
                    top: 0,
                    child: Icon(
                      Icons.star_rounded,
                      size: size * .31,
                      color: scheme.onSurface,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String pokemonMoveCategoryLabel(String? category) =>
    switch (category?.toLowerCase()) {
      'physical' => 'Physique',
      'special' => 'Spéciale',
      'status' => 'Statut',
      null => 'Catégorie inconnue',
      final String other => other,
    };

IconData pokemonMoveCategoryIcon(String? category) =>
    switch (category?.toLowerCase()) {
      'physical' => Icons.sports_martial_arts,
      'special' => Icons.auto_awesome,
      'status' => Icons.shield_outlined,
      _ => Icons.help_outline,
    };

IconData pokemonMoveTypeIcon(String? type) =>
    switch (type?.trim().toLowerCase()) {
      'normal' => Icons.circle_outlined,
      'fire' => Icons.local_fire_department,
      'water' => Icons.water_drop,
      'electric' => Icons.bolt,
      'grass' || 'plant' => Icons.eco,
      'ice' => Icons.ac_unit,
      'fighting' => Icons.sports_mma,
      'poison' => Icons.science,
      'ground' => Icons.terrain,
      'flying' => Icons.air,
      'psychic' => Icons.psychology,
      'bug' => Icons.bug_report,
      'rock' => Icons.hexagon_outlined,
      'ghost' => Icons.visibility_off,
      'dragon' => Icons.pets,
      'dark' => Icons.nightlight_round,
      'steel' => Icons.hardware,
      'fairy' => Icons.star_outline,
      _ => Icons.help_outline,
    };
