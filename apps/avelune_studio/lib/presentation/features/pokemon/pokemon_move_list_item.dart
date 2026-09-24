import 'package:flutter/material.dart';

import '../../../features/pokemon/domain/pokemon_workspace_models.dart';
import '../../theme/studio_tokens.dart';
import 'pokemon_move_emblem.dart';
import 'pokemon_ui_parts.dart';

class PokemonMoveListItem extends StatelessWidget {
  const PokemonMoveListItem({
    super.key,
    required this.entry,
    required this.selected,
    required this.choosing,
    required this.onTap,
    required this.onChoose,
  });

  final PokemonMoveSummary entry;
  final bool selected;
  final bool choosing;
  final VoidCallback onTap;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Material(
        color: selected
            ? colors.primaryContainer.withValues(alpha: .7)
            : colors.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StudioMetrics.controlRadius),
          side: BorderSide(
            color: selected ? colors.primary : colors.outlineVariant,
          ),
        ),
        child: InkWell(
          key: ValueKey('move-${entry.id}'),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              children: [
                PokemonMoveEmblem(
                  key: ValueKey('move-emblem-${entry.id}'),
                  move: entry,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.name,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${entry.type == null ? 'Type inconnu' : pokemonTypeLabel(entry.type!)}'
                        ' · ${pokemonMoveCategoryLabel(entry.category)}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (choosing)
                  IconButton(
                    tooltip: 'Choisir cette attaque',
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: onChoose,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
